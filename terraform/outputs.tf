# outputs.tf

output "acr_login_server" {
  description = "Use in CI to docker login & tag images"
  value       = azurerm_container_registry.acr.login_server
}

output "aks_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.aks.name
}

output "aks_rg" {
  description = "AKS resource group"
  value       = azurerm_resource_group.rg.name
}

output "redis_hostname" {
  description = "Azure Redis hostname"
  value       = azurerm_redis_cache.redis.hostname
}

output "redis_primary_key" {
  description = "Primary access key for Redis"
  value       = azurerm_redis_cache.redis.primary_access_key
  sensitive   = true
}

output "frontend_ip" {
  description = "Static IP for ingress"
  value       = azurerm_public_ip.ingress_ip.ip_address
}

output "ingress_ip" {
  description = "Static IP for ingress (GitHub Actions variable)"
  value       = azurerm_public_ip.ingress_ip.ip_address
}

output "frontend_fqdn" {
  description = "Fully-qualified frontend host"
  value       = local.frontend_fqdn
}

output "azure_dns_name_servers" {
  description = "Azure DNS name servers to set at registrar"
  value       = azurerm_dns_zone.campus.name_servers
}

output "dns_zone_name" {
  description = "DNS zone name"
  value       = azurerm_dns_zone.campus.name
}

output "dns_zone_id" {
  description = "DNS zone resource ID"
  value       = azurerm_dns_zone.campus.id
}

output "dns_records_info" {
  description = "Information about DNS records created"
  value = {
    root_domain = azurerm_dns_a_record.frontend.name
    root_ip     = azurerm_dns_a_record.frontend.records
    admin_cname = azurerm_dns_cname_record.admin.record
  }
}

output "admin_subdomain" {
  description = "Admin subdomain for Keel panel"
  value       = "admin.${var.domain_name}"
}

# Security and monitoring outputs
output "acr_id" {
  description = "Container Registry ID for role assignments"
  value       = azurerm_container_registry.acr.id
}

output "aks_identity_principal_id" {
  description = "AKS cluster identity principal ID"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "aks_kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# New monitoring and security outputs
output "key_vault_name" {
  description = "Key Vault name for secrets management"
  value       = azurerm_key_vault.key_vault.name
}

output "key_vault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.key_vault.vault_uri
}

output "app_insights_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.app_insights.instrumentation_key
  sensitive   = true
}

output "app_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.app_insights.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  value       = azurerm_log_analytics_workspace.aks_logs.workspace_id
}

output "vnet_id" {
  description = "Virtual network ID"
  value       = azurerm_virtual_network.aks_vnet.id
}

output "aks_subnet_id" {
  description = "AKS subnet ID"
  value       = azurerm_subnet.aks_subnet.id
}

# Deployment information
output "deployment_info" {
  description = "Key information for deployment"
  value = {
    cluster_name     = azurerm_kubernetes_cluster.aks.name
    resource_group   = azurerm_resource_group.rg.name
    acr_server       = azurerm_container_registry.acr.login_server
    ingress_ip       = azurerm_public_ip.ingress_ip.ip_address
    domain           = var.domain_name
    admin_domain     = "admin.${var.domain_name}"
    dns_servers      = azurerm_dns_zone.campus.name_servers
    key_vault_name   = azurerm_key_vault.key_vault.name
    vnet_id          = azurerm_virtual_network.aks_vnet.id
    subnet_id        = azurerm_subnet.aks_subnet.id
  }
}

# Security configuration outputs
output "security_info" {
  description = "Security configuration information"
  value = {
    allowed_ssh_ip = var.allowed_ssh_ip
    kubernetes_version = var.kubernetes_version
    network_policy = "azure"
    azure_policy_enabled = true
    key_vault_rbac_enabled = true
  }
}
