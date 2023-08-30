#!/bin/bash

#---------------------Database configuation----------------#
# Installing Firewalld
sudo yum install -y firewalld
sudo service firewalld start
sudo systemctl enable firewalld

# Installing DatabaseServer and starting it
sudo yum install -y mariadb-server
#sudo vi /etc/my.cnf
sudo service mariadb start
sudo systemctl enable mariadb

#Configure firewall for Database
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

#Configure Database
cat > configure-db.sql  <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF

sudo mysql < configure-db.sql

#Load Product Inventory Information to database
cat > db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;
INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");
EOF

sudo mysql < db-load-script.sql

#---------------Webserver Cofiguration-----------------

#Installing apache web server and php
sudo yum install -y httpd php php-mysql

#configuring firewall rules for webserver
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

#Configure httpd DirectoryIndex
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

#starting and enabling httpd service
sudo service httpd start
sudo systemctl enable httpd

#Download code for ecommerce application
sudo yum install -y git
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

#updating database server with localhost
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php
