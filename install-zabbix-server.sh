#!/bin/bash
#sudo su
#apt-get update -y && apt-get install git -y && mkdir -p ~/git && cd ~/git && git clone https://github.com/catonrug/zabbix-mariadb-nginx-raspbian-stretch.git && cd zabbix-mariadb-nginx-raspbian-stretch && time ./install-zabbix-server.sh


apt-get update -y
apt-get dist-upgrade -y
apt-get update -y
apt-get install mysql-server -y
apt-get install mysql-client -y
apt-get install default-libmysqlclient-dev -y
apt-get install php7.0-fpm -y
apt-get install libgd2-xpm-dev -y
apt-get install libpcrecpp0v5 -y
apt-get install libxpm4 -y
apt-get install php7.0-mysql -y
apt-get install nginx -y
apt-get install fcgiwrap -y
echo

apt-get install bc -y #to work with external SSL check zabbix template

#aditional tools. not necessary for zabbix server
apt-get install tree -y #list direcotry structrure really beautifully with tree -a
apt-get install vim -y #colored vi editor
apt-get install apt-file -y #for searching which package include specific binary
apt-get install snmp -y #to install snmpwalk utility

grep 'process.max' /etc/php/7.0/fpm/php-fpm.conf
sed -i "s/^.*process\.max = .*$/process.max = 2/" /etc/php/7.0/fpm/php-fpm.conf
grep 'process.max' /etc/php/7.0/fpm/php-fpm.conf
echo

grep 'worker_processes' /etc/nginx/nginx.conf
sed -i "s/^worker_processes .*;$/worker_processes 1;/"  /etc/nginx/nginx.conf
grep 'worker_processes' /etc/nginx/nginx.conf
echo

cp /etc/nginx/sites-available/{default,original}
ls -1 /etc/nginx/sites-available/
echo

cat > /etc/nginx/sites-available/default << EOF
server {
listen 80 default_server;
listen [::]:80 default_server;
root /var/www/html;
index index.php index.html index.htm;
server_name _;
location ~ \.php\$ {
include snippets/fastcgi-php.conf;
fastcgi_pass unix:/run/php/php7.0-fpm.sock;
}
}
EOF

apt-get install libiksemel-dev -y
apt-get install libxml2-dev -y
apt-get install libsnmp-dev -y
apt-get install libssh2-1-dev -y
apt-get install libopenipmi-dev -y
apt-get install libcurl4-openssl-dev -y
apt-get install libevent-dev -y
apt-get install libpcre3-dev -y
apt-get install php7.0-gd -y
apt-get install php7.0-xml -y
apt-get install php7.0-mbstring -y
apt-get install php7.0-bcmath -y

apt-get install unixodbc-dev -y
apt-get install libssl-dev -y #configure: error: OpenSSL library libssl or libcrypto not found

mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'CREATE DATABASE zabbix CHARACTER SET UTF8'
mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'GRANT ALL PRIVILEGES on zabbix.* to "zabbix"@"localhost" IDENTIFIED BY "drFJ7xx5MNTbqJ39"'


groupadd zabbix
useradd -g zabbix zabbix

wget http://downloads.sourceforge.net/project/zabbix/ZABBIX%20Latest%20Stable/3.4.8/zabbix-3.4.8.tar.gz
tar -vzxf zabbix-*.tar.gz -C ~
cd ~/zabbix-*/database/mysql

cd ~/zabbix-*/database/mysql
echo processing schema.sql
time mysql -uzabbix -pdrFJ7xx5MNTbqJ39 zabbix < schema.sql
echo processing images.sql
time mysql -uzabbix -pdrFJ7xx5MNTbqJ39 zabbix < images.sql
echo processing data.sql
time mysql -uzabbix -pdrFJ7xx5MNTbqJ39 zabbix < data.sql

cd ~/zabbix-*/
./configure --enable-server --enable-agent --with-mysql --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc

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
systemctl enable zabbix-server

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

if [ -f "/home/pi/dbdump.bz2" ]; then
bzcat /home/pi/dbdump.bz2 | sudo mysql zabbix
fi

systemctl start {zabbix-server,zabbix-agent}
systemctl restart {php7.0-fpm,nginx}

