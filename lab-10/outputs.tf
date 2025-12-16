output "vm_name" {
  value = azurerm_windows_virtual_machine.vm.name
}

output "vm_id" {
  value = azurerm_windows_virtual_machine.vm.id
}

output "rsv_region1" {
  value = azurerm_recovery_services_vault.rsv1.name
}

output "rsv_region2" {
  value = azurerm_recovery_services_vault.rsv2.name
}

output "backup_policy" {
  value = azurerm_backup_policy_vm.backup_policy.name
}

