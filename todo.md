# Project Tasks

Use this file as the single backlog for the repository. Keep entries actionable and remove them as soon as they are completed.

## Workflow Migration – Short-Term Tasks

- [ ] Read `WO-WORKFLOW-001` and create a GitHub Issue to track it.
- [ ] For `WO-WORKFLOW-001`: Research GitHub documentation for Issue templates and labels, then refine the Work Order if needed.
- [ ] For `WO-WORKFLOW-002`: Review `ai_project_rules.md` to understand existing AI rules before editing.
- [ ] For `WO-WORKFLOW-003`: List all open Work Orders that need migration into Issues.

## Legend

- **Type**
  - `BUG`  – Fixing broken behavior or test failures.
  - `ENH`  – Enhancements or feature improvements.
  - `META` – Repository structure, logging, build, or cross-cutting refinements.
  - `DOC`  – Documentation, comments, or metadata improvements.

- **Area**
  - `LOGGING`        – Run logs, diagnostics, and observability.
  - `EXPORTS`        – Export scripts and output behavior.
  - `MODULES`        – Shared modules (for example, connection, helpers).
  - `DOCS`           – README, runbooks, and reference documentation.
  - `SCHEMA-FUTURE`  – Schema and validation work deferred to a later phase.

- **Priority**
  - `P1` – High priority / near-term.
  - `P2` – Medium priority.
  - `P3` – Lower priority / future phase.

## Work Orders Snapshot

Detailed implementation guidance currently lives in the sandbox-only work_orders file for `WO-TODO-001`. The summaries below will be expanded there as the work orders progress.

- `WO-LOGGING-001` – Add central run logging for all scripts.
- `WO-AUDIT-001` – Merge audit notes into changelog and todo.
- `WO-TODO-001` – Restructure todo.md with categories and per-script/module tasks.

## Tasks by Area

### LOGGING

- [ ] [META][LOGGING][P1] Implement centralized run logging so every entry point emits consistent metadata (dataset name, tenant label, correlation ID, tool version) to `logs/` and `outputs/`.
- [ ] [ENH][LOGGING][P2] Refine logging helpers so scripts and modules emit the same correlation identifiers and payload structure required by WO-LOGGING-001.
- [ ] [DOC][LOGGING][P2] Add log review and retention guidance to `README.md` once the central logger is in place.
- [ ] [META][LOGGING][P2] Ensure Script Analyzer output persists to `examples/` after the Wave 7 prereq workflow updates.

### DOCS

- [ ] [DOC][DOCS][P1] Review `docs/` (reference, runbooks, governance) for outdated statements or gaps, focusing on documentation rules now that AI references were removed.
- [ ] [DOC][DOCS][P2] Decide whether module help should move fully to PlatyPS or stay hybrid inline/external and document the decision.
- [ ] [META][DOCS][P2] Identify any additional domains to allowlist for `fetch-ro` beyond Microsoft Learn and official GitHub sources.
- [ ] [DOC][DOCS][P1] Verify the Wave 1 inventory appendix covers:
  - **Scripts:**
    - `scripts/ensure-prereqs.ps1`
    - `scripts/export-azure_rbac_assignments.ps1`
    - `scripts/export-azure_rbac_definitions.ps1`
    - `scripts/export-azure_scopes.ps1`
    - `scripts/export-entra_apps_service_principals.ps1`
    - `scripts/export-entra_directory_roles.ps1`
    - `scripts/export-entra_group_memberships.ps1`
    - `scripts/export-entra_groups_cloud_only.ps1`
    - `scripts/export-entra_role_assignments.ps1`
  - **Modules:**
    - `modules/entra_connection/entra_connection.psm1`
    - `modules/export/Export.psm1`
    - `modules/logging/Logging.psm1`
  - **Cmdlets:** Ensure extracted commands remain listed in the command appendix.
- [ ] [DOC][DOCS][P1] Re-verify `Connect-AzAccount -UseDeviceAuthentication` guidance on Microsoft Learn and update docs or appendices as required.

### EXPORTS

- [ ] [ENH][EXPORTS][P1] Expose `-TenantId` and `-TenantLabel` (or equivalent) parameters across CLI scripts so operators do not edit `.config/tenants.json` for each run.
- [ ] [ENH][EXPORTS][P1] Apply `Invoke-WithRetry` or chunked pagination to Azure `Get-Az*` calls to avoid throttling on large tenants.
- [ ] [BUG][EXPORTS][P1] Run `scripts/ensure-prereqs.ps1` on a target host to confirm prereq detection still succeeds after Wave 7 changes.
- [ ] [META][EXPORTS][P1] Confirm PSResourceGet 1.0.5 installs cleanly during the prereq run and captures the version pin in logs.
- [ ] [ENH][EXPORTS][P2] Standardize output naming in `outputs/` so CSV/JSON sets follow the same timestamp and dataset pattern.

### MODULES

- [ ] [DOC][MODULES][P2] Update `modules/entra_connection/entra_connection.psm1` with clear comments and metadata for each code block.
- [ ] [META][MODULES][P1] Confirm minimum module versions to pin via `scripts/ensure-prereqs.ps1` and surface them through PSResourceGet.
- [ ] [BUG][MODULES][P1] Validate the connection module against a work environment to ensure tenant selection and auth still behave correctly.
- [ ] [ENH][MODULES][P2] Add parameter validation and clearer errors across shared modules before broader export expansion.
- [ ] [DOC][MODULES][P2] Improve module documentation so operators understand how connection, export, and logging modules interact.

### SCHEMA-FUTURE

- [ ] [ENH][SCHEMA-FUTURE][P3] Reintroduce schema validation helpers and associated tests once datasets stabilize.
- [ ] [ENH][SCHEMA-FUTURE][P3] Define the schema storage location and contract for the future dataset validation phase.

