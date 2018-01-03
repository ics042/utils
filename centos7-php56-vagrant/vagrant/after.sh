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

echo -e "\n--- Disable SELinux... ---\n"
sudo setenforce Permissive
sudo sed -i 's/^SELINUX=.*/SELINUX=disabled/g' /etc/selinux/config

echo -e "\n--- Installing softwares now... ---\n"

echo -e "\n--- Import packages list ---\n"
sudo yum -y install epel-release
sudo rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
sudo yum -y update

echo -e "\n--- Install base packages ---\n"
sudo yum -y install vim curl git

echo -e "\n--- Setting timezone ---\n"
sudo ln -sf /usr/share/zoneinfo/${SERVER_TIMEZONE} /etc/localtime

echo -e "\n--- Installing PHP ---\n"

sudo yum -y install --enablerepo=remi --enablerepo=remi-php56 php php-opcache php-devel php-mbstring php-mcrypt php-mysqlnd php-phpunit-PHPUnit php-pecl-xdebug php-pecl-xhprof php-mysql php-pdo php-soap php-gd php-xml php-pecl-apcu php-json php- php-dom php-zip

# xdebug Config
echo -e "\n--- Configuring xdebug for PHP ---\n"

XDEBUGCFG=$(cat << EOF
zend_extension=$(find /usr/lib64/php/ -name xdebug.so)
xdebug.remote_enable = 1
;xdebug.remote_connect_back = 1
xdebug.remote_handler=dbgp
xdebug.remote_host=10.0.2.2
xdebug.idekey = "eclipse-xdebug"
xdebug.remote_port = 9000
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1
xdebug.overload_var_dump = 0
xdebug.remote_log = /tmp/php56-xdebug.log
EOF
)
echo "${XDEBUGCFG}" | sudo tee $(find /etc/php.d -name 15-xdebug.ini)
echo -e "\n--- Installing Apache2 ---\n"

sudo yum install -y httpd

echo "ServerName $HOSTNAME" >> /etc/httpd/conf/httpd.conf
echo "127.0.0.1 $HOSTNAME" >> /etc/hosts

# Setup virtualhost 
VHOST=$(cat <<EOF
<VirtualHost *:80>
	ServerName  $HOSTNAME
	DocumentRoot /vagrant/www/web/
	<Directory "/vagrant/www/web/">
		DirectoryIndex index.html index.php
		Options FollowSymLinks
		AllowOverride All
		Require all granted
	</Directory>
    ErrorLog /var/log/httpd/${HOSTNAME}_error.log
    LogLevel warn
    CustomLog /var/log/httpd/${HOSTNAME}_access.log combined
</VirtualHost>
EOF
)

echo "${VHOST}" | sudo tee /etc/httpd/conf.d/vhost.conf

echo -e "\n--- Adding Apache service to autostart---\n"
sudo systemctl enable httpd

sudo systemctl restart httpd 

echo -e "\n--- Installing Composer for PHP package management ---\n"
curl --silent https://getcomposer.org/installer | php
mv composer.phar /usr/local/bin/composer

echo -e "\n--- Updating project components and pulling latest versions ---\n"

cd /vagrant/www

composer install

echo -e "\n--- MySQL Installation ---\n"
sudo yum install -y http://dev.mysql.com/get/mysql-community-release-el7-5.noarch.rpm

sudo yum install -y mysql-community-server

sudo systemctl enable mysqld

sudo systemctl start mysqld

# sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
# sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"

# sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

MYSQL=`which mysql`
Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;"
Q2="GRANT ALL ON *.* TO 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}' WITH GRANT OPTION;"
Q3="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}"
$MYSQL -uroot -e "$SQL"

echo -e "\n--- Init DB ---\n"
Q1="CREATE DATABASE IF NOT EXISTS ${DB_NAME};"
Q2="CREATE USER '${DB_USER}' IDENTIFIED BY '${DB_PASS}';"
Q3="GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'localhost' IDENTIFIED BY '${DB_PASS}';"
Q4="GRANT ALL PRIVILEGES ON ${DB_NAME}.* TO '${DB_USER}'@'%' IDENTIFIED BY '${DB_PASS}';;"
Q5="FLUSH PRIVILEGES;"
SQL="${Q1}${Q2}${Q3}${Q4}${Q5}"

MYSQL=`which mysql`
$MYSQL -uroot -p$MYSQL_ROOT_PASSWORD -e "$SQL"

sudo systemctl restart mysqld