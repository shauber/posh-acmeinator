$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$StorageAccountName = Get-AutomationVariable -Name 'StorageAccountName'

if ([string]::IsNullOrEmpty($env:TEMP)) { # This seems to be set to something sane on Windows, not on POSIX systems
    $env:TEMP = "/tmp"
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


#setup our storage context and related vars
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName "$ResourceGroupName" -AccountName "$StorageAccountName")[0].Value
$StorageContext = New-AzStorageContext -StorageAccountName "$StorageAccountName" -StorageAccountKey $storageKey
$PoshZipFile = Get-AutomationVariable -Name 'PoshZipName'
$PoshZipPath = "$($env:TEMP)/$PoshZipFile"
$zipContainer = Get-AutomationVariable -Name 'StorageContainerName'

#Create working directory
$workingDirectory = Join-Path -Path "." -ChildPath "pa"
New-Item -Path $workingDirectory -ItemType Directory -Force| Out-Null

#Sync contents of storage container to working directory
$blob = Get-AzStorageBlob -Blob $PoshZipFile -Container $zipContainer -Context $StorageContext -ErrorAction Ignore
if ($blob) {
    Write-Output "We Have a blob, quick, extract it!"
    Get-AzStorageBlobContent -Blob $PoshZipFile -Container $zipContainer -Destination $PoshZipPath -Context $StorageContext -Force
    Expand-Archive -Path $PoshZipPath -DestinationPath ".\" -Force
    Get-ChildItem -Recurse $env:POSHACME_HOME
} else {
    Write-Output "NO BLOB HERE!"
}

#Set Posh-ACME working directory
$env:POSHACME_HOME = $workingDirectory

