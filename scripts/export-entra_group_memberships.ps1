<#
.SYNOPSIS
    Exports all group memberships from the test Entra tenant.
.DESCRIPTION
    Connects to Microsoft Graph using the test tenant configuration, enumerates groups, and writes
    flattened membership records to outputs/entra/entra_group_memberships.csv.
.PARAMETER OutputPath
    Target directory for export files. Defaults to './outputs/entra'.
.EXAMPLE
    pwsh -NoProfile -File ./scripts/export-entra_group_memberships.ps1
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
$DatasetName = 'entra_group_memberships'

$context = Connect-EntraTestTenant -SkipAzure
Write-ExportLogStart -Name $DatasetName -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId

$allMemberships = [System.Collections.Generic.List[pscustomobject]]::new()

Write-StructuredLog -Level Info -Message 'Enumerating groups for membership export' -Context @{ correlation_id = (Get-CorrelationId) }
$groups = Invoke-WithRetry -ScriptBlock { Get-MgGroup -All }
$groupCounter = 0
foreach ($group in $groups) {
    $groupCounter++
    Write-Verbose "[$groupCounter/$($groups.Count)] Getting members for group: $($group.DisplayName)"
    $members = Invoke-WithRetry -ScriptBlock { Get-MgGroupMember -GroupId $group.Id -All }
    foreach ($member in $members) {
        $principalName = $member.AdditionalProperties.userPrincipalName
        if (-not $principalName) { $principalName = $member.AdditionalProperties.appId }
        $allMemberships.Add([pscustomobject]@{
            GroupId             = $group.Id
            GroupDisplayName    = $group.DisplayName
            MemberId            = $member.Id
            MemberType          = $member.OdataType.Replace('#microsoft.graph.','')
            MemberDisplayName   = $member.AdditionalProperties.displayName
            MemberPrincipalName = $principalName
        })
    }
}

Write-StructuredLog -Level Info -Message "Found $($allMemberships.Count) total group memberships" -Context @{ correlation_id = (Get-CorrelationId) }

Write-Export -DatasetName $DatasetName -Objects $allMemberships -OutputPath $OutputPath -Formats 'csv' -ToolVersion $ToolVersion

Write-ExportLogResult -Name $DatasetName -Success $true -OutputPath (Join-Path -Path $OutputPath -ChildPath "$DatasetName.csv") -RowCount $allMemberships.Count -Message 'Completed'
