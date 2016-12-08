 Login-AzureRmAccount

New-AzureRmResourceGroup -Name ts16cli -Location northeurope -Verbose

New-AzureRmResourceGroupDeployment -Name ts16cli -ResourceGroupName ts16cli -TemplateFile C:\azuredeploy.json -TemplateParameterFile C:\azuredeploy.parameters.json -Verbose 
