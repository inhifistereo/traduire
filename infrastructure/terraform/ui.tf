resource "azurerm_resource_group" "traduire_ui" {
  name                  = "${var.application_name}_ui_rg"
  location              = var.region
  tags                  = {
    Application         = var.application_name
    Tier                = "UI"
  }

  provisioner "local-exec" {
    command = "bash ./create_pubsub.sh ${var.pubsub_name} ${azurerm_resource_group.traduire_ui.name} ${var.pubsub_secret_name} ${var.keyvault_name} ${var.region}"
  }
}

resource "azurerm_static_site" "traduire_ui" {
  name                  = var.ui_storage_name
  resource_group_name   = azurerm_resource_group.traduire_ui.name
  location              = "centralus"
}

resource "azurerm_storage_account" "traduire_storage_ui" {
  name                     = var.ui_storage_name
  resource_group_name      = azurerm_resource_group.traduire_ui.name
  location                 = azurerm_resource_group.traduire_ui.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  static_website {
    error_404_document    = "404.html"
    index_document        = "index.html"
  }
} 