<#!
.SYNOPSIS
    Export Azure RBAC assignments for the test subscription.
.DESCRIPTION
    Connects to the preconfigured test tenant, retrieves all role assignments visible to the service
    principal, and writes the dataset to CSV and JSON using the shared export module so metadata
    remains consistent across runs. Logging is routed through the project logger for auditability.
.PARAMETER OutputPath
    Destination directory for the export artifacts. Defaults to outputs/azure under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/azure')
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
    $datasetName = 'azure_role_assignments'

    Write-StructuredLog -Level Info -Message 'Starting Azure RBAC assignment export.'
    $context = Connect-EntraTestTenant -ConnectAzure

    $assignments = Get-AzRoleAssignment
    Write-StructuredLog -Level Info -Message "Captured $($assignments.Count) role assignments" -Context @{ dataset_name = $datasetName }

    Write-Export -DatasetName $datasetName -Objects $assignments -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
}

Invoke-WithRunLog -ScriptName $scriptName -ScriptBlock $scriptBlock
