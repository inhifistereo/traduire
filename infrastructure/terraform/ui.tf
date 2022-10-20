resource "azurerm_static_site" "traduire_ui" {
  name                  = local.static_webapp_name
  resource_group_name   = azurerm_resource_group.traduire_ui.name
  location              = "centralus"
}

resource "azurerm_web_pubsub" "traduire_app" {
  name                = local.pubsub_name 
  location            = azurerm_resource_group.traduire_ui.location
  resource_group_name = azurerm_resource_group.traduire_ui.name

  sku      = "Free_F1"
  capacity = 1

}