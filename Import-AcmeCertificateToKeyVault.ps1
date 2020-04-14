param (
    [Parameter(Mandatory=$true)]
    [string] $CertificateNames,

    [string] $AcmeDirectory = "LE_STAGE" # "LE_PROD"
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
}

$KeyVaultResourceId = Get-AutomationVariable -Name 'KeyVaultResourceId'

# Split certificate names by comma or semi-colon
$certificateName = $CertificateNames.Replace(',', ';') -split ';' | ForEach-Object -Process { $_.Trim() } | Select-Object -First 1

#For wildcard certificates, Posh-ACME replaces * with ! in the directory name
$certificateName = $certificateName.Replace('*', '!')

#make sure we have a Posh-ACME working directory
if ([string]::IsNullOrWhiteSpace($env:POSHACME_HOME)) {
    Write-Output "No Posh-ACME HOME found"
	exit 1
}

$workingDirectory = $env:POSHACME_HOME

Import-Module Posh-ACME -Force

#Configure Posh-ACME server
Set-PAServer -DirectoryUrl $AcmeDirectory

#Configure Posh-ACME account
$account = Get-PAAccount
if (-not $account) {
    # New account
    exit 1
}
elseif ($account.contact -ne "mailto:$AcmeContact") {
    # Update account contact
    exit 1
}

# Resolve the details of the certificate
$currentServerName = ((Get-PAServer).location) -split "/" | Where-Object -FilterScript { $_ } | Select-Object -Skip 1 -First 1
$currentAccountName = (Get-PAAccount).id

# Determine paths to resources
$orderDirectoryPath = Join-Path -Path $workingDirectory -ChildPath $currentServerName | Join-Path -ChildPath $currentAccountName | Join-Path -ChildPath $certificateName
$orderDataPath = Join-Path -Path $orderDirectoryPath -ChildPath "order.json"
$pfxFilePath = Join-Path -Path $orderDirectoryPath -ChildPath "fullchain.pfx"

# If we have a order and certificate available
if ((Test-Path -Path $orderDirectoryPath) -and (Test-Path -Path $orderDataPath) -and (Test-Path -Path $pfxFilePath)) {
    # Load order data
    Write-Output "Getting certificate order info for $certificateName"
    $orderData = Get-Content -Path $orderDataPath -Raw | ConvertFrom-Json

    Write-Output "Getting certificate data for $certificateName"
    $pfxFilePath
    $orderData.PfxPass
    
    $azureKeyVaultCertificateName = $certificateName.Replace(".", "-").Replace("!", "wildcard")
    $keyVaultResource = Get-AzResource -ResourceId $KeyVaultResourceId

    Write-Output "Importing certificate for $certificateName to Key Vault"
    Import-AzKeyVaultCertificate -VaultName $keyVaultResource.Name `
    				 -Name $azureKeyVaultCertificateName `
				 -FilePath $pfxFilePath `
				 -Password (ConvertTo-SecureString -String $orderData.PfxPass -AsPlainText -Force) | Out-Null
}

