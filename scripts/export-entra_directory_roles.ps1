<#!
.SYNOPSIS
    Export Entra directory roles.
.DESCRIPTION
    Connects to the test tenant, retrieves all directory roles (including custom roles) with retry
    resiliency, and writes the dataset to CSV and JSON through the shared export pipeline to maintain
    consistent metadata and headers.
.PARAMETER OutputPath
    Destination directory for export artifacts. Defaults to outputs/entra under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

# Stop on any error so exports do not quietly fail.
$ErrorActionPreference = 'Stop'

# Import shared modules for connection orchestration, logging, and export formatting.
Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

# Dataset metadata stamped on every file for auditability.
$toolVersion = '0.3.0'
$datasetName = 'entra_directory_roles'

# Connect to the curated tenant and log the start of the role export.
Write-StructuredLog -Level Info -Message 'Starting Entra directory role export.'
$context = Connect-EntraTestTenant

# Retrieve directory roles with retry/backoff to handle throttling.
$roles = Invoke-WithRetry -ScriptBlock { Get-MgDirectoryRole -All }
Write-StructuredLog -Level Info -Message "Captured $($roles.Count) directory roles" -Context @{ dataset_name = $datasetName }

# Write the dataset to CSV and JSON using the shared export helper.
Write-Export -DatasetName $datasetName -Objects $roles -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
