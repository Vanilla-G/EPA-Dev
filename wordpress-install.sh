#!/bin/bash
sudo rm -rf /var/www/html
sudo apt -y install unzip
sudo wget -O /var/www/latest.zip https://wordpress.org/latest.zip
sudo unzip /var/www/latest.zip -d /var/www/
sudo rm /var/www/latest.zip
sudo mv /var/www/wordpress /var/www/html

# Generate password for use in WP DB
password=$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 25)
username=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 25)

echo $password > creds.txt   #remove this and below after testing
echo $username >> creds.txt

sudo mysql -u root -e "CREATE DATABASE IF NOT EXISTS \`$username\`"
sudo mysql -u root -e "CREATE USER IF NOT EXISTS '$username'@'localhost' IDENTIFIED BY '$password'"
sudo mysql -u root -e "GRANT ALL PRIVILEGES ON \`$username\`.* TO '$username'@'localhost'"
sudo mysql -u root -e "FLUSH PRIVILEGES"


sudo mv /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
sudo chmod 640 /var/www/html/wp-config.php 
sudo chown -R www-data:www-data /var/www/html/

sed -i "s/password_here/$password/g" /var/www/html/wp-config.php
sed -i "s/username_here/$username/g" /var/www/html/wp-config.php
sed -i "s/database_name_here/$username/g" /var/www/html/wp-config.php

SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
STRING='put your unique phrase here'
printf '%s\n' "g/$STRING/d" a "$SALT" . w | ed -s /var/www/html/wp-config.php



echo "Wordpress installation complete" >> /var/log/script-execution.log


#sudo bash /root/EPA/certbot-ssl-install.sh