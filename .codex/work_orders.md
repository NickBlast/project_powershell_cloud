# Work Orders — project_powershell_cloud

These work orders are designed to be executed **one at a time**, each producing a focused Pull Request.

Repository:
- https://github.com/NickBlast/project_powershell_cloud

Each work order is self-contained and should not modify areas owned by another work order unless explicitly stated.

---
```markdown
# WO-PR-RULES-000 — Establish Pull Request, Branching, and Change Governance Rules

## Context

To keep this repository maintainable, reviewable, and safe for incremental development, we need strict, explicit rules for:

- Pull Request (PR) size  
- PR scope  
- Branch structure  
- Commit hygiene  
- Reviewability  
- Documentation alignment  
- Expected behavior for automated agents (including Codex)  

These rules must be fully codified into the repo’s governance files so every AI agent and every human contributor follows the same standards.

This work order updates:
- `ai_project_rules.md`
- `repo_contract.md`
- Adds or updates `CONTRIBUTING.md`
- Creates `.github/pull_request_template.md`

No code behavior changes should occur during this PR.

---

## Objective

Implement clear, authoritative PR and workflow rules based on best practices from:

- Google Engineering Practices (Small CLs)
- GitHub Engineering Playbook
- Microsoft ALM Guidelines
- ThoughtWorks / Continuous Delivery
- Martin Fowler (Refactoring / Branching Strategy)

The rules should enforce:

- Small, focused, cohesive PRs  
- One Work Order = One PR  
- Minimal diff size  
- Clear commit grouping  
- Predictable agent behavior  
- Easy debugging and traceability  

The result should dramatically reduce risk and simplify maintenance.

---

## Tasks

### 1. Update `ai_project_rules.md`

Add a **new top-level section** titled **“Pull Request & Change Workflow Rules”** that defines:

#### PR Size Rules
- PRs must be **as small as reasonably possible**, target **< 200 lines changed**.
- Reviewable in **< 20 minutes**.
- If a PR becomes too large, it must be split before submission.

#### PR Scope Rules
- **One Work Order = One PR**.  
- PR must have **one intent** and modify only the files required for that intent.
- No mixing:
  - Refactors + behavior changes  
  - Cleanup + feature work  
  - Logging + export logic  
  - Multiple unrelated fixes  
  - Documentation revamps + code updates  

#### Branching Rules
- One branch per work order.
- Branch naming:
  - `wo-<ID>-short-description`  
  - Example: `wo-logging-001-central-logging`

#### Commit Hygiene
- Commits must be:
  - Small  
  - Logically grouped  
  - No drive-by changes  
  - No commented-out code left behind  

Recommended commit structure:
1. Deletes/moves  
2. Documentation updates  
3. Logic updates  
4. Final polish  

#### Review Rules
- PR description must include:
  - Work Order ID  
  - “This PR Does:”  
  - “This PR Does NOT Do:”  
  - Summary of files touched  
  - Testing performed  

- PR must be understandable top-to-bottom without external context.

#### Documentation Alignment
If a PR changes behavior or expectations, the contributor must:

- Update README
- Update relevant `/docs/` files
- Update `todo.md` (checking off tasks)

#### Safety Rules
- No stealth changes.
- No mixed concerns.
- No hidden dependency updates.
- No formatting + logic changes in the same commit.
- All new behavior must be explicitly described.

Codex MUST follow these rules for all future PRs.

---

### 2. Update `repo_contract.md`

Codex should insert or update a section titled **“Repository Workflow Contract”** with:

- A clear commitment to:
  - Small PRs  
  - One-Work-Order-per-PR  
  - Minimal diff surfaces  
  - Strict branching boundaries  
  - PR template usage  
- A requirement that all automated agents follow the Pull Request Rules from `ai_project_rules.md`.

This ensures the repo governance and AI rules match.

---

### 3. Create or Update `CONTRIBUTING.md`

Codex should create `CONTRIBUTING.md` at the repo root if it doesn’t exist.

The file must contain:

## CONTRIBUTING.md (Example for Codex to implement)

```

# Contributing Guidelines

This repository uses a strict, minimal, Work-Order-driven workflow.

## Branching

* One Work Order = One PR = One Branch
* Branch naming:

  * `wo-<ID>-short-description`
  * Example: `wo-schema-001-remove-schema-files`

## Pull Requests

* PR MUST reference its Work Order ID in the title.
* PR MUST contain only one logical change.
* PR MUST follow the PR template.
* Keep PRs under ~200 changed lines whenever possible.
* Commits must be small and logical:

  * File removal/moves
  * Documentation updates
  * Logic modifications
  * Final polish

## Review Expectations

