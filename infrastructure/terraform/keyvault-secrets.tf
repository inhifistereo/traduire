resource "azurerm_key_vault_secret" "pub_sub_connection_string" {
  name         = var.pubsub_secret_name
  value        = azurerm_web_pubsub.traduire_app.primary_connection_string
  key_vault_id = azurerm_key_vault.traduire_app.id
}

resource "azurerm_key_vault_secret" "service_bus_connection_string" {
  name         = var.service_bus_secret_name
  value        = azurerm_servicebus_namespace.traduire_app.default_primary_connection_string
  key_vault_id = azurerm_key_vault.traduire_app.id
}

resource "azurerm_key_vault_secret" "storage_secret_name" {
  name         = var.storage_secret_name
  value        = azurerm_storage_account.traduire_app.primary_access_key 
  key_vault_id = azurerm_key_vault.traduire_app.id
}
 
resource "azurerm_key_vault_secret" "postgresql_connection_string" {
  name         = var.postgresql_secret_name
  value        = "host=${local.sql_name}.postgres.database.azure.com user=${var.postgresql_user_name} password=${random_password.postgresql_user_password.result} port=5432 dbname=${var.postgresql_database_name} sslmode=require"
  key_vault_id = azurerm_key_vault.traduire_app.id
}

resource "azurerm_key_vault_secret" "azurerm_cognitive_account_key" {
  name         = var.cognitive_services_secret_name
  value        = azurerm_cognitive_account.traduire_app.primary_access_key
  key_vault_id = azurerm_key_vault.traduire_app.id
}