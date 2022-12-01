resource "azapi_resource" "flux_install" {
  depends_on = [
    azurerm_kubernetes_cluster_node_pool.traduire_app_node_pool
  ]

  type      = "Microsoft.KubernetesConfiguration/extensions@2021-09-01"
  name      = "flux"
  parent_id = azurerm_kubernetes_cluster.traduire_app.id

  body = jsonencode({
    properties = {
      extensionType           = "microsoft.flux"
      autoUpgradeMinorVersion = true
    }
  })
}

resource "azapi_resource" "flux_config" {
  depends_on = [
    azapi_resource.flux_install
  ]

  type      = "Microsoft.KubernetesConfiguration/fluxConfigurations@2022-03-01"
  name      = "aks-flux-extension"
  parent_id = azurerm_kubernetes_cluster.traduire_app.id

  body = jsonencode({
    properties : {
      scope      = "cluster"
      namespace  = "flux-system"
      sourceKind = "GitRepository"
      suspend    = false
      gitRepository = {
        url                   = local.flux_repository
        timeoutInSeconds      = 300
        syncIntervalInSeconds = 120
        repositoryRef = {
          branch = "main"
          #branch  = "workloadid"
        }
      }
      kustomizations : {
        cluster-config = {
          path                   = local.app_path
          dependsOn              = []
          timeoutInSeconds       = 300
          syncIntervalInSeconds  = 120
          retryIntervalInSeconds = 600
          prune                  = true
        }
      }
    }
  })
}