terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  backend "azurerm" {
    # Backend configuration should be provided via backend config file
    # or command line parameters during terraform init
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Variables
variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "cloud-notes-hub"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "supabase_url" {
  description = "Supabase project URL"
  type        = string
  sensitive   = true
}

variable "supabase_anon_key" {
  description = "Supabase anonymous key"
  type        = string
  sensitive   = true
}

variable "supabase_service_role_key" {
  description = "Supabase service role key"
  type        = string
  sensitive   = true
}

# Local variables
locals {
  resource_prefix = "${var.project_name}-${var.environment}"
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

# Data source for current client
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.resource_prefix}-rg"
  location = var.location
  tags     = local.common_tags
}

# Key Vault
resource "azurerm_key_vault" "main" {
  name                       = "${var.project_name}${var.environment}kv"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = [
      "Get",
      "List",
      "Set",
      "Delete",
      "Purge",
      "Recover"
    ]
  }

  tags = local.common_tags
}

# Store Supabase credentials in Key Vault
resource "azurerm_key_vault_secret" "supabase_url" {
  name         = "supabase-url"
  value        = var.supabase_url
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.common_tags
}

resource "azurerm_key_vault_secret" "supabase_anon_key" {
  name         = "supabase-anon-key"
  value        = var.supabase_anon_key
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.common_tags
}

resource "azurerm_key_vault_secret" "supabase_service_role_key" {
  name         = "supabase-service-role-key"
  value        = var.supabase_service_role_key
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.common_tags
}

# Storage Account for logs and static content
resource "azurerm_storage_account" "main" {
  name                     = "${var.project_name}${var.environment}st"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    versioning_enabled = true
  }

  tags = local.common_tags
}

# Storage Container for logs
resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Static Web App
resource "azurerm_static_web_app" "main" {
  name                = "${local.resource_prefix}-swa"
  resource_group_name = azurerm_resource_group.main.name
  location            = "East US 2" # Static Web Apps have limited region availability
  sku_tier            = "Free"
  sku_size            = "Free"

  tags = local.common_tags
}

# Add access policy for Static Web App to Key Vault
resource "azurerm_key_vault_access_policy" "static_web_app" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_static_web_app.main.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]

  depends_on = [azurerm_static_web_app.main]
}

# Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "static_web_app_name" {
  description = "Name of the Static Web App"
  value       = azurerm_static_web_app.main.name
}

output "static_web_app_url" {
  description = "Default hostname of the Static Web App"
  value       = azurerm_static_web_app.main.default_host_name
}

output "static_web_app_api_key" {
  description = "API key for Static Web App deployment"
  value       = azurerm_static_web_app.main.api_key
  sensitive   = true
}
