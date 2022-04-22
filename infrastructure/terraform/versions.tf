provider "azurerm" {
  features  {}
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = "~> 2.96"
  }
  backend "azurerm" {
    storage_account_name = "bjdterraform002"
    container_name       = "plans"
  }
}

