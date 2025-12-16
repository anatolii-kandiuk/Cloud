variable "resource_group_name" {
  type    = string
  default = "az104-rg9"
}

variable "container_name" {
  type    = string
  default = "az104-c1"
}

variable "container_image" {
  type    = string
  default = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "dns_name_label" {
  type    = string
  default = "kandiukwebapp-aci-2025"
}
