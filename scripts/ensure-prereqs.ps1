#requires -Version 7.4
<#
.SYNOPSIS
    Ensures all prerequisites for the PowerShell IAM Inventory project are met.
.DESCRIPTION
    This script verifies the PowerShell environment, installs required modules with pinned versions,
    and runs a quality check using PSScriptAnalyzer. Analyzer warnings are treated as errors to keep
    repository hygiene aligned with project guardrails.

    Key actions:
    1. Verifies PowerShell version is 7.4 or higher.
    2. Ensures Microsoft.PowerShell.PSResourceGet is installed and imported.
    3. Installs or updates required modules to pinned versions in the CurrentUser scope.
    4. Normalizes the PSModulePath to prioritize the CurrentUser scope.
    5. Runs PSScriptAnalyzer on the entire repository.
    6. Emits a JSON report of the analysis to './examples/prereq_report.json'.
    7. Exits with a non-zero code if PSScriptAnalyzer finds warnings or errors.
.PARAMETER WhatIf
    Shows what actions would be taken without actually executing them.
.PARAMETER Quiet
    Suppresses informational output. Errors are still written, and the JSON report is produced.
.EXAMPLE
    PS> ./scripts/ensure-prereqs.ps1
    Runs the full prerequisite check, displaying informational output.
.EXAMPLE
    PS> ./scripts/ensure-prereqs.ps1 -WhatIf
    Displays the modules that would be installed or updated without making changes.
.EXAMPLE
    PS> ./scripts/ensure-prereqs.ps1 -Quiet
    Runs the check with minimal output, useful for automated scripts.
.NOTES
    Author: Gemini
    License: See LICENSE file.
    Version: 1.1.0
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Switch]$Quiet
)

#region Setup and Configuration
Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($Quiet) { 'SilentlyContinue' } else { 'Continue' }
$InformationPreference = if ($Quiet) { 'SilentlyContinue' } else { 'Continue' }

$requiredPSVersion = [Version]'7.4.0'
$psResourceModuleName = 'Microsoft.PowerShell.PSResourceGet'
$psResourceModuleVersion = [Version]'1.0.5'

$requiredModules = @(
    @{ Name = 'Az.Accounts'; Version = '2.12.1' }
    @{ Name = 'Az.Resources'; Version = '6.6.0' }
    @{ Name = 'ImportExcel'; Version = '7.8.5' }
    @{ Name = 'PSScriptAnalyzer'; Version = '1.21.0' }
    @{ Name = 'Pester'; Version = '5.5.0' }
    @{ Name = 'Microsoft.PowerShell.SecretManagement'; Version = '1.1.2' }
    @{ Name = 'Microsoft.Graph'; Version = '2.9.0' }
)

$repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$examplesDir = Join-Path -Path $repoRoot -ChildPath 'examples'
$reportPath = Join-Path -Path $examplesDir -ChildPath 'prereq_report.json'

function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Information $Message
    Write-Verbose $Message
}
#endregion

#region 1. PowerShell Version Check
Write-Step "Step 1: Verifying PowerShell version..."
Write-Verbose "Required version: $requiredPSVersion or higher."
Write-Verbose "Detected version: $($PSVersionTable.PSVersion)"

if ($PSVersionTable.PSVersion -lt $requiredPSVersion) {
    Write-Error "PowerShell version $($PSVersionTable.PSVersion) is not supported. Please upgrade to version $requiredPSVersion or higher."
    exit 1
}
Write-Step "[OK] PowerShell version check passed."
#endregion

#region 2. PSResourceGet Check
Write-Step "`nStep 2: Verifying $psResourceModuleName..."

try {
    $psResourceGetModule = Get-Module -Name $psResourceModuleName -ListAvailable |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    if (-not $psResourceGetModule -or $psResourceGetModule.Version -lt $psResourceModuleVersion) {
        Write-Step "PSResourceGet not found or below version $psResourceModuleVersion. Installing..."
        if ($PSCmdlet.ShouldProcess($psResourceModuleName, "Install version $psResourceModuleVersion")) {
            Install-Module -Name $psResourceModuleName -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -RequiredVersion $psResourceModuleVersion | Out-Null
        }
    }

    Import-Module -Name $psResourceModuleName -MinimumVersion $psResourceModuleVersion -ErrorAction Stop | Out-Null
    $psResourceGetModule = Get-Module -Name $psResourceModuleName
    Write-Step "[OK] $psResourceModuleName version $($psResourceGetModule.Version) is available."
}
catch {
    Write-Error "Failed to find, install, or import $psResourceModuleName. $_"
    exit 1
}
#endregion

