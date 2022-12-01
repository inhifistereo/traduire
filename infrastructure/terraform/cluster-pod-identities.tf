resource "azapi_update_resource" "traduire_app" {
  depends_on = [
   azapi_resource.flux_config
  ]

  type        = "Microsoft.ContainerService/managedClusters@2022-09-02-preview"
  resource_id = azurerm_kubernetes_cluster.traduire_app.id

  body = jsonencode({
    properties = {
      podIdentityProfile = {
        enabled = true
      }
    }
  })
}