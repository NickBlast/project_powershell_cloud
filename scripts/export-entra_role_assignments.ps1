<#
.SYNOPSIS
    Exports all members for each Entra ID directory role.
.DESCRIPTION
    This script connects to Microsoft Graph, enumerates all directory roles, and then finds all members
    (users, service principals, groups) assigned to each role.
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './exports'.
.EXAMPLE
    PS> ./scripts/export-entra_role_assignments.ps1 -OutputPath .\my-entra-data
[.EXAMPLE
    PS> ./scripts/export-entra_role_assignments.ps1 -OutputPath .\my-entra-data -Verbose
    
.EXAMPLE
    PS> ./scripts/export-entra_role_assignments.ps1 -WhatIf
.NOTES
    Author: Repo automation
    Version: 1.0.0
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
$DatasetName = "entra_role_assignments"
# --------------------------

Write-Verbose "Starting Entra role assignments export..."

# Connect to Graph
$tenant = Select-Tenant
Connect-GraphContext -TenantId $tenant.tenant_id -AuthMode $tenant.preferred_auth
Write-Verbose "Successfully connected to Microsoft Graph."

$allAssignments = [System.Collections.Generic.List[pscustomobject]]::new()

Write-Verbose "Enumerating all directory roles to find members..."
$roles = Invoke-WithRetry -ScriptBlock { Get-MgDirectoryRole -All }

foreach ($role in $roles) {
    Write-Verbose "Getting members for role: $($role.DisplayName)"
    $members = Invoke-WithRetry -ScriptBlock { Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All }
    foreach ($member in $members) {
        $allAssignments.Add([pscustomobject]@{
            RoleId = $role.Id
            RoleDisplayName = $role.DisplayName
            MemberId = $member.Id
            MemberType = $member.OdataType.Replace('#microsoft.graph.','')
            # Attempt to get a user-friendly name
            MemberDisplayName = $member.AdditionalProperties.displayName
            MemberPrincipalName = $member.AdditionalProperties.userPrincipalName -or $member.AdditionalProperties.appId
        })
    }
}

Write-Verbose "Found $($allAssignments.Count) total role assignments."

# Export the data
Write-Export -DatasetName $DatasetName -Objects $allAssignments -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion

Write-Verbose "Entra role assignments export completed."
