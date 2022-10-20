resource "azurerm_role_assignment" "aks_role_assignemnt_nework" {
  scope                = azurerm_virtual_network.traduire_core.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_role_assignemnt_msi" {
  scope                = azurerm_user_assigned_identity.aks_kubelet_identity.id
  role_definition_name = "Managed Identity Operator"
  principal_id         = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true 
}

resource "azurerm_role_assignment" "aks_dapr_assignemnt_msi" {
  scope                     = azurerm_user_assigned_identity.dapr_reader.id
  role_definition_name      = "Managed Identity Operator"
  principal_id              = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "aks_keda_assignemnt_msi" {
  scope                     = azurerm_user_assigned_identity.keda_sb_user.id
  role_definition_name      = "Managed Identity Operator"
  principal_id              = azurerm_user_assigned_identity.aks_identity.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acr_pullrole_node" {
  scope                     = azurerm_container_registry.traduire_acr.id
  role_definition_name      = "AcrPull"
  principal_id              = azurerm_user_assigned_identity.aks_kubelet_identity.id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "keda_sb_data_owner" {
  scope                     = azurerm_servicebus_namespace.traduire_app.id
  role_definition_name      = "Azure Service Bus Data Owner" 
  principal_id              = azurerm_user_assigned_identity.keda_sb_user.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "dapr_storage_data_reader" {
  scope                     = azurerm_storage_account.traduire_app.id
  role_definition_name      = "Storage Blob Data Reader" 
  principal_id              = azurerm_user_assigned_identity.dapr_reader.principal_id
  skip_service_principal_aad_check = true
}
