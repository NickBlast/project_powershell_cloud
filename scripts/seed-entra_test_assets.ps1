<#!
.SYNOPSIS
    Seed deterministic test assets (users, groups, app registration) into the Entra test tenant.
.DESCRIPTION
    Connects to the curated test tenant using ENTRA_TEST_* credentials, ensures baseline users and
    groups exist, links users to groups, provisions a simple app registration plus service principal,
    and optionally assigns the app a Reader role at subscription scope. A summary is written to
    tests/results/last_seed.json for quick inspection.
#>
[CmdletBinding()]
param()

Import-Module "$PSScriptRoot/../modules/logging/logging.psd1" -Force

$scriptName = Split-Path -Path $PSCommandPath -Leaf

$scriptBlock = {
    Set-StrictMode -Version 3.0
    $ErrorActionPreference = 'Stop'

    Import-Module "$PSScriptRoot/../modules/entra_connection/entra_connection.psd1" -Force
    Import-Module "$PSScriptRoot/../modules/logging/logging.psd1" -Force

    $connection = Connect-EntraTestTenant -ConnectAzure -Verbose:$false
    $context = Get-EntraTestContext -GraphConnected -AzureConnected

    Write-StructuredLog -Level Info -Message 'Seeding pctest assets into test tenant.' -Context @{ tenant_id = $context.TenantId; subscription_id = $context.SubscriptionId }

    $org = Get-MgOrganization
    $defaultDomain = ($org.VerifiedDomains | Where-Object { $_.IsDefault }).Name

    $usersToEnsure = @(
        @{ DisplayName='pctest-user-01'; MailNickname='pctestuser01' },
        @{ DisplayName='pctest-user-02'; MailNickname='pctestuser02' },
        @{ DisplayName='pctest-user-03'; MailNickname='pctestuser03' }
    )

    $createdUsers = @()
    foreach ($user in $usersToEnsure) {
        $upn = "$($user.MailNickname)@$defaultDomain"
        $existing = Get-MgUser -Filter "userPrincipalName eq '$upn'" -ConsistencyLevel eventual -CountVariable count
        if ($existing) {
            Write-StructuredLog -Level Info -Message "User already exists: $upn"
            $createdUsers += $existing
            continue
        }

        $password = [System.Web.Security.Membership]::GeneratePassword(16,3)
        $newUser = New-MgUser -AccountEnabled -DisplayName $user.DisplayName -MailNickname $user.MailNickname -UserPrincipalName $upn -PasswordProfile @{ Password = $password; ForceChangePasswordNextSignIn = $true }
        $createdUsers += $newUser
        Write-StructuredLog -Level Info -Message "Created user $upn"
    }

    $groupsToEnsure = @('pctest-group-owners','pctest-group-members')
    $createdGroups = @()
    foreach ($groupName in $groupsToEnsure) {
        $existingGroup = Get-MgGroup -Filter "displayName eq '$groupName'"
        if ($existingGroup) {
            $createdGroups += $existingGroup
            Write-StructuredLog -Level Info -Message "Group already exists: $groupName"
            continue
        }
        $newGroup = New-MgGroup -DisplayName $groupName -MailEnabled:$false -MailNickname $groupName -SecurityEnabled
        $createdGroups += $newGroup
        Write-StructuredLog -Level Info -Message "Created group $groupName"
    }

    if ($createdGroups.Count -gt 0 -and $createdUsers.Count -gt 0) {
        foreach ($user in $createdUsers) {
            foreach ($group in $createdGroups) {
                $memberExists = Get-MgGroupMember -GroupId $group.Id -All | Where-Object { $_.Id -eq $user.Id }
                if (-not $memberExists) {
                    New-MgGroupMember -GroupId $group.Id -DirectoryObjectId $user.Id | Out-Null
                    Write-StructuredLog -Level Info -Message "Added $($user.DisplayName) to $($group.DisplayName)"
                }
            }
        }
    }

    $appName = 'pctest-app-basic'
    $app = Get-MgApplication -Filter "displayName eq '$appName'"
    if (-not $app) {
        $app = New-MgApplication -DisplayName $appName -SignInAudience AzureADMyOrg
        Write-StructuredLog -Level Info -Message "Created app registration $appName"
    } else {
        Write-StructuredLog -Level Info -Message "App registration already exists: $appName"
    }

    $sp = Get-MgServicePrincipal -Filter "displayName eq '$appName'"
    if (-not $sp) {
        $sp = New-MgServicePrincipal -AppId $app.AppId
        Write-StructuredLog -Level Info -Message "Created service principal for $appName"
    } else {
        Write-StructuredLog -Level Info -Message "Service principal already exists for $appName"
    }

    if ($context.SubscriptionId) {
        $roleAssignmentName = [guid]::NewGuid()
        $assignmentExists = Get-AzRoleAssignment -ObjectId $sp.Id -ErrorAction SilentlyContinue
        if (-not $assignmentExists) {
            New-AzRoleAssignment -RoleDefinitionName 'Reader' -ApplicationId $sp.AppId -Scope "/subscriptions/$($context.SubscriptionId)" -ErrorAction Stop | Out-Null
            Write-StructuredLog -Level Info -Message "Assigned Reader to $appName at subscription scope"
        } else {
            Write-StructuredLog -Level Info -Message "Azure role assignment already present for $appName"
        }
    }

    $summary = [pscustomobject]@{
        generated_at = [datetime]::UtcNow.ToString('o')
        users        = $createdUsers.Count
        groups       = $createdGroups.Count
        appId        = $app.AppId
        servicePrincipalId = $sp.Id
    }

    Write-StructuredLog -Level Info -Message "Seed summary: users=$($summary.users), groups=$($summary.groups), app=$($summary.appId)" -Context $summary

    $summary | ConvertTo-Json -Depth 5 | Set-Content -Path (Join-Path $PSScriptRoot '../tests/results/last_seed.json')
}

Invoke-WithRunLog -ScriptName $scriptName -ScriptBlock $scriptBlock
