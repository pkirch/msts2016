[cmdletbinding()] # common parameters like verbose, debug etc.

param(
    [string] $subscriptionId,
    [string] $tenantId,    

    [string] $targetResourceGroupName,
    [string] $sourceResourceGroupName,
    [string] $sourceStorageAccountName,

    [string] $vmName,
    [string] $vmSize = "Standard_D1_V2",

    [string] $adminName = "demoadmin",
    [string] $adminPassword = ".KennW0rt123",

    [string] $subnetName,
    [string] $customScriptFiles,
    [string] $customScriptRun,
    [string] $customScriptArgument,
    
    [string] $privateIpAddress
)

#region test data

# SubscriptionId                       SubscriptionName    State   TenantId                             CurrentStorageAccountName
# --------------                       ----------------    -----   --------                             -------------------------
# 26a630d2-1458-481b-8c8b-e38998425e92 MSFT IT Camp Stage  Enabled 72f988bf-86f1-41af-91ab-2d7cd011db47                          


# Domain Controller

<#

$subscriptionId = "26a630d2-1458-481b-8c8b-e38998425e92"
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47"   

$targetResourceGroupName = "demo-env-customer02"
$sourceResourceGroupName = "demoenvsrc"
$sourceStorageAccountName = "customscripts2893"

$vmName = "demodc"
$vmSize = "Standard_D1_V2"

$adminName = "demoadmin"
$adminPassword = ".KennW0rt123"

$subnetName = "main"
$customScriptFiles = @("startup-configure-dc.ps1", "diskpart-dc.txt")
$customScriptRun = "startup-configure-dc.ps1"
$customScriptArgument = "-adminPassword $adminPassword -domainName demoenv.local -domainNetbiosName demoenv"
    
$privateIpAddress = "192.168.0.4"

#>


<#
# SQL Server

$subscriptionId = "26a630d2-1458-481b-8c8b-e38998425e92",
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47",    

$targetResourceGroupName = "demo-env-customer01",
$sourceResourceGroupName = "demoenvsrc",
$sourceStorageAccountName = "customscripts2893",

$vmName = "demosql",
$vmSize = "Standard_D1_V2",

$adminName = "demoadmin",
$adminPassword = ".KennW0rt123",

$subnetName = "main",
$customScriptFiles = "startup-configure-sql.ps1",
$customScriptRun = "startup-configure-sql.ps1",
    
$adDomain = "demoenv.local", 
$domainNetBiosName = "demoenv",
$privateIpAddress = "192.168.0.4"


#>

<#
# Application Server

$subscriptionId = "26a630d2-1458-481b-8c8b-e38998425e92",
$tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47",    

$targetResourceGroupName = "demo-env-customer01",
$sourceResourceGroupName = "demoenvsrc",
$sourceStorageAccountName = "customscripts2893",

$vmName = "demovm",
$vmSize = "Standard_D1_V2",

$adminName = "demoadmin",
$adminPassword = ".KennW0rt123",

$subnetName = "main",
$customScriptFiles = "startup-configure-sql.ps1",
$customScriptRun = "startup-configure-sql.ps1",
    
$adDomain = "demoenv.local", 
$domainNetBiosName = "demoenv",
$privateIpAddress = "192.168.0.4"

#>

#endregion
    

# select to Azure subscription
Write-Output "Select Azure subscription '$subscriptionId' with tenant '$tenantId'"
Select-AzureRmSubscription -TenantId $tenantId -SubscriptionId $subscriptionId

# get location from resource group
$location = (Get-AzureRmResourceGroup -Name $targetResourceGroupName).Location
Write-Output "Location of resource group '$targetResourceGroupName': $location"

# get vnet name
$vNetName = (Get-AzureRmVirtualNetwork -ResourceGroupName $targetResourceGroupName)[0].Name
Write-Output "VNet of resource group '$targetResourceGroupName': $vNetName"

# get storage account from resource group
$targetStorageAccount = (Get-AzureRmStorageAccount -ResourceGroupName $targetResourceGroupName)[0]
If ( -not $targetStorageAccount )
{
    Write-Error "No storage account in ressource group '$targetResourceGroupName' found!"
    exit
}
Write-Output "Storage account of resource group '$targetResourceGroupName': $($targetStorageAccount.Name)"

# get storage account key and create new container
$targetStorageAccountKey = (Get-AzureRmStorageAccountKey -StorageAccountName $targetStorageAccount.StorageAccountName -ResourceGroupName $targetResourceGroupName).value[0]
$targetStorageContext = New-AzureStorageContext –StorageAccountName $targetStorageAccount.StorageAccountName –StorageAccountKey $targetStorageAccountKey
$storageContainer = Get-AzureStorageContainer -Context $targetStorageContext
if ( -not ( $storageContainer.Name -contains $vmName ))
{
    $storageContainer = New-AzureStorageContainer -Name $vmName -Context $targetStorageContext
    Write-Output "Created new container '$($storageContainer.Name)' in storage account '$($targetStorageContext.StorageAccountName)'"
}

