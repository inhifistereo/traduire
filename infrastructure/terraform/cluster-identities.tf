resource "azapi_update_resource" "traduire_app" {
  depends_on = [
    azurerm_kubernetes_cluster_node_pool.traduire_app_node_pool
  ]

  type        = "Microsoft.ContainerService/managedClusters@2022-09-02-preview"
  resource_id = azurerm_kubernetes_cluster.traduire_app.id

  body = jsonencode({
    properties = {
      podIdentityProfile = {
        enabled = true
      }
      securityProfile = {
        workloadIdentity = {
          enabled = true
        }
      }
    }
  })
}

#Add null_resource to add Keda Service Bus identity to cluster for Pod Identies - known name: aks-keda-identity
#az aks pod-identity add --resource-group ${CLUSTER_RG} --cluster-name ${CLUSTER_NAME} --namespace ${NAMESPACE} --name ${IDENTITY_NAME} --identity-resource-id ${RESOURCEID}