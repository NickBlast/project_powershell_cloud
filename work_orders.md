# Work Orders — project_powershell_cloud

These work orders are designed to be executed **one at a time**, each producing a focused Pull Request.

Repository:
- https://github.com/NickBlast/project_powershell_cloud

Each work order is self-contained and should not modify areas owned by another work order unless explicitly stated.

---
# WO-TODO-001 — Restructure `todo.md` with categories and per-script/module tasks

## Context

`todo.md` should become the **single, structured backlog** for the project.

---

## Objective

Rewrite `todo.md` so it:

- Contains a clear tagging system
- Has “Tasks by Area”
- Has a “Per-Script / Per-Module Bring-Up” section
- Contains a snapshot of work orders by ID

---

## Tasks

1. Add a legend describing:
   - Type tags: `BUG`, `ENH`, `META`, `DOC`
   - Areas: `LOGGING`, `EXPORTS`, `MODULES`, `DOCS`, `SCHEMA-FUTURE`
   - Priorities: `P1`, `P2`, `P3`

2. Add a “Work Orders Snapshot” section referencing this file.

3. Categorize all existing tasks into Areas with correct tags.

4. Create “Tasks by Area” sections.

5. Add a “Per-Script / Per-Module Bring-Up” section with:
   - One subsection per script/module
   - Three baseline tasks:
     - Debug
     - Enhance
     - Document/verify logging

6. Remove old, unstructured task lists.

---

## Expected Outcomes

- A clean, categorized `todo.md` suitable for corporate use.
- All tasks preserved and structured.
- Zero references to AI.

---

# WO-LOGGING-001 — Centralized run logging for entrypoint scripts

## Context

Entrypoint scripts currently emit ad-hoc console messages. A centralized, structured run log is required so operators can trace dataset runs with correlation identifiers, tenant metadata, and tool versions.

---

## Objective

Create a reusable logging spine in `modules/logging/Logging.psm1` and wire it into priority scripts so every run writes a consistent log file under `logs/` with machine-parseable entries.

---

## Tasks

1. Define the logging API (`Start-RunLog`, `Write-RunLog`, `Complete-RunLog`) with a standard log file name pattern and JSON line entries.
2. Update `scripts/ensure-prereqs.ps1` to emit structured run logs for prerequisite checks without altering its functional behavior.
3. Update `scripts/export-azure_scopes.ps1` to capture connection attempts and export summaries using the shared logging context.
4. Refresh `todo.md` and relevant documentation to reflect the new logging pattern and remaining migration work for other scripts.

---

## Acceptance Criteria

- `modules/logging/Logging.psm1` exposes the shared API and documents usage at the top of the module.
- `scripts/ensure-prereqs.ps1` and `scripts/export-azure_scopes.ps1` write run logs to `logs/` with correlation IDs and metadata (script name, dataset name, tenant details when available).
- Backlog entries in `todo.md` are updated to mark completed logging tasks and note follow-on migrations.
- Repository documentation mentions where to find run logs and what they contain.

---

## **Example `todo.md` Structure (Include This Under WO-TODO-001)**

```markdown
# Project Tasks

Use this file as the single backlog. Keep entries actionable and remove them as they are completed.

---

## Legend

- **Type**
  - `BUG`  – Fixing broken behavior or test failures.
  - `ENH`  – Enhancements or feature improvements.
  - `META` – Repository structure, logging, build, or cross-cutting refinements.
  - `DOC`  – Documentation, comments, or metadata improvements.

- **Area**
  - `LOGGING`        – Run logs, diagnostics, and observability.
  - `EXPORTS`        – Export scripts and output behavior.
  - `MODULES`        – Shared modules (e.g., connection, helpers).
  - `DOCS`           – README, runbooks, and reference docs.
  - `SCHEMA-FUTURE`  – Schema and validation work deferred to a later phase.

- **Priority**
  - `P1` – High priority / near-term.
  - `P2` – Medium priority.
  - `P3` – Lower priority / future phase.

---

## Work Orders Snapshot

The detailed implementation instructions for these items live in the sandbox-only work_orders file.

- `WO-LOGGING-001` – Add central run logging for all scripts.
- `WO-AUDIT-001` – Merge audit_notes into changelog and todo.
- `WO-TODO-001` – Restructure todo.md with categories and per-script/module tasks.

---

## Tasks by Area

### LOGGING

- [ ] [META][LOGGING][P1] Implement centralized run logging for all entrypoint scripts.  
- [ ] [ENH][LOGGING][P2] Refine existing logging helpers for compatibility with new log capture pattern.  
- [ ] [DOC][LOGGING][P2] Add log review instructions to README.

### DOCS

- [ ] [DOC][DOCS][P1] Clean documentation referencing schema; rewrite for raw export phase.  
- [ ] [DOC][DOCS][P2] Ensure README reflects simplified scope.  
- [ ] [DOC][DOCS][P2] Move troubleshooting guidance to use logs/ directory.  

### EXPORTS

- [ ] [ENH][EXPORTS][P1] Add -TenantId/-TenantLabel parameters to scripts.  
- [ ] [ENH][EXPORTS][P2] Add retry/pagination for Azure exports.  
- [ ] [ENH][EXPORTS][P2] Standardize output naming in outputs/.  

### MODULES

- [ ] [BUG][MODULES][P1] Validate connection module in work environment.  
- [ ] [DOC][MODULES][P2] Improve connection module documentation.  
- [ ] [ENH][MODULES][P2] Add parameter validation and clearer errors.  

### SCHEMA-FUTURE

- [ ] [ENH][SCHEMA-FUTURE][P3] Reintroduce schema helpers once raw exports are stable.  
- [ ] [ENH][SCHEMA-FUTURE][P3] Define schema location and contract for future dataset validation.  

---

## Per-Script / Per-Module Bring-Up

### scripts/ensure-prereqs.ps1

- [ ] [BUG][EXPORTS][P1] Debug in work environment  
- [ ] [ENH][EXPORTS][P2] Improve user messaging  
- [ ] [DOC][EXPORTS][P2] Document when and how to run  

### scripts/export-azure_scopes.ps1

- [ ] [BUG][EXPORTS][P1] Debug in work environment  
- [ ] [ENH][EXPORTS][P2] Align parameters with repo design  
- [ ] [META][LOGGING][P1] Confirm logging pattern  

### modules/entra_connect.psm1

- [ ] [BUG][MODULES][P1] Validate environment variable handling  
- [ ] [ENH][MODULES][P2] Improve error clarity  
- [ ] [DOC][MODULES][P2] Add module comments and usage notes  

---

## General Backlog Notes

- Keep this file free of explicit references to development tools.
- Assign a Type, Area, and Priority for new tasks.
- Remove tasks promptly once complete.
