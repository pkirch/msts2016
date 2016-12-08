####################################################
### Workshop Public Cloud @ Technical Summit 2016
### Deployment via ARM PowerShell
### by Peter Kirchner (peter.kirchner@microsoft.com)
####################################################

# prerequisites
# AzCopy has to be installed

Import-Module Azure

# add azure account if not already done
# Add-AzureRmAccount

# note your subscription and tenant ID here

# SubscriptionId                       SubscriptionName    State   TenantId                             CurrentStorageAccountName
# --------------                       ----------------    -----   --------                             -------------------------
# 26a630d2-1458-481b-8c8b-e38998425e92 MSFT IT Camp Stage  Enabled 72f988bf-86f1-41af-91ab-2d7cd011db47                          

# select Azure subscription
Set-AzureRmContext -TenantId "72f988bf-86f1-41af-91ab-2d7cd011db47" -SubscriptionName "MSFT IT Camp Stage"

# settings
$customerName = "customer02"    # alternative: using read-host
$resourceGroupName = "demo-env-$customerName"
$location = "westeurope"
$networkName = $customerName
$sourceResourceGroup = "demoenvsrc"
$sourceStorageAccount = "customscripts2893"

# create a new Azure ressource group
New-AzureRmResourceGroup -Name $resourceGroupName -Location $location

# create a new Azure storage account
do{
    $storageAccountName = Read-Host "Enter Storage Account Name for demo environment. E.g. demoenv1612zhfr."

    # Only lower case storage account name allowed.
    $storageAccountName = $storageAccountName.ToLower()

    # Check availability of storage account name.
    $testName = Get-AzureRmStorageAccountNameAvailability -Name $storageAccountName 

    if ($testName.NameAvailable) {
        # now really create new Azure storage account
        New-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName -Location $location -SkuName "Standard_LRS"

        # print success message
        Write-Output "Azure storage account '$storageAccountName' created"       
    }
    else {
        # print error message
        Write-Output $testName.Message
    }
}while (!$testName.NameAvailable)

# create Azure file share in newly created storage account
$storageKey = Get-AzureRmStorageAccountKey -ResourceGroupName $resourceGroupName -Name $storageAccountName
$storageContext = New-AzureStorageContext -StorageAccountName $storageAccountName -StorageAccountKey $storageKey[0].Value

$shareName = "install"
$shareName = $shareName.ToLower()
New-AzureStorageShare -Name $shareName -Context $storageContext

# ------------------------------------------------------------------------
# copy files from source share to the new storage account Azure file share

$sourceStorageAccount1 = Get-AzureRmStorageAccount -ResourceGroupName "demoenvsrc" -Name "customscripts2893"
$targetStorageAccount = Get-AzureRmStorageAccount -ResourceGroupName $resourceGroupName -Name $storageAccountName

$sourceShare = Get-AzureStorageShare -Context $sourceStorageAccount1.Context 
$targetShare = Get-AzureStorageShare -Context $targetStorageAccount.Context 

$sourceKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $sourceStorageAccount1.ResourceGroupName -Name $sourceStorageAccount1.StorageAccountName
$targetKeys = Get-AzureRmStorageAccountKey -ResourceGroupName $targetStorageAccount.ResourceGroupName -Name $targetStorageAccount.StorageAccountName

Write-Output "AzCopy job started: $((Get-Date).DateTime)"

&'C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe' /Source:$($sourceShare.StorageUri.PrimaryUri.AbsoluteUri) /Dest:$($targetShare.StorageUri.PrimaryUri.AbsoluteUri) /SourceKey:$($sourceKeys[0].Value) /DestKey:$($targetKeys[0].Value) /S

Write-Output "AzCopy Job completed: $((Get-Date).DateTime)"

    
#-------------------------------------------------
# create network
Write-Output "Create virtual network: $networkName"

$ipAddressRange = "192.168.0.0/16"
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $networkName -Location $location -AddressPrefix $ipAddressRange

###$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName -Name $networkName


# Add subnet to Azure Virtual Network
$subnetName = "main"
$ipAdressRangeSubnet = "192.168.0.0/24"
Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix $ipAdressRangeSubnet

$subnetName = "dmz"
$ipAdressRangeSubnet = "192.168.1.0/24"
Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix $ipAdressRangeSubnet

$subnetName = "clients"
$ipAdressRangeSubnet = "192.168.2.0/24"
Add-AzureRmVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $vnet -AddressPrefix $ipAdressRangeSubnet 

# Sample to remove a subnet 
# Remove-AzureRmVirtualNetworkSubnetConfig -Name "subnet1" -VirtualNetwork $vnet 

Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

Write-Output "Created virtual network: $networkName"

# --------------------------
# create availaibility set for all VMs
#New-AzureRmAvailabilitySet -ResourceGroupName $resourceGroupName -Location $location -Name "demoenvAS"

Write-Output "Infrastructure setup done. Create VMs."

# create DC
#.\02-create-dc.ps1 -resourceGroup $resourceGroupName

.\02-create-vm.ps1 -subscriptionId = "26a630d2-1458-481b-8c8b-e38998425e92" `
                   -tenantId = "72f988bf-86f1-41af-91ab-2d7cd011db47" `
                   -targetResourceGroupName = "demo-env-customer02" `
                   -sourceResourceGroupName = "demoenvsrc" `
                   -sourceStorageAccountName = "customscripts2893" `
                   -vmName = "demodc" `
                   -vmSize = "Standard_D1_V2" `
                   -adminName = "demoadmin" `
                   -adminPassword = ".KennW0rt123" `
                   -subnetName = "main" `
                   -customScriptFiles = @("startup-configure-dc.ps1", "diskpart-dc.txt") `
                   -customScriptRun = "startup-configure-dc.ps1" `
                   -customScriptArgument = "-adminPassword .KennW0rt123 -domainName demoenv.local -domainNetbiosName demoenv" `
                   -privateIpAddress = "192.168.0.4"

# dc dns server is now available... set azure virtual network with custom dns server
$vnet = @(Get-AzureRmVirtualNetwork -ResourceGroupName $resourceGroupName)[0]
$vnet.DhcpOptions.DnsServers.Add("192.168.0.4")
Set-AzureRmVirtualNetwork -VirtualNetwork $vnet

# create SQL
#.\02-create-vm.ps1 ...

# TODO: create script to summerize results by listing all relevant ressources created