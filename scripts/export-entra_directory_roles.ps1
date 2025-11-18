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

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force

$scriptName = Split-Path -Path $PSCommandPath -Leaf

$scriptBlock = {
    Set-StrictMode -Version 3.0
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
}

Invoke-WithRunLog -ScriptName $scriptName -ScriptBlock $scriptBlock
