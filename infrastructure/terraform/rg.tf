resource "azurerm_resource_group" "traduire_core" {
  name                  = "${local.resource_name}_core_rg"
  location              = var.location
  tags                  = {
    Application         = local.resource_name
    Tier                = "Core Components"
  }
}

resource "azurerm_resource_group" "traduire_app" {
  name                  = "${local.resource_name}_app_rg"
  location              = var.location
  tags                  = {
    Application         = local.resource_name
    Tier                = "App Components"
  }
}

resource "azurerm_resource_group" "traduire_ui" {
  name                  = "${local.resource_name}_ui_rg"
  location              = var.location
  tags                  = {
    Application         = local.resource_name
    Tier                = "UI"
  }
}