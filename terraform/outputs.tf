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
  description = "Static IP for your ingress"
  value       = azurerm_public_ip.ingress_ip.ip_address
}

output "frontend_fqdn" {
  description = "Fully-qualified frontend host"
  value       = local.frontend_fqdn
}

output "azure_dns_name_servers" {
  description = "Azure DNS name servers to set at your registrar"
  value       = azurerm_dns_zone.campus.name_servers
}
