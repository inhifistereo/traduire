resource "azurerm_resource_group" "traduire_ui" {
  name                  = "${var.application_name}_ui_rg"
  location              = var.region
  tags                  = {
    Application         = var.application_name
    Tier                = "UI"
  }

  provisioner "local-exec" {
    command = "az webpubsub create -n ${var.pubsub_name} -g ${azurerm_resource_group.traduire_ui.name} --sku Free_F1 -l eastus"
  }
}

resource "azurerm_static_site" "traduire_ui" {
  name                  = var.ui_storage_name
  resource_group_name   = azurerm_resource_group.traduire_ui.name
  location              = "centralus"
}