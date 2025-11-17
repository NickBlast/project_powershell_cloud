<#
.SYNOPSIS
    Seeds pctest-* users, groups, apps, and role assignments in the test tenant.
.DESCRIPTION
    Idempotently ensures a small set of test assets exists in the Microsoft Entra tenant and Azure subscription
    configured via ENTRA_TEST_* environment variables. The script creates users, groups, an app registration,
    a service principal, a directory role assignment, and an Azure RBAC assignment for the app.
.EXAMPLE
    pwsh -NoProfile -File ./scripts/seed-entra_test_assets.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psm1
Import-Module $PSScriptRoot/../modules/logging/Logging.psm1

$prefix = 'pctest'
$summary = [ordered]@{
    users             = 0
    groups            = 0
    applications      = 0
    servicePrincipals = 0
    directoryRoles    = 0
    azureAssignments  = 0
}

$context = Connect-EntraTestTenant
Write-StructuredLog -Level Info -Message "Seeding test assets in tenant $($context.TenantId)" -Context @{ correlation_id = (Get-CorrelationId) }

$org = Get-MgOrganization -ErrorAction Stop
$domain = ($org.VerifiedDomains | Where-Object { $_.IsDefault }).Name
if (-not $domain) { $domain = "$($context.TenantId).onmicrosoft.com" }

function New-PctestPassword {
    $base = [guid]::NewGuid().ToString('N')
    return "${base}!aA1".Substring(0,20)
}

$userSpecs = @(
    @{ Upn = "$prefix-user-01@$domain"; DisplayName = "$prefix-user-01"; GivenName = 'Pctest'; Surname = 'User01' },
    @{ Upn = "$prefix-user-02@$domain"; DisplayName = "$prefix-user-02"; GivenName = 'Pctest'; Surname = 'User02' },
    @{ Upn = "$prefix-user-03@$domain"; DisplayName = "$prefix-user-03"; GivenName = 'Pctest'; Surname = 'User03' }
)

$createdUsers = @()
foreach ($spec in $userSpecs) {
    $existing = Get-MgUser -Filter "userPrincipalName eq '${($spec.Upn)}'" -All
    if ($existing) {
        Write-StructuredLog -Level Info -Message "Reusing user ${($spec.Upn)}" -Context @{ correlation_id = (Get-CorrelationId) }
        $createdUsers += $existing[0]
        continue
    }

    $passwordProfile = @{ Password = New-PctestPassword; ForceChangePasswordNextSignIn = $false }
    $newUser = New-MgUser -DisplayName $spec.DisplayName -UserPrincipalName $spec.Upn -AccountEnabled -MailNickname $spec.DisplayName -GivenName $spec.GivenName -Surname $spec.Surname -PasswordProfile $passwordProfile
    $summary.users++
    $createdUsers += $newUser
    Write-StructuredLog -Level Info -Message "Created user ${($spec.Upn)}" -Context @{ correlation_id = (Get-CorrelationId) }
}

$groupSpecs = @(
    @{ DisplayName = "$prefix-group-owners"; Description = 'pctest owners group'; Members = @($createdUsers[0].Id, $createdUsers[1].Id) },
    @{ DisplayName = "$prefix-group-readers"; Description = 'pctest readers group'; Members = $createdUsers.Id }
)

$groups = @()
foreach ($spec in $groupSpecs) {
    $existing = Get-MgGroup -Filter "displayName eq '${($spec.DisplayName)}'" -All
    if ($existing) {
        $group = $existing[0]
        Write-StructuredLog -Level Info -Message "Reusing group ${($spec.DisplayName)}" -Context @{ correlation_id = (Get-CorrelationId) }
    } else {
        $group = New-MgGroup -DisplayName $spec.DisplayName -Description $spec.Description -SecurityEnabled -MailEnabled:$false -MailNickname $spec.DisplayName
        $summary.groups++
        Write-StructuredLog -Level Info -Message "Created group ${($spec.DisplayName)}" -Context @{ correlation_id = (Get-CorrelationId) }
    }

    $groups += $group

    $existingMembers = Get-MgGroupMember -GroupId $group.Id -All | Select-Object -ExpandProperty Id
    foreach ($memberId in $spec.Members) {
        if (-not $existingMembers -or -not ($existingMembers -contains $memberId)) {
            New-MgGroupMemberByRef -GroupId $group.Id -BodyParameter @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$memberId" } | Out-Null
        }
    }
}

