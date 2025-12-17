output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "virtual_machine_name" {
  value = azurerm_windows_virtual_machine.vm.name
}

output "action_group_name" {
  value = azurerm_monitor_action_group.ops_team.name
}

output "alert_rule_name" {
  value = azurerm_monitor_activity_log_alert.vm_delete_alert.name
}

