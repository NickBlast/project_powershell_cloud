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
    Author: Nick Lundquist
    License: See LICENSE file.
    Version: 1.1.0
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Switch]$Quiet
)

$scriptName = [System.IO.Path]::GetFileNameWithoutExtension($PSCommandPath)

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force

$runContext = Start-RunLog -ScriptName $scriptName -ScriptVersion '1.1.0'

function Invoke-ScriptMain {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [switch]$Quiet,
        [pscustomobject]$RunContext
    )

    #region Setup and Configuration
    # Establish strict runtime settings, version pins, and directories so every run behaves exactly the same.
    Set-StrictMode -Version 3.0
    $ErrorActionPreference = 'Stop'
    $VerbosePreference = if ($Quiet) { 'SilentlyContinue' } else { 'Continue' }
    $InformationPreference = if ($Quiet) { 'SilentlyContinue' } else { 'Continue' }

$requiredPSVersion = [Version]'7.4.0'
$psResourceModuleName = 'Microsoft.PowerShell.PSResourceGet'
$psResourceModuleVersion = [Version]'1.0.5'

$requiredModules = @(
    @{ Name = 'Az.Accounts'; MinimumVersion = '2.12.1' }
    @{ Name = 'Az.Resources'; MinimumVersion = '6.6.0' }
    @{ Name = 'ImportExcel'; MinimumVersion = '7.8.5' }
    @{ Name = 'PSScriptAnalyzer'; MinimumVersion = '1.21.0' }
    @{ Name = 'Pester'; MinimumVersion = '5.5.0' }
    @{ Name = 'Microsoft.PowerShell.SecretManagement'; MinimumVersion = '1.1.2' }
    @{ Name = 'Microsoft.Graph'; MinimumVersion = '2.9.0' }
    @{ Name = 'Microsoft.Graph.Entra'; MinimumVersion = '2.9.0' }
)

    Write-RunLog -Context $RunContext -Level Info -Message 'Starting prerequisite validation.' -Metadata @{ modules_target = $requiredModules.Count }

$repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$examplesDir = Join-Path -Path $repoRoot -ChildPath 'examples'
$reportPath = Join-Path -Path $examplesDir -ChildPath 'prereq_report.json'
$excludedAnalyzerDirectories = @('.git', '.archive', 'examples', 'logs', 'outputs', 'reports')
$moduleInstallSummary = [ordered]@{
        evaluated = $requiredModules.Count
        installed = 0
        skipped   = 0
    }

# Write-Step keeps operator-facing progress messages consistent even when Quiet/Verbose settings change.
function Write-Step {
    param(
        [Parameter(Mandatory)]
        [string]$Message
    )

    Write-Information $Message
    Write-Verbose $Message
}
#endregion

#region Helper Functions
# Encapsulated helpers keep the main steps terse and guarantee consistent behavior across platforms.
function Get-CurrentUserModulePath {
    <#
        .SYNOPSIS
            Resolves the CurrentUser module installation path without assuming MyDocuments is populated.

        .DESCRIPTION
            PowerShell normally stores CurrentUser modules under a directory derived from the user's
            Documents folder.  In containerized Linux environments, [Environment]::GetFolderPath('MyDocuments')
            can return an empty string which causes Join-Path to throw.  This helper centralizes the
            resolution logic and provides OS-specific fallbacks that align with the defaults documented in
            about_PSModulePath.
    #>

    $documentsPath = [Environment]::GetFolderPath('MyDocuments')
    if (-not [string]::IsNullOrWhiteSpace($documentsPath)) {
        $moduleRootName = if ($IsCoreCLR) { 'PowerShell' } else { 'WindowsPowerShell' }
        $documentsModuleRoot = Join-Path -Path $documentsPath -ChildPath $moduleRootName
        return Join-Path -Path $documentsModuleRoot -ChildPath 'Modules'
    }

    $homePath = $HOME
    if ([string]::IsNullOrWhiteSpace($homePath)) {
        throw "Unable to resolve the CurrentUser module path because neither MyDocuments nor HOME are defined."
    }

    if ($IsWindows) {
        $moduleRootName = if ($IsCoreCLR) { 'PowerShell' } else { 'WindowsPowerShell' }
        return [System.IO.Path]::Combine($homePath, 'Documents', $moduleRootName, 'Modules')
    }

    return [System.IO.Path]::Combine($homePath, '.local', 'share', 'powershell', 'Modules')
}