## Per-Script / Per-Module Bring-Up

### scripts/ensure-prereqs.ps1

- [ ] [BUG][EXPORTS][P1] Run the script on a representative host to confirm prereq detection, PSResourceGet installs, and analyzer output persistence still work post-Wave 7.
- [ ] [ENH][EXPORTS][P2] Improve user messaging and parameter handling so tenant and environment overrides do not require file edits.
- [ ] [META][LOGGING][P2] Document and verify the logging emitted during prereq checks once centralized logging lands.

### scripts/seed-entra_test_assets.ps1

- [ ] [BUG][EXPORTS][P2] Validate the seeding workflow on a clean or demo tenant to confirm assets provision correctly and idempotently.
- [ ] [ENH][EXPORTS][P2] Add a `-WhatIf`-style safety switch or equivalent guardrail to prevent accidental writes.
- [ ] [META][LOGGING][P2] Confirm seeding and any rollback behavior emit the shared logging payload once centralized logging is available.

### scripts/export-azure_rbac_assignments.ps1

- [ ] [BUG][EXPORTS][P1] Exercise the script end-to-end against a work tenant to confirm RBAC assignments export without throttling.
- [ ] [ENH][EXPORTS][P2] Align parameter naming (`-TenantId`, `-TenantLabel`, dataset selectors) with the repo design guidelines.
- [ ] [META][LOGGING][P2] Confirm that the script writes the standard run log entry including dataset name, tenant metadata, and correlation ID.

### scripts/export-azure_rbac_definitions.ps1

- [ ] [BUG][EXPORTS][P1] Debug definition exports to ensure scope traversal works for subscriptions and management groups.
- [ ] [ENH][EXPORTS][P2] Add pagination or retry logic for definition enumeration where Azure throttling occurs.
- [ ] [META][LOGGING][P2] Validate that definition exports produce the same logging envelope as other Azure scripts.

### scripts/export-azure_scopes.ps1

- [ ] [BUG][EXPORTS][P1] Confirm the script honors tenant-scoped filtering and does not mix scope types during export.
- [ ] [ENH][EXPORTS][P2] Add parameters for limiting resource types or depth so operators can tailor the scope crawl.
- [ ] [META][LOGGING][P2] Ensure scope exports record their traversal summary inside the shared logging format.

### scripts/export-entra_apps_service_principals.ps1

- [ ] [BUG][EXPORTS][P1] Validate app/service principal exports on a tenant with thousands of registrations to catch throttling or timeout issues.
- [ ] [ENH][EXPORTS][P2] Add filters for publisher verification or ownership state to reduce unnecessary data.
- [ ] [META][LOGGING][P2] Confirm Graph exports record Graph endpoint usage and page counts in the log payload.

### scripts/export-entra_directory_roles.ps1

- [ ] [BUG][EXPORTS][P1] Confirm directory role exports correctly expand role templates and localized names in real tenants.
- [ ] [ENH][EXPORTS][P2] Align output schema fields (role template ID, description, member counts) with other role exports.
- [ ] [META][LOGGING][P2] Verify logging captures the number of directory roles processed per run.

### scripts/export-entra_group_memberships.ps1

- [ ] [BUG][EXPORTS][P1] Debug membership expansion for nested groups to ensure cyclical references are handled safely.
- [ ] [ENH][EXPORTS][P2] Add chunked pagination and retry policies for large group enumerations to prevent Graph throttling.
- [ ] [META][LOGGING][P2] Confirm membership exports emit row counts and throttling notices inside the log entry.

### scripts/export-entra_groups_cloud_only.ps1

- [ ] [BUG][EXPORTS][P1] Validate that cloud-only group filtering works when synced groups exist in the tenant.
- [ ] [ENH][EXPORTS][P2] Provide optional include/exclude filters so operators can target specific group patterns.
- [ ] [META][LOGGING][P2] Ensure the script logs group filters and totals for audit traceability.

### scripts/export-entra_role_assignments.ps1

- [ ] [BUG][EXPORTS][P1] Confirm role assignment exports reconcile Graph and Azure sources without duplication.
- [ ] [ENH][EXPORTS][P2] Add sorting and deterministic output naming so reports compare cleanly across runs.
- [ ] [META][LOGGING][P2] Validate the log payload captures assignment counts per scope and whether fallbacks triggered.

### modules/entra_connection/entra_connection.psm1

- [ ] [BUG][MODULES][P1] Validate environment variable handling and default tenant resolution in a work tenant.
- [ ] [ENH][MODULES][P2] Improve error clarity when authentication fails or required configuration is missing.
- [ ] [DOC][MODULES][P2] Document how the module integrates with centralized logging to expose tenant metadata.

### modules/export/Export.psm1

- [ ] [BUG][MODULES][P1] Confirm export helpers maintain deterministic column ordering across datasets.
- [ ] [ENH][MODULES][P2] Add parameter validation so dataset exports reject unsupported modes early.
- [ ] [META][LOGGING][P2] Wire export helper functions into the shared logging infrastructure and document expected events.

### modules/logging/Logging.psm1

- [ ] [BUG][LOGGING][P1] Debug logging initialization to ensure correlation IDs persist across nested module calls.
- [ ] [ENH][LOGGING][P2] Extend the module to capture structured metadata (dataset name, tenant label, tool version) without duplicating code in scripts.
- [ ] [DOC][LOGGING][P2] Publish usage notes and samples once WO-LOGGING-001 establishes the final API surface.

## General Backlog Notes

- Every new task must include the `[TYPE][AREA][PRIORITY]` tags defined above.
- Remove tasks immediately after they are completed so this backlog stays authoritative.
- Keep this file focused on technical backlog items rather than tool-specific or assistant-specific notes.
