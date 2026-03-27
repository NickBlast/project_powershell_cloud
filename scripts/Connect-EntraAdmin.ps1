<#
.SYNOPSIS
    Authenticates to Microsoft Entra ID via the Microsoft Graph PowerShell SDK
    using delegated permissions, compatible with Okta federation and MFA.

.DESCRIPTION
    Prompts for the admin account UPN, then initiates an interactive browser or
    device code authentication flow. Designed for environments where:

      - The admin account UPN is federated to Okta
      - Okta Verify MFA (Face ID push) is required at login
      - A separate non-admin account may exist in the same session or browser

    Authentication is scoped to the current PowerShell process only (-ContextScope
    Process), so no cached tokens from other accounts or prior sessions are loaded,
    and no tokens are written to the on-disk CurrentUser cache after this runs.

    RECOMMENDATION: Use -UseDeviceCode in dual-account environments. Device code
    flow lets you authenticate at microsoft.com/devicelogin inside your existing
    incognito browser window — exactly the workflow you already know. The interactive
    browser popup (default) opens your system default browser and has no way to
    pre-select the admin account, so you must pick it manually from the account
    picker if other sessions are cached.

.PARAMETER TenantId
    The Microsoft Entra tenant ID (GUID) to authenticate against.
    Required — do not use 'common'; scoping to a specific tenant is critical when
    the admin account exists in multiple tenants (e.g., QA vs. Production).

.PARAMETER UseDeviceCode
    When specified, uses device code flow instead of interactive browser.
    PowerShell prints a URL and a one-time code. Open the URL in your incognito
    browser window, enter the code, then complete normal Okta + MFA sign-in.
    Recommended for dual-account environments (see DESCRIPTION above).

.OUTPUTS
    Microsoft.Graph.PowerShell.Authentication.AuthContext
    The connected Graph context object. Capture this for use by downstream scripts.

.EXAMPLE
    # Interactive browser (default) — browser popup will open
    $ctx = .\Connect-EntraAdmin.ps1 -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

.EXAMPLE
    # Device code flow — recommended for this environment
    $ctx = .\Connect-EntraAdmin.ps1 -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -UseDeviceCode

.NOTES
    Module  : Microsoft.Graph.Authentication (install via: Install-Module Microsoft.Graph -Scope CurrentUser)
    Min PS  : 5.1  (7.x recommended)
    Scopes  : Application.Read.All
              — sufficient for all service principal enumeration in this toolset.
              Additional scopes can be added to the $Scopes array below if needed.

    Auth flow (what happens after you run this):
      1. PowerShell opens a browser popup OR prints a device code URL + code
      2. You sign in with your admin UPN and CyberArk password
      3. Entra detects your domain is federated, redirects to Okta automatically
      4. Okta Verify sends a Face ID push to your iPhone — approve it
      5. Token is returned to this session; script confirms the connected account
#>

#Requires -Version 5.1

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true,
               HelpMessage = 'Entra tenant ID (GUID). Find it in Entra admin center > Overview.')]
    [ValidateNotNullOrEmpty()]
    [string] $TenantId,

    [Parameter(Mandatory = $false)]
    [switch] $UseDeviceCode
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Scopes requested for this session.
# Application.Read.All covers all service principal and app registration reads
# needed for the credential inventory toolset (Module 2).
$Scopes = @('Application.Read.All')

# ============================================================================
# 1. MODULE CHECK
# ============================================================================
# Ensure the required authentication module is available before doing anything.
# We do not auto-install — that decision belongs to the operator.

# Resolve the user-level module path in a way that handles OneDrive document
# redirection (common on managed workstations) and PS 5.1 vs 7.x path differences.
$psSubfolder    = if ($PSVersionTable.PSVersion.Major -ge 6) { 'PowerShell' } else { 'WindowsPowerShell' }
$userModulePath = Join-Path ([System.Environment]::GetFolderPath('MyDocuments')) "$psSubfolder\Modules"

if ($userModulePath -notin ($env:PSModulePath -split [System.IO.Path]::PathSeparator)) {
    $env:PSModulePath = $userModulePath + [System.IO.Path]::PathSeparator + $env:PSModulePath
}

if (-not (Get-Module -Name 'Microsoft.Graph.Authentication' -ListAvailable)) {
    Write-Error @"

Module 'Microsoft.Graph.Authentication' is not installed.
Install it with:
    Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery

Then re-run this script.
"@
    return $null
}

# Explicit import — does not rely on PowerShell auto-loading, which can behave
# inconsistently across PS 5.1 sessions.
Import-Module Microsoft.Graph.Authentication -ErrorAction Stop

