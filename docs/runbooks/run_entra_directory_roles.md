## Run Entra Directory Roles Export

Purpose
- Export all directory roles (definitions) present in Microsoft Entra ID for auditing.

Prerequisites
- PowerShell 7.4+, Microsoft.Graph module, Graph permissions to list directory roles.

Command
```powershell
pwsh -NoProfile -File scripts/export-entra_directory_roles.ps1 -OutputPath .\outputs -Verbose
```

Parameters
- `-OutputPath <path>` — directory to write CSV/JSON exports (defaults to `./exports`).

Expected outputs
- CSV: `entra_directory_roles.csv`
- JSON: `entra_directory_roles.json`
- Metadata headers/top-level keys: `generated_at`, `tool_version`, optional `dataset_version` plus fields like `Id`, `DisplayName`, `RoleTemplateId`. Schema validation is paused during the raw-export phase.

Validation
- Cross-check with Graph:
```powershell
Get-MgDirectoryRole | Measure-Object
```

Common errors & fixes
- Ensure roles are activated where necessary; Graph may not return inactive/undiscovered roles without proper permissions.
