terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~>3.0" }
  }
  backend "azurerm" {
    resource_group_name  = "terraform-rg"
    storage_account_name = "campusconnecttfstate"
    container_name       = "tfstate"
    key                  = "campus-connect-prod.tfstate"
  }
}

provider "azurerm" {
  features {}
}