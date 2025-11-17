<#!
.SYNOPSIS
    Export Azure subscription scope details for reference.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/azure')
)

$ErrorActionPreference = 'Stop'

Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

$toolVersion = '0.3.0'
$datasetName = 'azure_subscriptions'

Write-StructuredLog -Level Info -Message 'Starting Azure subscription export.'
$context = Connect-EntraTestTenant -ConnectAzure

$subscriptions = Get-AzSubscription
$records = foreach ($sub in $subscriptions) {
    [pscustomobject]@{
        subscription_id   = $sub.Id
        subscription_name = $sub.Name
        tenant_id         = $sub.TenantId
        state             = $sub.State
    }
}

Write-StructuredLog -Level Info -Message "Captured $($records.Count) subscriptions" -Context @{ dataset_name = $datasetName }
Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
