# Work Orders — project_powershell_cloud

These work orders are designed to be run one at a time by an automated coding assistant working against:

- Repository: https://github.com/NickBlast/project_powershell_cloud

Each work order is self-contained and should result in a focused pull request.

---

## WO-SCHEMA-001 — Remove schema folders and de-scope schema from current phase

### Context

The repository currently describes schema files and schema validation as part of the normal run path (for example under `docs/schemas/` and in the README), but the actual scripts are not yet stable. For the current phase, the priority is **raw exports running reliably**, not schema enforcement.

### Objective

Remove all schema-related folders and files, and update documentation so that:

- The current behavior is clearly “raw export first.”
- Schema and report design are explicitly marked as **future work**, not part of the current implementation.

### Tasks

1. **Discover schema locations**
   - Scan the repository for any folders and files that are clearly used for schema definitions (for example `docs/schemas/` or similarly named locations).
   - Identify any PowerShell functions that are strictly schema helpers and not required for basic raw exports (such as schema-specific test helpers).

2. **Remove schema assets from the active repo tree**
   - Delete schema folders and files that are dedicated solely to schema definitions.
   - If there are schema-related helper functions that are not currently used by any running script:
     - Either delete them, or move them into an archival location such as `.archive/` with a brief comment stating they are for future schema work.

3. **Update documentation and references**
   - Update `README.md` and any documentation files that currently:
     - Point to schema files under `docs/schemas/`.
     - State that schema validation is performed as part of the normal run path.
   - Replace those statements with language that clearly states:
     - “Current phase focuses on raw inventory exports (JSON/CSV).”
     - “Schema definitions and schema validation will be introduced in a later phase once exports are stable.”
   - Update any “minimal troubleshooting” guidance that refers to schema-related logs or schema validation output so it no longer implies schema validation is active.

4. **Align the existing TODO**
   - Locate the existing todo file (`todo.md`).
   - Update any tasks that reference schema work so they are clearly tagged as future-phase items (for example under a “Schema – Future” section), without referencing specific schema file paths that no longer exist.

### Constraints

- Do not change core export script behavior beyond removing direct schema validation that depends on deleted files.
- Do not introduce new features; focus only on removing schema assets and adjusting documentation.
- Preserve any historical notes about schema in `CHANGELOG.md` or `todo.md`, but clearly mark them as **future work** rather than current behavior.

### Expected Outcomes (Pull Request)

- All schema folders and dedicated schema definition files are removed or archived.
- `README.md` and any related docs no longer claim that schema files live under `docs/schemas/` or that schema validation is part of the current export flow.
- `todo.md` reflects schema work as a **future-phase** category rather than an active requirement.
- All export scripts still run (or fail for pre-existing reasons only) without referencing missing schema files.

---

## WO-LOGGING-001 — Add central run logging for all scripts

### Context

The repository lacks a consistent logging story. The requirement is:

- Every script run should produce a log file in a central `logs/` folder.
- Log files should contain everything that would normally appear in the terminal.
- Terminal output should stay minimal and user-friendly, pointing to the relevant log file.

### Objective

Implement a centralized logging pattern across all entrypoint scripts such that **every script run**:

- Writes a full log to `logs/` using a consistent naming convention.
- Keeps terminal output brief and focused on overall status and where to find the log.

### Tasks

1. **Establish logging directory and naming convention**
   - Ensure a root-level `logs/` directory exists.
   - Update `.gitignore` so that log files under `logs/` are not committed to source control.
   - Adopt a log filename convention:
     - `<YYYYMMDD-HHMMSS>-<script_name>-run.log`
     - Example: `20251117-103045-export-azure_scopes-run.log`.

2. **Design a central logging pattern**
   - Implement a reusable logging approach (for example, a helper function in a shared module or a standard pattern) that:
     - Captures all console output (standard and verbose) into the log file.
     - Minimizes duplication across scripts.
   - The exact implementation details can follow existing repository patterns (for example, if `Write-StructuredLog` or similar helpers exist, repurpose or update them to support full-run logging).

