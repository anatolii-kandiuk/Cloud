output "container_app_url" {
  value = "https://${azurerm_container_app.app.latest_revision_fqdn}"
}

output "container_app_fqdn" {
  value = azurerm_container_app.app.latest_revision_fqdn
}
