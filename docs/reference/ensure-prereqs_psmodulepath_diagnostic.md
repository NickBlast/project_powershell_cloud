# Diagnostic Notes: `scripts/ensure-prereqs.ps1` Step 4

## Summary
Step 4 of `scripts/ensure-prereqs.ps1` normalized `$env:PSModulePath` by combining the value returned by
`[Environment]::GetFolderPath('MyDocuments')` with module directories. Inside Debian-based containers, the
framework API returns an empty string, so passing it directly to `Join-Path` triggered the error:

> Cannot bind argument to parameter 'Path' because it is null or an empty string.

The script now uses a dedicated helper (`Get-CurrentUserModulePath`) that mirrors the defaults documented in
[`about_PSModulePath`](https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_psmodulepath)
and [`Environment.GetFolderPath`](https://learn.microsoft.com/dotnet/api/system.environment.getfolderpath). The helper:

- Prefers the platform's Documents directory when the API returns a non-empty value (Windows-first behaviour).
- Falls back to `$HOME/.local/share/powershell/Modules` on Linux/macOS PowerShell 7+, matching the defaults published in
the Microsoft documentation.
- Throws a clear error if neither `MyDocuments` nor `HOME` are available so the caller can surface the root cause.

## Custom Function Behaviour
`Get-CurrentUserModulePath` is an internal helper exported in the same region as `Test-IsExcludedAnalyzerPath`. The
function resolves a deterministic CurrentUser path that Step 4 can use to reorder `$env:PSModulePath` without invoking
`Join-Path` on empty strings. This mirrors the project's emphasis on deterministic paths and gives Step 4 consistent
behaviour across Windows, Linux, and macOS environments.

The normalization logic now:

1. Retrieves and logs the resolved path via `Write-Verbose`.
2. Splits `$env:PSModulePath` safely even when the variable is unset.
3. Deduplicates the CurrentUser path before rebuilding the environment variable.

## Related Microsoft References
- [`Install-Module`](https://learn.microsoft.com/powershell/module/powershellget/install-module)
- [`Install-PSResource`](https://learn.microsoft.com/powershell/module/microsoft.powershell.psresourceget/install-psresource)
- [`Invoke-ScriptAnalyzer`](https://learn.microsoft.com/powershell/module/psscriptanalyzer/invoke-scriptanalyzer)
- [`Get-InstalledPSResource`](https://learn.microsoft.com/powershell/module/microsoft.powershell.psresourceget/get-installedpsresource)

These cmdlets are unchanged by the fix, but the documentation review confirmed that they require the CurrentUser
module directory to exist when installing into the default scope.
