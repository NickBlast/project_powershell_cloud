# Project Tasks

Use this file as the single backlog for the repository. Keep entries actionable and remove them as soon as the work is completed.

## Legend

- **Type Tags**
  - `BUG`  – Fixing broken behavior or test failures.
  - `ENH`  – Enhancements or feature improvements.
  - `META` – Repository structure, logging, build, or cross-cutting refinements.
  - `DOC`  – Documentation, comments, or metadata improvements.

- **Area Tags**
  - `LOGGING`        – Run logs, diagnostics, and observability.
  - `EXPORTS`        – Export scripts and output behavior.
  - `MODULES`        – Shared modules (for example, connection, helpers).
  - `DOCS`           – README, runbooks, and reference documentation.
  - `SCHEMA-FUTURE`  – Schema and validation work deferred to a later phase.

- **Priority Tags**
  - `P1` – High priority / near-term.
  - `P2` – Medium priority.
  - `P3` – Lower priority / future phase.

## Work Orders Snapshot

Detailed implementation instructions for these efforts live in `.codex/work_orders.md`.

- `WO-LOGGING-001` – Add central run logging for all scripts.
- `WO-AUDIT-001` – Merge audit notes into changelog and todo.
- `WO-AI-001` – Remove tooling references from scripts and modules.
- `WO-TODO-001` – Restructure todo.md with categories and per-script/module tasks.

## Tasks by Area

### LOGGING

- [ ] [META][LOGGING][P1] Implement centralized run logging for every entrypoint script and align modules with the shared pattern.
- [ ] [ENH][LOGGING][P2] Refine logging helpers to support correlation IDs and consistent metadata payloads.
- [ ] [DOC][LOGGING][P2] Document log collection and review steps in README and supporting runbooks.
- [ ] [BUG][LOGGING][P1] Ensure analyzer output persists to `examples/` after the Wave 7 prereq workflow updates.

### DOCS

- [ ] [DOC][DOCS][P1] Review `docs/` for outdated statements or gaps, with emphasis on governance and documentation rules.
- [ ] [DOC][DOCS][P2] Decide whether PowerShell help stays inline or migrates to PlatyPS modules and document the direction.
- [ ] [DOC][DOCS][P2] Identify any additional domains to allowlist for `fetch-ro` beyond Microsoft Learn and official GitHub sources.
- [ ] [DOC][DOCS][P2] Verify the Wave 1 inventory draft covers all listed scripts/modules and finalize the command appendix excerpt.
- [ ] [DOC][DOCS][P2] Re-verify the `Connect-AzAccount -UseDeviceAuthentication` guidance and update docs if Microsoft Learn has changed.

### EXPORTS

- [ ] [ENH][EXPORTS][P1] Expose `-TenantId` and `-TenantLabel` (or equivalent) parameters on CLI scripts to avoid editing `.config/tenants.json`.
- [ ] [ENH][EXPORTS][P1] Apply `Invoke-WithRetry` or pagination to Azure exports so `Get-Az*` calls match Graph reliability.
- [ ] [META][EXPORTS][P2] Confirm the minimum module versions that `scripts/ensure-prereqs.ps1` must pin via PSResourceGet.
- [ ] [BUG][EXPORTS][P1] Run `scripts/ensure-prereqs.ps1` on a target host to confirm prereq detection still succeeds after Wave 7 changes.
- [ ] [BUG][EXPORTS][P1] Confirm PSResourceGet 1.0.5 installs cleanly during the prereq run and capture the version pin in logs.

### MODULES

- [ ] [DOC][MODULES][P2] Update `modules/entra_connection/entra_connection.psm1` with descriptive comments and metadata for each code block.
- [ ] [BUG][MODULES][P1] Validate the connection module in a work environment that mirrors production tenant controls.
- [ ] [ENH][MODULES][P2] Add parameter validation and clearer error messaging to the connection module and shared exports module.
- [ ] [DOC][MODULES][P2] Improve module documentation to clarify usage boundaries and supported authentication patterns.

### SCHEMA-FUTURE

- [ ] [ENH][SCHEMA-FUTURE][P3] Reintroduce schema validation helpers and tests once datasets stabilize, including property/type enforcement.
- [ ] [ENH][SCHEMA-FUTURE][P3] Define the schema storage location and contract once the future schema phase is approved.

## Per-Script / Per-Module Bring-Up

### scripts/ensure-prereqs.ps1

- [ ] [BUG][EXPORTS][P1] Debug the detection sequence on a clean PowerShell 7.4 host to confirm modules install predictably.
- [ ] [ENH][EXPORTS][P2] Harden module pinning and rerun logic so operators can specify tenant context without editing files.
- [ ] [META][LOGGING][P2] Confirm log and analyzer artifacts are written to `logs/` and `examples/` with timestamps.

