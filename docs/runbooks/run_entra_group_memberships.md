## Run Entra Group Memberships Export

Purpose
- Export all members for every group in Microsoft Entra ID (Azure AD).

Prerequisites
- PowerShell 7.4+, Microsoft.Graph module installed, and Graph permissions to list groups and members.

Command
```powershell
pwsh -NoProfile -File scripts/export-entra_group_memberships.ps1 -OutputPath .\outputs -Verbose
```

Parameters
- `-OutputPath <path>` — directory to write CSV/JSON exports (defaults to `./exports`).

Expected outputs
- CSV: `entra_group_memberships.csv`
- JSON: `entra_group_memberships.json`
- Metadata headers/top-level keys: `generated_at`, `tool_version`, optional `dataset_version` plus fields like `GroupId`, `GroupDisplayName`, `MemberId`, `MemberType`. Schema validation is paused during the raw-export phase.

Validation
- Cross-check total groups with Graph:
```powershell
Get-MgGroup -All | Measure-Object
```
- For a sample group, cross-check member count:
```powershell
Get-MgGroupMember -GroupId <groupId> -All | Measure-Object
```

Common errors & fixes
- Throttling: run per-group batches and use `Invoke-WithRetry`.
- Permissions: confirm Group.Read.All consent and token scopes.
