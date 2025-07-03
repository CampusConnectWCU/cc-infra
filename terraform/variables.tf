variable "location" {
  type    = string
  default = "eastus"
}

variable "prefix" {
  type    = string
  default = "cc-prod-2025"
}

variable "domain_name" {
  description = "Campus Connect domain name"
  type        = string
  default     = "campusconnectwcu.com"
}

variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.33.1"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 2
}

variable "vm_size" {
  description = "VM size for AKS nodes"
  type        = string
  default     = "Standard_B2s"
}

variable "allowed_ssh_ip" {
  description = "IP address allowed for SSH access (whitelisted IPs)"
  type        = string
  default     = ""  # Infra/terraform/deploy.sh will update this
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}
