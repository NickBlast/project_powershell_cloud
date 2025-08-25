<#
.SYNOPSIS
    Exports Azure scope information: Management Groups, Subscriptions, and Resource Groups.
.DESCRIPTION
    This script connects to Azure and enumerates the full resource hierarchy.
    It captures parent-child relationships between Management Groups, Subscriptions, and Resource Groups.
.PARAMETER OutputPath
    The directory path where the export files will be saved. Defaults to './exports'.
.EXAMPLE
    PS> ./scripts/export-azure_scopes.ps1 -OutputPath .\my-azure-data -Verbose
.EXAMPLE
    PS> ./scripts/export-azure_scopes.ps1 -WhatIf
.NOTES
    Author: Repo automation
    Version: 1.0.0
    Supports -WhatIf via CmdletBinding(SupportsShouldProcess=$true).
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
$DatasetName = "azure_scopes"
# --------------------------

Write-Verbose "Starting Azure scopes export..."

# Connect to Azure
Connect-AzureContext -TenantId (Select-Tenant).tenant_id -AuthMode DeviceCode
Write-Verbose "Successfully connected to Azure."

$allScopes = [System.Collections.Generic.List[pscustomobject]]::new()

# Get Management Groups
Write-Verbose "Enumerating Management Groups..."
$mgs = Get-AzManagementGroup
foreach ($mg in $mgs) {
    $allScopes.Add([pscustomobject]@{
        Type = 'ManagementGroup'
        Id = $mg.Id
        Name = $mg.Name
        ParentId = $mg.ParentId
    })
}

# Get Subscriptions
Write-Verbose "Enumerating Subscriptions..."
$subs = Get-AzSubscription
foreach ($sub in $subs) {
    $allScopes.Add([pscustomobject]@{
        Type = 'Subscription'
        Id = $sub.Id
        Name = $sub.Name
        ParentId = $sub.ManagementGroupId
        State = $sub.State
    })
}

# Get Resource Groups
Write-Verbose "Enumerating Resource Groups..."
foreach ($sub in $subs | Where-Object { $_.State -eq 'Enabled' }) {
    Set-AzContext -Subscription $sub.Id | Out-Null
    $rgs = Get-AzResourceGroup
    foreach ($rg in $rgs) {
        $allScopes.Add([pscustomobject]@{
            Type = 'ResourceGroup'
            Id = $rg.ResourceId
            Name = $rg.ResourceGroupName
            ParentId = $sub.Id
            Location = $rg.Location
        })
    }
}

Write-Verbose "Found $($allScopes.Count) total scopes."

# Export the data
Write-Export -DatasetName $DatasetName -Objects $allScopes -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $ToolVersion

Write-Verbose "Azure scopes export completed."
