# 1) Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
}

# 2) Container Registry
resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
}

# 3) Redis Cache
resource "azurerm_redis_cache" "redis" {
  name                = local.redis_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "Standard"
  family              = "C"
  capacity            = 1
  minimum_tls_version = "1.2"
}

# 4) Static Public IP (for your ingress controller)
resource "azurerm_public_ip" "ingress_ip" {
  name                = local.ingress_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 5) Create an Azure DNS Zone for your IONOS-registered domain
resource "azurerm_dns_zone" "campus" {
  name                = var.domain_name              # campusconnectwcu.com
  resource_group_name = azurerm_resource_group.rg.name
}

# 6) DNS A record for campusconnectwcu.com → your ingress IP
resource "azurerm_dns_a_record" "frontend" {
  name                = "@"
  zone_name           = azurerm_dns_zone.campus.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [ azurerm_public_ip.ingress_ip.ip_address ]
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name        # e.g. "cc-prod-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = local.aks_dns         # e.g. "cc-prod"

  default_node_pool {
    name       = "agentpool"
    node_count = 2
    vm_size    = "Standard_B2s"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
  }
}

# Role Assignments for AKS

# 1) AKS kubelet identity needs AcrPull on ACR
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# 2) AKS cluster identity needs Network Contributor for Azure CNI
resource "azurerm_role_assignment" "aks_network_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# 3) AKS cluster identity needs DNS Zone Contributor for DNS management
resource "azurerm_role_assignment" "aks_dns_contributor" {
  scope                = azurerm_dns_zone.campus.id
  role_definition_name = "DNS Zone Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# 4) AKS cluster identity needs Contributor on the AKS resource group for Azure CNI
resource "azurerm_role_assignment" "aks_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

# 5) AKS kubelet identity needs Network Contributor for Azure CNI
resource "azurerm_role_assignment" "aks_kubelet_network_contributor" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# Additional outputs for debugging and CI/CD
output "aks_identity_principal_id" {
  description = "AKS cluster identity principal ID"
  value       = azurerm_kubernetes_cluster.aks.identity[0].principal_id
}

output "aks_kubelet_identity_object_id" {
  description = "AKS kubelet identity object ID"
  value       = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}