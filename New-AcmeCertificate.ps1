param (
    [string] $AcmeContact,
    [string] $CertificateNames
)

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


$AcmeDirectory = "LE_STAGE" # "LE_PROD"

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
#    if ($cert.MainDomain -eq 'example.com') {
#        # deploy for example.com
#    } elseif ($cert.MainDomain -eq 'example.net') {
#        # deploy for example.com
#    } else {
#        # deploy for everything else
#    }
}

