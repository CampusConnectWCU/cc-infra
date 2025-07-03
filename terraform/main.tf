# 1) Resource Group
resource "azurerm_resource_group" "rg" {
  name     = local.rg_name
  location = var.location
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
    ManagedBy   = "terraform"
  }
}

# 2) Container Registry
resource "azurerm_container_registry" "acr" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"
  admin_enabled       = false
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 3) Redis Cache with enhanced security
resource "azurerm_redis_cache" "redis" {
  name                = local.redis_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku_name            = "Standard"
  family              = "C"
  capacity            = 1
  minimum_tls_version = "1.2"
  
  # Enable Redis persistence
  non_ssl_port_enabled = false
  
  # Redis configuration
  redis_configuration {
    maxmemory_reserved = 50
    maxmemory_delta    = 50
    maxmemory_policy   = "volatile-lru"
  }
  
  # Note: Firewall rules will be configured separately below
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 4) Static Public IP (for ingress controller)
resource "azurerm_public_ip" "ingress_ip" {
  name                = local.ingress_ip_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  
  # Add DNS label for easier management
  domain_name_label = "campusconnect-ingress"
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 5) Create an Azure DNS Zone for the IONOS-registered domain
resource "azurerm_dns_zone" "campus" {
  name                = var.domain_name              # campusconnectwcu.com
  resource_group_name = azurerm_resource_group.rg.name
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 6) DNS A record for campusconnectwcu.com → ingress IP
resource "azurerm_dns_a_record" "frontend" {
  name                = "@"
  zone_name           = azurerm_dns_zone.campus.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [ azurerm_public_ip.ingress_ip.ip_address ]
}

# 7) CNAME record for admin.campusconnectwcu.com → campusconnectwcu.com
resource "azurerm_dns_cname_record" "admin" {
  name                = "admin"
  zone_name           = azurerm_dns_zone.campus.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  record              = azurerm_dns_zone.campus.name
}

# 8) Virtual Network for AKS
resource "azurerm_virtual_network" "aks_vnet" {
  name                = "${var.prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.0.0.0/16"]
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 9) Subnet for AKS
resource "azurerm_subnet" "aks_subnet" {
  name                 = "${var.prefix}-aks-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.aks_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  
  # Enable service endpoints for ACR
  service_endpoints = ["Microsoft.ContainerRegistry", "Microsoft.KeyVault"]
}

# 10) Network Security Group for AKS with comprehensive rules
resource "azurerm_network_security_group" "aks_nsg" {
  name                = "${var.prefix}-aks-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  
  # Allow HTTPS inbound (for ingress)
  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTPS traffic to ingress controller"
  }
  
  # Allow HTTP inbound (for Let's Encrypt challenges)
  security_rule {
    name                       = "AllowHTTP"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow HTTP traffic for Let's Encrypt challenges"
  }
  
  # Allow SSH for debugging (restrict to whitelisted IP)
  security_rule {
    name                       = "AllowSSH"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.allowed_ssh_ip
    destination_address_prefix = "*"
    description                = "Allow SSH access from admin IP"
  }
  
  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Deny all other inbound traffic"
  }
  
  # Allow all outbound traffic (AKS needs this for pulling images, etc.)
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
    description                = "Allow all outbound traffic"
  }
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 11) Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "aks_nsg_association" {
  subnet_id                 = azurerm_subnet.aks_subnet.id
  network_security_group_id = azurerm_network_security_group.aks_nsg.id
}

# 12) Enhanced AKS Cluster
resource "azurerm_kubernetes_cluster" "aks" {
  name                = local.aks_name        # e.g. "cc-prod-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = local.aks_dns         # e.g. "cc-prod"
  kubernetes_version  = var.kubernetes_version

  default_node_pool {
    name                = "agentpool"
    node_count          = var.node_count
    vm_size             = var.vm_size
    vnet_subnet_id      = azurerm_subnet.aks_subnet.id
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    
    # Node pool tags
    tags = {
      Environment = "production"
      Project     = "campus-connect"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "azure"
    load_balancer_sku  = "standard"
    service_cidr       = "10.1.0.0/16"
    dns_service_ip     = "10.1.0.10"
  }
  
  # Enable Azure Policy
  azure_policy_enabled = true
  
  # Enable OMS agent for monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.aks_logs.id
  }
  
  # Enable Azure Key Vault integration
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2m"
  }
  
  # Enable cluster autoscaler
  auto_scaler_profile {
    scale_down_delay_after_add = "15m"
    scale_down_unneeded       = "15m"
  }
  
  # Enable maintenance window
  maintenance_window {
    allowed {
      day   = "Sunday"
      hours = [0, 1, 2, 3, 4, 5, 6]
    }
  }
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 13) Log Analytics Workspace for monitoring
resource "azurerm_log_analytics_workspace" "aks_logs" {
  name                = "${var.prefix}-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 14) Application Insights for application monitoring
resource "azurerm_application_insights" "app_insights" {
  name                = "${var.prefix}-appinsights"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.aks_logs.id
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 15) Key Vault for secrets management with comprehensive security
resource "azurerm_key_vault" "key_vault" {
  name                        = "${replace(var.prefix, "-", "")}kv"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                   = "standard"
  
  # Enable RBAC
  enable_rbac_authorization = true
  
  # Network rules - restrict to VNet and admin IP
  network_acls {
    default_action = "Deny"
    bypass         = "AzureServices"
    ip_rules       = [var.allowed_ssh_ip]
    virtual_network_subnet_ids = [azurerm_subnet.aks_subnet.id]
  }
  
  tags = {
    Environment = "production"
    Project     = "campus-connect"
  }
}

# 16) Data source for current Azure client
data "azurerm_client_config" "current" {}

# 17) Private Endpoint for Key Vault (optional, for extra security)
resource "azurerm_private_endpoint" "key_vault_pe" {
  name                = "${var.prefix}-kv-pe"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.aks_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-kv-psc"
    private_connection_resource_id = azurerm_key_vault.key_vault.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.key_vault.id]
  }
}

# 18) Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.rg.name
}

# 19) Link Private DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "${var.prefix}-kv-dnslink"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.aks_vnet.id
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

# 6) AKS identity needs Key Vault Secrets User for CSI driver
resource "azurerm_role_assignment" "aks_key_vault_secrets_user" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

# 7) Current user needs Key Vault Administrator for initial setup
resource "azurerm_role_assignment" "current_user_key_vault_admin" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# 20) Redis Cache Firewall Rule - Allow AKS subnet
resource "azurerm_redis_firewall_rule" "aks_subnet" {
  name                = "akssubnet"
  redis_cache_name    = azurerm_redis_cache.redis.name
  resource_group_name = azurerm_resource_group.rg.name
  start_ip            = cidrhost(azurerm_subnet.aks_subnet.address_prefixes[0], 0)
  end_ip              = cidrhost(azurerm_subnet.aks_subnet.address_prefixes[0], -1)
}