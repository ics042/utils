#!/usr/bin/env bash

# If you would like to do some extra provisioning you may
# add any commands you wish to this file and they will
# be run after the Homestead machine is provisioned.

HOSTNAME=$1
SERVER_TIMEZONE=$2
MYSQL_ROOT_PASSWORD=$3
DB_NAME=$4
DB_USER=$5
DB_PASS=$6

echo -e "\n--- Installing softwares now... ---\n"

echo -e "\n--- Updating packages list ---\n"
apt-get -qq update --fix-missing

echo -e "\n--- Install base packages ---\n"
sudo apt-get -y install vim curl build-essential python-software-properties git

echo -e "\n--- Setting timezone ---\n"
sudo ln -sf /usr/share/zoneinfo/${SERVER_TIMEZONE} /etc/localtime

echo -e "\n--- Installing PHP ---\n"

sudo apt-get -y install php7.0 php7.0-mysql php7.0-cli php7.0-gd php7.0-json
sudo apt-get -y install php7.0-curl php7.0-mcrypt php-xdebug php7.0-mbstring php7.0-dom php7.0-zip 

# xdebug Config
echo -e "\n--- Configuring xdebug for PHP ---\n"

XDEBUGCFG=$(cat << EOF
zend_extension=$(find /usr/lib/php/ -name xdebug.so)
xdebug.remote_enable = 1
;xdebug.remote_connect_back = 1
xdebug.remote_handler=dbgp
xdebug.remote_host=10.0.2.2
xdebug.idekey = "netbeans-xdebug"
xdebug.remote_port = 9000
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1
xdebug.overload_var_dump = 0
xdebug.remote_log = /tmp/php7-xdebug.log
EOF
)
echo "${XDEBUGCFG}" | sudo tee $(find /etc/php/7.0 -name xdebug.ini)
echo -e "\n--- Installing Apache2 ---\n"

sudo apt-get install -y apache2 libapache2-mod-php7.0

echo "ServerName $HOSTNAME" >> /etc/apache2/apache2.conf
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# Setup virtualhost 
VHOST=$(cat <<EOF
<VirtualHost *:80>
	ServerName  $HOSTNAME
	DocumentRoot /vagrant/www/web
	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>
	<Directory /vagrant/www/web>
		Options Indexes FollowSymLinks MultiViews
		Require all granted
		AllowOverride All
	</Directory>
    ErrorLog /var/log/apache2/${HOSTNAME}_error.log
    LogLevel warn
    CustomLog /var/log/apache2/${HOSTNAME}_access.log combined
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-enabled/000-default.conf

sudo a2dismod mpm_event
sudo a2enmod mpm_prefork rewrite headers ssl actions
sudo service apache2 restart

echo -e "\n--- Installing Composer for PHP package management ---\n"
curl --silent https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo -e "\n--- Updating project components and pulling latest versions ---\n"

cd /vagrant/www

sudo composer install

echo -e "\n--- MySQL Installation ---\n"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"

sudo apt-get install -y mysql-server

sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

MYSQL=`which mysql`
Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;"
Q2="GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
$MYSQL -uroot -p$MYSQL_ROOT_PASSWORD -e "$SQL"

echo -e "\n--- Init DB ---\n"
Q1="CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
Q2="CREATE USER '${DB_USER}' IDENTIFIED BY '${DB_PASS}';"
Q3="GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
Q4="GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';;"
Q5="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}"

MYSQL=`which mysql`
$MYSQL -uroot -p$MYSQL_ROOT_PASSWORD -e "$SQL"

service mysql restart