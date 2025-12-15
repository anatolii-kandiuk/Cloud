variable "resource_group_name" {
  type    = string
  default = "az104-rg9"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "webapp_name_prefix" {
  type    = string
  default = "webapp-ak"
}

variable "notification_emails" {
  type    = list(string)
  default = ["your.email@example.com"]
}
