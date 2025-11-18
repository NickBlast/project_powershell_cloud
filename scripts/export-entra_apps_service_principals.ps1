<#!
.SYNOPSIS
    Export Entra applications and service principals.
.DESCRIPTION
    Connects to the Entra test tenant, retrieves all applications and service principals with retry
    protection, links each app to its corresponding service principal, and writes flattened records
    to CSV and JSON using the shared export module to keep metadata consistent.
.PARAMETER OutputPath
    Destination directory for export artifacts. Defaults to outputs/entra under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

function Invoke-ScriptMain {
    # Fail fast on any errors to avoid silent data loss.
    $ErrorActionPreference = 'Stop'

    # Dataset metadata applied to every output for traceability.
    $toolVersion = '0.3.0'
    $datasetName = 'entra_apps_service_principals'

    # Connect to the test tenant and log the workflow start.
    Write-StructuredLog -Level Info -Message 'Starting Entra app and service principal export.'
    $context = Connect-EntraTestTenant

    # Pull all applications and service principals with retry/backoff to survive transient failures.
    $applications = Invoke-WithRetry -ScriptBlock { Get-MgApplication -All }
    $servicePrincipals = Invoke-WithRetry -ScriptBlock { Get-MgServicePrincipal -All }

    # Correlate each application to its service principal so the export has both identifiers and display names.
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

    # Persist the flattened dataset in CSV and JSON formats with standard headers.
    Write-Export -DatasetName $datasetName -Objects $records -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
}

$runResult = Invoke-WithRunLogging -ScriptName $scriptName -ScriptBlock { Invoke-ScriptMain }

if ($runResult.Succeeded) {
    Write-Output "Execution complete. Log: $($runResult.RelativeLogPath)"
} else {
    Write-Output "Errors detected. Check log: $($runResult.RelativeLogPath)"
    exit 1
}
