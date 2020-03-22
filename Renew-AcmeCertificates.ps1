param (
    [string] $AcmeDirectory = "LE_STAGE" # "LE_PROD"
)

## Allow the AzAutomation variable override the default, but not if it's passed in
$AutomationAcmeDirectory = Get-AutomationVariable -Name 'AcmeDirectory'
if (-not $PSBoundParameters.ContainsKey('AcmeDirectory') -and -not [string]::IsNullOrEmpty($AutomationAcmeDirectory)) {
    $AcmeDirectory = $AutomationAcmeDirectory
}

## All of this is Azure Automation specific initialization
if ($PSPrivateMetadata.JobId) {
    $connectionName = "AzureRunAsConnection"
    try
    {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection=Get-AutomationConnection -Name $connectionName         
    
        "Logging in to Azure..."
        Add-AzAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
    }
    catch {
        if (!$servicePrincipalConnection)
        {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
}


#Supress progress messages. Azure DevOps doesn't format them correctly (used by New-PACertificate)
$global:ProgressPreference = 'SilentlyContinue'

if ([string]::IsNullOrWhiteSpace($env:POSHACME_HOME)) {
	exit 1
}

./Restore-PoshHome.ps1

Import-Module Posh-ACME -Force

#Configure Posh-ACME server
Set-PAServer -DirectoryUrl $AcmeDirectory

#Configure Posh-ACME account
$account = Get-PAAccount
if (-not $account) {
    # New account
    throw "No Let's Encrypt accounts found"
}

#Acquire access token for Azure (as we want to leverage the existing connection)
$azureContext = Get-AzContext
$currentAzureProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
$currentAzureProfileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($currentAzureProfile);
$azureAccessToken = $currentAzureProfileClient.AcquireAccessToken($azureContext.Tenant.Id).AccessToken;

#Request certificate
$paPluginArgs = @{
    AZSubscriptionId = $azureContext.Subscription.Id
    AZAccessToken    = $azureAccessToken;
}

## Maybe switch this to -AllOrders if it takes too long and split 
## into per account jobs?
Submit-Renewal -AllAccounts -PluginArgs $paPluginArgs -Force| ForEach-Object {
    $cert = $_
    Write-Output "Got a certificate for $($cert.AllSANs[0]), saving to KeyVault"
    ./Import-AcmeCertificateToKeyVault.ps1 -CertificateNames $cert.AllSANs[0] -AcmeDirectory $AcmeDirectory
}

