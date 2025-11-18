<#!
.SYNOPSIS
    Export Entra role assignments for directory roles.
.DESCRIPTION
    Connects to the Entra test tenant, retrieves directory role assignments with retry handling,
    reshapes the results into consistent columns, and emits CSV and JSON outputs via the shared
    export helper so metadata remains consistent while schemas are paused.
.PARAMETER OutputPath
    Destination directory for export artifacts. Defaults to outputs/entra under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force

$scriptName = Split-Path -Path $PSCommandPath -Leaf

$scriptBlock = {
    Set-StrictMode -Version 3.0
    $ErrorActionPreference = 'Stop'

    Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
    Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
    Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

    $toolVersion = '0.3.0'
    $datasetName = 'entra_role_assignments'

    Write-StructuredLog -Level Info -Message 'Starting Entra role assignment export.'
    $context = Connect-EntraTestTenant

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

    Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
}

Invoke-WithRunLog -ScriptName $scriptName -ScriptBlock $scriptBlock