$appDisplayName = "$prefix-app-sample"
$app = Get-MgApplication -Filter "displayName eq '$appDisplayName'" -All
if (-not $app) {
    $app = New-MgApplication -DisplayName $appDisplayName -SignInAudience 'AzureADMyOrg'
    $summary.applications++
    Write-StructuredLog -Level Info -Message "Created app registration $appDisplayName" -Context @{ correlation_id = (Get-CorrelationId) }
} else {
    $app = $app[0]
    Write-StructuredLog -Level Info -Message "Reusing app registration $appDisplayName" -Context @{ correlation_id = (Get-CorrelationId) }
}

$sp = Get-MgServicePrincipal -Filter "appId eq '$($app.AppId)'" -All
if (-not $sp) {
    $sp = New-MgServicePrincipal -AppId $app.AppId
    $summary.servicePrincipals++
    Write-StructuredLog -Level Info -Message "Created service principal for $appDisplayName" -Context @{ correlation_id = (Get-CorrelationId) }
} else {
    $sp = $sp[0]
    Write-StructuredLog -Level Info -Message "Reusing service principal for $appDisplayName" -Context @{ correlation_id = (Get-CorrelationId) }
}

$roleName = 'Directory Readers'
$role = Get-MgDirectoryRole -Filter "displayName eq '$roleName'" -All
if (-not $role) {
    $template = Get-MgDirectoryRoleTemplate -Filter "displayName eq '$roleName'" -All
    if ($template) {
        $role = New-MgDirectoryRole -DirectoryRoleTemplateId $template[0].Id
    }
}

if ($role) {
    $summary.directoryRoles++
    $targetGroup = $groups | Where-Object { $_.DisplayName -eq "$prefix-group-readers" } | Select-Object -First 1
    if ($targetGroup) {
        $existingRoleMembers = Get-MgDirectoryRoleMember -DirectoryRoleId $role.Id -All | Select-Object -ExpandProperty Id
        if (-not ($existingRoleMembers -contains $targetGroup.Id)) {
            New-MgDirectoryRoleMemberByRef -DirectoryRoleId $role.Id -BodyParameter @{ '@odata.id' = "https://graph.microsoft.com/v1.0/directoryObjects/$($targetGroup.Id)" } | Out-Null
            Write-StructuredLog -Level Info -Message "Added $($targetGroup.DisplayName) to $roleName" -Context @{ correlation_id = (Get-CorrelationId) }
        }
    }
}

if ($context.SubscriptionId) {
    $scope = "/subscriptions/$($context.SubscriptionId)"
    $existingAssignment = Get-AzRoleAssignment -ObjectId $sp.Id -Scope $scope -ErrorAction SilentlyContinue
    if (-not $existingAssignment) {
        New-AzRoleAssignment -ObjectId $sp.Id -RoleDefinitionName 'Reader' -Scope $scope | Out-Null
        $summary.azureAssignments++
        Write-StructuredLog -Level Info -Message "Created Azure Reader assignment for $($sp.DisplayName) at $scope" -Context @{ correlation_id = (Get-CorrelationId) }
    } else {
        Write-StructuredLog -Level Info -Message "Reusing Azure assignment for $($sp.DisplayName) at $scope" -Context @{ correlation_id = (Get-CorrelationId) }
    }
}

Write-StructuredLog -Level Info -Message "Seed summary: users=$($summary.users), groups=$($summary.groups), apps=$($summary.applications), sps=$($summary.servicePrincipals), directoryRoles=$($summary.directoryRoles), azureAssignments=$($summary.azureAssignments)" -Context @{ correlation_id = (Get-CorrelationId) }
