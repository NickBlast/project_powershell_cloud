## Run Entra Role Assignments Export

Purpose
- Export members for each Entra (Azure AD / Microsoft Entra) directory role.

Prerequisites
- PowerShell 7.4+ and required modules, including Microsoft.Graph (see `scripts/ensure-prereqs.ps1`).
- Graph permissions (Directory.Read.All / RoleManagement.Read.Directory) and appropriate auth.

Command
```powershell
pwsh -NoProfile -File scripts/export-entra_role_assignments.ps1 -OutputPath .\outputs -Verbose
```

Parameters
- `-OutputPath <path>` — directory to write CSV/JSON exports (defaults to `./exports`).

Expected outputs
- CSV: `entra_role_assignments.csv`
- JSON: `entra_role_assignments.json`
- Metadata headers/top-level keys: `generated_at`, `tool_version`, optional `dataset_version` plus fields like `RoleId`, `RoleDisplayName`, `MemberId`, `MemberType`. Schema validation is paused during the raw-export phase.

Validation
- Cross-check roles with Graph:
```powershell
Get-MgDirectoryRole -All | Measure-Object
```
- Cross-check members for a sample role:
```powershell
Get-MgDirectoryRoleMember -DirectoryRoleId <roleId> -All | Measure-Object
```

Common errors & fixes
- Permissions: ensure Graph permissions and consent are granted.
- Rate limits: Add retries via `Invoke-WithRetry` or break into smaller queries.
