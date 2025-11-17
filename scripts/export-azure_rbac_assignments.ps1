<#
.SYNOPSIS
    Exports Azure RBAC role assignments for the configured test subscription.
.DESCRIPTION
    Connects using the shared service principal and writes outputs/azure/azure_rbac_assignments.csv.
.PARAMETER OutputPath
    Target directory for export files. Defaults to './outputs/azure'.
.EXAMPLE
    pwsh -NoProfile -File ./scripts/export-azure_rbac_assignments.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/azure')
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = $PSBoundParameters.Verbose.IsPresent ? 'Continue' : 'SilentlyContinue'

Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psm1
Import-Module $PSScriptRoot/../modules/logging/Logging.psm1
Import-Module $PSScriptRoot/../modules/export/Export.psm1

$ToolVersion = '0.3.0'
$DatasetName = 'azure_rbac_assignments'

$context = Connect-EntraTestTenant
Write-ExportLogStart -Name $DatasetName -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId

$assignments = Get-AzRoleAssignment
Write-StructuredLog -Level Info -Message "Found $($assignments.Count) Azure RBAC assignments" -Context @{ correlation_id = (Get-CorrelationId) }

Write-Export -DatasetName $DatasetName -Objects $assignments -OutputPath $OutputPath -Formats 'csv' -ToolVersion $ToolVersion

Write-ExportLogResult -Name $DatasetName -Success $true -OutputPath (Join-Path -Path $OutputPath -ChildPath "$DatasetName.csv") -RowCount $assignments.Count -Message 'Completed'
