#!/bin/bash
# docs https://developers.cloudflare.com/api/operations/dns-records-for-a-zone-create-dns-record

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
my_domain="${subdomain}.${S_DOMAIN}"
public_ip=S_PUBLIC_IP

# Cloudflare API and Zone Info
CF_API=S_CF_API
CF_ZONE_ID=S_CF_ZONE_ID

# Create the DNS record in Cloudflare
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

# Proceed to install SSL via Certbot
sudo bash /root/EPA/wordpress-install.sh