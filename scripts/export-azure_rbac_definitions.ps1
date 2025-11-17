<#!
.SYNOPSIS
    Export Azure role definitions for the test subscription.
.DESCRIPTION
    Connects to the curated test tenant, enumerates all Azure role definitions (built-in and custom),
    and writes the dataset to CSV and JSON using the shared export module. Standard metadata fields
    (generated_at, tool_version, dataset_version) are emitted to keep runs audit-friendly.
.PARAMETER OutputPath
    Destination directory for export artifacts. Defaults to outputs/azure under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/azure')
)

# Stop on any error so partial exports do not slip through.
$ErrorActionPreference = 'Stop'

# Import shared modules for authentication, logging, and export formatting.
Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

# Dataset metadata used in downstream validation and schema headers.
$toolVersion = '0.3.0'
$datasetName = 'azure_role_definitions'

# Connect to the expected tenant before querying role definitions.
Write-StructuredLog -Level Info -Message 'Starting Azure role definition export.'
$context = Connect-EntraTestTenant -ConnectAzure

# Retrieve role definitions and emit them with consistent metadata.
$definitions = Get-AzRoleDefinition
Write-StructuredLog -Level Info -Message "Captured $($definitions.Count) role definitions" -Context @{ dataset_name = $datasetName }
Write-Export -DatasetName $datasetName -Objects $definitions -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
