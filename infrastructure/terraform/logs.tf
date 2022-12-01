resource "azurerm_log_analytics_workspace" "traduire_logs" {
  name                     = local.la_name
  resource_group_name      = azurerm_resource_group.traduire_core.name
  location                 = azurerm_resource_group.traduire_core.location
  sku                      = "PerGB2018"
}

resource "azurerm_application_insights" "traduire_ai" {
  name                     = local.ai_name
  resource_group_name      = azurerm_resource_group.traduire_core.name
  location                 = azurerm_resource_group.traduire_core.location
  workspace_id             = azurerm_log_analytics_workspace.traduire_logs.id
  application_type         = "web"
}