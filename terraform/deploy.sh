#!/bin/bash

set -euo pipefail

echo "Initializing Terraform..."
terraform init

echo "Planning Terraform deployment..."
terraform plan -out=tfplan

echo "Applying Terraform deployment..."
terraform apply tfplan

echo ""
echo "Deployment complete! Key outputs:"
echo "------------------------------------"
echo "Resource Group:     $(terraform output -raw resource_group_name)"
echo "AKS Cluster:        $(terraform output -raw aks_cluster_name)"
echo "ACR Login Server:   $(terraform output -raw acr_login_server)"
echo ""
echo "To get kubectl credentials:"
echo "az aks get-credentials --resource-group $(terraform output -raw resource_group_name) --name $(terraform output -raw aks_cluster_name)"
echo ""