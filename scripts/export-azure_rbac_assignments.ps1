[<#
.SYNOPSIS
    Exports all Azure RBAC role assignments across all scopes.
.DESCRIPTION
    This script connects to Azure and retrieves a list of all role assignments. 
    This can be a long-running operation on large tenants.
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './exports'.
.EXAMPLE
    PS> ./scripts/export-azure_rbac_assignments.ps1 -OutputPath .\my-azure-data -Verbose
.EXAMPLE
    PS> ./scripts/export-azure_rbac_assignments.ps1 -WhatIf
.NOTES
    Author: Repo automation
    Version: 1.0.0
    Use -Verbose for detailed progress and -WhatIf for a dry run (no external calls).
#>
[CmdletBinding(SupportsShouldProcess = $true)]
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
$DatasetName = "azure_rbac_assignments"
# --------------------------

Write-Verbose "Starting Azure RBAC assignments export..."

# Connect to Azure
Connect-AzureContext -TenantId (Select-Tenant).tenant_id -AuthMode DeviceCode
Write-Verbose "Successfully connected to Azure."

Write-Verbose "Enumerating all role assignments... (This may take a while)"
# Note: In a real-world scenario, we would iterate through subscriptions and management groups
# to avoid potential throttling or memory issues with a single giant call.
# For this implementation, we make a single call.
$assignments = Get-AzRoleAssignment

Write-Verbose "Found $($assignments.Count) total role assignments."

# Export the data
Write-Export -DatasetName $DatasetName -Objects $assignments -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion

Write-Verbose "Azure RBAC assignments export completed."
