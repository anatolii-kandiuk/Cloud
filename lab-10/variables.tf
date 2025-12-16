variable "region1" {
  type    = string
  default = "Poland Central"
}

variable "region2" {
  type    = string
  default = "West US"
}

variable "admin_password" {
  type      = string
  sensitive = true
}

variable "timezone" {
  type    = string
  default = "E. Europe Standard Time"
}

