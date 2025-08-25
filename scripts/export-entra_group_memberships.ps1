<#
.SYNOPSIS
    Exports all members for every group in Entra ID.
.DESCRIPTION
    This script connects to Microsoft Graph, enumerates all groups, and then finds all members
    for each group. This can be a very long-running and data-intensive operation.
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './exports'.
.EXAMPLE
    PS> ./scripts/export-entra_group_memberships.ps1 -OutputPath .\my-entra-data
[.EXAMPLE
    PS> ./scripts/export-entra_group_memberships.ps1 -OutputPath .\my-entra-data -Verbose

.EXAMPLE
    PS> ./scripts/export-entra_group_memberships.ps1 -WhatIf

.NOTES
    Author: Repo automation
    Version: 1.0.0
#>
[CmdletBinding(SupportsShouldProcess = $true)]
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
$DatasetName = "entra_group_memberships"
# --------------------------

Write-Verbose "Starting Entra group memberships export... (This can take a very long time)"

# Connect to Graph
$tenant = Select-Tenant
Connect-GraphContext -TenantId $tenant.tenant_id -AuthMode $tenant.preferred_auth
Write-Verbose "Successfully connected to Microsoft Graph."

$allMemberships = [System.Collections.Generic.List[pscustomobject]]::new()

Write-Verbose "Enumerating all groups to find members..."
$groups = Invoke-WithRetry -ScriptBlock { Get-MgGroup -All }
$totalGroups = $groups.Count
$groupCounter = 0

foreach ($group in $groups) {
    $groupCounter++
    Write-Verbose "[$groupCounter/$totalGroups] Getting members for group: $($group.DisplayName)"
    $members = Invoke-WithRetry -ScriptBlock { Get-MgGroupMember -GroupId $group.Id -All }
    foreach ($member in $members) {
        $allMemberships.Add([pscustomobject]@{
            GroupId = $group.Id
            GroupDisplayName = $group.DisplayName
            MemberId = $member.Id
            MemberType = $member.OdataType.Replace('#microsoft.graph.','')
            MemberDisplayName = $member.AdditionalProperties.displayName
            MemberPrincipalName = $member.AdditionalProperties.userPrincipalName -or $member.AdditionalProperties.appId
        })
    }
}

Write-Verbose "Found $($allMemberships.Count) total group memberships."

# Export the data
Write-Export -DatasetName $DatasetName -Objects $allMemberships -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion

Write-Verbose "Entra group memberships export completed."
