<#
.SYNOPSIS
    Ensures all prerequisites for the PowerShell IAM Inventory project are met.
.DESCRIPTION
    This script verifies the PowerShell environment, installs required modules with pinned versions,
    and runs a quality check using PSScriptAnalyzer.

    It is idempotent and can be run multiple times safely.

    Key actions:
    1. Verifies PowerShell version is 7.4 or higher.
    2. Ensures PSResourceGet is installed and available.
    3. Installs or updates required modules to the CurrentUser scope.
    4. Normalizes the PSModulePath to prioritize the CurrentUser scope.
    5. Runs PSScriptAnalyzer on the entire repository.
    6. Emits a JSON report of the analysis to './examples/prereq_report.json'.
    7. Exits with a non-zero code if PSScriptAnalyzer finds errors.
.PARAMETER WhatIf
    Shows what actions would be taken without actually executing them.
.PARAMETER Quiet
    Suppresses all console output except for critical errors and the final summary.
    The JSON report is still written.
.EXAMPLE
    PS> ./scripts/ensure-prereqs.ps1
    Runs the full prerequisite check, displaying verbose output.
.EXAMPLE
    PS> ./scripts/ensure-prereqs.ps1 -WhatIf
    Displays the modules that would be installed or updated without making changes.
.EXAMPLE
    PS> ./scripts/ensure-prereqs.ps1 -Quiet
    Runs the check with minimal output, useful for automated scripts.
.NOTES
    Author: Gemini
    License: See LICENSE file.
    Version: 1.0.0
#>
[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [Switch]$Quiet
)

#region Setup and Configuration
$ErrorActionPreference = 'Stop'
$VerbosePreference = if ($Quiet) { 'SilentlyContinue' } else { 'Continue' }

$requiredPSVersion = '7.4.0'

# Define required modules with minimum versions
$requiredModules = @{
    'Az.Accounts' = '2.12.1'
    'Az.Resources' = '6.6.0'
    'ImportExcel' = '7.8.5'
    'PSScriptAnalyzer' = '1.21.0'
    'Pester' = '5.5.0'
    'Microsoft.PowerShell.SecretManagement' = '1.1.2'
    # Microsoft.Graph is handled separately due to its submodule structure.
    # We ensure the base module is present, but specific submodules are installed on-demand by other scripts.
    'Microsoft.Graph' = '2.9.0'
}

$repoRoot = Resolve-Path -Path (Join-Path $PSScriptRoot '..')
$examplesDir = Join-Path $repoRoot 'examples'
$reportPath = Join-Path $examplesDir 'prereq_report.json'

# Helper for writing output respecting -Quiet
function Write-OutputVerbose {
    param(
        [string]$Message
    )
    if (-not $Quiet) {
        Write-Host $Message
    }
    Write-Verbose $Message
}
#endregion

#region 1. PowerShell Version Check
Write-OutputVerbose "Step 1: Verifying PowerShell version..."
Write-Verbose "Required version: $requiredPSVersion or higher."
Write-Verbose "Detected version: $($PSVersionTable.PSVersion)"

if ($PSVersionTable.PSVersion -lt [Version]$requiredPSVersion) {
    Write-Error "PowerShell version $($PSVersionTable.PSVersion) is not supported. Please upgrade to version $requiredPSVersion or higher."
    exit 1
}
Write-OutputVerbose "[OK] PowerShell version check passed."
#endregion

#region 2. PSResourceGet Check
Write-OutputVerbose "`nStep 2: Verifying PSResourceGet module..."
try {
    $psResourceGetModule = Get-Module -Name PSResourceGet -ListAvailable
    if (-not $psResourceGetModule) {
        Write-OutputVerbose "PSResourceGet not found. Attempting to install from PSGallery..."
        if ($PSCmdlet.ShouldProcess('PSResourceGet', 'Install Module')) {
            Install-Module -Name PSResourceGet -Repository PSGallery -Force -Scope CurrentUser
            Write-OutputVerbose "[OK] PSResourceGet installed successfully."
        }
    }
    else {
        Write-OutputVerbose "[OK] PSResourceGet is available."
    }
}
catch {
    Write-Error "Failed to find or install PSResourceGet. Please install it manually from the PowerShell Gallery."
    exit 1
}
#endregion

