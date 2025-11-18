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

$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)

Import-Module "$PSScriptRoot/../modules/logging/logging.psd1" -Force
Import-Module "$PSScriptRoot/../modules/entra_connection/entra_connection.psd1" -Force

function Invoke-ScriptMain {
    # Abort immediately on any error to keep the tenant in a known-good state.
    $ErrorActionPreference = 'Stop'

    # Establish connections to Entra and Azure (if available) without verbose noise.
    $connection = Connect-EntraTestTenant -ConnectAzure -Verbose:$false
    $context = Get-EntraTestContext -GraphConnected -AzureConnected

    # Log the start of the seed operation for auditability.
    Write-StructuredLog -Level Info -Message 'Seeding pctest assets into test tenant.' -Context @{ tenant_id = $context.TenantId; subscription_id = $context.SubscriptionId }

    # Identify the default domain so new UPNs and mail nicknames align with the tenant baseline.
    $org = Get-MgOrganization
    $defaultDomain = ($org.VerifiedDomains | Where-Object { $_.IsDefault }).Name

    # Define the baseline users to ensure exist in the tenant.
    $usersToEnsure = @(
        @{ DisplayName='pctest-user-01'; MailNickname='pctestuser01' },
        @{ DisplayName='pctest-user-02'; MailNickname='pctestuser02' },
        @{ DisplayName='pctest-user-03'; MailNickname='pctestuser03' }
    )

    $createdUsers = @()
    # Create users when missing; otherwise capture existing ones so later steps can add memberships.
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

    # Ensure baseline groups exist to hold seeded users.
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

    # Add each created user to each created group, skipping memberships that already exist.
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

    # Ensure a simple app registration + service principal exists for downstream tests.
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

    # If an Azure subscription is present, assign Reader to the service principal for cross-service smoke tests.
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

    # Summarize the seed run so tests can inspect the results quickly.
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

$runResult = Invoke-WithRunLogging -ScriptName $scriptName -ScriptBlock { Invoke-ScriptMain }

if ($runResult.Succeeded) {
    Write-Output "Execution complete. Log: $($runResult.RelativeLogPath)"
    exit 0
} else {
    Write-Output "Errors detected. Check log: $($runResult.RelativeLogPath)"
    exit 1
}
