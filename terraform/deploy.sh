#!/bin/bash

set -euo pipefail

echo "Detecting your public IP..."
# Get IPv4 address specifically
MYIP=$(curl -s -4 ifconfig.me || curl -s -4 ipinfo.io/ip || curl -s ipv4.icanhazip.com || echo "")
if [ -z "$MYIP" ]; then
  echo "Could not detect your IPv4 address. Please set allowed_ssh_ip manually in variables.tf"
  exit 1
fi
echo "Detected IPv4: $MYIP"

# Update allowed_ssh_ip in variables.tf if needed
if grep -q 'allowed_ssh_ip' variables.tf; then
  sed -i.bak "s/allowed_ssh_ip = \".*\"/allowed_ssh_ip = \"$MYIP\/32\"/" variables.tf
  echo "Updated allowed_ssh_ip in variables.tf to $MYIP/32"
fi

echo "Initializing Terraform..."
terraform init

echo "Planning Terraform deployment..."
terraform plan -out=tfplan

echo "Applying Terraform deployment..."
terraform apply tfplan

echo ""
echo "Deployment complete! Key outputs:"
echo "------------------------------------"
echo "INGRESS_IP:           $(terraform output -raw ingress_ip)"
echo "ACR_LOGIN_SERVER:     $(terraform output -raw acr_login_server)"
echo "KEY_VAULT_NAME:       $(terraform output -raw key_vault_name)"
echo "DNS Name Servers:"
terraform output azure_dns_name_servers
echo ""