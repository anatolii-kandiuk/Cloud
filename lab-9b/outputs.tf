output "container_fqdn" {
  value = azurerm_container_group.aci.fqdn
}

output "container_ip" {
  value = azurerm_container_group.aci.ip_address
}
