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
    Write-RunLog -Context $RunContext -Level Info -Message 'Starting Azure subscription export.'
    $context = Connect-EntraTestTenant -ConnectAzure
    Write-RunLog -Context $RunContext -Level Info -Message 'Connected to test tenant.' -Metadata @{ tenant_id = $context.TenantId; subscription_id = $context.SubscriptionId }

    # Fetch subscriptions and reshape to consistent columns for downstream processing.
    $subscriptions = Get-AzSubscription
    Write-RunLog -Context $RunContext -Level Info -Message 'Retrieved subscriptions from Azure.' -Metadata @{ subscription_count = $subscriptions.Count }
    $records = foreach ($sub in $subscriptions) {
        [pscustomobject]@{
            subscription_id   = $sub.Id
            subscription_name = $sub.Name
            tenant_id         = $sub.TenantId
            state             = $sub.State
        }
    }

    Write-RunLog -Context $RunContext -Level Info -Message "Captured $($records.Count) subscriptions" -Metadata @{ dataset_name = $datasetName; subscription_count = $records.Count }

    # Persist the normalized dataset in CSV and JSON formats.
    Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion

    Write-RunLog -Context $RunContext -Level Info -Message 'Azure scopes export completed.' -Metadata @{ subscriptions_exported = $records.Count; output_path = $OutputPath }

    return [pscustomobject]@{
        SubscriptionCount = $records.Count
        OutputPath        = $OutputPath
    }
}

$succeeded = $false
$scriptSummary = $null
try {
    $scriptSummary = Invoke-ScriptMain -OutputPath $OutputPath -RunContext $runContext
    $succeeded = $true
}
catch {
    Write-RunLog -Context $runContext -Level Error -Message "Export failed: $($_.Exception.Message)" -Metadata @{ error = $_.Exception.GetType().Name }
    Write-Error $_
}
finally {
    Complete-RunLog -Context $runContext -Succeeded:$succeeded -Summary @{
        subscriptions_exported = if ($scriptSummary) { $scriptSummary.SubscriptionCount } else { $null }
        output_path            = $OutputPath
    } | Out-Null
}

if ($succeeded) {
    Write-Output "Azure scopes export completed. See $($runContext.RelativeLogPath) for details."
    exit 0
} else {
    Write-Output "Errors detected. Check $($runContext.RelativeLogPath) for details."
    exit 1
}
