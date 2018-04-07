#!/bin/bash

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

