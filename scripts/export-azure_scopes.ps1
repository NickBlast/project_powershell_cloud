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

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

function Invoke-ScriptMain {
    param(
        [string]$OutputPath,
        [pscustomobject]$RunContext
    )
    # Abort on any error to avoid partial exports.
    $ErrorActionPreference = 'Stop'

    # Dataset metadata is stamped onto every file for audit tracking.
    $toolVersion = '0.3.0'
    $datasetName = 'azure_subscriptions'
    $logDatasetName = 'azure_scopes'

    if ($RunContext) {
        Write-RunLog -RunContext $RunContext -Level 'Info' -Message 'Starting Azure scopes export' -Metadata @{
            dataset_name = $logDatasetName
            output_path  = $OutputPath
            tool_version = $toolVersion
        }
    }

    # Connect to the known test tenant and log the start of the export.
    $context = Connect-EntraTestTenant -ConnectAzure

    if ($RunContext) {
        $RunContext.TenantId = $context.TenantId
        Write-RunLog -RunContext $RunContext -Level 'Info' -Message 'Connected to test tenant' -Metadata @{
            tenant_id       = $context.TenantId
            subscription_id = $context.SubscriptionId
        }
    }

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

    if ($RunContext) {
        Write-RunLog -RunContext $RunContext -Level 'Info' -Message "Captured $($records.Count) subscriptions" -Metadata @{
            dataset_name = $datasetName
            record_count = $records.Count
        }
    }

    # Persist the normalized dataset in CSV and JSON formats.
    Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion

    return [pscustomobject]@{
        SubscriptionCount = $records.Count
        OutputPath        = $OutputPath
        TenantId          = $context.TenantId
    }
}
$runContext = Start-RunLog -ScriptName $scriptName -DatasetName 'azure_scopes' -ToolVersion '0.3.0'

try {
    $runSummary = Invoke-ScriptMain -OutputPath $OutputPath -RunContext $runContext
    if ($runSummary.TenantId) { $runContext.TenantId = $runSummary.TenantId }

    Complete-RunLog -RunContext $runContext -Status 'Success' -Summary @{
        subscription_count = $runSummary.SubscriptionCount
        output_path        = $runSummary.OutputPath
        tenant_id          = $runSummary.TenantId
    }

    Write-Output "Azure scopes export completed. See $($runContext.RelativeLogPath) for details."
    exit 0
}
catch {
    $errorMessage = $_.Exception.Message
    Write-RunLog -RunContext $runContext -Level 'Error' -Message "Azure scopes export failed: $errorMessage"
    Complete-RunLog -RunContext $runContext -Status 'Failed'

    Write-Output "Errors detected. See $($runContext.RelativeLogPath) for details."
    exit 1
}
