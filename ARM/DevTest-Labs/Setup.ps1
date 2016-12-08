cd $PSScriptRoot

Do{
    clear
    Write-Host "#Azure DevTest Labs & Blockchain as a Service Setup Script#" -ForegroundColor Green
    Write-Host "Options:" -ForegroundColor Green
    Write-Host "1:  Azure login" -ForegroundColor Green
    Write-Host "2:  Azure DevTest Lab" -ForegroundColor Green
    Write-Host "3:  Azure DevTest Lab VM deployment" -ForegroundColor Green
    Write-Host "E:  Exit." -ForegroundColor Green
    $InputKey=Read-Host
    switch($InputKey.ToUpper()){
        1{
            $null=Login-AzureRmAccount
            $null=Get-AzureRmSubscription|Out-gridview -PassThru|Select-AzureRmSubscription
        }
        2{
            $Deployment=.\DevTestLab.ps1
            $Deployment|Out-File .\Logs\DTL.log
        }
        3{
            $Deployment=.\DevTestLabVM.ps1
            $Deployment|Out-File .\Logs\DTLVM.log
        }
    }
}While ($InputKey.ToUpper() -ne 'E')
clear