3. **Apply logging across all entrypoint scripts**
   - Identify all PowerShell entrypoint scripts (for example under `scripts/`).
   - For each entrypoint script:
     - Wire it to use the centralized logging pattern so that:
       - Every run produces a unique log file in `logs/`.
       - Errors and warnings are captured in the log.
     - Reduce console output to:
       - High-level progress or summary lines.
       - Final status messages:
         - On success: a message indicating success and the path to the log file.
         - On failure: a message indicating failure and the path to the log file (for example, “Errors detected. Check log file <filename> in logs/.”).

4. **Update basic documentation**
   - Add a brief “Logging” section to `README.md` or the primary docs that:
     - Explains that scripts now write logs to `logs/`.
     - Explains the filename pattern.
     - Gives short instructions for reviewing logs when troubleshooting.

5. **Smoke-test logging**
   - Run at least:
     - The prerequisites script (for example `scripts/ensure-prereqs.ps1`).
     - One Azure export script (for example `scripts/export-azure_scopes.ps1` if present).
   - Confirm that:
     - Each run created a log file in `logs/`.
     - The console output is minimal and points to the log file.
     - No new errors were introduced solely due to logging changes.

### Constraints

- Do not alter the functional behavior of exports beyond adding logging.
- Avoid adding heavy external dependencies for logging; use built-in PowerShell capabilities.
- Maintain compatibility with PowerShell 7 or later.

### Expected Outcomes (Pull Request)

- A new or updated `logs/` directory exists with `.gitignore` rules to exclude logs from version control.
- All entrypoint scripts produce run logs in `logs/` with a consistent naming convention.
- Console output is minimal and instructs the operator to review the log file on success or failure.
- Documentation briefly describes where logs are created and how to interpret them.

---

## WO-AUDIT-001 — Merge `audit_notes` into `CHANGELOG.md` and `todo.md`

### Context

There is an `audit_notes` directory containing change notes and tasks, which behaves like a secondary backlog/change history. The goal is to collapse these into:

- `CHANGELOG.md` for historical/completed work.
- `todo.md` for active or future tasks.

### Objective

Eliminate the `audit_notes` directory by consolidating its content into `CHANGELOG.md` and `todo.md`, so that:

- `CHANGELOG.md` is the single source of historical changes.
- `todo.md` is the single source of outstanding work.

### Tasks

1. **Review all `audit_notes` content**
   - Open each file under `audit_notes/`.
   - Classify each note as one of:
     - Completed work / historical record.
     - Active or future task.
     - Ambiguous (status unclear).

2. **Move historical items into `CHANGELOG.md`
   - For completed or historical items:
     - Add them as entries to `CHANGELOG.md` in a logical chronological grouping.
     - Keep the descriptions concise but informative.
     - If specific dates are available, preserve them; otherwise, group under the approximate timeframe or version.

3. **Move active tasks into `todo.md`**
   - For active or future tasks:
     - Add them as entries into `todo.md` under the appropriate section (for example by area such as LOGGING, MODULES, EXPORTS, SCHEMA-FUTURE, DOCS).
     - If possible, tie each task to a specific script or module.

4. **Handle ambiguous items**
   - For any note that is ambiguous:
     - Do not discard it.
     - Add it to `todo.md` with a brief tag such as “clarify status” so it can be cleaned up later.

5. **Delete the `audit_notes` directory**
   - Once all items have been thoughtfully relocated:
     - Remove the `audit_notes` directory from the repository.
   - Update any documentation that references `audit_notes` to point to `CHANGELOG.md` and `todo.md` instead.

### Constraints

- Do not invent new change history; only reformat and consolidate existing notes.
- Preserve as much useful information as possible while keeping `CHANGELOG.md` readable.
- Do not alter existing semantic versioning or release structure in `CHANGELOG.md`, if present.

### Expected Outcomes (Pull Request)

