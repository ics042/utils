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

sudo apt-get -qq update --fix-missing

echo -e "\n--- Install base packages ---\n"
sudo apt-get -y install vim curl build-essential python-software-properties git

sudo apt-get -y install golang-go

# Setup virtualhost 
GOENV=$(cat <<EOF
PATH=$PATH:/usr/local/go/bin
GOPATH=/var/golang
EOF
)
echo "${GOENV}" >> ~/.profile

echo -e "\n--- Setting timezone ---\n"
sudo ln -sf /usr/share/zoneinfo/${SERVER_TIMEZONE} /etc/localtime

echo -e "\n--- MySQL Installation ---\n"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password ${MYSQL_ROOT_PASSWORD}"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password ${MYSQL_ROOT_PASSWORD}"

sudo apt-get install -y mysql-server

sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

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

sudo service mysql restart


