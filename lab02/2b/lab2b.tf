terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# ---------------------------
# Task 1: Create Resource Group with Tag
# ---------------------------

resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg2"
  location = "East US"

  tags = {
    "Cost Center" = "000"
  }
}

# ---------------------------
# Task 2: Assign Built-in Policy to enforce Cost Center Tag
# ---------------------------

resource "azurerm_policy_assignment" "require_cost_center" {
  name                 = "require-cost-center-tag"
  scope                = azurerm_resource_group.rg2.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/2d23f2a2-06b8-4fa8-91f0-6e4d0f6aeb37" # built-in: Require a tag and its value on resources

  description          = "Require Cost Center tag and its value on all resources in the resource group"
  enforce              = true

  parameters = jsonencode({
    tagName  = { "value" = "Cost Center" }
    tagValue = { "value" = "000" }
  })
}

# ---------------------------
# Task 3: Policy for Inheriting Tag from Resource Group
# ---------------------------

resource "azurerm_policy_assignment" "inherit_cost_center" {
  name                 = "inherit-cost-center-tag"
  scope                = azurerm_resource_group.rg2.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/8e3af657-a8ff-443c-a75c-2fe8c4bcb635"

  description          = "Inherit the Cost Center tag and its value 000 from the resource group if missing"
  enforce              = true

  parameters = jsonencode({
    tagName = { "value" = "Cost Center" }
  })

  # Enable remediation for existing resources
  identity {
    type = "SystemAssigned"
  }
}

# ---------------------------
# Task 4: Add Resource Lock to Resource Group
# ---------------------------

resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.rg2.id
  lock_level = "CanNotDelete"
  notes      = "Protect resource group from accidental deletion"
}
