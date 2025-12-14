variable "location" {
  description = "Azure region"
  default     = "Germany West Central"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  default     = "az104-rg8"
}

variable "admin_username" {
  description = "Admin username for VMs"
  default     = "localadmin"
}

variable "admin_password" {
  description = "Admin password for VMs"
  default     = "P@ssword1234!"
}
