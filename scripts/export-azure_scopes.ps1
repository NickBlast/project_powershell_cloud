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

# Abort on any error to avoid partial exports.
$ErrorActionPreference = 'Stop'

# Pull in shared modules for connectivity, logging, and export formatting.
Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

# Dataset metadata is stamped onto every file for audit tracking.
$toolVersion = '0.3.0'
$datasetName = 'azure_subscriptions'

# Connect to the known test tenant and log the start of the export.
Write-StructuredLog -Level Info -Message 'Starting Azure subscription export.'
$context = Connect-EntraTestTenant -ConnectAzure

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

Write-StructuredLog -Level Info -Message "Captured $($records.Count) subscriptions" -Context @{ dataset_name = $datasetName }

# Persist the normalized dataset in CSV and JSON formats.
Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
