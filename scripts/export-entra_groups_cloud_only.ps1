<#
.SYNOPSIS
    Exports all cloud-only Entra ID groups.
.DESCRIPTION
    This script connects to Microsoft Graph and retrieves a list of all groups that are not synchronized
    from an on-premises Active Directory.
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './exports'.
.EXAMPLE
    PS> ./scripts/export-entra_groups_cloud_only.ps1 -OutputPath .\my-entra-data
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'exports')
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = $PSBoundParameters.Verbose.IsPresent ? 'Continue' : 'SilentlyContinue'

# Import shared modules
Import-Module $PSScriptRoot/../modules/connect/Connect.psm1
Import-Module $PSScriptRoot/../modules/logging/Logging.psm1
Import-Module $PSScriptRoot/../modules/export/Export.psm1

# --- Script Configuration ---
$ToolVersion = "1.0.0"
$DatasetName = "entra_groups_cloud_only"
# --------------------------

Write-Verbose "Starting Entra cloud-only groups export..."

# Connect to Graph
$tenant = Select-Tenant
Connect-GraphContext -TenantId $tenant.tenant_id -AuthMode $tenant.preferred_auth
Write-Verbose "Successfully connected to Microsoft Graph."

# The filter for cloud-only groups is where onPremisesSyncEnabled is null or false.
# Using 'null' is generally effective.
$filter = "onPremisesSyncEnabled eq null"
Write-Verbose "Enumerating all cloud-only groups using filter: $filter"

$groups = Invoke-WithRetry -ScriptBlock { Get-MgGroup -Filter $filter -All }

Write-Verbose "Found $($groups.Count) total cloud-only groups."

# Export the data
Write-Export -DatasetName $DatasetName -Objects $groups -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion

Write-Verbose "Entra cloud-only groups export completed."
