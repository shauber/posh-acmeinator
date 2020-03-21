param (
    [string] $AcmeContact = $global:AcmeContact,

    [Parameter(Mandatory=$true)]
    [string] $CertificateNames,

    [string] $AcmeDirectory = "LE_STAGE" # always default to Let's Encrypt stage
)


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

    if ([string]::IsNullOrEmpty($AcmeContact)) { 
        $AcmeContact = Get-AutomationVariable -Name DefaultAcmeContact
    }

    ## if we weren't called with an explicit value for AcmeDirectory allow AZ Automation to override it
    if (-not $PSBoundParameters.ContainsKey('AcmeDirectory')) {
        $AzDefaultAcmeDirectory = Get-AutomationVariable -Name $AzDefaultAcmeDirectory
        if (-not [string]::IsNullOrEmpty($AzDefaultAcmeDirectory)) {
            $AcmeDirectory = $AzDefaultAcmeDirectory 
        }
    }

}

#Supress progress messages. Azure DevOps doesn't format them correctly (used by New-PACertificate)
$global:ProgressPreference = 'SilentlyContinue'

#Split certificate names by comma or semi-colin
$CertificateNamesArr = $CertificateNames.Replace(',',';') -split ';' | ForEach-Object -Process { $_.Trim() }

#make sure we have a Posh-ACME working directory
if ([string]::IsNullOrWhiteSpace($env:POSHACME_HOME)) {
	exit 1
}

Import-Module Posh-ACME -Force

#Configure Posh-ACME server
Set-PAServer -DirectoryUrl $AcmeDirectory

#Configure Posh-ACME account
$account = Get-PAAccount

if (-not $account) {
    if ([string]::IsNullOrEmpty($AcmeContact)) {
        throw "AcmeContact not passed in, not set as a global, and no DefaultAcmeContact set in AZ Automation (or not running in AZ Automation)."
    }
    # New account
    $account = New-PAAccount -Contact $AcmeContact -AcceptTOS
}
elseif ($account.contact -ne "mailto:$AcmeContact") {
    # Update account contact
    Set-PAAccount -ID $account.id -Contact $AcmeContact
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

New-PACertificate -Domain $CertificateNamesArr -DnsPlugin Azure -PluginArgs $paPluginArgs | ForEach-Object {
    $cert = $_
    Write-Output $cert
    if ($cert.MainDomain -eq 'example.com') {
        # deploy for example.com
    } elseif ($cert.MainDomain -eq 'example.net') {
        # deploy for example.com
    } else {
        # deploy for everything else
    }
}

