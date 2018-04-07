#!/bin/bash
#sudo su
#apt-get update -y && apt-get install git -y && cd && git clone https://github.com/catonrug/zabbix-mariadb-nginx-raspbian-stretch.git && cd zabbix-mariadb-nginx-raspbian-stretch && chmod +x install-zabbix-server.sh && time ./install-zabbix-server.sh


apt-get update -y
apt-get dist-upgrade -y
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

mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'CREATE DATABASE zabbix CHARACTER SET UTF8'
mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'GRANT ALL PRIVILEGES on zabbix.* to "zabbix"@"localhost" IDENTIFIED BY "drFJ7xx5MNTbqJ39"'


groupadd zabbix
useradd -g zabbix zabbix
#mkdir -p /var/log/zabbix
#chown -R zabbix:zabbix /var/log/zabbix/
#mkdir -p /var/zabbix/alertscripts
#mkdir -p /var/zabbix/externalscripts
#chown -R zabbix:zabbix /var/zabbix/

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
./configure --enable-server --enable-agent --with-mysql --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber

time make install &&

cp ~/zabbix-*/misc/init.d/debian/* /etc/init.d/

update-rc.d zabbix-server defaults
update-rc.d zabbix-agent defaults

#show existing configuration
grep -v "^#\|^$" /usr/local/etc/zabbix_server.conf
echo

sed -i "s/^DBUser=.*$/DBUser=zabbix/" /usr/local/etc/zabbix_server.conf
sed -i "s/^.*DBPassword=.*$/DBPassword=drFJ7xx5MNTbqJ39/" /usr/local/etc/zabbix_server.conf
#sed -i "s/^.*AlertScriptsPath=.*$/AlertScriptsPath=\/var\/zabbix\/alertscripts/" /usr/local/etc/zabbix_server.conf
#sed -i "s/^.*ExternalScripts=.*$/ExternalScripts=\/var\/zabbix\/externalscripts/" /usr/local/etc/zabbix_server.conf
sed -i "s/^LogFile=.*$/LogFile=\/tmp\/zabbix_server.log/" /usr/local/etc/zabbix_server.conf

grep -v "^#\|^$" /usr/local/etc/zabbix_server.conf
echo

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

/etc/init.d/zabbix-server restart
/etc/init.d/zabbix-agent restart
/etc/init.d/php7.0-fpm restart
/etc/init.d/nginx restart

