$ResourceGroupName = Get-AutomationVariable -Name 'ResourceGroupName'
$StorageAccountName = Get-AutomationVariable -Name 'StorageAccountName'

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

#make sure we have a Posh-ACME working directory
if ([string]::IsNullOrWhiteSpace($env:POSHACME_HOME)) {
	exit 1
}



#setup our storage context and related vars
$storageKey = (Get-AzStorageAccountKey -ResourceGroupName "$ResourceGroupName" -AccountName "$StorageAccountName")[0].Value
$StorageContext = New-AzStorageContext -StorageAccountName "$StorageAccountName" -StorageAccountKey $storageKey
$PoshZipFile = "posh-acme.zip"
$PoshZipPath = "$($env:TEMP)/$PoshZipFile"
$zipContainer = "automation"

#Sync working directory back to storage container
Compress-Archive -Path $env:POSHACME_HOME -DestinationPath $PoshZipPath -Force
Set-AzStorageBlobContent -Container $zipContainer -File $PoshZipPath -Blob $PoshZipFile -Context $StorageContext -Force

