output "postgresql_password" {
  value = azurerm_postgresql_server.traduire_app.administrator_login_password
}