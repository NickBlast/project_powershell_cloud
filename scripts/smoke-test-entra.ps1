#requires -Version 7.4
<#!
.SYNOPSIS
    Runs a non-destructive smoke test for the Entra connection module.
.DESCRIPTION
    This script ensures repository prerequisites are installed, imports the entra_connection module,
    and optionally invokes Connect-EntraTenant. By default the script only runs ensure-prereqs.ps1 and
    requires the -Connect switch before attempting to authenticate so operators can review the tenant
    parameters first. Provide either -TenantId or -Label (when the catalog contains multiple tenants)
    along with the desired authentication modes.

    Example workflow from the repository root:
        pwsh -File ./scripts/smoke-test-entra.ps1 -Connect -TenantId <tenant-guid>
        pwsh -File ./scripts/smoke-test-entra.ps1 -Connect -Label 'production' -GraphAuthMode DeviceCode -SkipAzure

    Remove the -WhatIf flag from ensure-prereqs.ps1 when you are ready to install/update modules instead
    of previewing the operations.
.PARAMETER TenantId
    Tenant GUID to connect. Either TenantId or Label must be supplied when more than one tenant exists.
.PARAMETER Label
    Friendly name from ./.config/tenants.json identifying the tenant to connect.
.PARAMETER GraphAuthMode
    Authentication mode for Microsoft Graph. Defaults to DeviceCode.
.PARAMETER AzureAuthMode
    Authentication mode for Azure Resource Manager. Defaults to DeviceCode.
.PARAMETER GraphClientId
    Application (client) ID used when GraphAuthMode is ServicePrincipal.
.PARAMETER GraphVaultName
    SecretManagement vault containing the Microsoft Graph client secret.
.PARAMETER GraphSecretName
    Secret name for the Microsoft Graph client secret.
.PARAMETER AzureClientId
    Application (client) ID for Azure service principal authentication. Defaults to GraphClientId when omitted.
.PARAMETER AzureVaultName
    SecretManagement vault for Azure credentials. Defaults to GraphVaultName when omitted.
.PARAMETER AzureSecretName
    Secret name for the Azure service principal credential. Defaults to GraphSecretName when omitted.
.PARAMETER SkipAzure
    Skips Azure Resource Manager authentication while still validating the Microsoft Graph connection.
.PARAMETER Connect
    Executes Connect-EntraTenant using the provided parameters. Without this switch the script only runs
    ensure-prereqs.ps1 and displays instructions.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$TenantId,
    [Parameter(Mandatory = $false)]
    [string]$Label,
    [Parameter(Mandatory = $false)]
    [ValidateSet('DeviceCode', 'ServicePrincipal')]
    [string]$GraphAuthMode = 'DeviceCode',
    [Parameter(Mandatory = $false)]
    [ValidateSet('DeviceCode', 'ServicePrincipal')]
    [string]$AzureAuthMode = 'DeviceCode',
    [Parameter(Mandatory = $false)]
    [string]$GraphClientId,
    [Parameter(Mandatory = $false)]
    [string]$GraphVaultName,
    [Parameter(Mandatory = $false)]
    [string]$GraphSecretName,
    [Parameter(Mandatory = $false)]
    [string]$AzureClientId,
    [Parameter(Mandatory = $false)]
    [string]$AzureVaultName,
    [Parameter(Mandatory = $false)]
    [string]$AzureSecretName,
    [switch]$SkipAzure,
    [switch]$Connect
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

$repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$ensurePrereqs = Join-Path -Path $repoRoot -ChildPath 'scripts/ensure-prereqs.ps1'
$moduleManifest = Join-Path -Path $repoRoot -ChildPath 'modules/entra_connection/entra_connection.psd1'

Write-Information 'Running prerequisite validation (WhatIf)...'
& $ensurePrereqs -WhatIf

if (-not $Connect) {
    Write-Information 'Prerequisites validated. Re-run with -Connect after reviewing tenant parameters.'
    return
}

Write-Information 'Importing entra_connection module...'
Import-Module -Name $moduleManifest -Force

$connectParameters = @{}
if ($TenantId) { $connectParameters.TenantId = $TenantId }
if ($Label) { $connectParameters.Label = $Label }
$connectParameters.GraphAuthMode = $GraphAuthMode
$connectParameters.AzureAuthMode = $AzureAuthMode
if ($GraphClientId) { $connectParameters.GraphClientId = $GraphClientId }
if ($GraphVaultName) { $connectParameters.GraphVaultName = $GraphVaultName }
if ($GraphSecretName) { $connectParameters.GraphSecretName = $GraphSecretName }
if ($AzureClientId) { $connectParameters.AzureClientId = $AzureClientId }
if ($AzureVaultName) { $connectParameters.AzureVaultName = $AzureVaultName }
if ($AzureSecretName) { $connectParameters.AzureSecretName = $AzureSecretName }
if ($SkipAzure) { $connectParameters.SkipAzure = $true }

Write-Information 'Connecting via Connect-EntraTenant...'
$result = Connect-EntraTenant @connectParameters

$result | ConvertTo-Json -Depth 6

if (-not $result.Success) {
    Write-Warning 'Connect-EntraTenant reported one or more issues. Review the JSON output for details.'
}
