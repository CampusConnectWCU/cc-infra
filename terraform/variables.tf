variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "campus-connect"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "campus-connect-rg"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "campus-connect"
    ManagedBy   = "terraform"
  }
}