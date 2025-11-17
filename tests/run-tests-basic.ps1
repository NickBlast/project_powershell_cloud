[CmdletBinding()]
param(
    [switch]$SkipAnalysis
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')

# Ensure modules are available
& "$repoRoot/scripts/ensure-prereqs.ps1" -Quiet | Out-Null

Import-Module "$repoRoot/modules/entra_connection/entra_connection.psd1" -Force
Import-Module "$repoRoot/modules/logging/logging.psd1" -Force
Import-Module "$repoRoot/modules/export/export.psd1" -Force

$context = Get-EntraTestContext
Write-StructuredLog -Level Info -Message "Running basic tests for tenant $($context.TenantId)" -Context @{ subscription_id = $context.SubscriptionId }

if (-not $SkipAnalysis) {
    Write-StructuredLog -Level Info -Message 'Running PSScriptAnalyzer across modules/ and scripts/'
    $analysisResults = Invoke-ScriptAnalyzer -Path "$repoRoot/modules","$repoRoot/scripts" -Recurse -Severity Warning,Error -ErrorAction SilentlyContinue
    if ($analysisResults) {
        $analysisResults | Format-Table -AutoSize
    } else {
        Write-StructuredLog -Level Info -Message 'ScriptAnalyzer reported no findings.'
    }
}

# Smoke connection
$connection = $null
try {
    $connection = Connect-EntraTestTenant -ConnectAzure
    Write-StructuredLog -Level Info -Message 'Connected to test tenant.' -Context @{ tenant_id = $connection.TenantId; subscription_id = $connection.SubscriptionId }
} catch {
    Write-StructuredLog -Level Error -Message "Failed to connect to test tenant: $($_.Exception.Message)"
    exit 1
}

$smokeTests = @(
    @{ Name='Entra Groups'; Dataset='entra_groups'; Script=Join-Path $repoRoot 'scripts/export-entra_groups_cloud_only.ps1'; Output=Join-Path $repoRoot 'outputs/entra' },
    @{ Name='Group Memberships'; Dataset='entra_group_memberships'; Script=Join-Path $repoRoot 'scripts/export-entra_group_memberships.ps1'; Output=Join-Path $repoRoot 'outputs/entra' },
    @{ Name='Apps & SPs'; Dataset='entra_apps_service_principals'; Script=Join-Path $repoRoot 'scripts/export-entra_apps_service_principals.ps1'; Output=Join-Path $repoRoot 'outputs/entra' },
    @{ Name='Directory Roles'; Dataset='entra_role_assignments'; Script=Join-Path $repoRoot 'scripts/export-entra_role_assignments.ps1'; Output=Join-Path $repoRoot 'outputs/entra' },
    @{ Name='Azure Role Definitions'; Dataset='azure_role_definitions'; Script=Join-Path $repoRoot 'scripts/export-azure_rbac_definitions.ps1'; Output=Join-Path $repoRoot 'outputs/azure' },
    @{ Name='Azure Role Assignments'; Dataset='azure_role_assignments'; Script=Join-Path $repoRoot 'scripts/export-azure_rbac_assignments.ps1'; Output=Join-Path $repoRoot 'outputs/azure' }
)

$results = @()
foreach ($test in $smokeTests) {
    $scriptName = Split-Path -Path $test.Script -Leaf
    Write-ExportLogStart -ScriptName $scriptName -DatasetName $test.Name -OutputPath $test.Output -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId

    $scriptSucceeded = $false
    $rowCount = -1
    $datasetFile = $null
    $message = ''

    try {
        & $test.Script -OutputPath $test.Output -Verbose:$false
        $datasetFile = Join-Path $test.Output "$($test.Dataset).csv"
        if ($datasetFile) {
            $rowCount = (Import-Csv -Path $datasetFile).Count
        }
        $scriptSucceeded = $true
        $message = 'Completed'
    }
    catch {
        $message = $_.Exception.Message
    }

    $outputPathToStore = if ($datasetFile) { $datasetFile } else { $null }
    Write-ExportLogResult -ScriptName $scriptName -DatasetName $test.Name -Succeeded:$scriptSucceeded -OutputPath $outputPathToStore -RowCount $rowCount -Message $message
    $results += [pscustomobject]@{
        Script      = $scriptName
        Status      = if ($scriptSucceeded) { 'Success' } else { 'Fail' }
        Output      = $datasetFile ? $datasetFile.FullName : 'n/a'
        RowCount    = $rowCount
        Message     = $message
    }
}

$results | Format-Table -AutoSize

if ($results.Status -contains 'Fail') { exit 1 } else { exit 0 }
