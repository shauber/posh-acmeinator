resource "azurerm_automation_module" "AzAccounts" {
  name                    = "Az.Accounts"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Accounts/1.7.3"
  }
}

resource "azurerm_automation_module" "AzStorage" {
  name                    = "Az.Storage"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Storage/1.13.0"
  }
}

resource "azurerm_automation_module" "AzKeyVault" {
  name                    = "Az.KeyVault"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.KeyVault/1.5.1"
  }
}

resource "azurerm_automation_module" "AzResources" {
  name                    = "Az.Resources"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Az.Resources/1.12.0"
  }
}

resource "azurerm_automation_module" "Posh-ACME" {
  name                    = "Posh-ACME"
  resource_group_name     = azurerm_resource_group.automation-rg.name
  automation_account_name = azurerm_automation_account.cron.name

  module_link {
    uri = "https://www.powershellgallery.com/api/v2/package/Posh-ACME/3.12.0"
  }
}
