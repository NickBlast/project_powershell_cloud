<#
.SYNOPSIS
    Exports Entra directory roles for the test tenant.
.DESCRIPTION
    Connects using the centralized helpers and writes outputs/entra/entra_directory_roles.csv.
.PARAMETER OutputPath
    Target directory for export files. Defaults to './outputs/entra'.
.EXAMPLE
    pwsh -NoProfile -File ./scripts/export-entra_directory_roles.ps1
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
$DatasetName = 'entra_directory_roles'

$context = Connect-EntraTestTenant -SkipAzure
Write-ExportLogStart -Name $DatasetName -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId

$roles = Invoke-WithRetry -ScriptBlock { Get-MgDirectoryRole -All }
Write-StructuredLog -Level Info -Message "Found $($roles.Count) directory roles" -Context @{ correlation_id = (Get-CorrelationId) }

Write-Export -DatasetName $DatasetName -Objects $roles -OutputPath $OutputPath -Formats 'csv' -ToolVersion $ToolVersion

Write-ExportLogResult -Name $DatasetName -Success $true -OutputPath (Join-Path -Path $OutputPath -ChildPath "$DatasetName.csv") -RowCount $roles.Count -Message 'Completed'
