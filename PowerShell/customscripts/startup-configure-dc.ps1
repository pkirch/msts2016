param($adminPassword, $domainName, $domainNetbiosName)

#############################
# Create and format data disk
diskpart /s ./diskpart-dc.txt

##########################################
# Install and configure AD domain services



Add-WindowsFeature AD-Domain-Services, RSAT-AD-AdminCenter, RSAT-ADDS-Tools

# Save secure string with password.
$securePassword = ConvertTo-SecureString -String $adminPassword -AsPlainText -Force

#
# Windows PowerShell script for AD DS Deployment
#

Import-Module ADDSDeployment

Install-ADDSForest `
-CreateDnsDelegation:$false `
-DatabasePath "F:\NTDS" `
-DomainMode "Win2012R2" `
-DomainName $domainName `
-DomainNetbiosName $domainNetbiosName `
-ForestMode "Win2012R2" `
-InstallDns:$true `
-LogPath "F:\NTDS" `
-NoRebootOnCompletion:$false `
-SysvolPath "F:\SYSVOL" `
-Force:$true `
-SafeModeAdministratorPassword:$securePassword

