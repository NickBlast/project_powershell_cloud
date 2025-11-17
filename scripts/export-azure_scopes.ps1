<#
.SYNOPSIS
    Exports Azure scope hierarchy (management groups, subscriptions, resource groups).
.DESCRIPTION
    Connects with the centralized test tenant credentials and writes outputs/azure/azure_scopes.csv.
.PARAMETER OutputPath
    Target directory for export files. Defaults to './outputs/azure'.
.EXAMPLE
    pwsh -NoProfile -File ./scripts/export-azure_scopes.ps1
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/azure')
)

$ErrorActionPreference = 'Stop'
$VerbosePreference = $PSBoundParameters.Verbose.IsPresent ? 'Continue' : 'SilentlyContinue'

Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psm1
Import-Module $PSScriptRoot/../modules/logging/Logging.psm1
Import-Module $PSScriptRoot/../modules/export/Export.psm1

$ToolVersion = '0.3.0'
$DatasetName = 'azure_scopes'

$context = Connect-EntraTestTenant
Write-ExportLogStart -Name $DatasetName -TenantId $context.TenantId -SubscriptionId $context.SubscriptionId

$allScopes = [System.Collections.Generic.List[pscustomobject]]::new()

$managementGroups = Get-AzManagementGroup
foreach ($mg in $managementGroups) {
    $allScopes.Add([pscustomobject]@{
        Type     = 'ManagementGroup'
        Id       = $mg.Id
        Name     = $mg.Name
        ParentId = $mg.ParentId
    })
}

$subscriptions = Get-AzSubscription
foreach ($sub in $subscriptions) {
    $allScopes.Add([pscustomobject]@{
        Type     = 'Subscription'
        Id       = $sub.Id
        Name     = $sub.Name
        ParentId = $sub.ManagementGroupId
        State    = $sub.State
    })
}

foreach ($sub in $subscriptions | Where-Object { $_.State -eq 'Enabled' }) {
    Set-AzContext -Subscription $sub.Id | Out-Null
    $resourceGroups = Get-AzResourceGroup
    foreach ($rg in $resourceGroups) {
        $allScopes.Add([pscustomobject]@{
            Type      = 'ResourceGroup'
            Id        = $rg.ResourceId
            Name      = $rg.ResourceGroupName
            ParentId  = $sub.Id
            Location  = $rg.Location
        })
    }
}

Write-StructuredLog -Level Info -Message "Found $($allScopes.Count) total Azure scopes" -Context @{ correlation_id = (Get-CorrelationId) }

Write-Export -DatasetName $DatasetName -Objects $allScopes -OutputPath $OutputPath -Formats 'csv' -ToolVersion $ToolVersion

Write-ExportLogResult -Name $DatasetName -Success $true -OutputPath (Join-Path -Path $OutputPath -ChildPath "$DatasetName.csv") -RowCount $allScopes.Count -Message 'Completed'
