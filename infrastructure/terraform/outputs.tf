output "postgresql_password" {
  value     = random_password.postgresql_user_password.result
  sensitive = true
}

output "cognitive_services_key" {
  value     = azurerm_cognitive_account.traduire_app.primary_access_key
  sensitive = true
}

output "AKS_RESOURCE_GROUP" {
  value     = azurerm_kubernetes_cluster.traduire_app.resource_group_name
  sensitive = false
}

output "CLUSTER_NAME" {
  value     = azurerm_kubernetes_cluster.traduire_app.name
  sensitive = false
}

output "KEDA_MI_NAME" {
  value     = azurerm_user_assigned_identity.keda_sb_user.name
  sensitive = false
}

output "KEDA_RESOURCE_ID" {
  value     = azurerm_user_assigned_identity.keda_sb_user.id
  sensitive = false
}

output "DAPR_MI_NAME" {
  value     = azurerm_user_assigned_identity.dapr_reader.name
  sensitive = false
}

output "DAPR_RESOURCE_ID" {
  value     = azurerm_user_assigned_identity.dapr_reader.id
  sensitive = false
}