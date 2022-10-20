resource "azurerm_cognitive_account" "traduire_app" {
  name                = local.cogs_name
  resource_group_name = azurerm_resource_group.traduire_app.name
  location            = azurerm_resource_group.traduire_app.location
  kind                = "SpeechServices"

  sku_name            = "S0"
}