#region 3. Install/Upgrade Modules
Write-Step "`nStep 3: Installing/updating required modules..."
foreach ($module in $requiredModules) {
    $moduleName = $module.Name
    $requiredVersion = [Version]$module.Version
    Write-Verbose "Checking module: $moduleName (required version: $requiredVersion)"

    $installedModule = Get-InstalledPSResource -Name $moduleName -ErrorAction SilentlyContinue |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    if ($installedModule -and [Version]$installedModule.Version -eq $requiredVersion) {
        Write-Step "  - $moduleName ($($installedModule.Version)) already installed."
        continue
    }

    $actionMessage = if ($installedModule) {
        "Update $moduleName from $($installedModule.Version) to $requiredVersion"
    }
    else {
        "Install $moduleName version $requiredVersion"
    }

    if ($PSCmdlet.ShouldProcess($moduleName, $actionMessage)) {
        try {
            Install-PSResource -Name $moduleName -Version $requiredVersion -Repository PSGallery -Scope CurrentUser -AcceptLicense -ErrorAction Stop | Out-Null
            Write-Step "  [OK] $actionMessage completed."
        }
        catch {
            Write-Error "Failed to install $moduleName version $requiredVersion. $_"
            exit 1
        }
    }
}
#endregion

#region 4. Normalize PSModulePath
Write-Step "`nStep 4: Normalizing PSModulePath..."
$currentUserPath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'WindowsPowerShell\Modules'
if ($IsCoreCLR) {
    $currentUserPath = Join-Path -Path ([Environment]::GetFolderPath('MyDocuments')) -ChildPath 'PowerShell\Modules'
}

$modulePaths = $env:PSModulePath -split [System.IO.Path]::PathSeparator
if (-not $modulePaths -or $modulePaths[0] -ne $currentUserPath) {
    Write-Verbose "CurrentUser module path is not prioritized. Adjusting..."
    $dedupedPaths = $modulePaths | Where-Object { $_ -and $_ -ne $currentUserPath }
    $env:PSModulePath = ($currentUserPath, $dedupedPaths) -join [System.IO.Path]::PathSeparator
    Write-Step "[OK] PSModulePath normalized to prioritize CurrentUser."
}
else {
    Write-Step "[OK] PSModulePath already prioritizes CurrentUser."
}
#endregion

#region 5. Run PSScriptAnalyzer
Write-Step "`nStep 5: Running PSScriptAnalyzer..."
if (-not (Test-Path -Path $examplesDir)) {
    if ($PSCmdlet.ShouldProcess($examplesDir, 'Create Directory')) {
        New-Item -Path $examplesDir -ItemType Directory -Force | Out-Null
        Write-Verbose "Created directory: $examplesDir"
    }
}

$analyzerResults = Invoke-ScriptAnalyzer -Path $repoRoot -Recurse
if ($PSCmdlet.ShouldProcess($reportPath, 'Generate PSScriptAnalyzer Report')) {
    $analyzerResults | ConvertTo-Json -Depth 6 | Out-File -FilePath $reportPath -Encoding utf8
    Write-Step "[OK] PSScriptAnalyzer report saved to: $reportPath"
}

if (-not $Quiet) {
    $errors = @($analyzerResults | Where-Object { $_.Severity -eq 'Error' })
    $warnings = @($analyzerResults | Where-Object { $_.Severity -eq 'Warning' })
    $info = @($analyzerResults | Where-Object { $_.Severity -eq 'Information' })

    Write-Information "`n[PSScriptAnalyzer Summary]"
    Write-Information "  Total Issues: $($analyzerResults.Count)"
    Write-Information "  - Errors: $($errors.Count)"
    Write-Information "  - Warnings: $($warnings.Count)"
    Write-Information "  - Information: $($info.Count)"

    if ($errors.Count -gt 0) {
        Write-Information "`nErrors:"
        $errors | ForEach-Object { Write-Information "  - $($_.ScriptName):$($_.Line): $($_.Message)" }
    }

    if ($warnings.Count -gt 0) {
        Write-Information "`nWarnings:"
        $warnings | ForEach-Object { Write-Information "  - $($_.ScriptName):$($_.Line): $($_.Message)" }
    }
}
#endregion

#region 6. Exit Code
$blockingFindings = $analyzerResults | Where-Object { $_.Severity -in @('Error', 'Warning') }
if ($blockingFindings.Count -gt 0) {
    Write-Error "`nPSScriptAnalyzer found blocking issues (warnings are treated as errors). Please review the report and fix them."
    exit 1
}

Write-Step "`n[OK] Prerequisite check completed successfully."
#endregion
