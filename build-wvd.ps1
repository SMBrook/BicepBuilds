$Timeout = 60
$timer = [Diagnostics.Stopwatch]::StartNew()
$Result = Get-AzImageBuilderTemplate -ResourceGroupName BICEP-WVD-SIG -Name WVDBicep20210602T160046Z | select LastRunStatusRunState
Write-Host $Result
$Result -match "Failed"
$ResultTF = $Result -match 'Failed'

while (($timer.Elapsed.TotalSeconds -lt $Timeout) -or (-not ($ResultTF -eq 'False'))) 
{
    Start-Sleep -Seconds 1
    Write-Host -Message 'Still waiting for action to complete after',($timer.Elapsed.TotalSeconds)
}
$timer.Stop()
