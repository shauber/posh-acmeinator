# param (
#     [string] $AcmeDirectory,
#     [string] $AcmeContact,
#     [string] $CertificateNames,
#     [string] $StorageContainerSASToken
# )

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

$AcmeDirectory = "LE_STAGE" # "LE_PROD"
$AcmeContact = "shawn@shauber.net"
$CertificateNames = "test.craver.me, *.test.craver.me"
$KeyVaultResourceId = "/subscriptions/eae38160-6016-4041-8e54-b08c8bf74c6e/resourceGroups/automation-rg/providers/Microsoft.KeyVault/vaults/spc-automation-kv"

# setup our storage context and related vars
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName "automation-rg" -AccountName "automationstorage78")[0].Value
$StorageContext = New-AzStorageContext -StorageAccountName "automationstorage78" -StorageAccountKey $storageKey
$PoshZipFile = "posh-acme.zip"
$PoshZipPath = "$($env:TEMP)/$PoshZipFile"
$zipContainer = "automation"

# Supress progress messages. Azure DevOps doesn't format them correctly (used by New-PACertificate)
$global:ProgressPreference = 'SilentlyContinue'

# Split certificate names by comma or semi-colin
$CertificateNamesArr = $CertificateNames.Replace(',',';') -split ';' | ForEach-Object -Process { $_.Trim() }

# Create working directory
$workingDirectory = Join-Path -Path "." -ChildPath "pa"
New-Item -Path $workingDirectory -ItemType Directory | Out-Null

# Sync contents of storage container to working directory
# ./azcopy sync "$StorageContainerSASToken" "$workingDirectory"
$blob = Get-AzStorageBlob -Blob $PoshZipFile -Container $zipContainer -Context $StorageContext -ErrorAction Ignore
if ($blob) {
    Write-Output "We Have a blob, quick, extract it!"
    Get-AzStorageBlobContent -Blob $PoshZipFile -Container $zipContainer -Destination $PoshZipPath -Context $StorageContext
    Expand-Archive -Path $PoshZipPath -DestinationPath ".\"
    Get-ChildItem -Recurse $env:POSHACME_HOME
} else {
    Write-Output "NO BLOB HERE!"
}
# Expand-Archive -Path pa-workingdir.zip -DestinationPath $workingDirectory

# Set Posh-ACME working directory
$env:POSHACME_HOME = $workingDirectory
Import-Module Posh-ACME -Force

# Configure Posh-ACME server
Set-PAServer -DirectoryUrl $AcmeDirectory

# Configure Posh-ACME account
$account = Get-PAAccount
if (-not $account) {
    # New account
    $account = New-PAAccount -Contact $AcmeContact -AcceptTOS
}
elseif ($account.contact -ne "mailto:$AcmeContact") {
    # Update account contact
    Set-PAAccount -ID $account.id -Contact $AcmeContact
}

# Acquire access token for Azure (as we want to leverage the existing connection)
$azureContext = Get-AzContext
$currentAzureProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile;
$currentAzureProfileClient = New-Object Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient($currentAzureProfile);
$azureAccessToken = $currentAzureProfileClient.AcquireAccessToken($azureContext.Tenant.Id).AccessToken;

# Request certificate
$paPluginArgs = @{
    AZSubscriptionId = $azureContext.Subscription.Id
    AZAccessToken    = $azureAccessToken;
}
New-PACertificate -Domain $CertificateNamesArr -DnsPlugin Azure -PluginArgs $paPluginArgs

# Sync working directory back to storage container
# ./azcopy sync "$workingDirectory" "$StorageContainerSASToken"
Compress-Archive -Path $env:POSHACME_HOME -DestinationPath $PoshZipPath -Force
Set-AzStorageBlobContent -Container $zipContainer -File $PoshZipPath -Blob $PoshZipFile -Context $StorageContext -Force
Get-ChildItem -Recurse $env:POSHACME_HOME



# param (
#     [string] $CertificateNames,
#     [string] $KeyVaultResourceId
# )

# Split certificate names by comma or semi-colon
$certificateName = $CertificateNames.Replace(',', ';') -split ';' | ForEach-Object -Process { $_.Trim() } | Select-Object -First 1

# For wildcard certificates, Posh-ACME replaces * with ! in the directory name
$certificateName = $certificateName.Replace('*', '!')

# # Set working directory
# $workingDirectory = Join-Path -Path "." -ChildPath "pa"

# # Set Posh-ACME working directory
# $env:POSHACME_HOME = $workingDirectory
# Import-Module -Name Posh-ACME -Force

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
    $orderData = Get-Content -Path $orderDataPath -Raw | ConvertFrom-Json




    $pfxFilePath
    $orderData.PfxPass
    
    # Load PFX
    $certificate = New-Object -TypeName System.Security.Cryptography.X509Certificates.X509Certificate2 -ArgumentList $pfxFilePath, $orderData.PfxPass, 'EphemeralKeySet'

    # Get the current certificate from key vault (if any)
    $azureKeyVaultCertificateName = $certificateName.Replace(".", "-").Replace("!", "wildcard")
    $keyVaultResource = Get-AzResource -ResourceId $KeyVaultResourceId
    $azureKeyVaultCertificate = Get-AzKeyVaultCertificate -VaultName $keyVaultResource.Name -Name $azureKeyVaultCertificateName -ErrorAction SilentlyContinue

    # If we have a different certificate, import it
    If (-not $azureKeyVaultCertificate -or $azureKeyVaultCertificate.Thumbprint -ne $certificate.Thumbprint) {
        Import-AzKeyVaultCertificate -VaultName $keyVaultResource.Name -Name $azureKeyVaultCertificateName -FilePath $pfxFilePath -Password (ConvertTo-SecureString -String $orderData.PfxPass -AsPlainText -Force) | Out-Null
    }
}