# Determines whether a path should be skipped when running ScriptAnalyzer so we do not lint generated folders.
function Test-IsExcludedAnalyzerPath {
    param(
        [Parameter(Mandatory)]
        [string]$FullPath
    )

    $relativePath = [System.IO.Path]::GetRelativePath($repoRoot, $FullPath)
    if (-not $relativePath -or $relativePath -eq '.' -or $relativePath.StartsWith('..')) {
        return $false
    }

    $relativeSegments = $relativePath -split '[\\/]' | Where-Object { $_ }
    if (-not $relativeSegments) {
        return $false
    }

    return $relativeSegments[0] -in $excludedAnalyzerDirectories
}
#endregion

#region 1. PowerShell Version Check
# We fail fast if someone runs an older shell so the rest of the install process does not waste time.
Write-Step "Step 1: Verifying PowerShell version..."
Write-Verbose "Required version: $requiredPSVersion or higher."
Write-Verbose "Detected version: $($PSVersionTable.PSVersion)"

Write-RunLog -Context $RunContext -Level Info -Message "Checking PowerShell version $($PSVersionTable.PSVersion) against minimum $requiredPSVersion."

if ($PSVersionTable.PSVersion -lt $requiredPSVersion) {
    Write-Error "PowerShell version $($PSVersionTable.PSVersion) is not supported. Please upgrade to version $requiredPSVersion or higher."
    Write-RunLog -Context $RunContext -Level Error -Message "PowerShell version $($PSVersionTable.PSVersion) below requirement." -Metadata @{ required = $requiredPSVersion.ToString() }
    throw "PowerShell version $($PSVersionTable.PSVersion) is below the required $requiredPSVersion."
}
Write-Step "[OK] PowerShell version check passed."
Write-RunLog -Context $RunContext -Level Info -Message "PowerShell version requirement satisfied." -Metadata @{ detected_version = $PSVersionTable.PSVersion.ToString() }
#endregion

#region 2. PSResourceGet Check
# Verifies PSResourceGet is present at the pinned version because every later module install depends on it.
Write-Step "`nStep 2: Verifying $psResourceModuleName..."
Write-RunLog -Context $RunContext -Level Info -Message "Validating $psResourceModuleName presence." -Metadata @{ required_version = $psResourceModuleVersion.ToString() }

try {
    $psResourceGetModule = Get-Module -Name $psResourceModuleName -ListAvailable |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    if (-not $psResourceGetModule -or $psResourceGetModule.Version -lt $psResourceModuleVersion) {
        Write-Step "PSResourceGet not found or below version $psResourceModuleVersion. Installing..."
        if ($PSCmdlet.ShouldProcess($psResourceModuleName, "Install version $psResourceModuleVersion")) {
            Install-Module -Name $psResourceModuleName -Repository PSGallery -Scope CurrentUser -Force -AllowClobber -RequiredVersion $psResourceModuleVersion | Out-Null
            Write-RunLog -Context $RunContext -Level Info -Message "Installed $psResourceModuleName $psResourceModuleVersion." -Metadata @{ action = 'install' }
        }
    }

    Import-Module -Name $psResourceModuleName -MinimumVersion $psResourceModuleVersion -ErrorAction Stop | Out-Null
    $psResourceGetModule = Get-Module -Name $psResourceModuleName
    Write-Step "[OK] $psResourceModuleName version $($psResourceGetModule.Version) is available."
    Write-RunLog -Context $RunContext -Level Info -Message "$psResourceModuleName available." -Metadata @{ detected_version = $psResourceGetModule.Version.ToString() }
}
catch {
    Write-Error "Failed to find, install, or import $psResourceModuleName. $_"
    Write-RunLog -Context $RunContext -Level Error -Message "Failed to prepare $psResourceModuleName." -Metadata @{ error = $_.Exception.Message }
    throw "Failed to find, install, or import $psResourceModuleName."
}
#endregion

