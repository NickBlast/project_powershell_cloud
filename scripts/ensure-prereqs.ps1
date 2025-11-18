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

Import-Module $PSScriptRoot/../modules/logging/logging.psd1 -Force

$scriptName = Split-Path -Path $PSCommandPath -Leaf

$scriptBlock = {
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

    $repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $examplesDir = Join-Path -Path $repoRoot -ChildPath 'examples'
    $reportPath = Join-Path -Path $examplesDir -ChildPath 'prereq_report.json'
    $excludedAnalyzerDirectories = @('.git', '.archive', 'examples', 'logs', 'outputs', 'reports')

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

    if ($PSVersionTable.PSVersion -lt $requiredPSVersion) {
        Write-Error "PowerShell version $($PSVersionTable.PSVersion) is not supported. Please upgrade to version $requiredPSVersion or higher."
        throw "Unsupported PowerShell version."
    }
    Write-Step "[OK] PowerShell version check passed."
    #endregion

    #region 2. PSResourceGet Check
    # Verifies PSResourceGet is present at the pinned version because every later module install depends on it.
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
        throw
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
                $versionRange = "[$minimumVersion,)"
                Install-PSResource -Name $moduleName -Repository PSGallery -Scope CurrentUser -Prerelease -ErrorAction Stop -TrustRepository -Version $versionRange | Out-Null
                Write-Step "  - Installed/updated $moduleName to meet minimum version $minimumVersion."
            }
            catch {
                Write-Error "Failed to install or update $moduleName. $_"
                throw
            }
        }
    }
    #endregion

    #region 4. Normalize PSModulePath
    # Ensures CurrentUser path is first so freshly installed modules are preferred over machine-scoped ones.
    Write-Step "`nStep 4: Normalizing PSModulePath to prioritize CurrentUser scope..."
    $currentUserModulePath = Get-CurrentUserModulePath
    $pathSeparator = [IO.Path]::PathSeparator
    $modulePaths = $env:PSModulePath -split [IO.Path]::PathSeparator | Where-Object { $_ -and -not ($_ -eq $currentUserModulePath) }
    $env:PSModulePath = "$currentUserModulePath$pathSeparator$([string]::Join($pathSeparator, $modulePaths))"
    Write-Verbose "PSModulePath is now: $env:PSModulePath"
    #endregion

    #region 5. Run PSScriptAnalyzer
    # Lints the repository and generates a JSON report for compliance evidence.
    Write-Step "`nStep 5: Running PSScriptAnalyzer on repository..."

    if (-not (Test-Path -Path $examplesDir)) {
        New-Item -Path $examplesDir -ItemType Directory -Force | Out-Null
    }

    $analyzerTargets = Get-ChildItem -Path $repoRoot -Recurse -File -Include *.ps1, *.psm1, *.psd1 |
        Where-Object { -not (Test-IsExcludedAnalyzerPath -FullPath $_.FullName) } |
        ForEach-Object { $_.FullName }

    $analysisResult = Invoke-ScriptAnalyzer -Path $analyzerTargets -Recurse -Severity @('Error', 'Warning') -ErrorAction Stop
    $analysisResult | ConvertTo-Json -Depth 5 | Set-Content -Path $reportPath -Encoding UTF8

    if ($analysisResult) {
        Write-Error "PSScriptAnalyzer found warnings or errors. See report at $reportPath."
        throw "ScriptAnalyzer findings detected."
    }

    Write-Step "[OK] PSScriptAnalyzer completed with no warnings or errors."
    #endregion
}

Invoke-WithRunLog -ScriptName $scriptName -ScriptBlock $scriptBlock