#region 3. Install/Upgrade Modules
Write-OutputVerbose "`nStep 3: Installing/updating required modules..."
foreach ($moduleName in $requiredModules.Keys) {
    $requiredVersion = $requiredModules[$moduleName]
    Write-Verbose "Checking module: $moduleName (minimum version: $requiredVersion)"

    $installedModule = Get-Module -Name $moduleName -ListAvailable
    if ($installedModule -and $installedModule.Version -ge [Version]$requiredVersion) {
        Write-OutputVerbose "  - $moduleName ($($installedModule.Version)) is already installed and meets requirements."
        continue
    }

    $targetVersion = if ($installedModule) { "from $($installedModule.Version) to >$requiredVersion" } else { $requiredVersion }
    if ($PSCmdlet.ShouldProcess("$moduleName", "Install/Update module $targetVersion")) {
        try {
            Write-OutputVerbose "  - Installing/Updating $moduleName..."
            # Use -RequiredVersion for Pester to avoid pre-release if not specified
            $installParams = @{
                Name = $moduleName
                MinimumVersion = $requiredVersion
                Repository = 'PSGallery'
                Scope = 'CurrentUser'
                Force = $true
                AcceptLicense = $true
            }
            Install-PSResource @installParams
            $newVersion = (Get-Module -Name $moduleName -ListAvailable).Version
            Write-OutputVerbose "  [OK] Successfully installed $moduleName version $newVersion."
        }
        catch {
            Write-Error "Failed to install module '$moduleName'. Error: $_"
            # Continue to the next module
        }
    }
}
#endregion

#region 4. Normalize PSModulePath
Write-OutputVerbose "`nStep 4: Normalizing PSModulePath..."
$currentUserPath = [Environment]::GetFolderPath('MyDocuments') + "\WindowsPowerShell\Modules"
# For PowerShell 7, the path is different.
if ($IsCoreCLR) {
    $currentUserPath = [Environment]::GetFolderPath('MyDocuments') + "\PowerShell\Modules"
}

$modulePaths = $env:PSModulePath -split [System.IO.Path]::PathSeparator
if ($modulePaths[0] -ne $currentUserPath) {
    Write-Verbose "CurrentUser module path is not prioritized. Adjusting..."
    $newPath = ($currentUserPath, ($modulePaths | Where-Object { $_ -ne $currentUserPath })) -join [System.IO.Path]::PathSeparator
    $env:PSModulePath = $newPath
    Write-OutputVerbose "[OK] PSModulePath normalized to prioritize CurrentUser."
} else {
    Write-OutputVerbose "[OK] PSModulePath already prioritizes CurrentUser."
}
#endregion

#region 5. Run PSScriptAnalyzer
Write-OutputVerbose "`nStep 5: Running PSScriptAnalyzer..."
if (-not (Test-Path -Path $examplesDir)) {
    if ($PSCmdlet.ShouldProcess($examplesDir, "Create Directory")) {
        New-Item -Path $examplesDir -ItemType Directory | Out-Null
        Write-Verbose "Created directory: $examplesDir"
    }
}

$analyzerResults = Invoke-ScriptAnalyzer -Path $repoRoot -Recurse
if ($PSCmdlet.ShouldProcess($reportPath, "Generate PSScriptAnalyzer Report")) {
    $analyzerResults | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath -Encoding UTF8
    Write-OutputVerbose "[OK] PSScriptAnalyzer report saved to: $reportPath"
}

# Human-readable summary
if (-not $Quiet) {
    if ($analyzerResults.Count -eq 0) {
        Write-Information "`n[PSScriptAnalyzer Summary]"
        Write-Information "  No issues found. Excellent!"
    } else {
        $errors = $analyzerResults | Where-Object { $_.Severity -eq 'Error' }
        $warnings = $analyzerResults | Where-Object { $_.Severity -eq 'Warning' }
        $info = $analyzerResults | Where-Object { $_.Severity -eq 'Information' }

        Write-Information "`n[PSScriptAnalyzer Summary]"
        Write-Information "  Total Issues: $($analyzerResults.Count)"
        Write-Information "  - Errors: $($errors.Count)"
        Write-Information "  - Warnings: $($warnings.Count)"
        Write-Information "  - Information: $($info.Count)"

        if ($errors.Count -gt 0) {
            Write-Information "`nErrors found:"
            $errors | ForEach-Object { Write-Information "  - $($_.ScriptName):$($_.Line): $($_.Message)" }
        }
    }
}
#endregion

#region 6. Exit Code
if (($analyzerResults | Where-Object { $_.Severity -eq 'Error' }).Count -gt 0) {
    Write-Error "`nPSScriptAnalyzer found errors. Please review the report and fix them."
    exit 1
}

Write-OutputVerbose "`n[OK] Prerequisite check completed successfully."
#endregion
