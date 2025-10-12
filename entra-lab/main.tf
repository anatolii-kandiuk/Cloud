# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MPL-2.0

terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 3.0"
    }
  }
}

provider "azuread" {}

provider "azurerm" {
  features {}
}

data "azuread_domains" "default" {
  only_initial = true
}

locals {
  domain_name = data.azuread_domains.default.domains.0.domain_name
}

# TASK-1.1 - Create user
resource "azuread_user" "az104-user1" {
  user_principal_name = format(
    "%s@%s",
    "az104-user1",
    local.domain_name
  )
  password              = "Password123!"
  force_password_change = true
  display_name          = "az104-user1"
  department            = "IT"
  job_title             = "IT Lab Administrator"
  usage_location        = "UA"
}

# TASK-1.2 - Invite user
resource "azuread_invitation" "user2" {
  user_email_address = "anatolii.kandiuk.01@gmail.com"
  redirect_url       = "https://myapps.microsoft.com"
  user_display_name  = "user2"
  message {
    body = "Welcome to Azure and our group project"
  }
}

# TASK-2 - Create a group
resource "azuread_group" "IT_Lab_Administrators" {
  display_name     = "IT Lab Administrators"
  mail_nickname    = "IT_Lab_Administrators"
  security_enabled = true
  description      = "Administrators that manage the IT lab"
  owners           = ["e6f2d0cb-c4f7-424f-b001-bb7bcef82a80"]
  members = [
    azuread_user.az104-user1.object_id,
    azuread_invitation.user2.user_id
  ]
}
