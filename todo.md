# Project Tasks

Use this file as the single backlog. Keep entries actionable, cite evidence when available, and remove them immediately once finished.

## Active Tasks
- [ ] Review `docs/` (reference, runbooks, governance) for outdated statements or gaps, focusing on AI and documentation rules.
- [ ] Expose `-TenantId`/`-TenantLabel` (or similar) parameters on CLI scripts so operators are not forced to edit `.config/tenants.json` for each run.
- [ ] Apply `Invoke-WithRetry` (or chunked pagination) to Azure exports (`Get-Az*` calls) the same way Graph scripts already do to avoid throttling failures on large tenants.
- [ ] Update entra_connect.psm1 module with strong comments and metadata for each code block.

## Audit Follow-ups
- [ ] Decide whether PowerShell help should move to external PlatyPS for all modules or remain a hybrid inline/external model (clarify status).
- [ ] Identify any additional domains to allowlist for `fetch-ro` beyond Microsoft Learn and official GitHub sources (clarify status).
- [ ] Confirm minimum module versions to pin via PSResourceGet in `scripts/ensure-prereqs.ps1` (clarify status).
- [ ] Verify whether the Wave 1 inventory draft covers all scripts/modules/functions and finalize the command appendix extraction for the listed assets:
  - scripts/ensure-prereqs.ps1
  - scripts/export-azure_rbac_assignments.ps1
  - scripts/export-azure_rbac_definitions.ps1
  - scripts/export-azure_scopes.ps1
  - scripts/export-entra_apps_service_principals.ps1
  - scripts/export-entra_directory_roles.ps1
  - scripts/export-entra_group_memberships.ps1
  - scripts/export-entra_groups_cloud_only.ps1
  - scripts/export-entra_role_assignments.ps1
  - modules/entra_connection/entra_connection.psm1
  - modules/export/Export.psm1
  - modules/logging/Logging.psm1
  - Extracted cmdlets for the command appendix
  (clarify status).
- [ ] Re-verify `Connect-AzAccount -UseDeviceAuthentication` guidance on Microsoft Learn and adjust docs/command appendix if required (clarify status).

## SCHEMA-FUTURE
- [ ] Reintroduce schema validation helpers and tests once datasets stabilize; include property/type enforcement when schemas return.
- [ ] Define the schema storage location and contract when the future schema phase is approved.
