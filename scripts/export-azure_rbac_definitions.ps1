<#
.SYNOPSIS
    Exports all Azure RBAC role definitions, both built-in and custom.
.DESCRIPTION
    This script connects to Azure and retrieves a list of all role definitions available in the tenant.
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './exports'.
.EXAMPLE
    PS> ./scripts/export-azure_rbac_definitions.ps1 -OutputPath .\my-azure-data
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
$DatasetName = "azure_rbac_definitions"
# --------------------------

Write-Verbose "Starting Azure RBAC definitions export..."

# Connect to Azure
Connect-AzureContext -TenantId (Select-Tenant).tenant_id -AuthMode DeviceCode
Write-Verbose "Successfully connected to Azure."

Write-Verbose "Enumerating all role definitions..."
$definitions = Get-AzRoleDefinition

Write-Verbose "Found $($definitions.Count) total role definitions."

# Export the data
Write-Export -DatasetName $DatasetName -Objects $definitions -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion

Write-Verbose "Azure RBAC definitions export completed."
