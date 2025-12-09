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

# Input variables
variable "azure_region" {
  description = "Azure region"
  type        = string
  default     = "Germany West Central"
}

variable "rg_name" {
  description = "Resource group name"
  type        = string
  default     = "az104-rg7"
}

variable "storage_name" {
  description = "Unique storage account name"
  type        = string
  default     = "storagelab7anatolii"
}

# Create resource group
resource "azurerm_resource_group" "main" {
  name     = var.rg_name
  location = var.azure_region
}

# Create storage account with geo-redundancy and read access
resource "azurerm_storage_account" "main" {
  name                     = var.storage_name
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  account_kind             = "StorageV2"

  # Enable read access for GRS
  access_tier = "Hot"

  blob_properties {
    versioning_enabled = false

    # Soft delete for blobs
    delete_retention_policy {
      days = 7
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [azurerm_subnet.storage_subnet.id]
  }

  tags = {
    lab         = "lab7"
    environment = "learning"
  }
}

# Create blob container for data storage with immutable policy
resource "azurerm_storage_container" "data_container" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Immutable storage policy with time-based retention
resource "azurerm_storage_container_immutability_policy" "retention_policy" {
  storage_container_resource_manager_id = azurerm_storage_container.data_container.resource_manager_id
  immutability_period_in_days           = 180
}

# Lifecycle policy to move blobs to cool tier
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "Movetocool"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["data/securitytest/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }
}

# Create file share for Azure Files
resource "azurerm_storage_share" "files" {
  name                 = "share1"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 5
  access_tier          = "TransactionOptimized"
}

# Virtual network for network restrictions
resource "azurerm_virtual_network" "storage_vnet" {
  name                = "vnet1"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/16"]
}

# Subnet with service endpoint for storage
resource "azurerm_subnet" "storage_subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.storage_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

# Output values
output "storage_account_id" {
  description = "ID of storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_primary_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "container_name" {
  description = "Blob container name"
  value       = azurerm_storage_container.data_container.name
}

output "file_share_url" {
  description = "File share URL"
  value       = azurerm_storage_share.files.url
}
