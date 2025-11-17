<#!
.SYNOPSIS
    Export Entra directory roles.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

$ErrorActionPreference = 'Stop'

Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

$toolVersion = '0.3.0'
$datasetName = 'entra_directory_roles'

Write-StructuredLog -Level Info -Message 'Starting Entra directory role export.'
$context = Connect-EntraTestTenant

$roles = Invoke-WithRetry -ScriptBlock { Get-MgDirectoryRole -All }
Write-StructuredLog -Level Info -Message "Captured $($roles.Count) directory roles" -Context @{ dataset_name = $datasetName }
Write-Export -DatasetName $datasetName -Objects $roles -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
