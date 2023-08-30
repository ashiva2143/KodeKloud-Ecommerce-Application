#!/bin/bash
#
# This script automates the deployment of a ecommerce application
# author:SHIVAPRASAD
# email:
# 


#########################################################
# This function prints message in colour
# Arguments 
# colour eg: green,red
# message
##########################################################
function print_colour() {

    #NC="\033[0m"
    case $1 in 
    "green") COLOUR="\033[0;32m" ;;
    "red") COLOUR="\033[0;31m" ;;
    *) COLOUR="\033[0m" ;;
    esac

    echo -e "${COLOUR} $2 ${NC}"
}

#########################################################
# This function checks the status of service and prints the status
# Arguments 
# service eg:httpd
#########################################################
function is_service_active() {
    service_status=$(sudo systemctl is-active $1)

    if [ $service_status = "active" ]
    then
        print_colour "green" "$1 service is active"
    else
        print_colour "red" "$1 service is not active"
    fi
}

#########################################################
# This function checks the firewalld port configured for databse and webserver or not
# Arguments 
# port eg 3306,80
#########################################################

function is_firewalld_port_configured() {
    firewalld_port=$(sudo firewall-cmd --zone=public --list-all)

    if [[ $firewalld_port = *$1* ]]
    then
        print_colour "green" "$1 port configured in firewalld"
    else
        print_colour "red" "$1 port not configured in firewalld"
    fi
}

#########################################################
# This function checks whether items are loaded to webpage or not
# Arguments 
# webpage
# item eg: Laptop,VR, etc
#########################################################

function check_item() {
    if [[ $1 = *$2* ]]
    then
        print_colour "green" "Item $2 is present on the webpage"
    else
        print_colour "red" "Item $2 is not present on the webpage"
    fi
}

#---------------------Database configuation----------------#
# Installing Firewalld
print_colour "green" "Installing FirewallD"

sudo yum install -y firewalld
sudo service firewalld start
sudo systemctl enable firewalld

is_service_active firewalld


# Installing DatabaseServer and starting it
print_colour "green" "Installing DatabaseServer and starting it"

sudo yum install -y mariadb-server
#sudo vi /etc/my.cnf
sudo service mariadb start
sudo systemctl enable mariadb

is_service_active mariadb


#Configure firewall for Database
print_colour "green" "Configuring firewall for Database"

sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

is_firewalld_port_configured 3306


#Configure Database
print_colour "green" "Configuring Database"

cat > configure-db.sql  <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF

sudo mysql < configure-db.sql

#Load Product Inventory Information to database
print_colour "green" "Loading Product Inventory Information to database"

cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;
INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");
EOF

sudo mysql < db-load-script.sql

if [[ $(sudo mysql -e "use ecomdb; select * from products;") = *Laptop* ]]
then
    print_colour "green" "Inventory successfully Loaded"
else
    print_colour "red" "Inventory not loaded"
fi

#---------------Webserver Cofiguration-----------------

#Installing apache web server and php
print_colour "green" "Installing apache web server and php"

sudo yum install -y httpd php php-mysql

#configuring firewall rules for webserver
print_colour "green" "configuring firewall rules for webserver"

sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

is_firewalld_port_configured 80

#Configure httpd DirectoryIndex
print_colour "green" "Configure httpd DirectoryIndex"

sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

#starting and enabling httpd service
print_colour "green" "starting and enabling httpd service"

sudo service httpd start
sudo systemctl enable httpd

is_service_active httpd

#Download code for ecommerce application
print_colour "green" "Download code for ecommerce application"

sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

#updating database server with localhost
print_colour "green" "updating database server with localhost"

sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

web_page=$(curl http://localhost)
for item in Laptop VR Drone Tablet Watch
do
    check_item "$web_page" $item
done
 
print_colour "green" "CONGRATULATIONS Your Website is ready"