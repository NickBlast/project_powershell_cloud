<#!
.SYNOPSIS
    Export Entra cloud-only groups to outputs/entra.
.DESCRIPTION
    Connects to the configured test tenant using service principal credentials from ENTRA_TEST_* variables,
    filters for cloud-only groups (onPremisesSyncEnabled is null), and writes CSV and JSON snapshots using
    the shared export helper so metadata fields stay consistent.
.PARAMETER OutputPath
    Destination directory for export artifacts. Defaults to outputs/entra under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

# Fail fast on any error to avoid silent data gaps.
$ErrorActionPreference = 'Stop'

# Import shared modules for connection handling, structured logging, and deterministic exports.
Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

# Dataset metadata used by downstream schema validation.
$toolVersion = '0.3.0'
$datasetName = 'entra_groups'

# Connect to the known tenant and log the start of the export pipeline.
Write-StructuredLog -Level Info -Message 'Starting Entra cloud-only groups export.'
$context = Connect-EntraTestTenant

# Query only cloud-only groups (no on-prem sync) and log the count for auditing.
$groups = Invoke-WithRetry -ScriptBlock { Get-MgGroup -Filter "onPremisesSyncEnabled eq null" -All }
Write-StructuredLog -Level Info -Message "Found $($groups.Count) cloud-only groups" -Context @{ dataset_name = $datasetName }

# Persist the dataset in CSV and JSON with standard headers.
Write-Export -DatasetName $datasetName -Objects $groups -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
