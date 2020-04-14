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
            Write-Error "Connection $connectionName not found."
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        } else{
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
}


#Supress progress messages. Azure DevOps doesn't format them correctly (used by New-PACertificate)
# $global:ProgressPreference = 'SilentlyContinue'

Write-Output "Restoring posh-acme home"
./Restore-PoshHome.ps1

if ([string]::IsNullOrWhiteSpace($env:POSHACME_HOME)) {
    Write-Error "POSHACME_HOME env var not set"
	exit 1
}

Import-Module Posh-ACME -Force

#Configure Posh-ACME servera
Write-Output "Setting ACME directory to $AcmeDirectory"
Set-PAServer -DirectoryUrl $AcmeDirectory

#Configure Posh-ACME account
Write-Output "Configuring ACME account"
$account = Get-PAAccount
if (-not $account) {
    # New account
    throw "No Let's Encrypt accounts found"
}

#Acquire access token for Azure (as we want to leverage the existing connection)
Write-Output "Getting Azure Access Token"
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
Write-Output "Checking for certs that need renewal"
Submit-Renewal -AllAccounts -PluginArgs $paPluginArgs | ForEach-Object {
    $cert = $_
    Write-Output "Got a certificate for $($cert.AllSANs[0]), saving to KeyVault"
    ./Import-AcmeCertificateToKeyVault.ps1 -CertificateNames $cert.AllSANs[0] -AcmeDirectory $AcmeDirectory
}

Write-Output "Saving posh-acme home"
./Save-PoshHome.ps1
