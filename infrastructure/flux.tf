resource "azurerm_kubernetes_cluster_extension" "flux" {
  depends_on = [
    azurerm_kubernetes_cluster_node_pool.traduire_app_node_pool
  ]
  name           = "flux"
  cluster_id     = azurerm_kubernetes_cluster.traduire_app.id
  extension_type = "microsoft.flux"
}

resource "azurerm_kubernetes_flux_configuration" "flux_config" {
  depends_on = [
    azurerm_kubernetes_cluster_extension.flux
  ]

  name       = "aks-flux-extension"
  cluster_id = azurerm_kubernetes_cluster.traduire_app.id
  namespace  = "flux-system"
  scope      = "cluster"

  git_repository {
    url                      = local.flux_repository
    reference_type           = "branch"
    reference_value          = var.github_repo_branch
    timeout_in_seconds       = 600
    sync_interval_in_seconds = 30
  }

  kustomizations {
    name = "cluster-config"
    path = local.app_path

    timeout_in_seconds         = 600
    sync_interval_in_seconds   = 120
    retry_interval_in_seconds  = 300
    garbage_collection_enabled = true
  }
}
