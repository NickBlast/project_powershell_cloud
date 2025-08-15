## Run Entra Groups (Cloud-only) Export

Purpose
- Export groups that are cloud-only (not synced from on-prem) from Microsoft Entra ID.

Prerequisites
- PowerShell 7.4+, Microsoft.Graph module, Graph permissions to list groups.

Command
```powershell
pwsh -NoProfile -File scripts/export-entra_groups_cloud_only.ps1 -OutputPath .\outputs -Verbose
```

Parameters
- `-OutputPath <path>` — directory to write CSV/JSON exports (defaults to `./exports`).

Expected outputs
- CSV: `entra_groups_cloud_only.csv`
- JSON: `entra_groups_cloud_only.json`
- Required headers/top-level keys: `generated_at`, `tool_version`, `dataset_version` plus group fields (`Id`, `DisplayName`, `Mail`, `GroupTypes`).

Validation
- Cross-check groups with Graph and filter cloud-only:
```powershell
Get-MgGroup -All | Where-Object { -not $_.OnPremisesSyncEnabled } | Measure-Object
```

Common errors & fixes
- API paging: use `-All` and handle throttling with retries.
- Permissions: ensure Group.Read.All is granted.
