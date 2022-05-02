provider "azurerm" {
  features  {}
}

terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = "~> 3.3"
  }
  backend "azurerm" {
    storage_account_name = "bjdterraform002"
    container_name       = "plans"
  }
}

resource "azurerm_resource_group" "traduire_core" {
  name                  = "${var.application_name}_core_rg"
  location              = var.region
  tags                  = {
    Application         = var.application_name
    Tier                = "Core Components"
  }
}

resource "azurerm_resource_group" "traduire_app" {
  name                  = "${var.application_name}_app_rg"
  location              = var.region
  tags                  = {
    Application         = var.application_name
    Tier                = "App Components"
  }
}

resource "azurerm_resource_group" "traduire_ui" {
  name                  = "${var.application_name}_ui_rg"
  location              = var.region
  tags                  = {
    Application         = var.application_name
    Tier                = "UI"
  }
}