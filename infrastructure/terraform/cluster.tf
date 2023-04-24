data "azurerm_client_config" "current" {}

data "azurerm_kubernetes_service_versions" "current" {
  location = azurerm_resource_group.traduire_app.location
}

resource "azurerm_kubernetes_cluster" "traduire_app" {
  name                            = local.aks_name
  resource_group_name             = azurerm_resource_group.traduire_app.name
  location                        = azurerm_resource_group.traduire_app.location
  node_resource_group             = "${azurerm_resource_group.traduire_app.name}_k8s_nodes"
  kubernetes_version              = data.azurerm_kubernetes_service_versions.current.latest_version
  dns_prefix                      = local.aks_name
  sku_tier                        = "Standard"
  oidc_issuer_enabled             = true
  workload_identity_enabled       = true
  azure_policy_enabled            = true
  local_account_disabled          = false 
  automatic_channel_upgrade       = "patch"
  api_server_authorized_ip_ranges = ["${chomp(data.http.myip.response_body)}/32"]
  
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aks_identity.id]
  }

  kubelet_identity {
    client_id                 = azurerm_user_assigned_identity.aks_kubelet_identity.client_id
    object_id                 = azurerm_user_assigned_identity.aks_kubelet_identity.principal_id
    user_assigned_identity_id = azurerm_user_assigned_identity.aks_kubelet_identity.id
  }

  default_node_pool  {
    name                    = "default"
    node_count              = 3
    vm_size                = "Standard_DS2_v2"
    os_disk_size_gb         = 30
    vnet_subnet_id          = azurerm_subnet.kubernetes.id
    type                    = "VirtualMachineScaleSets"
    enable_auto_scaling     = true
    min_count               = 3
    max_count               = 10
    max_pods                = 40
  }

  network_profile {
    dns_service_ip          = "100.${random_integer.services_cidr.id}.0.10"
    service_cidr            = "100.${random_integer.services_cidr.id}.0.0/16"
    docker_bridge_cidr      = "172.17.0.1/16"
    network_plugin          = "azure"
    load_balancer_sku       = "standard"
  }

  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.traduire_logs.id
  }

  microsoft_defender {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.traduire_logs.id
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "traduire_app_node_pool" {
  name                  = "traduire"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.traduire_app.id
  vm_size               = "Standard_B4ms"
  enable_auto_scaling   = true
  node_count            = 3
  min_count             = 3
  max_count             = 10
  vnet_subnet_id        = azurerm_subnet.kubernetes.id
  node_taints           = [ "app=traduire:NoSchedule" ]
}