Write-Output "Start VM preparation: $((Get-Date).DateTime)"

# get vnet and subnet
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $targetResourceGroupName -Name $vNetName
$subnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name $subnetName

# create credentials for local admin of DC
$credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminName, $(ConvertTo-SecureString –String $adminPassword –AsPlainText -Force)

# compute OS disk name and OS disk uri
$date = Get-Date -UFormat "%y%m%d%H%M%S"
$osDiskName = $vmNameDC + "-" + $date + "-OS"
$osDiskUri = $targetStorageAccount.PrimaryEndpoints.Blob.ToString() + $vmName + "/" + $osDiskName + ".vhd"
###$osDiskUri = "$targetStorageAccount.PrimaryEndpoints.Blob.ToString()$vmName/$osDiskName.vhd"

# create network interface
if ($privateIpAddress) {
    $nic = New-AzureRmNetworkInterface -Name $($vmName + "-NIC1") -ResourceGroupName $targetResourceGroupName -Location $location -SubnetId $subnetConfig.Id -Force -PrivateIpAddress $privateIpAddress
} else {
    $nic = New-AzureRmNetworkInterface -Name $($vmName + "-NIC1") -ResourceGroupName $targetResourceGroupName -Location $location -SubnetId $subnetConfig.Id -Force
}
Write-Output "Created NIC: $($nic.Name)"

# create network security group for network interface
$networkSecurityGroup = New-AzureRmNetworkSecurityGroup -ResourceGroupName $targetResourceGroupName -Location $location -Name "NSG-$vmName" -force

Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSecurityGroup -Name INET-RDP-IN -Access Allow -Protocol * -Direction Inbound -Priority 100 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 3389
Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSecurityGroup -Name All-Internal -Access Allow -Protocol * -Direction Inbound -Priority 110 -SourceAddressPrefix 192.168.0.0/16 -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange *
Add-AzureRmNetworkSecurityRuleConfig -NetworkSecurityGroup $networkSecurityGroup -Name INET-HTTPS-IN -Access Allow -Protocol Tcp -Direction Inbound -Priority 120 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 443
Set-AzureRmNetworkSecurityGroup -NetworkSecurityGroup $networkSecurityGroup
$nic.NetworkSecurityGroup = $networkSecurityGroup

# create public IP address
$publicIpAddress = New-AzureRmPublicIpAddress -Name "PIP-$vmName" -ResourceGroupName $targetResourceGroupName -Location $location -AllocationMethod Static -Force
$nic.IpConfigurations[0].PublicIpAddress = $publicIpAddress

# save network security group and public IP address to NIC
Set-AzureRmNetworkInterface -NetworkInterface $nic
Write-Output "Created public IP address: $($publicIpAddress.IpAddress)"

# create VM configuration
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmSize 
Set-AzureRmVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName -Credential $credential -ProvisionVMAgent -EnableAutoUpdate
Set-AzureRmVMSourceImage -VM $vmConfig -PublisherName "MicrosoftWindowsServer" -Offer "WindowsServer" -Skus "2012-R2-Datacenter" -Version "latest"
Add-AzureRmVMNetworkInterface -VM $vmConfig -NetworkInterface $nic

# create OS and data disks
Set-AzureRmVMOSDisk -VM $vmConfig -Name $osDiskName -VhdUri $osDiskUri -CreateOption FromImage
$diskUri = $targetStorageAccount.PrimaryEndpoints.Blob.ToString() + $vmName + "/" + $osDiskName + "-1.vhd"
Add-AzureRmVMDataDisk -VM $vmConfig -Name $($osDiskName + "-1") -VhdUri $diskUri -CreateOption Empty -Caching ReadOnly -DiskSizeInGB 1023 -Lun 0

Write-Output "Create VM: $((Get-Date).DateTime)"

New-AzureRmVM -Location $location -ResourceGroupName $targetResourceGroupName -VM $vmConfig

Write-Output "Created VM: $((Get-Date).DateTime)"

Write-Output "Start custom script: $((Get-Date).DateTime)"

# inject custom script
$sourceStorageAccountKeys = (Get-AzureRmStorageAccountKey -StorageAccountName $sourceStorageAccountName -ResourceGroupName $sourceResourceGroupName)

Set-AzureRmVMCustomScriptExtension `
    -ContainerName $vmName `
    -FileName $customScriptFiles `
    -Run $customScriptRun `
    -ResourceGroupName $targetResourceGroupName `
    -VMName $vmName `
    -Location $location `
    -Name "StartupScript" `
    -StorageAccountKey $sourceStorageAccountKeys[0].Value `
    -StorageAccountName $sourceStorageAccountName `
    -SecureExecution `
    -Argument $customScriptArgument

Write-Output "Finished custom script: $((Get-Date).DateTime)"

Write-Output "VM '$vmName' created."