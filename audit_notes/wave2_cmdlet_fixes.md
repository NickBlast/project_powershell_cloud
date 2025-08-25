# Wave 2 — Cmdlet Reality Fixes

## Scope

- Validate cmdlets used and correct any unknown, misspelled, or deprecated ones.
- Ensure module imports match actual sources; add missing module references to README and Command Appendix.

## Findings

- No misspelled or deprecated cmdlets identified in code upon static review.
- `Connect-AzAccount` Device Code usage retained (`-UseDeviceAuthentication`); earmarked to double-check against Microsoft Learn during Wave 3/6 link validation.
- Two non-cmdlet tokens surfaced in Wave 1 extraction (`A-Za`, `Module-Scoped`) were false positives from regex/comments.
- The initial Command Appendix erroneously included internal functions and manifest entries.

## Changes (Before → After)

1) Command Appendix cleanup

- Removed internal functions and manifest rows; appendix now lists external cmdlets only.
- Removed false-positive tokens (`A-Za`, `Module-Scoped`).
- Added module families to `Module` column (e.g., Microsoft.Graph SDK, Az.Accounts, Az.Resources, SecretManagement, ImportExcel, PSScriptAnalyzer, PSResourceGet, PowerShellGet, Core modules).

2) README dependencies

- Added “Required Modules” section enumerating key modules installed by `ensure-prereqs.ps1`.
- Corrected repo contract link path to `docs/repo_design/repo_contract.md`.

## Notes & Deferrals

- LearnURL column to be populated with Microsoft Learn links in a later wave (Wave 6 finalization), after analyzer pass.
- Verify `Connect-AzAccount` device-code parameter name on Learn; update if needed.

