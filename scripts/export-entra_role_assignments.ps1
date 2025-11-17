<#
.SYNOPSIS
    Exports Entra directory role assignments for the test tenant.
.DESCRIPTION
    Enumerates directory roles and members using the centralized test tenant connection and writes
    outputs/entra/entra_role_assignments.csv.
.PARAMETER OutputPath
    Target directory for export files. Defaults to './outputs/entra'.
.EXAMPLE
    pwsh -NoProfile -File ./scripts/export-entra_role_assignments.ps1
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
$DatasetName = 'entra_role_assignments'

$context = Connect-EntraTestTenant -SkipAzure
Write-ExportLogStart -Name $DatasetName -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId

$allAssignments = [System.Collections.Generic.List[pscustomobject]]::new()
$roles = Invoke-WithRetry -ScriptBlock { Get-MgDirectoryRole -All }
foreach ($role in $roles) {
    Write-Verbose "Getting members for role: $($role.DisplayName)"
    $members = Invoke-WithRetry -ScriptBlock { Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All }
    foreach ($member in $members) {
        $principalName = $member.AdditionalProperties.userPrincipalName
        if (-not $principalName) { $principalName = $member.AdditionalProperties.appId }
        $allAssignments.Add([pscustomobject]@{
            RoleId             = $role.Id
            RoleDisplayName    = $role.DisplayName
            MemberId           = $member.Id
            MemberType         = $member.OdataType.Replace('#microsoft.graph.','')
            MemberDisplayName  = $member.AdditionalProperties.displayName
            MemberPrincipalName = $principalName
        })
    }
}

Write-StructuredLog -Level Info -Message "Found $($allAssignments.Count) directory role assignments" -Context @{ correlation_id = (Get-CorrelationId) }

Write-Export -DatasetName $DatasetName -Objects $allAssignments -OutputPath $OutputPath -Formats 'csv' -ToolVersion $ToolVersion

Write-ExportLogResult -Name $DatasetName -Success $true -OutputPath (Join-Path -Path $OutputPath -ChildPath "$DatasetName.csv") -RowCount $allAssignments.Count -Message 'Completed'
