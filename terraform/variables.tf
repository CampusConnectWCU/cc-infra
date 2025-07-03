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