### scripts/export-azure_rbac_assignments.ps1

- [ ] [BUG][EXPORTS][P1] Debug export behavior against a tenant with thousands of assignments to catch throttling or timeout issues.
- [ ] [ENH][EXPORTS][P2] Align parameter handling with the standard tenant selection switches and safe output naming.
- [ ] [META][LOGGING][P2] Verify the script emits structured logs once the centralized logging work is complete.

### scripts/export-azure_rbac_definitions.ps1

- [ ] [BUG][EXPORTS][P1] Run the export against production-sized tenants to confirm role definitions return in full.
- [ ] [ENH][EXPORTS][P2] Add dataset metadata (generated_at/tool_version) consistently to the output files.
- [ ] [META][LOGGING][P2] Ensure logging captures API pagination and any skipped items.

### scripts/export-azure_scopes.ps1

- [ ] [BUG][EXPORTS][P1] Validate the scope discovery logic in environments with mixed management groups and subscriptions.
- [ ] [ENH][EXPORTS][P2] Add filters or parameters to target specific management group prefixes when required.
- [ ] [META][LOGGING][P2] Confirm the script logs discovered scopes, pagination, and retries.

### scripts/export-entra_apps_service_principals.ps1

- [ ] [BUG][EXPORTS][P1] Debug export stability when enumerating large service principal inventories.
- [ ] [ENH][EXPORTS][P2] Implement chunked retrieval or selective filters to limit API strain.
- [ ] [META][LOGGING][P2] Verify logging records high-water marks and throttling retries.

### scripts/export-entra_directory_roles.ps1

- [ ] [BUG][EXPORTS][P1] Exercise the export in a tenant with many custom roles to ensure results are complete.
- [ ] [ENH][EXPORTS][P2] Align output headers with the repository’s raw export conventions.
- [ ] [META][LOGGING][P2] Confirm logs capture directory role enablement events and dataset counts.

### scripts/export-entra_group_memberships.ps1

- [ ] [BUG][EXPORTS][P1] Debug membership traversal across nested groups to ensure full coverage.
- [ ] [ENH][EXPORTS][P2] Support incremental or scoped exports for oversized tenants.
- [ ] [META][LOGGING][P2] Confirm logs summarize membership counts per group and capture failures.

### scripts/export-entra_groups_cloud_only.ps1

- [ ] [BUG][EXPORTS][P1] Validate the cloud-only filter works across hybrid tenants.
- [ ] [ENH][EXPORTS][P2] Add parameters for include/exclude patterns to avoid manual edits.
- [ ] [META][LOGGING][P2] Ensure logs differentiate between excluded and exported groups.

### scripts/export-entra_role_assignments.ps1

- [ ] [BUG][EXPORTS][P1] Debug behavior in tenants with delegated admin relationships to ensure all assignments are captured.
- [ ] [ENH][EXPORTS][P2] Align dataset naming and metadata with the other role export scripts.
- [ ] [META][LOGGING][P2] Verify logging captures assignment counts and skip reasons.

### scripts/seed-entra_test_assets.ps1

- [ ] [BUG][EXPORTS][P1] Exercise the seeding workflow in a non-production tenant to validate cleanup routines.
- [ ] [ENH][EXPORTS][P2] Add confirmation prompts or `-WhatIf` support before modifying tenant data.
- [ ] [META][LOGGING][P2] Ensure seeding actions and rollbacks are logged with correlation IDs.

### modules/entra_connection/entra_connection.psm1

- [ ] [BUG][MODULES][P1] Validate environment variable handling and fallback auth flows in restricted networks.
- [ ] [ENH][MODULES][P2] Improve error clarity, parameter validation, and tenant context handling.
- [ ] [DOC][MODULES][P2] Expand module-level comments and usage notes for operators.

### modules/export/Export.psm1

- [ ] [BUG][MODULES][P1] Debug CSV/JSON emitters to ensure deterministic formatting for each dataset.
- [ ] [ENH][MODULES][P2] Add helpers for standardized metadata (generated_at/tool_version) across exports.
- [ ] [META][LOGGING][P2] Integrate logging hooks so scripts inherit consistent telemetry without duplication.

### modules/logging/Logging.psm1

- [ ] [BUG][MODULES][P1] Verify logging works on hosts without existing log directories and handles concurrent runs.
- [ ] [ENH][MODULES][P2] Extend helpers for correlation IDs, run phases, and redaction utilities.
- [ ] [DOC][MODULES][P2] Document the logging contract for script authors and reviewers.

## General Backlog Notes

- New tasks must include Type, Area, and Priority tags as shown above.
- Remove tasks as soon as they are completed to keep this backlog authoritative.
- Keep this file free of explicit references to development tools or artificial intelligence assistants.