- All relevant `audit_notes` content is now represented either in `CHANGELOG.md` or `todo.md`.
- `audit_notes/` has been removed from the repository.
- There is a clear separation between historical changes (`CHANGELOG.md`) and upcoming work (`todo.md`).

---

## WO-AI-001 — Remove AI/tooling references from scripts and modules

### Context

Scripts and modules from this repository will be manually copied to a restricted corporate environment where:

- Use of AI tooling is not permitted.
- References to AI tooling inside scripts/modules may be problematic.

However, AI-specific meta files (for example `.codex`, `AGENTS.md`, `ai_project_rules.md`) should remain for local sandbox usage.

### Objective

Remove or neutralize references to AI tooling from any **scripts, modules, or operator-facing doc files** that are likely to be copied to a corporate environment, while leaving dedicated AI meta files intact.

### Tasks

1. **Identify AI/tooling references**
   - Search under:
     - `scripts/`
     - `modules/`
     - Any small, script-adjacent documentation that operators would likely copy along with scripts (for example docs that live directly under `scripts/` or `modules/`).
   - Look for references to:
     - AI tools by name (for example “Copilot”, “Codex”, “Cline”, “ChatGPT”).
     - Phrases that suggest code was generated by AI.
     - Instructions that tell the user to “ask an AI agent” or similar.

2. **Rewrite or remove problematic references**
   - For comments or documentation inside scripts/modules:
     - Replace AI-specific language with neutral engineering language (for example, “Review the log file and update the script as needed” instead of “Ask your AI assistant to fix this”).
   - Ensure that the meaning of the operational instructions is preserved without mentioning AI or external tooling.

3. **Preserve sandbox AI meta content**
   - Do **not** modify or remove:
     - `AGENTS.md`
     - `ai_project_rules.md`
     - Contents of `.codex/` or other clearly AI-focused files.
   - If any AI-focused guidance was previously embedded in core docs (for example main `docs/` or `README.md` sections needed by operators), move that guidance into a clearly sandbox-oriented doc if necessary, or remove it entirely if redundant.

4. **Quick pass on `docs/`**
   - For primary docs that operators may read alongside scripts (for example the main `README.md` and core runbooks):
     - Remove explicit references to AI-driven development.
     - Focus text on how to run and troubleshoot scripts using logs and standard tools.

### Constraints

- Do not modify core script logic except for comment/docstring changes.
- Keep all sandbox-oriented AI meta files untouched; they are needed in the local environment.

### Expected Outcomes (Pull Request)

- All PowerShell scripts and modules are free of explicit AI references in comments or operator-facing text.
- Operator-facing documentation intended to go with scripts is free of explicit AI references.
- AI meta files (for example `.codex`, `AGENTS.md`, `ai_project_rules.md`) remain unchanged.

---

## WO-TODO-001 — Restructure `todo.md` with categories and per-script/module tasks

### Context

The current `todo.md` file is a single list of tasks. The desired state is:

- `todo.md` as the **single source of backlog**, structured by:
  - Type (`BUG`, `ENH`, `META`, `DOC`)
  - Area (`LOGGING`, `EXPORTS`, `MODULES`, `DOCS`, `SCHEMA-FUTURE`, etc.)
- A dedicated section for **per-script and per-module bring-up**.

Existing tasks should be preserved and mapped into this structure.

### Objective

Refactor `todo.md` so that it:

- Contains a legend describing categories and priorities.
- Contains a “Work Orders Snapshot” section that references the work orders in `.codex/WORK_ORDERS.md` by ID.
- Categorizes existing tasks and adds a per script/module bring-up section.

### Tasks

1. **Add legend and structure**
   - Introduce a legend at the top of `todo.md` that explains:
     - Type tags (`BUG`, `ENH`, `META`, `DOC`).
     - Area tags (`LOGGING`, `EXPORTS`, `MODULES`, `DOCS`, `SCHEMA-FUTURE`, etc.).
     - Priority tags (`P1`, `P2`, `P3`).
   - Add a “Work Orders Snapshot” section listing the work order IDs and their titles (for example `WO-SCHEMA-001 – Remove schema folders and references`).