Write-Host "Module loaded: Microsoft.Graph.Authentication" -ForegroundColor Green

# ============================================================================
# 2. CLEAR ANY EXISTING GRAPH SESSION
# ============================================================================
# If Connect-MgGraph was called earlier in this same PowerShell process, MSAL
# holds a cached token in memory. Disconnecting ensures we start with a clean
# auth context rather than silently reusing a prior session.

$existingContext = Get-MgContext

if ($null -ne $existingContext) {
    Write-Host ""
    Write-Host "Existing Graph session detected:" -ForegroundColor Yellow
    Write-Host "  Account  : $($existingContext.Account)" -ForegroundColor Yellow
    Write-Host "  Tenant   : $($existingContext.TenantId)" -ForegroundColor Yellow
    Write-Host "Disconnecting before re-authenticating..." -ForegroundColor Yellow
    Disconnect-MgGraph | Out-Null
    Write-Host "Disconnected." -ForegroundColor Yellow
}

# ============================================================================
# 3. PROMPT FOR ADMIN UPN
# ============================================================================
# The UPN is collected before auth for two purposes:
#   (a) Displayed back so the operator can confirm they typed the right account
#       before the browser/device code flow launches.
#   (b) Compared against the connected account after auth to detect if a wrong
#       or cached account was used instead of the intended admin account.
#
# NOTE: The UPN is NOT passed to Connect-MgGraph — the SDK's UserParameterSet
# does not support a -LoginHint or -Username parameter. Authentication happens
# interactively in the browser or at microsoft.com/devicelogin, where the
# operator enters their credentials directly.

Write-Host ""
$adminUpn = Read-Host "Admin account UPN"

