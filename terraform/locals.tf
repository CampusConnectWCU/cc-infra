
locals {
  # Resource Group
  rg_name         = "${var.prefix}-rg"

  # Container Registry
  acr_name        = "${replace(var.prefix, "-", "")}acr"

  # Redis Cache
  redis_name      = "${var.prefix}-redis"

  # Static Public IP for ingress controller
  ingress_ip_name = "${var.prefix}-ip"

  # AKS cluster
  aks_name        = "${var.prefix}-aks"
  aks_dns         = var.prefix

  # (IONOS-registered) domain
  dns_zone        = var.domain_name

  # Fully qualified frontend hostname
  frontend_fqdn   = var.domain_name
}