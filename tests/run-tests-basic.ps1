<#
.SYNOPSIS
    Minimal test entrypoint for project_powershell_cloud.
.DESCRIPTION
    Ensures prerequisites, runs Script Analyzer, and executes live smoke exports against the test tenant.
.PARAMETER SkipSmoke
    Skip the live export smoke tests (useful for offline validation).
.EXAMPLE
    pwsh -NoProfile -File ./tests/run-tests-basic.ps1
.EXAMPLE
    pwsh -NoProfile -File ./tests/run-tests-basic.ps1 -SkipSmoke
#>
[CmdletBinding()]
param(
    [switch]$SkipSmoke
)

$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$modulePath = Join-Path -Path $repoRoot -ChildPath 'modules'
$scriptPath = Join-Path -Path $repoRoot -ChildPath 'scripts'

Write-Host "[1/3] Ensuring prerequisites..."
& (Join-Path -Path $scriptPath -ChildPath 'ensure-prereqs.ps1') -Quiet

Write-Host "[2/3] Running PSScriptAnalyzer on modules/ and scripts/" -ForegroundColor Cyan
$analysisResults = Invoke-ScriptAnalyzer -Path @(
    (Join-Path -Path $modulePath -ChildPath '.'),
    $scriptPath
) -Recurse

if ($analysisResults) {
    $analysisResults | Group-Object Severity | ForEach-Object {
        Write-Host "  $($_.Count) findings with severity $($_.Name)" -ForegroundColor Yellow
    }
}
else {
    Write-Host "  No ScriptAnalyzer findings." -ForegroundColor Green
}

$analysisFailed = $analysisResults | Where-Object { $_.Severity -eq 'Error' }

$smokeResults = @()
if (-not $SkipSmoke) {
    Write-Host "[3/3] Running live smoke exports" -ForegroundColor Cyan
    Import-Module (Join-Path -Path $modulePath -ChildPath 'logging/Logging.psm1')
    Import-Module (Join-Path -Path $modulePath -ChildPath 'entra_connection/entra_connection.psm1')

    try {
        $context = Connect-EntraTestTenant
    }
    catch {
        Write-Host "Failed to connect to test tenant: $($_.Exception.Message)" -ForegroundColor Red
        exit 1
    }

    $smokeTargets = @(
        @{ Name = 'entra_groups_cloud_only'; Path = Join-Path -Path $scriptPath -ChildPath 'export-entra_groups_cloud_only.ps1'; Output = Join-Path -Path $repoRoot -ChildPath 'outputs/entra/entra_groups_cloud_only.csv' },
        @{ Name = 'entra_group_memberships'; Path = Join-Path -Path $scriptPath -ChildPath 'export-entra_group_memberships.ps1'; Output = Join-Path -Path $repoRoot -ChildPath 'outputs/entra/entra_group_memberships.csv' },
        @{ Name = 'entra_role_assignments'; Path = Join-Path -Path $scriptPath -ChildPath 'export-entra_role_assignments.ps1'; Output = Join-Path -Path $repoRoot -ChildPath 'outputs/entra/entra_role_assignments.csv' },
        @{ Name = 'azure_rbac_assignments'; Path = Join-Path -Path $scriptPath -ChildPath 'export-azure_rbac_assignments.ps1'; Output = Join-Path -Path $repoRoot -ChildPath 'outputs/azure/azure_rbac_assignments.csv' }
    )

    foreach ($target in $smokeTargets) {
        $start = Get-Date
        Write-ExportLogStart -Name $target.Name -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId
        $status = 'Success'
        $message = ''
        $rows = 0

        try {
            pwsh -NoProfile -File $target.Path -ErrorAction Stop | Out-Null
            if (Test-Path -Path $target.Output) {
                $rows = (Import-Csv -Path $target.Output).Count
            } else {
                $status = 'Failed'
                $message = 'Output file missing'
            }
        }
        catch {
            $status = 'Failed'
            $message = $_.Exception.Message
        }

        $smokeResults += [pscustomobject]@{
            Script      = $target.Name
            Status      = $status
            OutputPath  = $target.Output
            RowCount    = $rows
            Message     = $message
            DurationSec = [math]::Round(((Get-Date) - $start).TotalSeconds,2)
        }

        $successFlag = $status -eq 'Success'
        Write-ExportLogResult -Name $target.Name -Success $successFlag -OutputPath $target.Output -RowCount $rows -Message $message
    }
}
else {
    Write-Host "[3/3] Live smoke exports skipped." -ForegroundColor Yellow
}

if ($smokeResults.Count -gt 0) {
    Write-Host "\nSmoke test summary:" -ForegroundColor Cyan
    $smokeResults | Format-Table -AutoSize
}

if ($analysisFailed -or ($smokeResults | Where-Object { $_.Status -ne 'Success' }).Count -gt 0) {
    exit 1
}
