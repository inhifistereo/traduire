resource "azurerm_resource_group" "traduire_ui" {
  name                  = "${var.application_name}_ui_rg"
  location              = var.region
  tags                  = {
    Application         = var.application_name
    Tier                = "UI"
  }

}

resource "azurerm_static_site" "traduire_ui" {
  name                  = var.ui_storage_name
  resource_group_name   = azurerm_resource_group.traduire_ui.name
  location              = azurerm_resource_group.traduire_ui.name
}

resource "azurerm_web_pubsub" "traduire_app" {
  name                = var.pubsub_name
  location            = azurerm_resource_group.traduire_ui.location
  resource_group_name = azurerm_resource_group.traduire_ui.name

  sku      = "Free_F1"
  capacity = 1

}

resource "azurerm_key_vault_secret" "pub_sub_connection_string" {
  name         = var.pubsub_secret_name
  value        = azurerm_web_pubsub.traduire_app.primary_connection_string
  key_vault_id = azurerm_key_vault.traduire_app.id
}