2. **Map existing tasks into categorized sections**
   - Take the current tasks from `todo.md` and place them into the appropriate sections, for example:
     - Docs review and documentation rules → `[DOC][DOCS]`.
     - Logging-related instrumentation → `[META][LOGGING]` or `[ENH][LOGGING]`.
     - Schema-related tasks → `[ENH][SCHEMA-FUTURE]`.
     - Tenant parameterization, retry logic, module comments → `[ENH][EXPORTS]` or `[DOC][MODULES]`.
   - Ensure that each task line includes the Type, Area, and Priority tags.

3. **Create “Tasks by Area” sections**
   - For example:
     - `### LOGGING`
     - `### MODULES`
     - `### EXPORTS`
     - `### DOCS`
     - `### SCHEMA-FUTURE`
   - Place the categorized tasks under these headings.

4. **Add a per-script / per-module bring-up section**
   - Add a section labeled like `## Per-Script / Per-Module Bring-Up`.
   - For each script under `scripts/` and module under `modules/`:
     - Add a subsection with the file path as the title.
     - Add at least three baseline tasks:
       - Run and debug in target environment.
       - Enhance and refine parameters/output.
       - Confirm logging and documentation.
   - It is acceptable to start with a subset of the most important scripts and modules; the rest can be added incrementally.

5. **Remove outdated structure**
   - Remove the old “Project Tasks” heading and any unstructured lists that are now represented in the new sections.
   - Ensure that all previously existing tasks are represented in the new structure (none are accidentally dropped).

### Constraints

- Do not include explicit references to AI tooling or agent names in `todo.md`.
- Keep `todo.md` readable for human operators and suitable for use in a corporate environment.

### Expected Outcomes (Pull Request)

- `todo.md` has:
  - A legend explaining tags.
  - A “Work Orders Snapshot” section with references to this file.
  - “Tasks by Area” sections with categorized tasks.
  - A “Per-Script / Per-Module Bring-Up” section listing scripts/modules with standard tasks.
- All previously existing tasks are preserved and clearly tagged.
- `todo.md` contains no explicit references to AI tooling.


### Example of todo.md to follow
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
  - `MODULES`        – Shared modules (for example connection, helpers).
  - `DOCS`           – README, runbooks, and reference docs.
  - `SCHEMA-FUTURE`  – Schema and validation work deferred to a later phase.

- **Priority**
  - `P1` – High priority / near-term.
  - `P2` – Medium priority.
  - `P3` – Lower priority / future phase.

---

## Work Orders Snapshot

The detailed implementation instructions for these items live in `.codex/WORK_ORDERS.md`.

- `WO-SCHEMA-001` – Remove schema folders and de-scope schema from current phase.
- `WO-LOGGING-001` – Add central run logging for all scripts.
- `WO-AUDIT-001` – Merge `audit_notes` into `CHANGELOG.md` and `todo.md`.
- `WO-AI-001` – Remove tooling references from scripts and modules.
- `WO-TODO-001` – Restructure `todo.md` with categories and per-script/module tasks.

---

## Tasks by Area

### LOGGING

- [ ] [META][LOGGING][P1] Implement central run logging for all entrypoint scripts so each run writes a full log to `logs/` using a predictable filename pattern. (WO-LOGGING-001)
- [ ] [ENH][LOGGING][P2] Replace or extend existing logging helpers (for example structured logging functions) so that they route output into the new run log files rather than relying on verbose-only output.
- [ ] [DOC][LOGGING][P2] Add a short “Logging” section to the main documentation describing where logs are written, how they are named, and how to use them during troubleshooting.

### DOCS

