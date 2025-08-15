## Run Azure RBAC Assignments Export

Purpose
- Export Azure RBAC role assignments across scopes (tenant, subscription, resource groups).

Prerequisites
- PowerShell 7.4+ and required modules (see README and `scripts/ensure-prereqs.ps1`).
- Valid Azure credentials with permissions to list role assignments.

Command
```powershell
pwsh -NoProfile -File scripts/export-azure_rbac_assignments.ps1 -OutputPath .\outputs -Verbose
```

Parameters
- `-OutputPath <path>` — directory to write CSV/JSON exports (defaults to `./exports`).

Expected outputs
- CSV: `azure_rbac_assignments.csv`
- JSON: `azure_rbac_assignments.json`
- Required headers/top-level keys: `generated_at`, `tool_version`, `dataset_version` plus role assignment fields (e.g., `PrincipalId`, `RoleDefinitionId`, `Scope`).

Validation
- Cross-check total assignments with Az (per subscription):
```powershell
Get-AzRoleAssignment -Scope "/subscriptions/<subId>" | Measure-Object
```
- Or use Graph: `Get-MgRoleManagementDirectoryRoleAssignment` where applicable.

Common errors & fixes
- Permissions: ensure caller has Authorization Provider (`RoleManagement.Read.Directory`) or required Az RBAC rights.
- Large tenants: consider exporting per-subscription to avoid timeouts.
