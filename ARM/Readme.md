#Azure ARM Template Deployment via CLI:  

azure login  

azure group create -n ts16cli -l northeurope  

azure group deployment create -f C:\azuredeploy.json -e C:\azuredeploy.parameters.json -g ts16cli -n ts16cli


#Azure ARM Template Deployment via PowerShell:  

Login-AzureRmAccount  

New-AzureRmResourceGroup -Name ts16cli -Location northeurope -Verbose

New-AzureRmResourceGroupDeployment -Name ts16cli -ResourceGroupName ts16cli -TemplateFile C:\azuredeploy.json -TemplateParameterFile C:\azuredeploy.parameters.json -Verbose 
