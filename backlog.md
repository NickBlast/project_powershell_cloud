```markdown
# Backlog — Single Source of Truth

This file replaces the prior `todo.md` and `work_orders.md` files and serves as the canonical backlog and Work Order registry for the repository.

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
  - `MODULES`        – Shared modules (for example, connection, helpers).
  - `DOCS`           – README, runbooks, and reference documentation.
  - `SCHEMA-FUTURE`  – Schema and validation work deferred to a later phase.

- **Priority**
  - `P1` – High priority / near-term.
  - `P2` – Medium priority.
  - `P3` – Lower priority / future phase.

---

## Work Orders Snapshot

List Work Orders here (one per line). Each Work Order should be small and focused, mapping to a single PR/branch.

- `WO-LOGGING-001` — Centralize run logging for entrypoint scripts.
- `WO-AUDIT-001` — Audit and migrate artifacts (example record; remove when complete).
- `WO-TODO-001` — Restructure backlog and consolidate work orders (this file).

---

## Tasks by Area

### LOGGING

- [ ] [META][LOGGING][P1] Implement centralized run logging (`modules/logging/Logging.psm1`).
- [ ] [ENH][LOGGING][P2] Ensure correlation IDs persist across module boundaries.

### DOCS

- [ ] [DOC][DOCS][P1] Review `docs/` reference files for outdated statements.

### EXPORTS

- [ ] [ENH][EXPORTS][P1] Add tenant parameters to entrypoint scripts.

### MODULES

- [ ] [BUG][MODULES][P1] Validate `modules/entra_connection/entra_connection.psm1` in a test environment.

### SCHEMA-FUTURE

- [ ] [ENH][SCHEMA-FUTURE][P3] Reintroduce schema helpers only after exports stabilize.

---

## Per-Script / Per-Module Bring-Up

Use this section to list a small set of baseline tasks for each script/module.

### scripts/ensure-prereqs.ps1

- [ ] [BUG][EXPORTS][P1] Debug in a representative host environment.
- [ ] [ENH][EXPORTS][P2] Improve messaging and parameter handling.
- [ ] [META][LOGGING][P2] Verify logging emitted during prereq checks.

### scripts/seed-entra_test_assets.ps1

- [ ] [BUG][EXPORTS][P2] Validate seeding workflow is idempotent and safe.
- [ ] [ENH][EXPORTS][P2] Add a `-WhatIf` safety switch.

### modules/entra_connection/entra_connection.psm1

- [ ] [DOC][MODULES][P2] Add clear comments and metadata for each code block.

### modules/export/Export.psm1

- [ ] [BUG][MODULES][P1] Confirm deterministic column ordering for CSV exports.

### modules/logging/Logging.psm1

- [ ] [BUG][LOGGING][P1] Ensure Start/Write/Complete log functions exist and emit consistent metadata.

---

## Work Order Template

Each work order should include:

- **Title**: short descriptive name
- **Context**: why this matters
- **Objective**: clear acceptance criteria
- **Tasks**: small, verifiable steps
- **Validation**: tests/commands to run

---

## General Backlog Notes

- Keep items small and evidence-driven.
- Tag each item with `[TYPE][AREA][PRIORITY]`.
- Remove tasks immediately after completing and merging the change.

---

## How to Use This File

- When opening a PR, reference the Work Order ID (if present), update this file with progress, and record any follow-ups as new items.
- Maintain a single line-per-work-order in the snapshot; move completed work orders to the changelog or archive section if desired.

```
