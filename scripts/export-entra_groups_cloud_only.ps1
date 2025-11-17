<#
.SYNOPSIS
    Exports all cloud-only Entra ID groups.
.DESCRIPTION
    Connects to Microsoft Graph using the test tenant configuration and exports cloud-only groups
    to outputs/entra/entra_groups_cloud_only.csv.
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './outputs/entra'.
.EXAMPLE
    pwsh -NoProfile -File ./scripts/export-entra_groups_cloud_only.ps1
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
$DatasetName = 'entra_groups_cloud_only'

$context = Connect-EntraTestTenant -SkipAzure
Write-ExportLogStart -Name $DatasetName -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId

$filter = "onPremisesSyncEnabled eq null"
Write-StructuredLog -Level Info -Message "Enumerating cloud-only groups with filter '$filter'" -Context @{ correlation_id = (Get-CorrelationId) }

$groups = Invoke-WithRetry -ScriptBlock { Get-MgGroup -Filter $filter -All }
Write-StructuredLog -Level Info -Message "Found $($groups.Count) cloud-only groups" -Context @{ correlation_id = (Get-CorrelationId) }

Write-Export -DatasetName $DatasetName -Objects $groups -OutputPath $OutputPath -Formats 'csv' -ToolVersion $ToolVersion

Write-ExportLogResult -Name $DatasetName -Success $true -OutputPath (Join-Path -Path $OutputPath -ChildPath "$DatasetName.csv") -RowCount $groups.Count -Message 'Completed'
