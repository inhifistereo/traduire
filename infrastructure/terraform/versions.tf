
terraform {
  required_version = ">= 0.12"
  required_providers {
    azurerm = "~> 2.60"
  }
}

provider "azurerm" {
  features  {}
}