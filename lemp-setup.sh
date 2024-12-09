#!/bin/bash

# Create output file for unit test results
#sudo touch /var/log/script-execution.log
LOG_FILE="/var/log/script-execution.log"

# To make script cross-comptable First, quesry Azure using the Azure metadata service
AZURE_RESPONSE=$(curl -s -H "Metadata:true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01")

# A conditional statements checking azure query response, if response contains compute we are in Azure VM
if [[ "$AZURE_RESPONSE" == *"compute"* ]]; then
  SUBDOMAIN="az"
else
  # If Azure response is not found, check AWS metadata
  AWS_RESPONSE=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  
  # Check if AWS response contains "error"
  if [[ "$AWS_RESPONSE" == *"error"* ]]; then
    echo "Error: Unable to detect environment (AWS or Azure)."
    exit 1
  else
    SUBDOMAIN="aws"
  fi #Need to add other cloud providers.
fi

# A simplified condition, however this is binary, i do want to add the option to deploy in gcp as extra credit so will keep 
# commented out until assessment date
# Check if the Azure response contains "compute"
#if [[ "$AZURE_RESPONSE" == *"compute"* ]]; then
#  SUBDOMAIN="az"
#else
#  # Assume AWS environment if not Azure
#  SUBDOMAIN="aws"
#fi


# Function to check the exit status of the last executed command
# then read from standard input and write to standard output and files append
check_exit_status() {
    if [ $? -ne 0 ]; then
        echo -e "\e[31mError: $1 failed.\e[0m" | tee -a $LOG_FILE #red
        exit 1
    else
        echo -e "\e[32m$1 succeeded.\e[0m" | tee -a $LOG_FILE #green
    fi
}


# Install Nginx
sudo echo "Running install nginx..." | tee -a $LOG_FILE
sudo apt install nginx -y
check_exit_status "apt nginx"


# Start and enable Nginx
sudo echo "Running start nginx and systemctl enable nginx..." | tee -a $LOG_FILE
sudo systemctl start nginx && sudo systemctl enable nginx
check_exit_status "start and enable nginx"


# Save Nginx status to log
sudo systemctl status nginx >> /var/log/script-execution.log

# Install MariaDB
sudo echo "Running install mariadb..." | tee -a $LOG_FILE
sudo apt install mariadb-server -y
check_exit_status "apt install mariadb"


# Start and enable MariaDB
sudo echo "Running start mariadb and systemctl enable mariadb..." | tee -a $LOG_FILE
sudo systemctl start mariadb && sudo systemctl enable mariadb
check_exit_status "start and enable mariadb"


# Append MariaDB status to log
systemctl status mariadb >> /var/log/script-execution.log

# Install PHP and extensions
sudo echo "Running install php..." | tee -a $LOG_FILE
sudo apt install php php-cli php-common php-imap php-fpm php-snmp php-xml php-zip php-mbstring php-curl php-mysqli php-gd php-intl -y
check_exit_status "apt install php"


# Append PHP version to log
sudo php -v >> /var/log/script-execution.log

# Stop apache2
sudo echo "Running stop apache2..." | tee -a $LOG_FILE
sudo systemctl stop apache2
check_exit_status "stop apache2"
# Diable apache2
sudo echo "Running disable apache2..." | tee -a $LOG_FILE
sudo systemctl disable apache2
check_exit_status "disable apache2"


sudo echo "Runniung mv /var/www/html/index.html /var/www/html/index.html.old..." | tee -a $LOG_FILE
sudo mv /var/www/html/index.html /var/www/html/index.html.old
check_exit_status "move /var/www/html/index.html"



# Replace Nginx config
#sudo chown ubuntu:ubuntu /root/EPA/nginx.conf
sudo echo "Running mv /root/EPA/nginx.conf /etc/nginx/conf.d/nginx.conf..." | tee -a $LOG_FILE
sudo mv /root/EPA/nginx.conf /etc/nginx/conf.d/nginx.conf
check_exit_status "move mv /root/EPA/nginx.conf /etc/nginx/conf.d/nginx.conf"


# Update Nginx config with DNS record
DNS_RECORD="${SUBDOMAIN}.gball.uk"
sudo echo "Running sed -i DNS_RECORD to nginx.conf..." | tee -a $LOG_FILE
sudo sed -i "s/SERVERNAME/$DNS_RECORD/g" /etc/nginx/conf.d/nginx.conf
check_exit_status "sed -i DNS_RECORD to nginx.conf"


# Test and reload Nginx
sudo nginx -t >> /var/log/script-execution.log 

sudo echo "Running reload nginx..." | tee -a $LOG_FILE
sudo systemctl reload nginx
check_exit_status "disable apache2"

# I should add ip to CF dns
#sudo echo "Running bash /root/EPA/cloudflare-dns.sh..." | tee -a $LOG_FILE
#sudo bash /root/EPA/cloudflare-dns.sh
#check_exit_status "bash /root/EPA/cloudflare-dns.sh"