* PR must be readable in under 20 minutes.
* No “stealth changes.”
* No mixing:

  * Cleanup + feature work
  * Logging + logic changes
  * Schema + export modifications

## Documentation

If a PR affects behavior:

* Update README
* Update `/docs/`
* Update `todo.md` (mark relevant tasks complete)

## Testing

Every PR must be runnable in isolation.

```

Codex should generate this exact structure unless minor adjustments are required.

---

### 4. Create `.github/pull_request_template.md`

Codex should create the file:

**`.github/pull_request_template.md`**

With this exact content:

```

## Work Order

<!-- Example: WO-LOGGING-001 -->

## This PR Does

* …

## This PR Does NOT Do

* …

## Files Touched

* …

## Testing Performed

* …

## Notes for Reviewers

* Keep PRs small, single-purpose, and aligned with the Work Order.

```

This template ensures all PRs provide clear, auditable scope.

---

### 5. Update README (if needed)

Codex should add a short section titled **“Pull Request Philosophy”** summarizing:

- Small PRs  
- One Work Order per PR  
- Branch-per-work-order workflow  
- PR template usage  
- No mixed concerns  

Keep this section at the bottom of README to avoid overwhelming new users.

---

## Constraints

- This PR must ONLY modify:
  - `ai_project_rules.md`
  - `repo_contract.md`
  - `CONTRIBUTING.md`
  - `.github/pull_request_template.md`
  - README (only to add PR philosophy section)

- NO changes to:
  - Scripts
  - Modules
  - Schemas
  - Logging
  - Export functionality

- This PR must be completely non-functional and documentation-only.

---

## Expected Outcomes

After this PR:

- All governance files define small, focused, strict PR rules.
- Codex and any agent now operate with predictable, safe workflows.
- The repo becomes simpler to maintain, debug, and evolve.
- Future PRs become dramatically easier to understand and review.
- The entire development workflow becomes incremental and low-risk.

```
---

# WO-SCHEMA-001 — Remove all schema assets and scrub schema references from documentation & rules

## Context

The repository historically included schema definitions under `docs/schemas/`, schema validation helpers, and documentation describing schema governance.  
Schema is **now fully de-scoped** from the current phase.  
The immediate goal: **raw data exports only (JSON/CSV)** with no schema enforcement.

All schema files, functions, references, and governance language must be removed or rewritten accordingly.

---

## Objective

Remove all schema artifacts and update all documentation and governance files so the repository no longer implies that schema validation exists today.

Schema should be described **only as a future phase**, not an active requirement.

---

## Tasks

### 1. Discover schema assets

- Identify folders and files such as:
  - `docs/schemas/`
  - Any JSON/YAML schema definitions
  - Schema-driven PowerShell helpers
  - Schema-related test helpers

### 2. Remove schema assets

- Delete schema folders/files from the repo.
- If helper functions exist solely to support schema enforcement:
  - Delete them or
  - Move them to `.archive/` with a note:
    - “Preserved for future schema reintroduction.”

### 3. Scrub schema references from all documentation

#### Update `README.md`

- Remove claims that:
  - Schema files exist.
  - Schema validation runs during exports or CI.
  - Schema changes require governance.
- Replace with:
  - “Current phase focuses on raw inventory exports (JSON/CSV).”
  - “Schema definitions will return in a later phase once data is stable.”

#### Update `/docs/`

- Remove or revise:
  - Runbooks referencing schema validation
  - Diagrams pointing to schema directories
  - Developer documentation describing dataset schemas

All references should reflect:
- “Schema is future-phase; not active now.”

### 4. Update repository governance files

#### Update `repo_contract.md`

- Remove requirements around:
  - Schema files
  - Schema location structure
  - Schema review workflow
  - Schema validation CI
- Add a note:
  - “Schema governance is paused until raw exports stabilize.”

#### Update `ai_project_rules.md`

- Remove or rewrite any rule implying schema presently exists.
- Rewrite references to schema to:
  - “Schema design will be reintroduced as a future-phase enhancement.”

### 5. Update `todo.md`

- Move any existing schema tasks into the `SCHEMA-FUTURE` area.
- Remove references to paths like `docs/schemas/`.

### 6. Verification Sweep

- Perform a search for:
  - “schema”
  - “schemas/”
  - “schema validation”
- Ensure no references remain that imply active usage.

---

## Constraints

- Do not change export behavior except where removing broken schema validation.
- Historical mentions of schema in `CHANGELOG.md` must remain (as history).

---

## Expected Outcomes (Pull Request)

- No schema files remain in the repository.
- No documentation implies schema exists today.
- Governance rules are aligned with raw-export-first design.
- `todo.md` records schema as future-phase work only.

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

- `WO-SCHEMA-001` – Remove schema folders and scrub schema references.
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