#region 3. Install/Upgrade Modules
# Installs each required module (or upgrades it) so the repo, analyzers, and export scripts run with known bits.
Write-Step "`nStep 3: Installing/updating required modules..."
foreach ($module in $requiredModules) {
    $moduleName = $module.Name
    $minimumVersion = [Version]$module.MinimumVersion
    Write-Verbose "Checking module: $moduleName (minimum version: $minimumVersion)"

    $installedModule = Get-InstalledPSResource -Name $moduleName -ErrorAction SilentlyContinue |
        Sort-Object -Property Version -Descending |
        Select-Object -First 1

    if ($installedModule -and [Version]$installedModule.Version -ge $minimumVersion) {
        Write-Step "  - $moduleName ($($installedModule.Version)) meets the minimum version requirement ($minimumVersion)."
        $moduleInstallSummary.skipped++
        Write-RunLog -Context $RunContext -Level Info -Message "$moduleName already meets minimum version." -Metadata @{ detected_version = $installedModule.Version.ToString(); required_version = $minimumVersion.ToString() }
        continue
    }

    $actionMessage = if ($installedModule) {
        "Update $moduleName from $($installedModule.Version) to at least $minimumVersion"
    }
    else {
        "Install $moduleName version $minimumVersion"
    }

    if ($PSCmdlet.ShouldProcess($moduleName, $actionMessage)) {
        try {
            Install-PSResource -Name $moduleName -Version $module.MinimumVersion -Repository PSGallery -Scope CurrentUser -AcceptLicense -ErrorAction Stop | Out-Null
            Write-Step "  [OK] $actionMessage completed."
            $moduleInstallSummary.installed++
            Write-RunLog -Context $RunContext -Level Info -Message "$actionMessage completed." -Metadata @{ module = $moduleName; target_version = $minimumVersion.ToString() }
        }
        catch {
            Write-Error "Failed to install $moduleName version $($module.MinimumVersion). $_"
            Write-RunLog -Context $RunContext -Level Error -Message "Failed to install or update $moduleName." -Metadata @{ target_version = $minimumVersion.ToString(); error = $_.Exception.Message }
            throw "Failed to install or update module $moduleName."
        }
    }
}
#endregion

#region 4. Normalize PSModulePath
# Moves the CurrentUser module folder to the front of PSModulePath so our pinned modules load before any system copies.
Write-Step "`nStep 4: Normalizing PSModulePath..."
$currentUserPath = Get-CurrentUserModulePath
Write-Verbose "Resolved CurrentUser module path: $currentUserPath"

$modulePaths = @()
if (-not [string]::IsNullOrWhiteSpace($env:PSModulePath)) {
    $modulePaths = $env:PSModulePath -split [System.IO.Path]::PathSeparator
}

$modulePaths = $modulePaths | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

if ($modulePaths.Count -eq 0 -or $modulePaths[0] -ne $currentUserPath) {
    Write-Verbose "CurrentUser module path is not prioritized. Adjusting..."
    $dedupedPaths = $modulePaths | Where-Object { $_ -ne $currentUserPath }
    $normalizedPaths = @($currentUserPath) + $dedupedPaths
    $env:PSModulePath = $normalizedPaths -join [System.IO.Path]::PathSeparator
    Write-Step "[OK] PSModulePath normalized to prioritize CurrentUser."
}
else {
    Write-Step "[OK] PSModulePath already prioritizes CurrentUser."
}
#endregion

#region 5. Run PSScriptAnalyzer
# Runs the PowerShell linter across the repo, stores a JSON report, and treats any issues as blockers.
Write-Step "`nStep 5: Running PSScriptAnalyzer..."

# Make sure the report folder exists so saving the analyzer output never fails.
if (-not (Test-Path -Path $examplesDir)) {
    if ($PSCmdlet.ShouldProcess($examplesDir, 'Create Directory')) {
        New-Item -Path $examplesDir -ItemType Directory -Force | Out-Null
        Write-Verbose "Created directory: $examplesDir"
    }
}


# Collect the files we want ScriptAnalyzer to inspect while skipping generated folders.
try {
    $analysisTargets = Get-ChildItem -Path $repoRoot -Recurse -File -ErrorAction Stop
}
catch {
    Write-Error "Failed to enumerate files for ScriptAnalyzer. $_"
    throw "Prerequisite module validation failed."
}

[string[]]$analysisPaths = $analysisTargets |
    Where-Object { $_.Extension -in '.ps1', '.psm1', '.psd1', '.ps1xml' } |
    Where-Object { -not (Test-IsExcludedAnalyzerPath -FullPath $_.FullName) } |
    Select-Object -ExpandProperty FullName

