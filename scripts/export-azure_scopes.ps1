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

function Invoke-ScriptMain {
    param(
        [string]$OutputPath,
        [pscustomobject]$RunContext
    )
    # Abort on any error to avoid partial exports.
    $ErrorActionPreference = 'Stop'

    # Connect to the known test tenant and log the start of the export.
    Write-RunLog -RunContext $RunContext -Level Info -Message 'Starting Azure subscription export.' -Metadata @{ event = 'start_export'; dataset = $datasetName }
    $connectionContext = Connect-EntraTestTenant -ConnectAzure
    $RunContext.TenantId = $connectionContext.TenantId
    $RunContext.TenantLabel = $connectionContext.ClientId
    Write-RunLog -RunContext $RunContext -Level Info -Message "Connected to tenant $($connectionContext.TenantId)." -Metadata @{ event = 'tenant_connection'; subscription_id = $connectionContext.SubscriptionId }

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

    Write-RunLog -RunContext $RunContext -Level Info -Message "Captured $($records.Count) subscriptions." -Metadata @{ event = 'subscription_capture'; count = $records.Count }

    # Persist the normalized dataset in CSV and JSON formats.
    Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
    Write-RunLog -RunContext $RunContext -Level Info -Message 'Export complete.' -Metadata @{ event = 'export_complete'; output_path = $OutputPath }

    return [pscustomobject]@{
        SubscriptionCount = $records.Count
        OutputPath        = $OutputPath
    }
}

$runContext = Start-RunLog -ScriptName $scriptName -DatasetName $datasetName -ToolVersion $toolVersion
$runStatus = 'Success'
$exitCode = 0
$runSummary = $null

try {
    $runSummary = Invoke-ScriptMain -OutputPath $OutputPath -RunContext $runContext
}
catch {
    $runStatus = 'Failed'
    $exitCode = 1
    Write-RunLog -RunContext $runContext -Level Error -Message "Scope export failed: $($_.Exception.Message)" -Metadata @{ event = 'export_error' }
}
finally {
    $summaryPayload = @{ scopes_exported = $null; output_path = $null }
    if ($null -ne $runSummary) {
        $summaryPayload.scopes_exported = $runSummary.SubscriptionCount
        $summaryPayload.output_path = $runSummary.OutputPath
    }
    Complete-RunLog -RunContext $runContext -Status $runStatus -Summary $summaryPayload
}

if ($runStatus -eq 'Success') {
    Write-Output "Azure scope export completed. See $($runContext.RelativeLogPath) for details."
} else {
    Write-Output "Errors detected during Azure scope export. See $($runContext.RelativeLogPath) for details."
}

exit $exitCode
