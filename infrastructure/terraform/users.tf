resource "azurerm_user_assigned_identity" "keda_sb_user" {
  resource_group_name = azurerm_resource_group.traduire_app.name
  location            = azurerm_resource_group.traduire_app.location
  name                = "${local.resource_name}-keda-sb-owner"
}

resource "azurerm_user_assigned_identity" "dapr_reader" {
  resource_group_name = azurerm_resource_group.traduire_app.name
  location            = azurerm_resource_group.traduire_app.location
  name                = "${local.resource_name}-dapr-reader"
}