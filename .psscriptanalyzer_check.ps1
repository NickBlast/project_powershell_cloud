$m = Invoke-ScriptAnalyzer -Path .\modules -Recurse -Severity Warning,Error
$s = Invoke-ScriptAnalyzer -Path .\scripts -Recurse -Severity Warning,Error
$total = $m.Count + $s.Count
if ($total -eq 0) {
    Write-Host 'No remaining analyzer findings.'
} else {
    $m + $s | Select-Object ScriptName,RuleName,Severity,Message | Format-Table -AutoSize
}
