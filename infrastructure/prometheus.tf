resource "azapi_resource" "azure_monitor_workspace" {
  type      = "microsoft.monitor/accounts@2021-06-03-preview"
  name      = "${local.resource_name}-workspace"
  parent_id = azurerm_resource_group.traduire_app.id

  location = azurerm_resource_group.traduire_app.location

  body = jsonencode({
  })
}

locals {
  am_workspace_id = "${data.azurerm_subscription.current.id}/resourcegroups/${azurerm_resource_group.traduire_app.name}/providers/microsoft.monitor/accounts/${local.resource_name}-workspace"
}

resource "azurerm_monitor_data_collection_endpoint" "this" {
  name                          = "${local.resource_name}-ama-datacollection-ep"
  resource_group_name           = azurerm_resource_group.traduire_app.name
  location                      = azurerm_resource_group.traduire_app.location
  kind                          = "Linux"
  public_network_access_enabled = true
}

resource "azurerm_monitor_data_collection_rule" "azuremonitor" {
  name                = "${local.resource_name}-ama-datacollection-rules"
  resource_group_name = azurerm_resource_group.traduire_app.name
  location            = azurerm_resource_group.traduire_app.location
  depends_on = [
    azapi_resource.azure_monitor_workspace,
    azurerm_monitor_data_collection_endpoint.this
  ]
  kind                        = "Linux"
  data_collection_endpoint_id = azurerm_monitor_data_collection_endpoint.this.id

  destinations {
    monitor_account {
      monitor_account_id = local.am_workspace_id
      name               = "MonitoringAccount"
    }
  }

  data_flow {
    destinations = ["MonitoringAccount"]
    streams      = ["Microsoft-PrometheusMetrics"]
  }

  data_sources {
    prometheus_forwarder {
      name    = "PrometheusDataSource"
      streams = ["Microsoft-PrometheusMetrics"]
    }
  }
}

resource "azapi_resource" "monitor_datacollection_rule_associations" {
  type = "Microsoft.Insights/dataCollectionRuleAssociations@2021-09-01-preview"
  name = "${local.resource_name}-ama-datacollection-rules-association"
  parent_id = azurerm_kubernetes_cluster.traduire_app.id
  body = jsonencode({
    properties = {
      dataCollectionRuleId = azurerm_monitor_data_collection_rule.azuremonitor.id
    }
  })
}