## Run Azure Scopes Export

Purpose
- Export hierarchical scope information (Management Groups, Subscriptions, Resource Groups) for Azure.

Prerequisites
- PowerShell 7.4+ and required modules (see README and `scripts/ensure-prereqs.ps1`).
- Valid Azure credentials with rights to list management groups and subscriptions.

Command
```powershell
pwsh -NoProfile -File scripts/export-azure_scopes.ps1 -OutputPath .\outputs -Verbose
```

Parameters
- `-OutputPath <path>` — directory to write CSV/JSON exports (defaults to `./exports`).

Expected outputs
- CSV: `azure_scopes.csv`
- JSON: `azure_scopes.json`
- Metadata headers/top-level keys in JSON: `generated_at`, `tool_version`, optional `dataset_version` plus scope fields (`Type`, `Id`, `Name`, `ParentId`, ...). Schema validation is paused during the raw-export phase.

Validation
- Cross-check subscription count with Az:
```powershell
Get-AzSubscription | Measure-Object
```
- Cross-check management groups with Az:
```powershell
Get-AzManagementGroup | Measure-Object
```
Compare totals with counts in the exported files (use `Import-Csv` / `Get-Content | ConvertFrom-Json`).

Common errors & fixes
- Authentication errors: run `Connect-AzAccount` or ensure `Connect-AzureContext` credentials are valid.
- Throttling: retry with -Verbose and run during off-peak hours; split the export by subscription if needed.
