resource "azurerm_container_registry" "traduire_acr" {
  name                     = local.acr_name
  resource_group_name      = azurerm_resource_group.traduire_core.name
  location                 = azurerm_resource_group.traduire_core.location
  sku                      = "Premium"
  admin_enabled            = false

  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action              = "Allow"
      ip_range            =  "${chomp(data.http.myip.response_body)}/32"
    }
  }
  
}

resource "azurerm_private_endpoint" "acr_account" {
  name                      = "${local.acr_name}-ep"
  resource_group_name       = azurerm_resource_group.traduire_core.name
  location                  = azurerm_resource_group.traduire_core.location
  subnet_id                 = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "${local.acr_name}-ep"
    private_connection_resource_id = azurerm_container_registry.traduire_acr.id
    subresource_names              = [ "registry" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                          = azurerm_private_dns_zone.privatelink_azurecr_io.name
    private_dns_zone_ids          = [ azurerm_private_dns_zone.privatelink_azurecr_io.id ]
  }
}