if ([string]::IsNullOrWhiteSpace($adminUpn)) {
    Write-Error "UPN cannot be empty. Exiting."
    return $null
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Target account  : $adminUpn"                    -ForegroundColor Cyan
Write-Host "  Target tenant   : $TenantId"                    -ForegroundColor Cyan
Write-Host "  Auth flow       : $(if ($UseDeviceCode) { 'Device code  (open browser to microsoft.com/devicelogin)' } else { 'Interactive browser popup' })" -ForegroundColor Cyan
Write-Host "  Scopes          : $($Scopes -join ', ')"        -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

if ($UseDeviceCode) {
    Write-Host "A code and URL will appear below." -ForegroundColor White
    Write-Host "Open the URL in your incognito browser window, enter the code, then" -ForegroundColor White
    Write-Host "sign in with the account shown above and complete Okta MFA." -ForegroundColor White
} else {
    Write-Host "A browser window will open for sign-in." -ForegroundColor White
    Write-Host "If an account picker appears, select: $adminUpn" -ForegroundColor White
    Write-Host "Then complete Okta MFA when prompted." -ForegroundColor White
}

Write-Host ""

# ============================================================================
# 4. AUTHENTICATE
# ============================================================================
#
# WHY DEVICE CODE FLOW IS ALWAYS USED — DO NOT CHANGE TO INTERACTIVE BROWSER
# ---------------------------------------------------------------------------
# On Windows 10+, the Microsoft Graph PowerShell SDK enables Web Account
# Manager (WAM) by default. WAM is an OS-level authentication broker that
# intercepts the interactive browser auth flow and injects the currently
# active Windows session identity (the regular non-admin account) regardless
# of which admin UPN was entered above.
#
# Set-MgGraphOption -EnableLoginByWAM $false is documented in SDK examples
# but does NOT reliably suppress WAM on current SDK versions. Do not add it.
#
# Device code flow (-UseDeviceCode) bypasses WAM entirely. MSAL prints a URL
# and a one-time code to the terminal; the operator completes authentication
# in any browser tab at microsoft.com/devicelogin. WAM has no involvement in
# this path — explicit account selection is always presented.
#
# -TenantId must still be passed alongside -UseDeviceCode. Without it, MSAL
# targets the 'common' endpoint and may authenticate to the wrong tenant when
# the admin account has access to multiple tenants (e.g., QA vs. Production).
#
# Other parameter notes:
#   -Scopes              Requested delegated permissions. MSAL presents a
#                        consent prompt if the tenant admin has not pre-consented;
#                        for admin accounts this is usually pre-consented for the
#                        Microsoft Graph PowerShell enterprise app.
#   -ContextScope Process  Prevents loading cached tokens from the regular
#                          account's on-disk CurrentUser token cache, and
#                          prevents writing admin tokens back to that cache.
#   -NoWelcome           Suppresses the "Welcome To Microsoft Graph!" banner.
#                        Requires Microsoft.Graph.Authentication >= 1.22.0.
#                        Remove this line if you are on an older SDK version.
#
# Note: the -UseDeviceCode switch parameter is preserved in the script
# signature for clarity, but its value is not read here — device code is
# always forced. Passing -UseDeviceCode on the command line is a no-op.

Write-Host "--- Sign-in steps ---" -ForegroundColor White
Write-Host ""
Write-Host "  1. A one-time code will appear in this terminal in a moment."           -ForegroundColor White
Write-Host "  2. Open an incognito browser tab and navigate to:"                      -ForegroundColor White
Write-Host "       https://microsoft.com/devicelogin"                                 -ForegroundColor Cyan
Write-Host "  3. Enter the code exactly as shown (codes are case-sensitive)."         -ForegroundColor White
Write-Host "  4. When prompted to choose an account, sign in as:"                     -ForegroundColor White
Write-Host "       $adminUpn"                                                         -ForegroundColor Cyan
Write-Host "  5. Enter your CyberArk password at the password prompt."                -ForegroundColor White
Write-Host "  6. Entra will redirect to Okta automatically — do not close the tab."   -ForegroundColor White
Write-Host "  7. Approve the Okta Verify push notification on your iPhone (Face ID)." -ForegroundColor White
Write-Host "  8. Once the browser confirms sign-in, return here."                     -ForegroundColor White
Write-Host ""

$connectParams = @{
    Scopes        = $Scopes
    TenantId      = $TenantId
    ContextScope  = 'Process'
    UseDeviceCode = $true       # Always forced — WAM bypass. See comment block above.
    NoWelcome     = $true
    ErrorAction   = 'Stop'
}

try {
    Connect-MgGraph @connectParams
}
catch {
    Write-Host ""
    Write-Host "Authentication failed." -ForegroundColor Red
    Write-Host "Error: $_"             -ForegroundColor Red
    Write-Host ""
    Write-Host "Common causes:"                                                           -ForegroundColor Yellow
    Write-Host "  - MFA prompt timed out or was denied on Okta Verify"                   -ForegroundColor Yellow
    Write-Host "  - Device code page was closed before completing sign-in"               -ForegroundColor Yellow
    Write-Host "  - Tenant ID is incorrect (check Entra admin center > Overview)"        -ForegroundColor Yellow
    Write-Host "  - Admin consent has not been granted for the Microsoft Graph PS app"   -ForegroundColor Yellow
    return $null
}

# ============================================================================
# 5. VALIDATE AND CONFIRM
# ============================================================================
# Retrieve the context MSAL established and confirm:
#   (a) A context was actually returned (defensive — Connect-MgGraph should
#       throw on failure, but guard against a silent no-op just in case).
#   (b) The connected account UPN matches what the operator entered.
#       A mismatch means a cached or SSO session for a different account slipped
#       through despite -ContextScope Process. Operator should be warned and can
#       decide whether to continue or disconnect and retry.

$context = Get-MgContext

if ($null -eq $context) {
    Write-Host ""
    Write-Host "ERROR: Connect-MgGraph completed but returned no context." -ForegroundColor Red
    Write-Host "Authentication may have failed silently. Exiting."         -ForegroundColor Red
    return $null
}

$accountMatches = ($context.Account -ieq $adminUpn)

Write-Host ""
Write-Host "=================================================" -ForegroundColor Green
Write-Host "  Graph Connection Established"                    -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host "  Account   : $($context.Account)"
Write-Host "  Tenant ID : $($context.TenantId)"
Write-Host "  Auth type : $($context.AuthType)"
Write-Host "  Scopes    : $($context.Scopes -join ', ')"
Write-Host "=================================================" -ForegroundColor Green

if (-not $accountMatches) {
    Write-Host ""
    Write-Warning @"
ACCOUNT MISMATCH
  Expected : $adminUpn
  Connected: $($context.Account)

A different account authenticated — possibly via a cached or SSO session.
If this is not the intended admin account:
  1. Run: Disconnect-MgGraph
  2. Re-run this script with -UseDeviceCode to force a fresh credential prompt
     and authenticate in your incognito browser window.
"@
}

Write-Host ""

# ============================================================================
# 6. RETURN CONTEXT
# ============================================================================
# Return the context object so downstream scripts (e.g. Get-EntraAppCredentials)
# can consume an already-established session without re-authenticating.
# The caller should check for $null to detect a failed auth:
#
#   $ctx = .\Connect-EntraAdmin.ps1 -TenantId "..." -UseDeviceCode
#   if ($null -eq $ctx) { Write-Error "Auth failed"; return }

return $context
