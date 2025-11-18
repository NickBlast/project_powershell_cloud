<#!
.SYNOPSIS
    Export Entra group memberships to outputs/entra.
.DESCRIPTION
    Connects to the test tenant using ENTRA_TEST_* credentials, enumerates every group and its members,
    flattens the relationships into a simple mapping, and writes CSV and JSON outputs with standard
    metadata fields for audit trails.
.PARAMETER OutputPath
    Destination directory for export artifacts. Defaults to outputs/entra under the repo root.
#>
[CmdletBinding()]
param(
    [string]$OutputPath = (Join-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..') -ChildPath 'outputs/entra')
)

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force

$scriptName = Split-Path -Path $PSCommandPath -Leaf

$scriptBlock = {
    Set-StrictMode -Version 3.0
    $ErrorActionPreference = 'Stop'

    Import-Module $PSScriptRoot/../modules/entra_connection/entra_connection.psd1 -Force
    Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force
    Import-Module $PSScriptRoot/../modules/export/export.psd1 -Force

    $toolVersion = '0.3.0'
    $datasetName = 'entra_group_memberships'

    Write-StructuredLog -Level Info -Message 'Starting Entra group membership export.'
    $context = Connect-EntraTestTenant

    $groups = Invoke-WithRetry -ScriptBlock { Get-MgGroup -All }
    $relationships = @()
    foreach ($group in $groups) {
        $members = Get-MgGroupMember -GroupId $group.Id -All -ErrorAction SilentlyContinue
        foreach ($member in $members) {
            $relationships += [pscustomobject]@{
                group_id    = $group.Id
                group_name  = $group.DisplayName
                member_id   = $member.Id
                member_type = $member.AdditionalProperties['@odata.type']
            }
        }
    }

    Write-StructuredLog -Level Info -Message "Captured $($relationships.Count) memberships" -Context @{ dataset_name = $datasetName }

    Write-Export -DatasetName $datasetName -Objects $relationships -OutputPath $OutputPath -Formats 'csv','json' -ToolVersion $toolVersion
}

Invoke-WithRunLog -ScriptName $scriptName -ScriptBlock $scriptBlock
