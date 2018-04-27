#!/bin/bash
#sudo su
#apt-get update -y && apt-get install git -y && mkdir -p ~/git && cd ~/git && git clone https://github.com/catonrug/zabbix-mariadb-nginx-raspbian-stretch.git && cd zabbix-mariadb-nginx-raspbian-stretch && time ./install-zabbix-proxy-stretch.sh

apt-get update -y
apt-get dist-upgrade -y
apt-get update -y

apt-get install bc -y #to work with external SSL check zabbix template

#backup solution to google drive 
#https://catonrug.blogspot.com/2016/01/upload-file-to-google-drive-raspbian-command-line.html
apt-get install python-pip -y
pip install --upgrade google-api-python-client

#additional json library. usage for example https://catonrug.blogspot.com/2018/03/show-isp-for-zabbix-active-agents.html
apt-get install jq -y

#aditional tools. not necessary for zabbix server
apt-get install tree -y #list direcotry structrure really beautifully with tree -a
apt-get install vim -y #colored vi editor
apt-get install apt-file -y #for searching which package include specific binary
apt-get install snmp -y #to install snmpwalk utility

apt-get install mysql-server -y
apt-get install mysql-client -y
apt-get install default-libmysqlclient-dev -y
echo

#create empty database with name 'zabbix_proxy'
mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'CREATE DATABASE zabbix_proxy CHARACTER SET UTF8'
mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'GRANT ALL PRIVILEGES on zabbix_proxy.* to "zabbix"@"localhost" IDENTIFIED BY "drFJ7xx5MNTbqJ39"'
mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'show databases;'

cd
wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.8/zabbix-3.4.8.tar.gz
tar -vzxf zabbix-*.tar.gz -C ~

cd ~/zabbix-*/database/mysql
echo processing schema.sql
time mysql -uzabbix -pdrFJ7xx5MNTbqJ39 zabbix_proxy < schema.sql

apt-get install libiksemel-dev -y #configure: error: Jabber library not found
apt-get install libxml2-dev -y #configure: error: LIBXML2 library not found
apt-get install unixodbc-dev -y #configure: error: unixODBC library not found
apt-get install libsnmp-dev -y #configure: error: Invalid Net-SNMP directory - unable to find net-snmp-config
apt-get install libssh2-1-dev -y #configure: error: SSH2 library not found
apt-get install libopenipmi-dev -y #configure: error: Invalid OPENIPMI directory - unable to find ipmiif.h
apt-get install libevent-dev -y #configure: error: Unable to use libevent (libevent check failed)
apt-get install libssl-dev -y #configure: error: OpenSSL library libssl or libcrypto not found
apt-get install libcurl4-openssl-dev -y #configure: error: Curl library not found
apt-get install libpcre3-dev -y #configure: error: Unable to use libpcre (libpcre check failed)


cd ~/zabbix-*/
./configure --enable-proxy --enable-agent --with-mysql --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc


groupadd zabbix
useradd -g zabbix -d /var/lib/zabbix -s /usr/sbin/nologin zabbix

cd ~/zabbix-*/

groupadd zabbix
useradd -g zabbix zabbix


time make install &&

#start zabbix server at reboot
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

#show existing configuration
proxy=/usr/local/etc/zabbix_proxy.conf

grep -v "^#\|^$" $proxy
echo

#what is the server name of zabbix server
sed -i "s/^Server=.*$/Server=ec2-35-166-97-138.us-west-2.compute.amazonaws.com/" $proxy
#set hostname the same as systems
#sed -i "s/^Hostname=.*$/Hostname=ProxyHome/" $proxy
sed -i "s/^Hostname=.*$/Hostname=$(ifconfig | egrep -o -m1 ":..:..:.. " | sed "s/://g")/" $proxy
#database username
sed -i "s/^DBUser=.*$/DBUser=zabbix/" $proxy
#set db password
grep "^DBPassword=" $proxy > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^DBPassword=.*$/DBPassword=drFJ7xx5MNTbqJ39/" $proxy
else
echo "DBPassword=drFJ7xx5MNTbqJ39" >> $proxy
fi

sed -i "s/^Timeout=.*$/Timeout=30/" $proxy
sed -i "s/^LogFile=.*$/LogFile=\/tmp\/zabbix_proxy.log/" $proxy


grep "^CacheUpdateFrequency=" $proxy > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^CacheUpdateFrequency=.*$/CacheUpdateFrequency=4/" $proxy
else
echo "CacheUpdateFrequency=4" >> $proxy
fi

grep "^SSHKeyLocation=" $proxy > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^SSHKeyLocation=.*$/SSHKeyLocation=\/home\/zabbix\/.ssh/" $proxy
else
echo "SSHKeyLocation=/home/zabbix/.ssh" >> $proxy
fi

apt-get install fping -y
grep "^FpingLocation=" $proxy > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^FpingLocation=.*$/FpingLocation=\/usr\/bin\/fping/" $proxy
else
echo "FpingLocation=/usr/bin/fping" >> $proxy
fi

grep "^EnableRemoteCommands=" $proxy > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^EnableRemoteCommands=.*$/EnableRemoteCommands=1/" $proxy
else
echo "EnableRemoteCommands=1" >> $proxy
fi

grep "^LogRemoteCommands=" $proxy > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^LogRemoteCommands=.*$/LogRemoteCommands=1/" $proxy
else
echo "LogRemoteCommands=1" >> $proxy
fi





grep -v "^#\|^$" $proxy
echo

#do some agent configuratiuon
agent=/usr/local/etc/zabbix_agentd.conf
grep -v "^#\|^$" $agent

#set hostname
sed -i "s/^Hostname=.*$/Hostname=$(hostname)/" $proxy

grep "^EnableRemoteCommands=" $agent > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^EnableRemoteCommands=.*$/EnableRemoteCommands=1/" $agent
else
echo "EnableRemoteCommands=1" >> $agent
fi

grep "^LogRemoteCommands=" $agent > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^LogRemoteCommands=.*$/LogRemoteCommands=1/" $agent
else
echo "LogRemoteCommands=1" >> $agent
fi

grep "^Include=" $agent > /dev/null
if [ $? -ne 0 ]; then
echo "Include=$agent.d/*.conf" >> $agent
fi

grep -v "^#\|^$" $agent


#restore backup
if [ ! -d "/home/pi/backup" ]; then
cd /home/pi/backup
cp -R * /

chown -R pi:pi /home/pi


#install git keys
#allow only owner read and write to these keys
chmod 600 ~/.ssh/id_rsa #git private key
chmod 600 ~/.ssh/id_rsa.pub #git public key
chmod 644 ~/.gitconfig #email and username for git

#fix permissions
chown -R zabbix:zabbix /home/zabbix
chown -R zabbix:zabbix /usr/local/share/zabbix
chmod 770 /usr/local/share/zabbix/externalscripts/*
chmod 600 /home/zabbix/.my.cnf

#set google uploader executable
chmod +x /home/pi/uploader.py

fi

echo
grep -v "^#\|^$" $proxy

echo
grep -v "^#\|^$" $agent


systemctl start {zabbix-proxy,zabbix-agent}




