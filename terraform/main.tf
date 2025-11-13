terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Commented out for initial setup - using local state
  # Uncomment and configure after first deployment if remote state is needed
  # backend "azurerm" {
  #   # Backend configuration should be provided via backend config file
  #   # or command line parameters during terraform init
  # }
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

variable "alert_email" {
  description = "Email address for monitoring alerts"
  type        = string
  default     = "codecloudevops@outlook.com"
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
  name                     = "cloudnoteshubprodst"
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

# Application Insights
resource "azurerm_log_analytics_workspace" "main" {
  name                = "${local.resource_prefix}-law"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

resource "azurerm_application_insights" "main" {
  name                = "${local.resource_prefix}-ai"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = "web"

  tags = local.common_tags
}

# Store Application Insights connection string in Key Vault
resource "azurerm_key_vault_secret" "app_insights_connection_string" {
  name         = "app-insights-connection-string"
  value        = azurerm_application_insights.main.connection_string
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.common_tags
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "${local.resource_prefix}-action-group"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "cloudnotes"

  email_receiver {
    name          = "admin-email"
    email_address = var.alert_email
    use_common_alert_schema = true
  }

  tags = local.common_tags
}

# Alert: High Error Rate
resource "azurerm_monitor_metric_alert" "error_rate" {
  name                = "${local.resource_prefix}-high-error-rate"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when error rate exceeds threshold"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "exceptions/count"
    aggregation      = "Count"
    operator         = "GreaterThan"
    threshold        = 10
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Alert: Low Availability
resource "azurerm_monitor_metric_alert" "availability" {
  name                = "${local.resource_prefix}-low-availability"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_insights.main.id]
  description         = "Alert when availability drops below threshold"
  severity            = 1
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "microsoft.insights/components"
    metric_name      = "availabilityResults/availabilityPercentage"
    aggregation      = "Average"
    operator         = "LessThan"
    threshold        = 95
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Azure Container Registry for Docker images
resource "azurerm_container_registry" "main" {
  name                = "${replace(local.resource_prefix, "-", "")}acr"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Basic"
  admin_enabled       = true

  tags = local.common_tags
}

# App Service Plan (F1 Free tier)
resource "azurerm_service_plan" "main" {
  name                = "${local.resource_prefix}-asp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "F1" # Free tier

  tags = local.common_tags
}

# Web App for Containers
resource "azurerm_linux_web_app" "main" {
  name                = "${local.resource_prefix}-webapp"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = false # F1 tier doesn't support always_on

    application_stack {
      docker_registry_url      = "https://${azurerm_container_registry.main.login_server}"
      docker_registry_username = azurerm_container_registry.main.admin_username
      docker_registry_password = azurerm_container_registry.main.admin_password
      docker_image_name        = "cloud-notes-hub:latest"
    }
  }

  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.main.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.main.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.main.admin_password
    "NEXT_PUBLIC_SUPABASE_URL"            = var.supabase_url
    "NEXT_PUBLIC_SUPABASE_ANON_KEY"       = var.supabase_anon_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Azure Container Instance for Ansible Semaphore
resource "azurerm_container_group" "semaphore" {
  name                = "${local.resource_prefix}-semaphore"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  dns_name_label      = "${replace(local.resource_prefix, "-", "")}semaphore"
  ip_address_type     = "Public"

  container {
    name   = "semaphore"
    image  = "semaphoreui/semaphore:latest"
    cpu    = "0.5"
    memory = "1.0"

    ports {
      port     = 3000
      protocol = "TCP"
    }

    environment_variables = {
      "SEMAPHORE_DB_DIALECT" = "bolt"
      "SEMAPHORE_ADMIN"      = "admin"
      "SEMAPHORE_ADMIN_PASSWORD" = "changeme"
      "SEMAPHORE_ADMIN_NAME" = "Administrator"
      "SEMAPHORE_ADMIN_EMAIL" = var.alert_email
    }

    volume {
      name       = "semaphore-data"
      mount_path = "/etc/semaphore"
      empty_dir  = true
    }
  }

  tags = local.common_tags
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

output "container_registry_name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "Container Registry login server"
  value       = azurerm_container_registry.main.login_server
}

output "container_registry_admin_username" {
  description = "Container Registry admin username"
  value       = azurerm_container_registry.main.admin_username
  sensitive   = true
}

output "container_registry_admin_password" {
  description = "Container Registry admin password"
  value       = azurerm_container_registry.main.admin_password
  sensitive   = true
}

output "web_app_name" {
  description = "Name of the Web App"
  value       = azurerm_linux_web_app.main.name
}

output "web_app_url" {
  description = "Default hostname of the Web App"
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
}

output "semaphore_url" {
  description = "URL for Ansible Semaphore portal"
  value       = "http://${azurerm_container_group.semaphore.fqdn}:3000"
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

output "log_analytics_workspace_id" {
  description = "Log Analytics Workspace ID"
  value       = azurerm_log_analytics_workspace.main.id
}
