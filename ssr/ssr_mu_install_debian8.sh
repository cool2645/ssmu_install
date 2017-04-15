#!/bin/bash

# A script to automatically install and config ssr mu.
# Author: LJH from 2645 Studio
# Date: 2017-4-15

# Update system and get some packages
apt-get update
apt-get upgrade -y
apt-get install make gcc g++ rsyslog supervisor redis-server git wget curl python python-pip m2crypto -y
pip install cymysql
source ../patch/libsodium.sh

# Source config file and copy iptables config file
source ./ssmu.cfg
if [ $is_iptables != 0 ];
then
	cp iptables.banmailports.rules /etc/iptables.banmailports.rules
fi

# Install ssr mu
cd /root
git clone https://github.com/2645Corp/shadowsocksr.git

# Write ssmu-py config file
cd /root/shadowsocksr
bash initcfg.sh

echo "API_INTERFACE = 'sspanelv3'" > userapiconfig.py
echo "UPDATE_TIME = 60" >> userapiconfig.py
echo "MYSQL_CONFIG = 'usermysql.json'" >> userapiconfig.py

echo '{' > usermysql.json
echo "    \"host\": \"$my_host\"," >> usermysql.json
echo "    \"port\": $my_port," >> usermysql.json
echo "    \"user\": \"$my_user\"," >> usermysql.json
echo "    \"password\": \"$my_pass\"," >> usermysql.json
echo "    \"db\": \"$my_db\"," >> usermysql.json
echo "    \"node_id\": $api_node_id," >> usermysql.json
echo "    \"transfer_mul\": $transfer_mul," >> usermysql.json
echo "    \"ssl_enable\": 0," >> usermysql.json
echo "    \"ssl_ca\": \"\"," >> usermysql.json
echo "    \"ssl_cert\": \"\"," >> usermysql.json
echo "    \"ssl_key\": \"\"" >> usermysql.json
echo "}" >> usermysql.json

echo "{" > user-config.json
echo "    \"server\": \"0.0.0.0\"," >> user-config.json
echo "    \"server_ipv6\": \"::\"," >> user-config.json
echo "    \"password\": \"$password\"," >> user-config.json
echo "    \"protocol\": \"$protocol\"," >> user-config.json
echo "    \"protocol_param\": \"$protocol_param\"," >> user-config.json
echo "    \"obfs\": \"$obfs\"," >> user-config.json
echo "    \"obfs_param\": \"$obfs_param\"," >> user-config.json
echo "    \"redirect\": \"$redirect\"," >> user-config.json
if [[ $add_enable  ]]; then
	echo "    \"additional_ports\": {" >> user-config.json
	echo "        \"$add_port\": {" >> user-config.json
	echo "            \"passwd\": \"$add_passwd\"," >> user-config.json
	echo "            \"method\": \"$add_method\"," >> user-config.json
	echo "            \"protocol\": \"$add_protocol\"," >> user-config.json
	echo "            \"protocol_param\": \"$add_protocol_param\"," >> user-config.json
	echo "            \"obfs\": \"$add_obfs\"," >> user-config.json
	echo "            \"obfs_param\": \"$add_obfs_param\"" >> user-config.json
	echo "        }" >> user-config.json
	echo "    }," >> user-config.json
fi
echo "    \"additional_ports_only\": \"$add_only\"," >> user-config.json
echo "    \"timeout\": 120," >> user-config.json
echo "    \"udp_timeout\": 60," >> user-config.json
echo "    \"dns_ipv6\": false," >> user-config.json
echo "    \"connect_verbose_info\": 0," >> user-config.json
echo "    \"fast_open\": $fast_open" >> user-config.json
echo "}" >> user-config.json

# Write supervisor config file
cd /etc/supervisor/conf.d
echo "[program:ssrserver_prq]" >> ssrserver.conf
echo "command = ulimit -n 512000" >> ssrserver.conf
echo "autostart = true" >> ssrserver.conf
echo "stdout_logfile = /var/log/supervisor/ssrserver_prq.log" >> ssrserver.conf
echo "stderr_logfile = /var/log/supervisor/ssrserver_prq_err.log" >> ssrserver.conf
echo "[program:ssrserver]" >> ssrserver.conf
echo "command = python /root/shadowsocksr/server.py" >> ssrserver.conf
echo "directory = /root/shadowsocksr/" >> ssrserver.conf
echo "user = root" >> ssrserver.conf
echo "autostart = true" >> ssrserver.conf
echo "autorestart = true" >> ssrserver.conf
echo "stdout_logfile = /var/log/supervisor/ssrserver.log" >> ssrserver.conf
echo "stderr_logfile = /var/log/supervisor/ssrserver_err.log" >> ssrserver.conf

# Install serverspeeder if necessary
cd /root
if [ $is_serverspeeder != 0 ];
then
	wget -N --no-check-certificate https://raw.githubusercontent.com/91yun/serverspeeder/master/serverspeeder-all.sh && bash serverspeeder-all.sh
fi

# Overwrite iptables if necessary
if [ $is_iptables != 0 ];
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
systemctl enable supervisor
systemctl restart supervisor
supervisorctl reload

echo "ssr mu install complete QwQ"
