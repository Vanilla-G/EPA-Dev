#!/bin/bash

# First, try to detect Azure by querying the Azure metadata service
AZURE_RESOURCE=$(curl -s -H "Metadata:true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01")


# Define the SUBDOMAIN dynamically
if [[ "$AZURE_RESOURCE" == *"compute"* ]]; then
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
  fi
fi


# Update package list and install Certbot and Certbot Nginx plugin
#sudo apt update -y && sudo apt upgrade -y
sudo apt install -y certbot python3-certbot-nginx
DOMAIN=S_DOMAIN
# Define your email
EMAIL=S_EMAIL
# Define your domain(s)
MYDOMAIN="${SUBDOMAIN}.${DOMAIN}"

# Use Certbot to obtain and install the SSL certificate for the specified domain
#sudo certbot --nginx --non-interactive --agree-tos --email $EMAIL -d $MYDOMAIN -v
sudo certbot certonly --nginx --agree-tos --dry-run --email $EMAIL -d $DOMAIN -v

# Nginx unit test that will reload Nginx to apply changes ONLY if the test is successful
sudo nginx -t && sudo systemctl reload nginx

# Run the WordPress installation script
echo "SSL certificate installation complete" >> /var/log/script-execution.log

sudo bash /opt/script/EPA/mount.sh