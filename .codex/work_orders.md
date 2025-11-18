# Work Orders — project_powershell_cloud

These work orders are designed to be executed **one at a time**, each producing a focused Pull Request.

Repository:
- https://github.com/NickBlast/project_powershell_cloud

Each work order is self-contained and should not modify areas owned by another work order unless explicitly stated.

---

# WO-LOGGING-001 — Add central run logging for all scripts

## Context

Scripts must emit run logs into `logs/` capturing full execution output, while terminal output remains minimal.

---

## Objective

Create a unified logging system applied to every entrypoint script.

---

## Tasks

1. **Create root `logs/` directory**  
   - Add `.gitignore` entry to exclude log files.

2. **Implement reusable logging pattern**  
   - Log filename format:
     - `<YYYYMMDD-HHMMSS>-<scriptname>-run.log`
   - Capture:
     - stdout
     - stderr
     - verbose output

3. **Apply logging to all scripts under `scripts/`**  
   - Each execution generates one log file.
   - Errors and warnings go to the log file, not the console.

4. **Minimize console output**  
   - Success:  
     - “Execution complete. Log: <path>”
   - Failure:  
     - “Errors detected. Check log: <path>”

5. **Update README with a Logging section**

6. **Smoke-test**
   - `ensure-prereqs.ps1`
   - At least one export script

---

## Constraints

- No new external dependencies.
- No functional export logic changes outside logging.

---

## Expected Outcomes (Pull Request)

- All entrypoint scripts write logs.
- Minimal, user-friendly terminal output.
- README updated accordingly.

---

# WO-AUDIT-001 — Merge `audit_notes` into `CHANGELOG.md` and `todo.md`

## Context

`audit_notes` contains mixed historical notes and active tasks.  
These must be consolidated cleanly.

---

## Objective

Eliminate `audit_notes` by merging:

- Completed/historical items → `CHANGELOG.md`
- Active tasks → `todo.md`

---

## Tasks

1. Review each file under `audit_notes/`.
2. Categorize each note:
   - Completed
   - Active/future
   - Ambiguous
3. Add completed items to `CHANGELOG.md`.
4. Add active tasks to `todo.md` under the correct area/category.
5. Add ambiguous items to `todo.md` with a “clarify status” note.
6. Remove the `audit_notes` directory.
7. Update any documentation referencing it.

---

## Constraints

- Maintain historical accuracy.
- Do not fabricate dates or completions.

---

## Expected Outcomes

- `audit_notes` deleted.
- All content represented in `CHANGELOG.md` or `todo.md`.

---

# WO-AI-001 — Remove AI/tooling references from scripts and modules

## Context

Scripts/modules will be copied into a corporate environment where AI references are not permitted.

---

## Objective

Remove all AI-related references from:

- Scripts
- Modules
- Operator-facing documentation

while keeping `.codex/`, `AGENTS.md`, and `ai_project_rules.md` intact (sandbox only).

---

## Tasks

1. Search under:
   - `scripts/`
   - `modules/`
   - Doc files copied with scripts
2. Remove references to:
   - “Copilot”
   - “Codex”
   - “Cline”
   - “ChatGPT”
   - “AI assistant”
3. Rewrite instructions into neutral language.
4. Ensure sandbox-specific files retain their AI language.
5. Ensure README and primary docs do not encourage AI use for operation.

---

## Constraints

- Do not alter functionality of scripts.
- AI tooling references remain in sandbox docs only.

---

## Expected Outcomes

- Scripts and modules contain no AI references.
- Sandbox docs remain untouched.

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

The detailed implementation instructions for these items live in `.codex/work_orders.md`.

- `WO-LOGGING-001` – Add central run logging for all scripts.
- `WO-AUDIT-001` – Merge audit_notes into changelog and todo.
- `WO-AI-001` – Remove tooling references from scripts and modules.
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
