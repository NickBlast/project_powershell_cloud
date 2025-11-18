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

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force

$scriptName = Split-Path -Path $PSCommandPath -Leaf

$scriptBlock = {
    Set-StrictMode -Version 3.0
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
}

Invoke-WithRunLog -ScriptName $scriptName -ScriptBlock $scriptBlock
