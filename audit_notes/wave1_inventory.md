# Wave 1 — Inventory and Mapping (Draft)

## Scope

- Enumerate scripts, modules, and exported functions.
- Extract cmdlets used and create a draft Command Appendix for link filling in later waves.

## Scripts

- scripts/ensure-prereqs.ps1
- scripts/export-azure_rbac_assignments.ps1
- scripts/export-azure_rbac_definitions.ps1
- scripts/export-azure_scopes.ps1
- scripts/export-entra_apps_service_principals.ps1
- scripts/export-entra_directory_roles.ps1
- scripts/export-entra_group_memberships.ps1
- scripts/export-entra_groups_cloud_only.ps1
- scripts/export-entra_role_assignments.ps1

## Modules

- modules/entra_connection/entra_connection.psm1
- modules/export/Export.psm1
- modules/logging/Logging.psm1

## Exported Functions (from manifests)

- connect
  - Get-TenantCatalog, Select-Tenant, Connect-GraphContext, Connect-AzureContext, Get-ActiveContexts
- export
  - Get-DatasetSchema, Test-ObjectAgainstSchema, ConvertTo-FlatRecord, Write-Export
- logging
  - New-LogContext, Set-LogRedactionPatterns, Write-Log, Get-CorrelationId, Invoke-WithRetry

## Cmdlets Used (see docs/command_appendix.csv)

- Highlights:
  - Azure: Connect-AzAccount, Get-AzContext, Set-AzContext, Get-AzSubscription, Get-AzResourceGroup, Get-AzManagementGroup, Get-AzRoleAssignment, Get-AzRoleDefinition.
  - Microsoft Graph: Connect-MgGraph, Get-MgContext, Get-MgDirectoryRole, Get-MgDirectoryRoleMember, Get-MgGroup, Get-MgGroupMember, Get-MgApplication, Get-MgServicePrincipal, Get-MgOauth2PermissionGrant, Get-MgUser.
  - Core/Utility: Import-Module, Export-Csv, ConvertTo-Json, ConvertFrom-Json, Select-Object, Where-Object, Add-Member, Start-Sleep.
  - Secrets: Get-Secret (Microsoft.PowerShell.SecretManagement).
  - Analyzer/Packaging: Invoke-ScriptAnalyzer (PSScriptAnalyzer), Install-PSResource (PSResourceGet), Install-Module (PowerShellGet).
  - Optional: Export-Excel (ImportExcel module).

## Suspicious/Unknown Tokens (need review)

- modules/logging/Logging.psm1: "A-Za" — appears from a regex/comment; not a cmdlet.
- modules/logging/Logging.psm1: "Module-Scoped" — comment token; not a cmdlet.

These are excluded from any remediation; they will be ignored in Wave 2 fixes as non-cmdlet noise.

## Next Steps for Wave 2

- Fill Module and LearnURL columns in the Command Appendix using Microsoft Learn pages (prioritized per source rules).
- Verify any deprecated or misspelled cmdlets; propose replacements where needed.
- Confirm required modules in README and ensure `scripts/ensure-prereqs.ps1` pins minimum versions via PSResourceGet.
