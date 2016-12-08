azure login  

azure group create -n ts16cli -l northeurope  

azure group deployment create -f C:\azuredeploy.json -e C:\azuredeploy.parameters.json -g ts16cli -n ts16cli
