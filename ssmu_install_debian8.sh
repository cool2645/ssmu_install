#!/bin/bash

# A script to automatically install and config ss mu.
# Author: Harry from 2645 Studio
# Date: 2016-12-17

# Update system and get some packages
apt-get update
apt-get upgrade -y
apt-get install gcc g++ rsyslog supervisor redis-server git curl -y

# Source config file and copy iptables config file
source ./ssmu.cfg
if [ $is_serverspeeder != 0 ];
then
	cp iptables.banmailports.rules /etc/iptables.banmailports.rules
fi

# Install and config go
wget -c https://storage.googleapis.com/golang/go1.6.linux-amd64.tar.gz
tar -C /usr/local -xzf go1.6.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
export GOPATH=~/.go

# Install go mu
go get github.com/orvice/shadowsocks-go
cd ~/.go/src/github.com/orvice/shadowsocks-go/mu
go get
go build

# Write ssmu config file
cd ~/.go/bin/
echo "[base]" >> config.conf
echo "N 1" >> config.conf
echo "ip 0.0.0.0" >> config.conf
echo "client webapi" >> config.conf
echo "checktime 60" >> config.conf
echo "synctime 60" >> config.conf
echo "[webapi]" >> config.conf
echo "url $api_url" >> config.conf
echo "key $api_key" >> config.conf
echo "node_id $api_node_id" >> config.conf
echo "[mysql]" >> config.conf
echo "host $my_host" >> config.conf
echo "user $my_user" >> config.conf
echo "pass $my_pass" >> config.conf
echo "db $my_db" >> config.conf
echo "table $my_table" >> config.conf
echo "[redis]" >> config.conf
echo "host $redis_host" >> config.conf

# Write supervisor config file
cd /etc/supervisor/conf.d
echo "[program:ssserver]" >> ssserver.conf
echo "command = /root/.go/bin/mu" >> ssserver.conf
echo "directory = /root/.go/bin/" >> ssserver.conf
echo "user = root" >> ssserver.conf
echo "autostart = true" >> ssserver.conf
echo "autorestart = true" >> ssserver.conf
echo "stdout_logfile = /var/log/supervisor/ssserver.log" >> ssserver.conf
echo "stderr_logfile = /var/log/supervisor/ssserver_err.log" >> ssserver.conf

# Install serverspeeder if necessary
cd ~
if [ $is_serverspeeder != 0 ];
then
	wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/code/master/vm_check.sh && bash vm_check.sh
fi

# Overwrite iptables if necessary
if [ $is_serverspeeder != 0 ];
then
	iptables-restore < /etc/iptables.banmailports.rules
	iptables-save > /etc/iptables.up.rules
	echo "#!/bin/bash" >> /etc/network/if-pre-up.d/iptables
	echo "/sbin/iptables-restore < /etc/iptables.up.rules" >> /etc/network/if-pre-up.d/iptables
	chmod +x /etc/network/if-pre-up.d/iptables
	echo ':msg,contains,"IPTABLES" /var/log/iptables.log' >> /etc/rsyslog.d/my_iptables.conf
	systemctl restart rsyslog
fi

# Reload supervisor
supervisorctl reload

echo "ssmu install complete QwQ"