#!/bin/bash
#sudo su
#apt-get update -y && apt-get install git -y && mkdir -p ~/git && cd ~/git && git clone https://github.com/catonrug/zabbix-mariadb-nginx-raspbian-stretch.git && cd zabbix-mariadb-nginx-raspbian-stretch && time ./install-zabbix-proxy-stretch.sh

apt-get update -y
apt-get dist-upgrade -y
apt-get update -y
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
useradd -g zabbix zabbix


cd ~/zabbix-*/
./configure --enable-server --enable-agent --with-mysql --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc

groupadd zabbix
useradd -g zabbix zabbix


time make install &&

#start zabbix server at reboot
cat > /etc/init.d/zabbix-server << EOF
#!/bin/sh
### BEGIN INIT INFO
# Provides:          zabbix-server
# Required-Start:    \$remote_fs \$network
# Required-Stop:     \$remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Should-Start:      mysql
# Should-Stop:       mysql
# Short-Description: Start zabbix-server daemon
### END INIT INFO
EOF
grep -v "^#\!\/bin\/sh$" ~/zabbix-*/misc/init.d/debian/zabbix-server >> /etc/init.d/zabbix-server
chmod +x /etc/init.d/zabbix-server

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
systemctl enable zabbix-server
systemctl enable zabbix-agent

#show existing configuration
grep -v "^#\|^$" /usr/local/etc/zabbix_server.conf
echo

sed -i "s/^DBUser=.*$/DBUser=zabbix/" /usr/local/etc/zabbix_server.conf
sed -i "s/^Timeout=.*$/Timeout=30/" /usr/local/etc/zabbix_server.conf
sed -i "s/^LogFile=.*$/LogFile=\/tmp\/zabbix_server.log/" /usr/local/etc/zabbix_server.conf

grep "^DBPassword=" /usr/local/etc/zabbix_server.conf > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^DBPassword=.*$/DBPassword=drFJ7xx5MNTbqJ39/" /usr/local/etc/zabbix_server.conf
else
echo "DBPassword=drFJ7xx5MNTbqJ39" >> /usr/local/etc/zabbix_server.conf
fi

grep "^CacheUpdateFrequency=" /usr/local/etc/zabbix_server.conf > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^CacheUpdateFrequency=.*$/CacheUpdateFrequency=4/" /usr/local/etc/zabbix_server.conf
else
echo "CacheUpdateFrequency=4" >> /usr/local/etc/zabbix_server.conf
fi

grep "^SSHKeyLocation=" /usr/local/etc/zabbix_server.conf > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^SSHKeyLocation=.*$/SSHKeyLocation=\/home\/zabbix\/.ssh/" /usr/local/etc/zabbix_server.conf
else
echo "SSHKeyLocation=/home/zabbix/.ssh" >> /usr/local/etc/zabbix_server.conf
fi

apt-get install fping -y
sed -i "s/^.*FpingLocation=.*$/FpingLocation=\/usr\/bin\/fping/" /usr/local/etc/zabbix_server.conf

grep -v "^#\|^$" /usr/local/etc/zabbix_server.conf
echo

#do some agent configuratiuon

grep "^EnableRemoteCommands=" /usr/local/etc/zabbix_agentd.conf > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^EnableRemoteCommands=.*$/EnableRemoteCommands=1/" /usr/local/etc/zabbix_agentd.conf
else
echo "EnableRemoteCommands=1" >> /usr/local/etc/zabbix_agentd.conf
fi

grep "^LogRemoteCommands=" /usr/local/etc/zabbix_agentd.conf > /dev/null
if [ $? -eq 0 ]; then
sed -i "s/^LogRemoteCommands=.*$/LogRemoteCommands=1/" /usr/local/etc/zabbix_agentd.conf
else
echo "LogRemoteCommands=1" >> /usr/local/etc/zabbix_agentd.conf
fi

grep "^Include=" /usr/local/etc/zabbix_agentd.conf > /dev/null
if [ $? -ne 0 ]; then
echo "Include=/usr/local/etc/zabbix_agentd.conf.d/*.conf" >> /usr/local/etc/zabbix_agentd.conf
fi

mkdir /var/www/html/zabbix
cd ~/zabbix-*/frontends/php/
cp -a . /var/www/html/zabbix/
chown -R www-data:www-data /var/www

cd
grep post_max_size /etc/php/7.0/fpm/php.ini
sed -i "s/^post_max_size = .*$/post_max_size = 16M/" /etc/php/7.0/fpm/php.ini
grep post_max_size /etc/php/7.0/fpm/php.ini
echo

grep max_execution_time /etc/php/7.0/fpm/php.ini
sed -i "s/^max_execution_time = .*$/max_execution_time = 300/" /etc/php/7.0/fpm/php.ini
grep max_execution_time /etc/php/7.0/fpm/php.ini
echo

grep max_input_time /etc/php/7.0/fpm/php.ini
sed -i "s/^max_input_time = .*$/max_input_time = 300/g" /etc/php/7.0/fpm/php.ini
grep max_input_time /etc/php/7.0/fpm/php.ini
echo

grep "date.timezone" /etc/php/7.0/fpm/php.ini
sed -i "s/^.*date.timezone =.*$/date.timezone = Europe\/Riga/g" /etc/php/7.0/fpm/php.ini
grep "date.timezone" /etc/php/7.0/fpm/php.ini
echo

#restore backup
if [ ! -d "/home/pi/backup" ]; then
cd /home/pi/backup
cp -R * /

chown -R pi:pi /home/pi

if [ -f "/home/pi/dbdump.bz2" ]; then
bzcat /home/pi/dbdump.bz2 | sudo mysql zabbix
fi

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

#install certboot agentls
curl -s https://dl.eff.org/certbot-auto > /usr/bin/certbot
chmod 770 /usr/bin/certbot
#integrate some certbot settings
mkdir -p /etc/letsencrypt
echo renew-hook = systemctl reload nginx> /etc/letsencrypt/cli.ini

#set google uploader executable
chmod +x /home/pi/uploader.py

#fix crontab permissions
chmod +x /etc/cron.daily/backup-zabbix-db

#remove symlink - default nginx sites
unlink /etc/nginx/sites-enabled/default
ln -s /etc/nginx/sites-available/5d61050b753b.sn.mynetname.net /etc/nginx/sites-enabled/5d61050b753b.sn.mynetname.net

fi

systemctl start {zabbix-server,zabbix-agent}
systemctl restart {php7.0-fpm,nginx}


apt-get install bc -y #to work with external SSL check zabbix template

#backup solution for google drive. https://catonrug.blogspot.com/2016/01/upload-file-to-google-drive-raspbian-command-line.html
apt-get install python-pip -y
pip install --upgrade google-api-python-client

#additional json library. usage for example https://catonrug.blogspot.com/2018/03/show-isp-for-zabbix-active-agents.html
apt-get install jq -y

#aditional tools. not necessary for zabbix server
apt-get install tree -y #list direcotry structrure really beautifully with tree -a
apt-get install vim -y #colored vi editor
apt-get install apt-file -y #for searching which package include specific binary
apt-get install snmp -y #to install snmpwalk utility


