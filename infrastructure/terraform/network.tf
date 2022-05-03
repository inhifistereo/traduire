resource "azurerm_log_analytics_workspace" "traduire_logs" {
  name                     = var.loganalytics_account_name
  resource_group_name      = azurerm_resource_group.traduire_core.name
  location                 = azurerm_resource_group.traduire_core.location
  sku                      = "PerGB2018"
}

resource "azurerm_application_insights" "traduire_ai" {
  name                     = var.ai_account_name
  resource_group_name      = azurerm_resource_group.traduire_core.name
  location                 = azurerm_resource_group.traduire_core.location
  workspace_id             = azurerm_log_analytics_workspace.traduire_logs.id
  application_type         = "web"
}

resource "azurerm_network_security_group" "traduire-default" {
  name                = "${var.vnet_name}-default-nsg"
  location            = azurerm_resource_group.traduire_core.location
  resource_group_name = azurerm_resource_group.traduire_core.name
}

resource "azurerm_network_security_group" "traduire-internet" {
  name                = "${var.vnet_name}-internet-nsg"
  location            = azurerm_resource_group.traduire_core.location
  resource_group_name = azurerm_resource_group.traduire_core.name

  security_rule {
    name                       = "http"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "https"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

}

resource "azurerm_virtual_network" "traduire_core" {
  name                = var.vnet_name
  location            = azurerm_resource_group.traduire_core.location
  resource_group_name = azurerm_resource_group.traduire_core.name
  address_space       = ["10.50.0.0/16"]
}

resource "azurerm_subnet" "private-endpoints" {
  name                  = "private-endpoints"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.50.0/24"]

  enforce_private_link_endpoint_network_policies = true
}

resource "azurerm_subnet_network_security_group_association" "private-endpoints" {
  subnet_id                 = azurerm_subnet.private-endpoints.id
  network_security_group_id = azurerm_network_security_group.traduire-default.id
}

resource "azurerm_subnet" "kubernetes" {
  name                  = "kubernetes"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.4.0/22"]
}

resource "azurerm_subnet" "sql" {
  name                  = "sql"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = ["10.50.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
  delegation {
    name = "fs"
    service_delegation {
      name = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
      ]
    }
  }
}

resource "azurerm_subnet_network_security_group_association" "kubernetes" {
  subnet_id                 = azurerm_subnet.kubernetes.id
  network_security_group_id = azurerm_network_security_group.traduire-internet.id
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

resource "azurerm_container_registry" "traduire_acr" {
  name                     = var.acr_account_name
  resource_group_name      = azurerm_resource_group.traduire_core.name
  location                 = azurerm_resource_group.traduire_core.location
  sku                      = "Premium"
  admin_enabled            = false

  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action              = "Allow"
      ip_range            =  var.api_server_authorized_ip_ranges
    }
  }
  
}

resource "azurerm_private_endpoint" "acr_account" {
  name                      = "${var.acr_account_name}-ep"
  resource_group_name       = azurerm_resource_group.traduire_core.name
  location                  = azurerm_resource_group.traduire_core.location
  subnet_id                 = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "${var.acr_account_name}-ep"
    private_connection_resource_id = azurerm_container_registry.traduire_acr.id
    subresource_names              = [ "registry" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                          = azurerm_private_dns_zone.privatelink_azurecr_io.name
    private_dns_zone_ids          = [ azurerm_private_dns_zone.privatelink_azurecr_io.id ]
  }
}
