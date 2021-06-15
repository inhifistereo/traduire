output "postgresql_password" {
  value = azurerm_postgresql_server.traduire_app.administrator_login_password
  sensitive = true
}

output "cognitive_services_key" {
  value = azurerm_cognitive_account.traduire_app.primary_access_key
  sensitive = true
}
