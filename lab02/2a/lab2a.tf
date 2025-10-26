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

#------------------------------------
# TASK-1: Implement Management Groups
#------------------------------------

resource "azurerm_management_group" "az104_mg1" {
  display_name = "az104-mg1"
  name         = "az104-mg1"
}

#------------------------------------------------
# TASK-2: Review and assign a built-in Azure role
#------------------------------------------------

resource "azuread_group" "helpdesk" {
  display_name = "Help Desk"
  description  = "Help Desk Group"
  mail_enabled = false
  security_enabled = true
}

resource "azurerm_role_assignment" "virtual_machine_contributor_assignment" {
  scope                = azurerm_management_group.az104_mg1.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_group.helpdesk.object_id
}

#----------------------------------
# TASK-3: Create a custom RBAC role
#----------------------------------

resource "azurerm_role_definition" "custom_support_request" {
  name        = "Custom Support Request"
  scope       = azurerm_management_group.az104_mg1.id
  description = "A custom contributor role for support requests."

  permissions {
    actions     = ["Microsoft.Support/*"]
    not_actions = ["Microsoft.Support.register/action"]
  }

  assignable_scopes = [azurerm_management_group.az104_mg1.id]
}

resource "azurerm_role_assignment" "custom_support_assignment" {
  scope              = azurerm_management_group.az104_mg1.id
  role_definition_id = azurerm_role_definition.custom_support_request.role_definition_resource_id
  principal_id       = azuread_group.helpdesk.object_id
}
