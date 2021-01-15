resource "azurerm_resource_group" "traduire_app" {
  name                  = "${var.application_name}_app_rg"
  location              = var.region
  tags                  = {
    Application         = var.application_name
    Tier                = "App Components"
  }
}

#resource "azurerm_postgresql_database" "traduire_app" { 
#
#}

resource "azurerm_servicebus_namespace" "traduire_app" {
  name                      = var.service_bus_namespace_name
  location                  = azurerm_resource_group.traduire_app.location
  resource_group_name       = azurerm_resource_group.traduire_app.name
  sku                       = "Premium"
  capacity                  = 2
}

resource "azurerm_servicebus_queue" "traduire_app" {
  name                  = "events"
  namespace_name        = azurerm_servicebus_namespace.traduire_app.name
  resource_group_name   = azurerm_resource_group.traduire_app.name
  enable_partitioning   = true
}

resource "azurerm_private_endpoint" "servicebus_namespace" {
  name                      = "${var.service_bus_namespace_name}-ep"
  resource_group_name       = azurerm_resource_group.traduire_app.name
  location                  = azurerm_resource_group.traduire_app.location
  subnet_id                 = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "${var.service_bus_namespace_name}-ep"
    private_connection_resource_id = azurerm_servicebus_namespace.traduire_app.id
    subresource_names              = [ "namespace" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                          = azurerm_private_dns_zone.privatelink_servicebus_windows_net.name
    private_dns_zone_ids          = [ azurerm_private_dns_zone.privatelink_servicebus_windows_net.id ]
  }
}

resource "azurerm_storage_account" "traduire_app" {
  name                     = var.mp3_storage_name
  resource_group_name      = azurerm_resource_group.traduire_app.name
  location                 = azurerm_resource_group.traduire_app.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_private_endpoint" "storage_account" {
  name                      = "${var.mp3_storage_name}-ep"
  resource_group_name       = azurerm_resource_group.traduire_app.name
  location                  = azurerm_resource_group.traduire_app.location
  subnet_id                 = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "${var.mp3_storage_name}-ep"
    private_connection_resource_id = azurerm_storage_account.traduire_app.id
    subresource_names              = [ "blob" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                          = azurerm_private_dns_zone.privatelink_blob_core_windows_net.name
    private_dns_zone_ids          = [ azurerm_private_dns_zone.privatelink_blob_core_windows_net.id ]
  }
}

resource "azurerm_kubernetes_cluster" "traduire_app" {
  name                      = var.aks_name
  resource_group_name       = azurerm_resource_group.traduire_app.name
  location                  = azurerm_resource_group.traduire_app.location
  node_resource_group       = "${azurerm_resource_group.traduire_app.name}_k8s_nodes"
  dns_prefix                = var.aks_name
  sku_tier                  = "Paid"
  api_server_authorized_ip_ranges = [ var.api_server_authorized_ip_ranges ]
  linux_profile {
    admin_username          = "manager"

    ssh_key {
        key_data            = var.ssh_public_key
    }
  }

  identity {
    type                    = "SystemAssigned"
  }

  default_node_pool  {
    name                    = "default"
    node_count              = 3
    vm_size                = "Standard_B4ms"
    os_disk_size_gb         = 30
    vnet_subnet_id          = azurerm_subnet.kubernetes.id
    type                    = "VirtualMachineScaleSets"
    enable_auto_scaling     = true
    min_count               = 3
    max_count               = 10
    max_pods                = 40
  }

  role_based_access_control {
    enabled                 = "true"
  }

  network_profile {
    dns_service_ip          = "10.190.0.10"
    service_cidr            = "10.190.0.0/16"
    docker_bridge_cidr      = "172.17.0.1/16"
    network_plugin          = "azure"
    load_balancer_sku       = "standard"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.traduire_logs.id
    }
  }
}

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

resource "azurerm_role_assignment" "network_contributor_node" {
  scope                     = azurerm_resource_group.traduire_core.id
  role_definition_name      = "Network Contributor"
  principal_id              = azurerm_kubernetes_cluster.traduire_app.identity.0.principal_id
  skip_service_principal_aad_check = true
}

resource "azurerm_container_registry" "traduire_acr" {
  name                     = var.acr_account_name
  resource_group_name      = azurerm_resource_group.traduire_app.name
  location                 = azurerm_resource_group.traduire_app.location
  sku                      = "Premium"
  admin_enabled            = false

  network_rule_set {
    default_action = "Deny"
    ip_rule {
      action              = "Allow"
      ip_range            =  var.api_server_authorized_ip_ranges
    }
  }
  
}

resource "azurerm_private_endpoint" "acr_account" {
  name                      = "${var.acr_account_name}-ep"
  resource_group_name       = azurerm_resource_group.traduire_app.name
  location                  = azurerm_resource_group.traduire_app.location
  subnet_id                 = azurerm_subnet.private-endpoints.id

  private_service_connection {
    name                           = "${var.acr_account_name}-ep"
    private_connection_resource_id = azurerm_container_registry.traduire_acr.id
    subresource_names              = [ "registry" ]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                          = azurerm_private_dns_zone.privatelink_azurecr_io.name
    private_dns_zone_ids          = [ azurerm_private_dns_zone.privatelink_azurecr_io.id ]
  }
}