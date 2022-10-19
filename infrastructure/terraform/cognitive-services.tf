resource "azurerm_cognitive_account" "traduire_app" {
  name                = "${local.resource_name}-cogs01"
  resource_group_name = azurerm_resource_group.traduire_app.name
  location            = azurerm_resource_group.traduire_app.location
  kind                = "SpeechServices"

  sku_name            = "S0"
}