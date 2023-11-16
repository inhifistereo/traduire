locals {
  workload_identity = "${local.resource_name}-traduire-identity"
}

resource "azurerm_user_assigned_identity" "traduire_identity" {
  name                = "${local.workload_identity}"
  resource_group_name = azurerm_resource_group.traduire_app.name
  location            = azurerm_resource_group.traduire_app.location
}

resource "azurerm_federated_identity_credential" "app_identity" {
  name                = "${local.workload_identity}"
  resource_group_name = azurerm_resource_group.traduire_app.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.traduire_app.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.traduire_identity.id
  subject             = "system:serviceaccount:${var.namespace}:${local.workload_identity}"
}

resource "azurerm_user_assigned_identity" "aks_identity" {
  name                = "${local.aks_name}-cluster-identity"
  resource_group_name = azurerm_resource_group.traduire_app.name
  location            = azurerm_resource_group.traduire_app.location
}

resource "azurerm_user_assigned_identity" "aks_kubelet_identity" {
  name                = "${local.aks_name}-kubelet-identity"
  resource_group_name = azurerm_resource_group.traduire_app.name
  location            = azurerm_resource_group.traduire_app.location
}