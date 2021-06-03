Invoke-AzResourceAction -ResourceName ${imageTemplateName} -ResourceGroupName ${rgname} -ResourceType Microsoft.VirtualMachineImages/imageTemplates -ApiVersion "2020-02-14" -Action Run -Force

$Timeout = 3600
$timer = [Diagnostics.Stopwatch]::StartNew()
$Result = Get-AzImageBuilderTemplate -ResourceGroupName BICEP-WVD-SIG -Name WVDBicep20210603T101135Z | select LastRunStatusRunState
Write-Host $Result

while (($timer.Elapsed.TotalSeconds -lt $Timeout) -and ($Result -match 'Running')) 
{
    Start-Sleep -Seconds 1
    Write-Host -Message 'Still waiting for action to complete after',($timer.Elapsed.TotalSeconds)
}

if ($Result -match 'Failed') {
    Write-Host 'Job failed after' ($timer.Elapsed.TotalSeconds)
}

if ($Result -match 'Succeded') {
    Write-Host 'Job completed after' ($timer.Elapsed.TotalSeconds)
}

$timer.Stop()
