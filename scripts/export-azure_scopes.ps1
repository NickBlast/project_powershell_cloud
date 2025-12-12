<#!
.SYNOPSIS
    Export Azure subscription scope details for reference.
.DESCRIPTION
    Connects to the standard test tenant, pulls all subscriptions visible to the service principal,
    normalizes the data into a flat record shape, and writes CSV and JSON artifacts with the shared
    export pipeline so metadata and structure remain consistent while schemas are paused.
.PARAMETER OutputPath
    Destination directory for export artifacts. Defaults to outputs/azure under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/azure')
)

$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)
$toolVersion = '0.3.0'
$datasetName = 'azure_subscriptions'

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

$runContext = Start-RunLog -ScriptName $scriptName -DatasetName $datasetName -ToolVersion $toolVersion

function Invoke-ScriptMain {
    param(
        [string]$OutputPath,
        [pscustomobject]$RunContext
    )
    # Abort on any error to avoid partial exports.
    $ErrorActionPreference = 'Stop'

    # Dataset metadata is stamped onto every file for audit tracking.

    # Connect to the known test tenant and log the start of the export.
    Write-RunLog -RunContext $RunContext -Level Info -Message 'Starting Azure subscription export.'
    $context = Connect-EntraTestTenant -ConnectAzure
    if ($context.TenantId) {
        $RunContext.TenantId = $context.TenantId
    }
    Write-RunLog -RunContext $RunContext -Level Info -Message 'Connected to Entra test tenant' -AdditionalData @{ tenant_id = $context.TenantId; subscription_id = $context.SubscriptionId; graph_connected = $context.GraphConnected; azure_connected = $context.AzureConnected }

    # Fetch subscriptions and reshape to consistent columns for downstream processing.
    $subscriptions = Get-AzSubscription
    $records = foreach ($sub in $subscriptions) {
        [pscustomobject]@{
            subscription_id   = $sub.Id
            subscription_name = $sub.Name
            tenant_id         = $sub.TenantId
            state             = $sub.State
        }
    }

    Write-RunLog -RunContext $RunContext -Level Info -Message "Captured $($records.Count) subscriptions" -AdditionalData @{ subscription_count = $records.Count }

    # Persist the normalized dataset in CSV and JSON formats.
    Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion

    return [pscustomobject]@{
        SubscriptionCount = $records.Count
        OutputPath        = $OutputPath
    }
}

$executionSucceeded = $false
$exportSummary = $null
$failureMessage = $null

try {
    $exportSummary = Invoke-ScriptMain -OutputPath $OutputPath -RunContext $runContext
    $executionSucceeded = $true
}
catch {
    $failureMessage = $_.Exception.Message
    Write-RunLog -RunContext $runContext -Level Error -Message 'Export failed' -AdditionalData @{ error = $failureMessage }
}
finally {
    $completionData = @{}
    if ($exportSummary) {
        $completionData['subscription_count'] = $exportSummary.SubscriptionCount
        $completionData['output_path'] = $exportSummary.OutputPath
    }

    if ($failureMessage) {
        $completionData['error'] = $failureMessage
    }

    Complete-RunLog -RunContext $runContext -Status ($executionSucceeded ? 'Success' : 'Failed') -AdditionalData $completionData
}

if ($executionSucceeded) {
    Write-Output "Azure scope export completed. See $($runContext.RelativeLogPath) for details."
    exit 0
}

Write-Output "Errors detected during export. See $($runContext.RelativeLogPath) for details."
exit 1