$analysisCount = if ($analysisPaths) { $analysisPaths.Count } else { 0 }
Write-RunLog -Context $RunContext -Level Info -Message 'Collected files for ScriptAnalyzer.' -Metadata @{ file_count = $analysisCount }

if ($analysisCount -eq 0) {
    Write-Step "No PowerShell files found for analysis. Skipping Invoke-ScriptAnalyzer."
    $analyzerResults = @()
}
else {
    # Invoke the analyzer one file at a time to avoid surprise failures and keep the JSON report deterministic.
    $analyzerResults = @()
    foreach ($analysisPath in $analysisPaths) {
        try {
            # Invoke-ScriptAnalyzer 1.21.0 expects a single string for -Path, so run once per path and collect the results.
            $pathResults = Invoke-ScriptAnalyzer -Path $analysisPath -ErrorAction Stop
            if ($pathResults) {
                $analyzerResults += $pathResults
            }
        }
        catch {
            Write-Error "Invoke-ScriptAnalyzer failed for '$analysisPath'. $_"
            throw "PSScriptAnalyzer encountered an error."
        }
    }
}

if ($PSCmdlet.ShouldProcess($reportPath, 'Generate PSScriptAnalyzer Report')) {
    $analyzerResults | ConvertTo-Json -Depth 6 | Out-File -FilePath $reportPath -Encoding utf8
    Write-Step "[OK] PSScriptAnalyzer report saved to: $reportPath"
}

$errors = @($analyzerResults | Where-Object { $_.Severity -eq 'Error' })
$warnings = @($analyzerResults | Where-Object { $_.Severity -eq 'Warning' })
$info = @($analyzerResults | Where-Object { $_.Severity -eq 'Information' })
Write-RunLog -Context $RunContext -Level Info -Message 'PSScriptAnalyzer completed.' -Metadata @{ total = $analyzerResults.Count; errors = $errors.Count; warnings = $warnings.Count }

if (-not $Quiet) {
    Write-Information "`n[PSScriptAnalyzer Summary]"
    Write-Information "  Files analyzed: $($analysisPaths.Count)"
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
# Treat analyzer warnings as failures so CI/CD and humans both know when hygiene needs attention.
$blockingFindings = @($analyzerResults | Where-Object { $_.Severity -in @('Error', 'Warning') })
if ($blockingFindings.Count -gt 0) {
    Write-Error "`nPSScriptAnalyzer found blocking issues (warnings are treated as errors). Please review the report and fix them."
    throw "PSScriptAnalyzer found blocking issues (warnings are treated as errors)."
}

Write-Step "`n[OK] Prerequisite check completed successfully."
#endregion

    $summary = [pscustomobject]@{
        ModulesEvaluated = $moduleInstallSummary.evaluated
        ModulesInstalled = $moduleInstallSummary.installed
        ModulesSkipped   = $moduleInstallSummary.skipped
        AnalyzerIssues   = $analyzerResults.Count
        AnalyzerErrors   = $errors.Count
        AnalyzerWarnings = $warnings.Count
    }

    Write-RunLog -Context $RunContext -Level Info -Message 'Prerequisite check completed.' -Metadata @{ modules_installed = $moduleInstallSummary.installed; modules_skipped = $moduleInstallSummary.skipped; analyzer_issues = $analyzerResults.Count }

    return $summary
}

$scriptSummary = $null
$succeeded = $false
try {
    $scriptSummary = Invoke-ScriptMain -Quiet:$Quiet -RunContext $runContext
    $succeeded = $true
}
catch {
    Write-RunLog -Context $runContext -Level Error -Message "Unhandled error during prerequisite check: $($_.Exception.Message)" -Metadata @{ error = $_.Exception.GetType().Name }
    Write-Error $_
}
finally {
    Complete-RunLog -Context $runContext -Succeeded:$succeeded -Summary @{
        modules_installed = if ($scriptSummary) { $scriptSummary.ModulesInstalled } else { $null }
        modules_skipped   = if ($scriptSummary) { $scriptSummary.ModulesSkipped } else { $null }
        analyzer_issues   = if ($scriptSummary) { $scriptSummary.AnalyzerIssues } else { $null }
    } | Out-Null
}

if ($succeeded) {
    Write-Output "Prerequisite checks completed. See $($runContext.RelativeLogPath) for details."
    exit 0
} else {
    Write-Output "Errors detected. Check $($runContext.RelativeLogPath) for details."
    exit 1
}
