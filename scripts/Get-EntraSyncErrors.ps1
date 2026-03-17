<#
.SYNOPSIS
    Exports all Entra ID on-premises sync provisioning errors to CSV.

.DESCRIPTION
    Uses Microsoft Graph PowerShell SDK to pull all synced users and groups,
    filters to those with onPremisesProvisioningErrors, and exports a flat
    CSV showing exactly what attribute is broken and what the conflicting value is.

    No server-side filter exists for onPremisesProvisioningErrors, so the script
    pulls all synced objects with the error property selected and filters client-side.
    For ~200K objects this typically takes 2-5 minutes depending on throttling.

.NOTES
    Auth:     Global Admin (interactive browser sign-in)
    Modules:  Microsoft.Graph.Users, Microsoft.Graph.Groups
    Runs on:  Any workstation with PowerShell 5.1+ and internet access
#>

#Requires -Version 5.1

# ============================================================================
# 1. INSTALL & IMPORT
# ============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Install only the sub-modules we need (not the full Microsoft.Graph meta-package)
$modules = @('Microsoft.Graph.Authentication', 'Microsoft.Graph.Users', 'Microsoft.Graph.Groups')

foreach ($mod in $modules) {
    if (-not (Get-Module -Name $mod -ListAvailable)) {
        Write-Host "Installing $mod..." -ForegroundColor Cyan
        Install-Module -Name $mod -Repository PSGallery -Scope CurrentUser -Force -AllowClobber

        # Refresh PSModulePath so the newly installed module is discoverable this session
        $env:PSModulePath = [System.Environment]::GetEnvironmentVariable('PSModulePath', 'User') +
            [System.IO.Path]::PathSeparator +
            [System.Environment]::GetEnvironmentVariable('PSModulePath', 'Machine')
    }

    Import-Module $mod -ErrorAction Stop
}

Write-Host "Modules loaded." -ForegroundColor Green

# ============================================================================
# 2. CONNECT
# ============================================================================

Write-Host "Connecting to Microsoft Graph (browser sign-in)..." -ForegroundColor Cyan

Connect-MgGraph -Scopes 'User.Read.All','Group.Read.All' -NoWelcome -ErrorAction Stop

Write-Host "Connected as: $((Get-MgContext).Account)" -ForegroundColor Green

# ============================================================================
# 3. PULL ALL SYNCED USERS WITH PROVISIONING ERRORS
# ============================================================================

Write-Host "Pulling synced users (this may take a few minutes for large directories)..." -ForegroundColor Cyan

