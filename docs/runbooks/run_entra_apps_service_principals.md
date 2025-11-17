## Run Entra Apps / Service Principals Export

Purpose
- Export registered applications and service principals from Microsoft Entra ID for inventory and consent review.

Prerequisites
- PowerShell 7.4+, Microsoft.Graph module, Graph permissions to list applications and service principals.

Command
```powershell
pwsh -NoProfile -File scripts/export-entra_apps_service_principals.ps1 -OutputPath .\outputs -Verbose
```

Parameters
- `-OutputPath <path>` — directory to write CSV/JSON exports (defaults to `./exports`).

Expected outputs
- CSV: `entra_apps_service_principals.csv`
- JSON: `entra_apps_service_principals.json`
- Metadata headers/top-level keys: `generated_at`, `tool_version`, optional `dataset_version` plus fields like `AppId`, `DisplayName`, `AppOwner`, `SignInAudience`. Schema validation is paused during the raw-export phase.

Validation
- Cross-check with Graph:
```powershell
Get-MgApplication -All | Measure-Object
Get-MgServicePrincipal -All | Measure-Object
```

Common errors & fixes
- Permissions: ensure Application.Read.All or equivalent application permissions are granted for full listings.
- Paging/throttling: use `-All` and `Invoke-WithRetry`.
