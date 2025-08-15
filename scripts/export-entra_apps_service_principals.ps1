<#
.SYNOPSIS
    Exports Entra ID Applications, Service Principals, and consent grants.
.DESCRIPTION
    This script connects to Microsoft Graph and performs three separate exports:
    1. All Application objects.
    2. All Service Principal objects.
    3. All OAuth2 permission grants (delegated and app-only consents).
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './exports'.
.EXAMPLE
    PS> ./scripts/export-entra_apps_service_principals.ps1 -OutputPath .\my-entra-data
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
# --------------------------

Write-Verbose "Starting Entra Apps, SPs, and Consents export..."

# Connect to Graph
$tenant = Select-Tenant
Connect-GraphContext -TenantId $tenant.tenant_id -AuthMode $tenant.preferred_auth
Write-Verbose "Successfully connected to Microsoft Graph."

# 1. Export Applications
$datasetApps = "entra_apps"
Write-Verbose "Enumerating all Applications..."
$apps = Invoke-WithRetry -ScriptBlock { Get-MgApplication -All }
Write-Verbose "Found $($apps.Count) total applications."
Write-Export -DatasetName $datasetApps -Objects $apps -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion
Write-Verbose "$datasetApps export completed."

# 2. Export Service Principals
$datasetSps = "entra_service_principals"
Write-Verbose "Enumerating all Service Principals..."
$sps = Invoke-WithRetry -ScriptBlock { Get-MgServicePrincipal -All }
Write-Verbose "Found $($sps.Count) total service principals."
Write-Export -DatasetName $datasetSps -Objects $sps -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion
Write-Verbose "$datasetSps export completed."

# 3. Export Consents (OAuth2 Permission Grants)
$datasetConsents = "entra_consents"
Write-Verbose "Enumerating all OAuth2 Permission Grants..."
$consents = Invoke-WithRetry -ScriptBlock { Get-MgOauth2PermissionGrant -All }
Write-Verbose "Found $($consents.Count) total OAuth2 permission grants."
Write-Export -DatasetName $datasetConsents -Objects $consents -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion
Write-Verbose "$datasetConsents export completed."

Write-Verbose "All Entra app-related exports are complete."
