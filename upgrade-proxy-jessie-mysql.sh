#!/bin/bash
apt-get update -y
apt-get dist-upgrade -y
apt-get update -y

systemctl stop {zabbix-proxy,zabbix-agent}
rm /etc/init.d/{zabbix-agent,zabbix-proxy}
rm /usr/local/sbin/{zabbix_agent,zabbix_agentd,zabbix_proxy}
rm /usr/local/bin/{zabbix_get,zabbix_sender}

systemctl status mysql

cd

mkdir -p ~/temp
cd ~/temp

#download source
wget "http://downloads.sourceforge.net/project/zabbix/ZABBIX Latest Stable/3.4.8/zabbix-3.4.8.tar.gz"

#extract archive
tar -vzxf zabbix-*.tar.gz -C ~

#move to the sources root
cd ~/zabbix-*/

#check and configure
./configure --enable-proxy --enable-agent --with-mysql --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc

#install
time make install

cat > /etc/init.d/zabbix-proxy << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          zabbix-proxy
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Should-Start:      mysql
# Should-Stop:       mysql
# Short-Description: Start zabbix-proxy daemon
### END INIT INFO
EOF
grep -v "^#\!\/bin\/sh$" ~/zabbix-*/misc/init.d/debian/zabbix-server >> /etc/init.d/zabbix-proxy
sed -i "s/server/proxy/g" /etc/init.d/zabbix-proxy
chmod +x /etc/init.d/zabbix-proxy

#start zabbix agent at reboot
cat > /etc/init.d/zabbix-agent << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          zabbix-agent
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start zabbix-agent daemon
### END INIT INFO
EOF
grep -v "^#\!\/bin\/sh$" ~/zabbix-*/misc/init.d/debian/zabbix-agent >> /etc/init.d/zabbix-agent
chmod +x /etc/init.d/zabbix-agent

systemctl daemon-reload
#allow to run service at startup
systemctl enable zabbix-proxy
systemctl enable zabbix-agent

systemctl start {zabbix-proxy,zabbix-agent}
systemctl status {zabbix-proxy,zabbix-agent}
