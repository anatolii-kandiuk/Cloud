terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Task 1: Create Resource Group and App Service Plan
resource "azurerm_resource_group" "webapp_rg" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    Environment = "Lab"
    Project     = "AZ-104"
    Lab         = "09a-Web-Apps"
    ManagedBy   = "Terraform"
  }
}

# App Service Plan with Premium V3 tier for production workloads
resource "azurerm_service_plan" "webapp_plan" {
  name                = "${var.webapp_name_prefix}-plan"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name
  os_type             = "Linux"
  sku_name            = "P1v3"

  tags = {
    Environment = "Lab"
    ManagedBy   = "Terraform"
  }
}

# Generate random suffix for unique web app name
resource "random_string" "webapp_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_linux_web_app" "main" {
  name                = "${var.webapp_name_prefix}-${random_string.webapp_suffix.result}"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name
  service_plan_id     = azurerm_service_plan.webapp_plan.id
  https_only          = true

  site_config {
    always_on     = true
    http2_enabled = true
    ftps_state    = "FtpsOnly"

    application_stack {
      php_version = "8.2"
    }

    # Health check configuration
    health_check_path = "/"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "WEBSITE_HTTPLOGGING_RETENTION_DAYS"  = "7"
  }

  # System-assigned managed identity for secure access to Azure resources
  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Task 2: Create Staging Deployment Slot
resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.main.id
  https_only     = true

  site_config {
    always_on     = true
    http2_enabled = true

    application_stack {
      php_version = "8.2"
    }

    health_check_path = "/"
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "SLOT_NAME"                           = "staging"
  }

  tags = {
    Environment = "Staging"
    ManagedBy   = "Terraform"
  }
}

# Task 3: Configure Deployment Settings for Staging Slot
resource "azurerm_app_service_source_control_slot" "staging_source" {
  slot_id                = azurerm_linux_web_app_slot.staging.id
  repo_url               = "https://github.com/Azure-Samples/php-docs-hello-world"
  branch                 = "master"
  use_manual_integration = true
  use_mercurial          = false

  depends_on = [azurerm_linux_web_app_slot.staging]
}

# Task 4: Swap Deployment Slots (Production ↔ Staging)
resource "null_resource" "slot_swap" {
  count = 0 # Set to 1 to enable automatic swap

  provisioner "local-exec" {
    command = <<-EOT
      az webapp deployment slot swap \
        --resource-group ${azurerm_resource_group.webapp_rg.name} \
        --name ${azurerm_linux_web_app.main.name} \
        --slot staging \
        --target-slot production
    EOT
  }
  depends_on = [azurerm_app_service_source_control_slot.staging_source]
}

# Task 5: Configure Auto-Scaling Rules
resource "azurerm_monitor_autoscale_setting" "webapp_autoscale" {
  name                = "${var.webapp_name_prefix}-autoscale"
  location            = azurerm_resource_group.webapp_rg.location
  resource_group_name = azurerm_resource_group.webapp_rg.name
  target_resource_id  = azurerm_service_plan.webapp_plan.id
  enabled             = true

  profile {
    name = "default-profile"

    capacity {
      default = 1
      minimum = 1
      maximum = 2
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.webapp_plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.webapp_plan.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  notification {
    email {
      send_to_subscription_administrator    = false
      send_to_subscription_co_administrator = false
      custom_emails                         = var.notification_emails
    }
  }

  tags = {
    ManagedBy = "Terraform"
  }
}
