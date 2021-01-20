resource "azurerm_resource_group" "traduire_core" {
  name                  = "${var.application_name}_core_rg"
  location              = var.region
  tags                  = {
    Application         = var.application_name
    Tier                = "Core Components"
  }
}

resource "azurerm_log_analytics_workspace" "traduire_logs" {
  name                     = var.loganalytics_account_name
  resource_group_name      = azurerm_resource_group.traduire_core.name
  location                 = azurerm_resource_group.traduire_core.location
  sku                      = "pergb2018"
}

resource "azurerm_application_insights" "traduire_ai" {
  name                     = var.ai_account_name
  resource_group_name      = azurerm_resource_group.traduire_core.name
  location                 = azurerm_resource_group.traduire_core.location
  application_type         = "web"
}

resource "azurerm_virtual_network" "traduire_core" {
  name                = var.vnet_name
  location            = azurerm_resource_group.traduire_core.location
  resource_group_name = azurerm_resource_group.traduire_core.name
  address_space       = ["10.50.0.0/16"]
}

resource "azurerm_subnet" "AppGateway" {
  name                  = "app-gateway"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.1.0/24"]
}

resource "azurerm_subnet" "APIM" {
  name                  = "apim"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.2.0/24"]
}

resource "azurerm_subnet" "databricks-private" {
  name                  = "databricks-private"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.41.0/24"]
}

resource "azurerm_subnet" "databricks-public" {
  name                  = "databricks-public"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.40.0/24"]
}

resource "azurerm_subnet" "private-endpoints" {
  name                  = "private-endpoints"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.50.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet" "kubernetes" {
  name                  = "kubernetes"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.4.0/22"]
}

resource "azurerm_private_dns_zone" "privatelink_azurecr_io" {
  name                      = "privatelink.azurecr.io"
  resource_group_name       = azurerm_resource_group.traduire_core.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_azurecr_io" {
  name                      = "${azurerm_virtual_network.traduire_core.name}-link"
  private_dns_zone_name     = azurerm_private_dns_zone.privatelink_azurecr_io.name
  resource_group_name       = azurerm_resource_group.traduire_core.name
  virtual_network_id        = azurerm_virtual_network.traduire_core.id
}

resource "azurerm_private_dns_zone" "privatelink_blob_core_windows_net" {
  name                      = "privatelink.blob.core.windows.net"
  resource_group_name       = azurerm_resource_group.traduire_core.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_blob_core_windows_net" {
  name                      = "${azurerm_virtual_network.traduire_core.name}-link"
  private_dns_zone_name     = azurerm_private_dns_zone.privatelink_blob_core_windows_net.name
  resource_group_name       = azurerm_resource_group.traduire_core.name
  virtual_network_id        = azurerm_virtual_network.traduire_core.id
}

resource "azurerm_private_dns_zone" "privatelink_vaultcore_azure_net" {
  name                      = "privatelink.vaultcore.azure.net"
  resource_group_name       = azurerm_resource_group.traduire_core.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_vaultcore_azure_net" {
  name                      = "${azurerm_virtual_network.traduire_core.name}-link"
  private_dns_zone_name     = azurerm_private_dns_zone.privatelink_vaultcore_azure_net.name
  resource_group_name       = azurerm_resource_group.traduire_core.name
  virtual_network_id        = azurerm_virtual_network.traduire_core.id
}

resource "azurerm_private_dns_zone" "privatelink_postgres_database_azure_com" {
  name                      = "privatelink.postgres.database.azure.com"
  resource_group_name       = azurerm_resource_group.traduire_core.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_postgres_database_azure_com" {
  name                      = "${azurerm_virtual_network.traduire_core.name}-link"
  private_dns_zone_name     = azurerm_private_dns_zone.privatelink_postgres_database_azure_com.name
  resource_group_name       = azurerm_resource_group.traduire_core.name
  virtual_network_id        = azurerm_virtual_network.traduire_core.id
}

resource "azurerm_private_dns_zone" "privatelink_servicebus_windows_net" {
  name                      = "privatelink.servicebus.windows.net"
  resource_group_name       = azurerm_resource_group.traduire_core.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "privatelink_servicebus_windows_net" {
  name                      = "${azurerm_virtual_network.traduire_core.name}-link"
  private_dns_zone_name     = azurerm_private_dns_zone.privatelink_servicebus_windows_net.name
  resource_group_name       = azurerm_resource_group.traduire_core.name
  virtual_network_id        = azurerm_virtual_network.traduire_core.id
}