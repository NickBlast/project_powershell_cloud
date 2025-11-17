<#!
.SYNOPSIS
    Export Azure RBAC assignments for the test subscription.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/azure')
)

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
