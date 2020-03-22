provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "~> 2.2.0"
  features {}
}

data "azurerm_resource_group" "automation-rg" {
  name     = "automation-rg"
}

data "azurerm_storage_account" "storage" {
  resource_group_name = data.azurerm_resource_group.automation-rg.name
  name                = "automationstorage78"
}

data "azurerm_storage_container" "container" {
    storage_account_name = data.azurerm_storage_account.storage.name
    name                 = "automation"
}

data "azurerm_key_vault" "kv" {
  resource_group_name = data.azurerm_resource_group.automation-rg.name
  name                = "spc-automation-kv"
}

data "azurerm_automation_account" "acmeinator" {
  resource_group_name = data.azurerm_resource_group.automation-rg.name
  name                = "acmeinator"
}

resource "azurerm_automation_variable_string" "AcmeDirectory" {
  name                    = "AcmeDirectory"
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  value                   = "LE_STAGE"
}

resource "azurerm_automation_variable_string" "RGVar" {
  name                    = "ResourceGroupName"
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  value                   = data.azurerm_resource_group.automation-rg.name
}

resource "azurerm_automation_variable_string" "SAVar" {
  name                    = "StorageAccountName"
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  value                   = data.azurerm_storage_account.storage.name
}

resource "azurerm_automation_variable_string" "KVVar" {
  name                    = "KeyVaultResourceId"
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  value                   = data.azurerm_key_vault.kv.id
}

resource "azurerm_automation_variable_string" "ContainerVar" {
  name                    = "StorageContainerName"
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  value                   = data.azurerm_storage_container.container.name
}

resource "azurerm_automation_variable_string" "PoshZipVar" {
  name                    = "PoshZipName"
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  value                   = "posh-acme.zip"
}

data "local_file" "ImportCert" {
  filename = "${path.module}/Import-AcmeCertificateToKeyValut.ps1"
}

resource "azurerm_automation_runbook" "NewCert" {
  name                    = "Import-AcmeCertificateToKeyValut"
  location                = data.azurerm_resource_group.automation-rg.location
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://example.com"
  }

  content = data.local_file.ImportCert.content
}

data "local_file" "NewCert" {
  filename = "${path.module}/New-AcmeCertificate.ps1"
}

resource "azurerm_automation_runbook" "NewCert" {
  name                    = "New-AcmeCertificate"
  location                = data.azurerm_resource_group.automation-rg.location
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://example.com"
  }

  content = data.local_file.NewCert.content
}

data "local_file" "RenewCerts" {
  filename = "${path.module}/Renew-AcmeCertificates.ps1"
}

resource "azurerm_automation_runbook" "RenewCerts" {
  name                    = "Renew-AcmeCertificates"
  location                = data.azurerm_resource_group.automation-rg.location
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://example.com"
  }

  content = data.local_file.RenewCerts.content
}

data "local_file" "RestorePosh" {
  filename = "${path.module}/Restore-PoshHome.ps1"
}

resource "azurerm_automation_runbook" "RestorePosh" {
  name                    = "Restore-PoshHome"
  location                = data.azurerm_resource_group.automation-rg.location
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://example.com"
  }

  content = data.local_file.RestorePosh.content
}

data "local_file" "SavePosh" {
  filename = "${path.module}/Save-PoshHome.ps1"
}

resource "azurerm_automation_runbook" "SavePosh" {
  name                    = "Save-PoshHome"
  location                = data.azurerm_resource_group.automation-rg.location
  resource_group_name     = data.azurerm_resource_group.automation-rg.name
  automation_account_name = data.azurerm_automation_account.acmeinator.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://example.com"
  }

  content = data.local_file.SavePosh.content
}
