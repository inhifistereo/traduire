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

resource "null_resource" "post_config_setup" {
  depends_on = [
    azapi_update_resource.traduire_app
  ]
  provisioner "local-exec" {
    command = "az aks pod-identity add --resource-group ${CLUSTER_RG} --cluster-name ${CLUSTER_NAME} --namespace ${NAMESPACE} --name ${IDENTITY_NAME} --identity-resource-id ${RESOURCEID}"
    interpreter = ["bash"]

    environment = {
      CLUSTER_NAME        = "${var.cluster_name}"
      CLUSTER_RG          = "${azurerm_resource_group.traduire_app.name}"
      NAMESPACE           = "keda-system"
      IDENTITY_NAME       = "aks-keda-identity"
      RESOURCEID          = "${azurerm_user_assigned_identity.keda_sb_user.id}"
    }
  }
}
