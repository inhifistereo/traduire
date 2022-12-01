resource "azurerm_virtual_network" "traduire_core" {
  name                = local.vnet_name
  location            = azurerm_resource_group.traduire_core.location
  resource_group_name = azurerm_resource_group.traduire_core.name
  address_space       = [ local.vnet_cidr ]
}

resource "azurerm_subnet" "private-endpoints" {
  name                  = "private-endpoints"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = [ local.pe_subnet_cidr ]

  private_endpoint_network_policies_enabled = true
}

resource "azurerm_subnet" "kubernetes" {
  name                  = "kubernetes"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = [ local.k8s_subnet_cidr ]
}

resource "azurerm_subnet" "sql" {
  name                  = "sql"
  resource_group_name   = azurerm_virtual_network.traduire_core.resource_group_name
  virtual_network_name  = azurerm_virtual_network.traduire_core.name
  address_prefixes      = [ local.sql_subnet_cidr ]
  service_endpoints     = ["Microsoft.Storage"]
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

