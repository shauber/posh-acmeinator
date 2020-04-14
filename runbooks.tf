resource "azurerm_automation_runbook" "ImportCert" {
  name                    = "Import-AcmeCertificateToKeyVault"
  location                = azurerm_resource_group.automation-rg.location
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
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
  location                = azurerm_resource_group.automation-rg.location
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
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
  location                = azurerm_resource_group.automation-rg.location
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
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
  location                = azurerm_resource_group.automation-rg.location
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
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
  location                = azurerm_resource_group.automation-rg.location
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://example.com"
  }

  content = data.local_file.SavePosh.content
}

data "local_file" "TestKV" {
  filename = "${path.module}/Test-KeyVaultConnection.ps1"
}

resource "azurerm_automation_runbook" "TestKV" {
  name                    = "Test-KeyVaultConnection"
  location                = azurerm_resource_group.automation-rg.location
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name
  log_verbose             = "true"
  log_progress            = "true"
  runbook_type            = "PowerShell"

  publish_content_link {
    uri = "https://example.com"
  }

  content = data.local_file.TestKV.content
}