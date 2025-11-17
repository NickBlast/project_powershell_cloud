<#!
.SYNOPSIS
    Export Entra applications and service principals.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

$ErrorActionPreference = 'Stop'

Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

$toolVersion = '0.3.0'
$datasetName = 'entra_apps_service_principals'

Write-StructuredLog -Level Info -Message 'Starting Entra app and service principal export.'
$context = Connect-EntraTestTenant

$applications = Invoke-WithRetry -ScriptBlock { Get-MgApplication -All }
$servicePrincipals = Invoke-WithRetry -ScriptBlock { Get-MgServicePrincipal -All }

$records = @()
foreach ($app in $applications) {
    $sp = $servicePrincipals | Where-Object { $_.AppId -eq $app.AppId } | Select-Object -First 1
    $records += [pscustomobject]@{
        app_id            = $app.AppId
        app_object_id     = $app.Id
        app_display_name  = $app.DisplayName
        sp_object_id      = $sp.Id
        sp_display_name   = $sp.DisplayName
        sign_in_audience  = $app.SignInAudience
    }
}

Write-StructuredLog -Level Info -Message "Captured $($records.Count) applications" -Context @{ dataset_name = $datasetName }
Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
