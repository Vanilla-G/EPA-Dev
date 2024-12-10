#!/bin/bash
# docs https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-create-dns-record

LOG_FILE="/var/log/script-execution.log"

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

# First, try to detect Azure by querying the Azure metadata service
azure_response=$(curl -s -H "Metadata:true" "http://169.254.169.254/metadata/instance?api-version=2021-02-01")

# Check if the response is valid (i.e., contains expected data)
if [[ "$azure_response" == *"compute"* ]]; then
  subdomain="az"
else
  # If Azure response is not found, check AWS metadata
  aws_response=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
  
  # Check if AWS response contains "error"
  if [[ "$aws_response" == *"error"* ]]; then
    echo "Error: Unable to detect environment (AWS or Azure)."
    exit 1
  else
    subdomain="aws"
  fi
fi

# Set the subdomain and IP address for Cloudflare DNS
domain=S_DOMAIN
my_domain="${subdomain}.gball.uk"
public_ip=S_PUBLIC_IP

# Cloudflare API and Zone Info
CF_API=S_CF_API
CF_ZONE_ID=S_CF_ZONE_ID

echo "S_DOMAIN: $DOMAIN" >> $LOG_FILE
echo "S_PUBLIC_IP: $PUBLIC_IP" >> $LOG_FILE
echo "CF_API: $CF_API" >> $LOG_FILE
echo "CF_ZONE_ID: $CF_ZONE_ID" >> $LOG_FILE

# Create the DNS record in Cloudflare
sudo echo "Running curl POST request into Cloudflare API..." | tee -a $LOG_FILE

# Debug
echo "*****Curl data: {\"content\": \"$public_ip\", \"name\": \"$my_domain\", \"proxied\": true, \"type\": \"A\", \"comment\": \"Automatically adding A record\", \"tags\": [], \"ttl\": 3600}" | tee -a $LOG_FILE

curl --request POST \
  --url https://api.cloudflare.com/client/v4/zones/$CF_ZONE_ID/dns_records \
  --header 'Content-Type: application/json' \
  --header "Authorization: Bearer $CF_API" \
  --data '{
  "content": "'$public_ip'",
  "name": "'$my_domain'",
  "proxied": true,
  "type": "A",
  "comment": "Automatically adding an A record",
  "tags": [],
  "ttl": 3600
}'

check_exit_status "Cloudflare DNS API endpoint"

# Proceed to install Wordpress
sudo echo "Running bash /root/EPA/wordpress-install.sh..." | tee -a $LOG_FILE
sudo bash /root/EPA/wordpress-install.sh
check_exit_status "Cloudflare-DNS finished"