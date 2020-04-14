variable "resource-group-location" {
  type = string
  default = "East US"
}

variable "env" {
  type = string
  default = "dev"
}

variable "run_as_account_sp_object_id" {
  type = string
  default = "deadbeef-8080-8080-dead-deadbeef8080"
}

resource "random_string" "suffix" {
  length = 12 - length(var.env) 
  upper = false
  special = false
}

resource "azurerm_resource_group" "automation-rg" {
  name     = "${var.env}-marvin-rg-${random_string.suffix.result}"
  location = var.resource-group-location
}

resource "azurerm_storage_account" "storage" {
  resource_group_name = azurerm_resource_group.automation-rg.name
  name                     = "${var.env}0marvin0sa0${random_string.suffix.result}"
  location                 = azurerm_resource_group.automation-rg.location
  account_tier             = "Standard"
  account_kind             = "StorageV2"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
    storage_account_name = azurerm_storage_account.storage.name
    name                 = "automation"
    container_access_type = "private"
}

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "kv" {
  resource_group_name = azurerm_resource_group.automation-rg.name
  name                      = "${var.env}-marvin-kv-${random_string.suffix.result}"
  location                  =  azurerm_resource_group.automation-rg.location
  sku_name                  = "standard"
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  soft_delete_enabled       = false
  purge_protection_enabled  = false

  network_acls {
    default_action = "Allow"
    bypass         = "None"
  }
}

resource "azurerm_key_vault_access_policy" "give_me_access" {
  key_vault_id = azurerm_key_vault.kv.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "backup", "create", "decrypt", "delete", "encrypt", "get", "import", 
    "list", "purge", "recover", "restore", "sign", "unwrapKey", "update", 
    "verify", "wrapKey"
  ]

  secret_permissions = [
    "backup", "delete", "get", "list", "purge", "recover", "restore", "set"
  ]

  certificate_permissions = [
    "backup", "create", "delete", "deleteissuers", "get", "getissuers", 
    "import", "list", "listissuers", "managecontacts", "manageissuers", 
    "purge", "recover", "restore", "setissuers", "update"
  ]
}

resource "azurerm_automation_account" "cron" {
  resource_group_name = azurerm_resource_group.automation-rg.name
  location            = azurerm_resource_group.automation-rg.location
  sku_name            = "Basic"
  name                = "${var.env}-marvin-aa-${random_string.suffix.result}"
}

resource "azurerm_key_vault_access_policy" "run_as_account_access" {
  count = var.run_as_account_sp_object_id != "deadbeef-8080-8080-dead-deadbeef8080" ? 1 : 0
  key_vault_id = azurerm_key_vault.kv.id

  tenant_id      = data.azurerm_client_config.current.tenant_id
  object_id      = var.run_as_account_sp_object_id

  certificate_permissions = [
    "backup", "create", "delete", "deleteissuers", "get", "getissuers", 
    "import", "list", "listissuers", "managecontacts", "manageissuers", 
    "purge", "recover", "restore", "setissuers", "update"
  ]
}