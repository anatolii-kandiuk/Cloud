terraform {
  required_version = ">= 1.4.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.100"
    }
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "region1" {
  name     = "az104-rg-region1"
  location = var.region1
}

resource "azurerm_resource_group" "region2" {
  name     = "az104-rg-region2"
  location = var.region2
}


resource "azurerm_virtual_network" "vnet_region1" {
  name                = "az104-vnet-kandiuk"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
}

resource "azurerm_subnet" "subnet_default" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.region1.name
  virtual_network_name = azurerm_virtual_network.vnet_region1.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_interface" "vm_nic" {
  name                = "az104-nic-kandiuk"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_default.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Virtual Machine (Task 1)
resource "azurerm_windows_virtual_machine" "vm" {
  name                = "az104-10-vm0"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  size                = "Standard_B1ms"

  admin_username = "localadmin"
  admin_password = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.vm_nic.id
  ]

  os_disk {
    name                 = "az104-10-vm0-osdisk"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  tags = {
    lab   = "az104"
    owner = "kandiuk"
  }
}

# Recovery Services Vault (Region 1)
# Task 2
resource "azurerm_recovery_services_vault" "rsv_region1" {
  name                = "az104-rsv-region1"
  location            = azurerm_resource_group.region1.location
  resource_group_name = azurerm_resource_group.region1.name
  sku                 = "Standard"

  soft_delete_enabled = true

  tags = {
    owner = "kandiuk"
  }
}

# Backup Policy (Task 3)
resource "azurerm_backup_policy_vm" "vm_backup_policy" {
  name                = "az104-backup"
  resource_group_name = azurerm_resource_group.region1.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_region1.name

  timezone = var.timezone

  backup {
    frequency = "Daily"
    time      = "00:00"
  }

  retention_daily {
    count = 7
  }
}

resource "azurerm_backup_protected_vm" "vm_backup" {
  resource_group_name = azurerm_resource_group.region1.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv_region1.name
  source_vm_id        = azurerm_windows_virtual_machine.vm.id
  backup_policy_id    = azurerm_backup_policy_vm.vm_backup_policy.id
}

# Storage Account for Diagnostics (Task 4)
resource "azurerm_storage_account" "backup_logs" {
  name                     = "kandiukstorage${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.region1.name
  location                 = azurerm_resource_group.region1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    purpose = "backup-logs"
    owner   = "kandiuk"
  }
}

resource "random_string" "suffix" {
  length  = 6
  upper   = false
  special = false
}

# Recovery Services Vault (Region 2)
# Task 5
resource "azurerm_recovery_services_vault" "rsv_region2" {
  name                = "az104-rsv-region2"
  location            = azurerm_resource_group.region2.location
  resource_group_name = azurerm_resource_group.region2.name
  sku                 = "Standard"

  soft_delete_enabled = true

  tags = {
    owner = "kandiuk"
  }
}

