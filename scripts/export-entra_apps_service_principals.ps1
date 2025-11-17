<#
.SYNOPSIS
    Exports Entra applications, service principals, and OAuth2 permission grants for the test tenant.
.DESCRIPTION
    Uses the centralized connection helpers to connect with the configured test app and writes
    three CSV datasets under outputs/entra/.
.PARAMETER OutputPath
    Directory for export files. Defaults to './outputs/entra'.
.EXAMPLE
    pwsh -NoProfile -File ./scripts/export-entra_apps_service_principals.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = $PSBoundParameters.Verbose.IsPresent ? 'Continue' : 'SilentlyContinue'

Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psm1
Import-Module $PSScriptRoot/../modules/logging/Logging.psm1
Import-Module $PSScriptRoot/../modules/export/Export.psm1

$ToolVersion = '0.3.0'
$datasets = @(
    @{ Name = 'entra_apps'; Command = { Get-MgApplication -All } },
    @{ Name = 'entra_service_principals'; Command = { Get-MgServicePrincipal -All } },
    @{ Name = 'entra_consents'; Command = { Get-MgOauth2PermissionGrant -All } }
)

$context = Connect-EntraTestTenant -SkipAzure

foreach ($dataset in $datasets) {
    $datasetName = $dataset.Name
    Write-ExportLogStart -Name $datasetName -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId
    $objects = Invoke-WithRetry -ScriptBlock $dataset.Command
    Write-StructuredLog -Level Info -Message "Found $($objects.Count) objects for $datasetName" -Context @{ correlation_id = (Get-CorrelationId) }
    Write-Export -DatasetName $datasetName -Objects $objects -OutputPath $OutputPath -Formats 'csv' -ToolVersion $ToolVersion
    Write-ExportLogResult -Name $datasetName -Success $true -OutputPath (Join-Path -Path $OutputPath -ChildPath "$datasetName.csv") -RowCount $objects.Count -Message 'Completed'
}
