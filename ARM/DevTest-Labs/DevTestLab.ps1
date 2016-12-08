cd $PSScriptRoot
clear

$ResourceGroup="TS16Lab"
New-AzureRmResourceGroup -Name $ResourceGroup -Location northeurope -Tag @{"department"="Technical Summit";"environment"="2016"} -Force -Verbose

Write-Host "Creating DevTest Lab configuration:" -ForegroundColor Green

$DeploymentGUID=New-Guid
New-AzureRmResourceGroupDeployment -Name $DeploymentGUID.Guid -ResourceGroupName $ResourceGroup -TemplateFile .\DevTestLab.json -TemplateParameterFile .\DevTestLab.parameters.json -Verbose
pause