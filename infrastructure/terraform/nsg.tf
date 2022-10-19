
resource "azurerm_network_security_group" "traduire-default" {
  name                = "${local.vnet_name}-default-nsg"
  location            = azurerm_resource_group.traduire_core.location
  resource_group_name = azurerm_resource_group.traduire_core.name
}

resource "azurerm_network_security_group" "traduire-internet" {
  name                = "${local.vnet_name}-internet-nsg"
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

resource "azurerm_subnet_network_security_group_association" "kubernetes" {
  subnet_id                 = azurerm_subnet.kubernetes.id
  network_security_group_id = azurerm_network_security_group.traduire-internet.id
}

resource "azurerm_subnet_network_security_group_association" "private-endpoints" {
  subnet_id                 = azurerm_subnet.private-endpoints.id
  network_security_group_id = azurerm_network_security_group.traduire-default.id
}