variable "acme_dir" {
  type = string
  default = "LE_STAGE"
}

resource "azurerm_automation_variable_string" "AcmeDirectory" {
  name                    = "AcmeDirectory"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  value                   = var.acme_dir
}

resource "azurerm_automation_variable_string" "RGVar" {
  name                    = "ResourceGroupName"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  value                   = azurerm_resource_group.automation-rg.name
}

resource "azurerm_automation_variable_string" "SAVar" {
  name                    = "StorageAccountName"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  value                   = azurerm_storage_account.storage.name
}

resource "azurerm_automation_variable_string" "KVVar" {
  name                    = "KeyVaultResourceId"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  value                   = azurerm_key_vault.kv.id
}

resource "azurerm_automation_variable_string" "KVName" {
  name                    = "KeyVaultName"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  value                   = azurerm_key_vault.kv.name

}

resource "azurerm_automation_variable_string" "ContainerVar" {
  name                    = "StorageContainerName"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  value                   = azurerm_storage_container.container.name
}

resource "azurerm_automation_variable_string" "PoshZipVar" {
  name                    = "PoshZipName"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  value                   = "${var.env}-posh-acme-${random_string.suffix.result}.zip"
}

data "local_file" "ImportCert" {
  filename = "${path.module}/Import-AcmeCertificateToKeyVault.ps1"
}