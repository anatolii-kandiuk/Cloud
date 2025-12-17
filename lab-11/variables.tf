variable "location" {
  default = "Poland Central"
}

variable "resource_group_name" {
  default = "az104-rg11"
}

variable "vm_admin_username" {
  default = "localadmin"
}

variable "vm_admin_password" {
  description = "Complex password for VM"
  sensitive   = true
}

variable "action_group_email" {
  description = "Email for alert notifications"
}
