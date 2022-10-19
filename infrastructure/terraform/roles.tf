
resource "azurerm_role_assignment" "acr_pullrole_node" {
  scope                     = azurerm_container_registry.traduire_acr.id
  role_definition_name      = "AcrPull"
  principal_id              = azurerm_kubernetes_cluster.traduire_app.kubelet_identity.0.object_id 
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "acr_pullrole_cluster" {
  scope                     = azurerm_container_registry.traduire_acr.id
  role_definition_name      = "AcrPull"
  principal_id              = azurerm_kubernetes_cluster.traduire_app.identity.0.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "network_contributor_cluster" {
  scope                     = azurerm_resource_group.traduire_core.id
  role_definition_name      = "Network Contributor"
  principal_id              = azurerm_kubernetes_cluster.traduire_app.kubelet_identity.0.object_id 
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "msi_operator_cluster_node_rg" {
  scope                     = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.traduire_app.node_resource_group}"
  role_definition_name      = "Managed Identity Operator"
  principal_id              = azurerm_kubernetes_cluster.traduire_app.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "msi_operator_cluster_msi_rg" {
  scope                     = azurerm_resource_group.traduire_app.id
  role_definition_name      = "Managed Identity Operator"
  principal_id              = azurerm_kubernetes_cluster.traduire_app.kubelet_identity.0.object_id
  skip_service_principal_aad_check = true
}

resource "azurerm_role_assignment" "vm_contributor_cluster" {
  scope                     = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${azurerm_kubernetes_cluster.traduire_app.node_resource_group}"
  role_definition_name      = "Virtual Machine Contributor" 
  principal_id              = azurerm_kubernetes_cluster.traduire_app.kubelet_identity.0.object_id
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
