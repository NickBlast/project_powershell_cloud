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

---

## Workflow Migration Work Orders

# WO-WORKFLOW-001 — Define GitHub Issue labels and templates

## Summary
Design Issue types and labels for Work Orders, Bugs, and Research tasks.

## Tasks
1. Research & Plan: Review GitHub documentation on Issue templates and labels before implementation.
2. Define label taxonomy for type and status.
3. Draft GitHub Issue templates for Work Orders, Bugs, and Research.
4. Add template configuration under `.github/ISSUE_TEMPLATE`.
5. Validate that new Issues can be created with the templates, confirming labels and fields.

## Acceptance Criteria
- Creating a new Issue shows the three templates.
- Templates apply correct labels and fields.

---

# WO-WORKFLOW-002 — Freeze markdown trackers for new work

## Summary
Transition new work tracking to GitHub Issues once templates exist and clearly mark markdown trackers as migration-only.

## Tasks
1. Research & Plan: Review `ai_project_rules.md` constraints before editing.
2. Update `ai_project_rules.md` to state that new work must be tracked in GitHub Issues once templates are available.
3. Add a banner at the top of `work_orders.md` and `todo.md` marking them as "no new work, migration in progress" after Stage 1 completes.
4. Confirm contributors know to open new Issues instead of adding markdown entries.

## Acceptance Criteria
- `ai_project_rules.md` calls for Issues as the canonical backlog post-template creation.
- `work_orders.md` and `todo.md` display a migration banner once Stage 1 is complete.

---

# WO-WORKFLOW-003 — Migrate open Work Orders and todos into GitHub Issues

## Summary
Move existing Work Orders and backlog items into GitHub Issues using the new templates.

## Tasks
1. Research & Plan: Review GitHub documentation on closing Issues via Pull Requests before migrating entries.
2. Inventory all open Work Orders.
3. Inventory todos that should become Issues.
4. Create matching GitHub Issues for each item using the new templates.
5. Mark migrated entries in `work_orders.md` and `todo.md` as archived or migrated.

## Acceptance Criteria
- All open Work Orders and relevant todos have corresponding GitHub Issues.
- Migrated markdown entries are marked as archived/migrated with links or identifiers.

---

# WO-WORKFLOW-004 — Enforce AI agent rules and automation for Issue workflow

## Summary
Update guardrails and automation to enforce the Issue → branch → Pull Request flow.

## Tasks
1. Research & Plan: Review official guidance for GitHub automation options before updating guardrails.
2. Update `ai_project_rules.md` and `AGENTS.md` to describe the Issue → branch → Pull Request flow.
3. Plan a minimal GitHub Actions workflow to enforce the new process (implemented in a later Pull Request).
4. Emphasize that each Work Order or Issue begins with a short Research & Plan subtask leveraging official vendor documentation.

## Acceptance Criteria
- `ai_project_rules.md` and `AGENTS.md` capture the Issue-driven workflow and Research & Plan requirement.
- A follow-on work item is ready to add GitHub Actions enforcement without ambiguity.
