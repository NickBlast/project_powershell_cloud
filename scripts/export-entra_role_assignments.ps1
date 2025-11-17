<#!
.SYNOPSIS
    Export Entra role assignments for directory roles.
.DESCRIPTION
    Connects to the Entra test tenant, retrieves directory role assignments with retry handling,
    reshapes the results to the expected schema columns, and emits CSV and JSON outputs via the shared
    export helper so metadata remains consistent.
.PARAMETER OutputPath
    Destination directory for export artifacts. Defaults to outputs/entra under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

# Stop on any error to prevent partial exports.
$ErrorActionPreference = 'Stop'

# Import shared modules for tenant connection, logging, and export formatting.
Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

# Dataset metadata added to every output file.
$toolVersion = '0.3.0'
$datasetName = 'entra_role_assignments'

# Connect to the curated tenant and log the start of the export.
Write-StructuredLog -Level Info -Message 'Starting Entra role assignment export.'
$context = Connect-EntraTestTenant

# Retrieve role assignments with retry/backoff, then flatten into the expected columns.
$assignments = Invoke-WithRetry -ScriptBlock { Get-MgRoleManagementDirectoryRoleAssignment -All }
$records = @()
foreach ($assignment in $assignments) {
    $records += [pscustomobject]@{
        role_definition_id = $assignment.RoleDefinitionId
        principal_id       = $assignment.PrincipalId
        directory_scope_id = $assignment.DirectoryScopeId
        resource_scope     = $assignment.Scope
    }
}

Write-StructuredLog -Level Info -Message "Captured $($records.Count) role assignments" -Context @{ dataset_name = $datasetName }

# Persist the flattened dataset in CSV and JSON with standard metadata headers.
Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
