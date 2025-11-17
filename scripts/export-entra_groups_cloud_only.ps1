<#!
.SYNOPSIS
    Export Entra cloud-only groups to outputs/entra.
.DESCRIPTION
    Connects to the configured test tenant using service principal credentials from ENTRA_TEST_* variables
    and writes a CSV and JSON snapshot of cloud-only groups with standard metadata headers.
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
$datasetName = 'entra_groups'

Write-StructuredLog -Level Info -Message 'Starting Entra cloud-only groups export.'
$context = Connect-EntraTestTenant

$groups = Invoke-WithRetry -ScriptBlock { Get-MgGroup -Filter "onPremisesSyncEnabled eq null" -All }
Write-StructuredLog -Level Info -Message "Found $($groups.Count) cloud-only groups" -Context @{ dataset_name = $datasetName }

Write-Export -DatasetName $datasetName -Objects $groups -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
