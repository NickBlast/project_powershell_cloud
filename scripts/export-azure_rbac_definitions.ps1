<#!
.SYNOPSIS
    Export Azure role definitions for the test subscription.
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
$datasetName = 'azure_role_definitions'

Write-StructuredLog -Level Info -Message 'Starting Azure role definition export.'
$context = Connect-EntraTestTenant -ConnectAzure

$definitions = Get-AzRoleDefinition
Write-StructuredLog -Level Info -Message "Captured $($definitions.Count) role definitions" -Context @{ dataset_name = $datasetName }
Write-Export -DatasetName $datasetName -Objects $definitions -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
