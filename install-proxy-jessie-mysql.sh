#!/bin/bash
apt-get update -y
apt-get dist-upgrade -y
apt-get install mysql-server -y #you are prompted to enter password here. please enter password [password]
apt-get install mysql-client libmysqlclient-dev -y
apt-get install fping -y
apt-get install libiksemel-dev -y #configure: error: Jabber library not found
apt-get install libxml2-dev -y #configure: error: LIBXML2 library not found
apt-get install libsnmp-dev -y #configure: error: Not found Net-SNMP library
apt-get install libssh2-1-dev -y #configure: error: SSH2 library not found
apt-get install libopenipmi-dev -y #configure: error: Invalid OPENIPMI directory - unable to find ipmiif.h
apt-get install libcurl4-openssl-dev -y #configure: error: Not found Curl library
apt-get install libevent-dev -y #configure: error: Unable to use libevent (libevent check failed)
apt-get install libpcre3-dev #configure: error: Unable to use libpcre (libpcre check failed)
apt-get install php5-gd -y

apt-get install libssl-dev -y #configure: error: OpenSSL library libssl or libcrypto not found
apt-get install unixodbc-dev -y

mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'CREATE DATABASE zabbix CHARACTER SET UTF8'
mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'GRANT ALL PRIVILEGES on zabbix.* to "zabbix"@"localhost" IDENTIFIED BY "drFJ7xx5MNTbqJ39"'

groupadd zabbix
useradd -g zabbix zabbix

cd 

#download source
wget "http://downloads.sourceforge.net/project/zabbix/ZABBIX Latest Stable/3.4.8/zabbix-3.4.8.tar.gz"

#extract archive
tar -vzxf zabbix-*.tar.gz -C ~

#move to the sources root
cd ~/zabbix-*/

#check and configure
./configure --enable-proxy --enable-agent --with-mysql --with-libcurl --with-libxml2 --with-ssh2 --with-net-snmp --with-openipmi --with-jabber --with-openssl --with-unixodbc

#install
time make install &&

echo $?

mysql -uroot -ppassword

#drop some databases if not necessary.

#create database:

mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'CREATE DATABASE zabbix_proxy CHARACTER SET UTF8 collate utf8_bin'

#create user with password and assign to the database
mysql -h localhost -uroot -ppassword -P 3306 -s <<< 'GRANT ALL PRIVILEGES on zabbix_proxy.* to "zabbix"@"localhost" IDENTIFIED BY "drFJ7xx5MNTbqJ39"'

#install database schema
cd ~/zabbix-*/database/mysql
echo processing schema.sql
time mysql -uzabbix -pdrFJ7xx5MNTbqJ39 zabbix < schema.sql

#install service
cp ~/zabbix-*/misc/init.d/debian/* /etc/init.d/

#rename zabbix-server service to zabbix-proxy service
mv /etc/init.d/{zabbix-server,zabbix-proxy}

#substitute
sed -i "s/server/proxy/g" /etc/init.d/zabbix-proxy

#refresh services
update-rc.d zabbix-proxy defaults
update-rc.d zabbix-agent defaults

#tell zabbix server what is the password for mysql user zabbix
sed -i "s/^.*DBPassword=.*$/DBPassword=drFJ7xx5MNTbqJ39/" /usr/local/etc/zabbix_proxy.conf

systemctl start {zabbix-proxy,zabbix-agent}