# -Property is critical here: onPremisesProvisioningErrors is NOT returned by default.
# -All pages through the entire result set (default is only 100).
# -Filter narrows to synced objects only, reducing payload.
$users = Get-MgUser -All `
    -Filter "onPremisesSyncEnabled eq true" `
    -Property Id, DisplayName, UserPrincipalName, ProxyAddresses, `
              OnPremisesDistinguishedName, OnPremisesImmutableId, `
              OnPremisesProvisioningErrors `
    -ErrorAction Stop

$usersWithErrors = $users | Where-Object { $_.OnPremisesProvisioningErrors.Count -gt 0 }

Write-Host "Users scanned: $($users.Count) | Users with errors: $($usersWithErrors.Count)" -ForegroundColor Yellow

# ============================================================================
# 4. PULL ALL SYNCED GROUPS WITH PROVISIONING ERRORS
# ============================================================================

Write-Host "Pulling synced groups..." -ForegroundColor Cyan

$groups = Get-MgGroup -All `
    -Filter "onPremisesSyncEnabled eq true" `
    -Property Id, DisplayName, ProxyAddresses, `
              OnPremisesProvisioningErrors `
    -ErrorAction Stop

$groupsWithErrors = $groups | Where-Object { $_.OnPremisesProvisioningErrors.Count -gt 0 }

Write-Host "Groups scanned: $($groups.Count) | Groups with errors: $($groupsWithErrors.Count)" -ForegroundColor Yellow

# ============================================================================
# 5. FLATTEN TO CSV ROWS
# ============================================================================

$results = [System.Collections.Generic.List[PSCustomObject]]::new()

# Process users
foreach ($u in $usersWithErrors) {
    foreach ($err in $u.OnPremisesProvisioningErrors) {
        $results.Add([PSCustomObject]@{
            ObjectType         = 'User'
            DisplayName        = $u.DisplayName
            UserPrincipalName  = $u.UserPrincipalName
            ObjectId           = $u.Id
            OnPremisesDN       = $u.OnPremisesDistinguishedName
            ImmutableId        = $u.OnPremisesImmutableId
            ProxyAddresses     = ($u.ProxyAddresses -join '; ')
            ErrorCategory      = $err.Category
            PropertyCausingError = $err.PropertyCausingError
            ConflictingValue   = $err.Value
            OccurredDateTime   = $err.OccurredDateTime
            WhatToFix          = switch ($err.PropertyCausingError) {
                'UserPrincipalName' {
                    "DUPLICATE UPN - Another object claims '$($err.Value)'. " +
                    "Fix: Change UPN on one object in on-prem AD, or delete the orphan cloud object. " +
                    "Find conflict: Get-MgUser -Filter `"userPrincipalName eq '$($err.Value)'`""
                }
                'ProxyAddresses' {
                    "DUPLICATE PROXY - '$($err.Value)' claimed by multiple objects. " +
                    "Fix: Remove duplicate proxyAddress from one object in on-prem AD. " +
                    "Find conflict: Get-ADObject -Filter {proxyAddresses -eq '$($err.Value)'} -Properties proxyAddresses"
                }
                default {
                    "Review '$($err.PropertyCausingError)' = '$($err.Value)' on DN: $($u.OnPremisesDistinguishedName)"
                }
            }
        })
    }
}

# Process groups
foreach ($g in $groupsWithErrors) {
    foreach ($err in $g.OnPremisesProvisioningErrors) {
        $results.Add([PSCustomObject]@{
            ObjectType         = 'Group'
            DisplayName        = $g.DisplayName
            UserPrincipalName  = ''
            ObjectId           = $g.Id
            OnPremisesDN       = ''
            ImmutableId        = ''
            ProxyAddresses     = ($g.ProxyAddresses -join '; ')
            ErrorCategory      = $err.Category
            PropertyCausingError = $err.PropertyCausingError
            ConflictingValue   = $err.Value
            OccurredDateTime   = $err.OccurredDateTime
            WhatToFix          = switch ($err.PropertyCausingError) {
                'ProxyAddresses' {
                    "DUPLICATE PROXY - '$($err.Value)' claimed by multiple objects. " +
                    "Fix: Remove duplicate proxyAddress from one object in on-prem AD. " +
                    "Find conflict: Get-ADObject -Filter {proxyAddresses -eq '$($err.Value)'} -Properties proxyAddresses"
                }
                default {
                    "Review '$($err.PropertyCausingError)' = '$($err.Value)' on group '$($g.DisplayName)'"
                }
            }
        })
    }
}

# ============================================================================
# 6. EXPORT
# ============================================================================

if ($results.Count -eq 0) {
    Write-Host "`nNo provisioning errors found. Sync is clean." -ForegroundColor Green
    exit 0
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$csvPath   = ".\EntraID_SyncErrors_$timestamp.csv"

$results | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "  Export complete: $csvPath" -ForegroundColor Green
Write-Host "  Total errors:   $($results.Count)" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green

# Summary tables
Write-Host "`n--- By Error Property ---" -ForegroundColor Yellow
$results | Group-Object PropertyCausingError | Sort-Object Count -Descending |
    Format-Table @{L='Property';E={$_.Name}}, Count -AutoSize

Write-Host "--- By Object Type ---" -ForegroundColor Yellow
$results | Group-Object ObjectType | Sort-Object Count -Descending |
    Format-Table @{L='Type';E={$_.Name}}, Count -AutoSize

Write-Host "--- First 10 Errors ---" -ForegroundColor Yellow
$results | Select-Object -First 10 DisplayName, ObjectType, PropertyCausingError, ConflictingValue |
    Format-Table -AutoSize

Write-Host "Full details including remediation commands are in the 'WhatToFix' column of the CSV." -ForegroundColor DarkGray