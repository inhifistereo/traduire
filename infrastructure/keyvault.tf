
resource "azurerm_key_vault" "traduire_app" {
  name                        = local.kv_name
  resource_group_name         = azurerm_resource_group.traduire_app.name
  location                    = azurerm_resource_group.traduire_app.location
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false

  sku_name = "standard"

  network_acls {
    bypass                    = "AzureServices"
    default_action            = "Deny"
    ip_rules                  = ["${chomp(data.http.myip.response_body)}/32"] 
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_user_assigned_identity.traduire_identity.principal_id 

    secret_permissions = [
      "List",
      "Get"
    ]
  }

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id 

    secret_permissions = [
      "Set",
      "Get",
      "Delete",
      "List"
    ]
  }
}

resource "azurerm_private_endpoint" "key_vault" {
  name                      = "${local.kv_name}-ep"
  resource_group_name       = azurerm_resource_group.traduire_app.name
  location                  = azurerm_resource_group.traduire_app.location
  subnet_id                 = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "${local.kv_name}-ep"
    private_connection_resource_id = azurerm_key_vault.traduire_app.id
    subresource_names              = [ "vault" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                          = azurerm_private_dns_zone.privatelink_vaultcore_azure_net.name
    private_dns_zone_ids          = [ azurerm_private_dns_zone.privatelink_vaultcore_azure_net.id ]
  }
}