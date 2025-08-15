<#
.SYNOPSIS
    Exports all Entra ID (formerly Azure AD) directory roles.
.DESCRIPTION
    This script connects to Microsoft Graph and retrieves a list of all available directory roles.
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './exports'.
.EXAMPLE
    PS> ./scripts/export-entra_directory_roles.ps1 -OutputPath .\my-entra-data
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path $PSScriptRoot '..' 'exports')
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = $PSBoundParameters.Verbose.IsPresent ? 'Continue' : 'SilentlyContinue'

# Import shared modules
Import-Module $PSScriptRoot/../modules/connect/Connect.psm1
Import-Module $PSScriptRoot/../modules/logging/Logging.psm1
Import-Module $PSScriptRoot/../modules/export/Export.psm1

# --- Script Configuration ---
$ToolVersion = "1.0.0"
$DatasetName = "entra_directory_roles"
# --------------------------

Write-Verbose "Starting Entra directory roles export..."

# Connect to Graph
$tenant = Select-Tenant
Connect-GraphContext -TenantId $tenant.tenant_id -AuthMode $tenant.preferred_auth
Write-Verbose "Successfully connected to Microsoft Graph."

Write-Verbose "Enumerating all directory roles..."
$roles = Invoke-WithRetry -ScriptBlock { Get-MgDirectoryRole -All }

Write-Verbose "Found $($roles.Count) total directory roles."

# Export the data
Write-Export -DatasetName $DatasetName -Objects $roles -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion

Write-Verbose "Entra directory roles export completed."
