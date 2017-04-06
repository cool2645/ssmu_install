#!/bin/bash

# A script to automatically install and config ss mu py.
# Author: Harry from 2645 Studio
# Date: 2017-4-1

# Update system and get some packages
apt-get update
apt-get upgrade -y
apt-get install make gcc g++ rsyslog supervisor redis-server git wget curl python python-pip m2crypto -y
source ../patch/libsodium.sh

# Source config file and copy iptables config file
source ./ssmu.cfg
if [ $is_iptables != 0 ];
then
	cp iptables.banmailports.rules /etc/iptables.banmailports.rules
fi

# Install pip and ss py mu
cd /root
git clone https://github.com/fsgmhoward/shadowsocks-py-mu.git

# Write ssmu-py config file
cd /root/shadowsocks-py-mu/shadowsocks
echo "import logging" >> config.py
echo "CONFIG_VERSION = '20160623-2'" >> config.py
echo "API_ENABLED = $api_enable" >> config.py
echo "MYSQL_HOST = '$my_host'" >> config.py
echo "MYSQL_PORT = $my_port" >> config.py
echo "MYSQL_USER = '$my_user'" >> config.py
echo "MYSQL_PASS = '$my_pass'" >> config.py
echo "MYSQL_DB = '$my_db'" >> config.py
echo "MYSQL_USER_TABLE = '$my_table'" >> config.py
echo "MYSQL_TIMEOUT = 30" >> config.py
echo "API_URL = '$api_url'" >> config.py
echo "API_PASS = '$api_key'" >> config.py
echo "NODE_ID = '$api_node_id'" >> config.py
echo "CHECKTIME = 30" >> config.py
echo "SYNCTIME = 120" >> config.py
echo "CUSTOM_METHOD = $custom_method" >> config.py
echo "MANAGE_PASS = 'passwd'" >> config.py
echo "MANAGE_BIND_IP = '127.0.0.1'" >> config.py
echo "MANAGE_PORT = 65000" >> config.py
echo "SS_BIND_IP = '::'" >> config.py
echo "SS_METHOD = '$ss_method'" >> config.py
echo "SS_OTA = False" >> config.py
echo "SS_SKIP_PORTS = $ss_skip_ports" >> config.py
echo "SS_FASTOPEN = False" >> config.py
echo "SS_TIMEOUT = 185" >> config.py
echo "SS_FIREWALL_ENABLED = $firewall_enable" >> config.py
echo "SS_FIREWALL_MODE = '$firewall_mode'" >> config.py
echo "SS_BAN_PORTS = $ban_ports" >> config.py
echo "SS_ALLOW_PORTS = $allow_ports" >> config.py
echo "SS_FIREWALL_TRUSTED = [443]" >> config.py
echo "SS_FORBIDDEN_IP = []" >> config.py
echo "LOG_ENABLE = True" >> config.py
echo "SS_VERBOSE = False" >> config.py
echo "LOG_LEVEL = logging.INFO" >> config.py
echo "LOG_FILE = 'shadowsocks.log'" >> config.py
echo "LOG_FORMAT = '%(asctime)s %(levelname)s %(message)s'" >> config.py
echo "LOG_DATE_FORMAT = '%b %d %H:%M:%S'" >> config.py

# Write supervisor config file
cd /etc/supervisor/conf.d
echo "[program:ssserver]" >> ssserver.conf
echo "command = python /root/shadowsocks-py-mu/shadowsocks/servers.py" >> ssserver.conf
echo "directory = /root/shadowsocks-py-mu/shadowsocks/" >> ssserver.conf
echo "user = root" >> ssserver.conf
echo "autostart = true" >> ssserver.conf
echo "autorestart = true" >> ssserver.conf
echo "stdout_logfile = /var/log/supervisor/ssserver.log" >> ssserver.conf
echo "stderr_logfile = /var/log/supervisor/ssserver_err.log" >> ssserver.conf

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
supervisorctl reload

echo "ssmu-py install complete QwQ"