- [ ] [DOC][DOCS][P1] Review `docs/` (reference, runbooks, schema guidance) for outdated statements or gaps, especially references to schemas that are no longer part of the current phase. Align wording with “raw exports first; schema later.” (WO-SCHEMA-001)
- [ ] [DOC][DOCS][P2] Ensure the main `README.md` reflects the simplified scope: PowerShell-only tooling, Azure as the primary focus, raw export outputs to `outputs/`, and logging to `logs/`.
- [ ] [DOC][DOCS][P2] Confirm that general troubleshooting guidance refers to log files under `logs/` instead of older patterns (for example logs in `outputs/`).

### EXPORTS

- [ ] [ENH][EXPORTS][P1] Expose `-TenantId` and/or `-TenantLabel` parameters on command-line scripts so operators do not have to edit `.config/tenants.json` for each run.
- [ ] [ENH][EXPORTS][P2] Apply retry or pagination patterns to Azure exports (for example `Get-Az*` calls) so they handle throttling and large tenants more gracefully, consistent with any existing retry patterns used for Microsoft Graph.
- [ ] [ENH][EXPORTS][P2] Standardize output file naming for export scripts so outputs in `outputs/` are predictable and include at least a timestamp and dataset/tenant identifier.

### MODULES

- [ ] [BUG][MODULES][P1] Validate the connection module (for example `modules/entra_connect.psm1` or its renamed equivalent) in the target environment and fix any authentication or configuration issues discovered during real runs.
- [ ] [DOC][MODULES][P2] Update the connection module with clear comments and metadata for each significant block so operators and reviewers can understand what each part of the module is doing.
- [ ] [ENH][MODULES][P2] Add basic parameter validation and improved error messages to the connection module and other shared modules that handle configuration, so misconfiguration is surfaced clearly.

### SCHEMA-FUTURE

- [ ] [ENH][SCHEMA-FUTURE][P3] Enhance any remaining schema-related helpers (for example `Test-ObjectAgainstSchema`) to enforce property types and additional fields (for example via `Test-Json` or similar), once schema work is reintroduced in a future phase.
- [ ] [ENH][SCHEMA-FUTURE][P3] Design a minimal schema strategy and location for future dataset definitions once raw exports and logging are stable.

---

## Per-Script / Per-Module Bring-Up

This section tracks work to verify and refine each script and module one at a time in the target (work) environment. Add additional entries as new scripts and modules are created.

### scripts/ensure-prereqs.ps1

- [ ] [BUG][EXPORTS][P1] Run and debug this script in the work environment; resolve any missing modules, permissions, or platform issues.
- [ ] [ENH][EXPORTS][P2] Refine messaging so operators clearly understand what prerequisites are being installed or verified.
- [ ] [DOC][EXPORTS][P2] Add or update any usage notes in the documentation to show how and when this script should be run.

### scripts/export-azure_scopes.ps1

- [ ] [BUG][EXPORTS][P1] Run and debug this export in the work environment and ensure it can complete successfully against at least one real subscription or tenant.
- [ ] [ENH][EXPORTS][P2] Align parameter names and defaults (for example tenant/subscription selection) with the overall design so operators do not need to edit configuration files directly.
- [ ] [META][LOGGING][P1] Confirm that this script uses the central logging pattern and produces a run log in `logs/` with the expected filename structure.

### modules/entra_connect.psm1 (or updated connection module name)

- [ ] [BUG][MODULES][P1] Verify that this module can successfully establish connections in the work environment using the expected environment variables and configuration files.
- [ ] [ENH][MODULES][P2] Improve error handling so common failure modes (for example invalid credentials, missing configuration) return clear, actionable error messages.
- [ ] [DOC][MODULES][P2] Document module responsibilities and key functions with comments and brief usage notes, so the connection setup is easy to understand.

---

## General Backlog Notes

- Keep this file free of explicit references to any specific development tools or assistants.
- When new work is identified, choose an appropriate Type, Area, and Priority and add it under the relevant section or create a new section as needed.
- Remove tasks promptly once they are completed to keep this backlog accurate and lightweight.
