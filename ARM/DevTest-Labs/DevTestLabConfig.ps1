$ResourceGroup="TS16Lab"
$LabName="TS16Lab"

Set-AzureRmDtlAllowedVMSizesPolicy -ResourceGroupName $ResourceGroup -LabName $LabName -VmSizes "Standard_F1","Standard_A2_v2","Standard_A1_v2","Standard_D1_v2" -Enable -Verbose

Set-AzureRmDtlVMsPerLabPolicy -ResourceGroupName $ResourceGroup -LabName $LabName -MaxVMs 100 -Enable -Verbose

Set-AzureRmDtlVMsPerUserPolicy -ResourceGroupName $ResourceGroup -LabName $LabName -MaxVMs 10 -Enable -Verbose