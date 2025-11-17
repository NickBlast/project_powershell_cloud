## Run Azure RBAC Definitions Export

Purpose
- Export Azure RBAC role definitions (built-in and custom) for inventory and policy review.

Prerequisites
- PowerShell 7.4+ and required modules (see README and `scripts/ensure-prereqs.ps1`).
- Valid Azure credentials with permissions to read role definitions.

Command
```powershell
pwsh -NoProfile -File scripts/export-azure_rbac_definitions.ps1 -OutputPath .\outputs -Verbose
```

Parameters
- `-OutputPath <path>` — directory to write CSV/JSON exports (defaults to `./exports`).

Expected outputs
- CSV: `azure_rbac_definitions.csv`
- JSON: `azure_rbac_definitions.json`
- Metadata headers/top-level keys: `generated_at`, `tool_version`, optional `dataset_version` plus definition fields (`Id`, `Name`, `Permissions`, `AssignableScopes`). Schema validation is paused during the raw-export phase.

Validation
- Cross-check role definitions with Az:
```powershell
Get-AzRoleDefinition | Measure-Object
```
- Compare known built-in roles counts and sample role names.

Common errors & fixes
- API permissions: ensure Az context has rights to read role definitions.
- Missing custom roles: check correct subscription/management-group context when retrieving definitions.
