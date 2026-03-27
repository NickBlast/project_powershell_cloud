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
    Auth:     Global Reader (interactive browser sign-in)
    Modules:  Microsoft.Graph
    Runs on:  Any workstation with internet access
#>

# ============================================================================
# 1. INSTALL & IMPORT
# ============================================================================

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Resolve the actual Documents folder (handles OneDrive redirection on work machines)
# and ensure the correct user module path is in this session's PSModulePath.
$psSubfolder = if ($PSVersionTable.PSVersion.Major -ge 6) { 'PowerShell' } else { 'WindowsPowerShell' }
$userModulePath = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) "$psSubfolder\Modules"

if ($userModulePath -notin ($env:PSModulePath -split [System.IO.Path]::PathSeparator)) {
    $env:PSModulePath = $userModulePath + [System.IO.Path]::PathSeparator + $env:PSModulePath
}

$requiredModules = @('Microsoft.Graph.Authentication', 'Microsoft.Graph.Users', 'Microsoft.Graph.Groups', 'MSAL.PS')
$missingModules  = $requiredModules | Where-Object { -not (Get-Module -Name $_ -ListAvailable) }

if ($missingModules) {
    Write-Host "Installing missing modules: $($missingModules -join ', ')..." -ForegroundColor Cyan
    foreach ($mod in $missingModules) {
        $installName = if ($mod -like 'Microsoft.Graph*') { 'Microsoft.Graph' } else { $mod }
        Install-Module -Name $installName -Repository PSGallery -Scope CurrentUser -Force -AllowClobber
    }
}

Import-Module Microsoft.Graph.Authentication -ErrorAction Stop
Import-Module Microsoft.Graph.Users         -ErrorAction Stop
Import-Module Microsoft.Graph.Groups        -ErrorAction Stop
Import-Module MSAL.PS                       -ErrorAction Stop

Write-Host "Modules loaded." -ForegroundColor Green

# ============================================================================
# 2. CONNECT
# ============================================================================

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# GUI input dialog — used instead of Read-Host so all user prompts are popup
# windows (required for portability on machines where the console may be hidden
# or where Read-Host is undesirable). Returns $null if the user cancels or
# closes the dialog without entering a value.
function Show-InputDialog {
    param(
        [string]$Prompt,
        [string]$Title = 'Input Required'
    )
    $form                 = New-Object System.Windows.Forms.Form
    $form.Text            = $Title
    $form.Size            = New-Object System.Drawing.Size(420, 155)
    $form.StartPosition   = 'CenterScreen'
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox     = $false
    $form.MinimizeBox     = $false
    $form.TopMost         = $true

    $label          = New-Object System.Windows.Forms.Label
    $label.Text     = $Prompt
    $label.Location = New-Object System.Drawing.Point(12, 14)
    $label.Size     = New-Object System.Drawing.Size(384, 20)
    $form.Controls.Add($label)

    $textBox          = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(12, 40)
    $textBox.Size     = New-Object System.Drawing.Size(384, 22)
    $form.Controls.Add($textBox)

    $okBtn              = New-Object System.Windows.Forms.Button
    $okBtn.Text         = 'OK'
    $okBtn.Location     = New-Object System.Drawing.Point(220, 74)
    $okBtn.Size         = New-Object System.Drawing.Size(85, 28)
    $okBtn.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okBtn)
    $form.AcceptButton  = $okBtn

    $cancelBtn              = New-Object System.Windows.Forms.Button
    $cancelBtn.Text         = 'Cancel'
    $cancelBtn.Location     = New-Object System.Drawing.Point(311, 74)
    $cancelBtn.Size         = New-Object System.Drawing.Size(85, 28)
    $cancelBtn.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelBtn)
    $form.CancelButton      = $cancelBtn

    $result = $form.ShowDialog()
    $form.Dispose()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK -and
        -not [string]::IsNullOrWhiteSpace($textBox.Text)) {
        return $textBox.Text.Trim()
    }
    return $null
}

# Prompt for the secondary account UPN so this script is portable.
$secondaryAccount = Show-InputDialog `
    -Prompt 'Enter the secondary admin account email (UPN):' `
    -Title  'Secondary Account — Entra Sync Error Export'

if (-not $secondaryAccount) {
    Write-Warning 'No account entered. Exiting.'
    exit
}

Write-Host "Connecting to Microsoft Graph as $secondaryAccount..." -ForegroundColor Cyan

# Root cause: same-tenant SSO — AAD silently completes OAuth using the primary
# account's existing browser session before credentials can be entered. On
# Entra-joined devices, the device-bound account can also be injected through
# the OS account system (WAM/broker layer).
#
# Device code flow is blocked by Conditional Access in this tenant.
# Authorization Code flow (what MSAL.PS uses interactively) is allowed.
#
# Fix:
#   -Prompt ForceLogin        → sends prompt=login to the IdP, breaking any
#                               existing SSO session in the web view. This is
#                               Prompt.ForceLogin in MSAL.NET — the correct field
#                               name (there is no Prompt.Login). Confirmed via
#                               MSAL.NET API docs.
#   -LoginHint                → pre-fills the UPN at the Okta login page so the
#                               user only has to enter their password. NOTE: login_hint
#                               alone does NOT skip AAD's own credential form —
#                               that is what domain_hint is for (see below).
#   -ExtraQueryParameters     → domain_hint tells AAD to skip Home Realm Discovery
#                               (its own credential form) and redirect immediately
#                               to the Okta federated IdP for $domain. This is the
#                               key fix for the double-prompt: without it AAD renders
#                               its own password field first, then redirects to Okta,
#                               resulting in two credential prompts. Confirmed via
#                               MS identity platform OAuth2 auth code flow docs.
#                               If $domain is not a verified federated domain in the
#                               tenant, AAD silently ignores the hint — no error.
#
# WAM note: WAM requires an explicit WithBroker() call in MSAL.NET and is NOT
# enabled by MSAL.PS. WAM also does not support third-party IdPs (Okta) per
# MS docs ("WAM supports only Microsoft Entra ID"). Device-broker interference
# therefore does not apply to this MSAL.PS flow.
#
# The resulting access token is passed directly to Connect-MgGraph -AccessToken,
# so no Connect-MgGraph auth flow runs at all.

# Extract the domain portion of the UPN for domain_hint (e.g. "contoso.com").
# Split('@')[1] is safe here because the null/empty guard above already exited.
$domain = $secondaryAccount.Split('@')[1]

# '14d82eec-204b-4c2f-b7e8-296a70dab67e' is the well-known client ID for the
# "Microsoft Graph Command Line Tools" enterprise app, present in every tenant.
$msalToken = Get-MsalToken `
    -ClientId            '14d82eec-204b-4c2f-b7e8-296a70dab67e' `
    -TenantId            'organizations' `
    -Scopes              'https://graph.microsoft.com/Directory.Read.All' `
    -Interactive `
    -Prompt               ForceLogin `
    -LoginHint            $secondaryAccount `
    -ExtraQueryParameters @{ domain_hint = $domain } `
    -ErrorAction          Stop

$secureToken = $msalToken.AccessToken | ConvertTo-SecureString -AsPlainText -Force
Connect-MgGraph -AccessToken $secureToken -NoWelcome -ErrorAction Stop

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
                'ProxyAddress' {
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
                'ProxyAddress' {
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
