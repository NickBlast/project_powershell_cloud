# AI Project Rules
_Last Updated: 2025-11-17_

## General Principles
- Anchor every task to `AGENTS.md` plus the repo contract/design docs; implement exclusively in PowerShell 7.4+ with `lower_case_with_underscores` directories and approved Verb-Noun naming.
- Run `scripts/ensure-prereqs.ps1`, `Invoke-ScriptAnalyzer -Path . -Recurse`, and `Invoke-Pester` during each wave; do not merge with analyzer warnings or failing tests.
- Current phase is raw-export-first: keep `generated_at`, `tool_version`, and optional `dataset_version` metadata, but **do not** enforce schemas. Schema design/validation will return in a later phase.
- Logging is mandatory: instrument scripts with `modules/logging` (`Write-StructuredLog`, correlation IDs, redaction) and store sanitized samples only under `examples/`, `logs/`, `reports/`, or `outputs/`.
- Use SecretManagement for credentials, pin module versions via PSResourceGet, and document required permissions in `docs/compliance`.
- Maintain the wave/micro-PR cadence by updating `todo.md`, `audit_notes/`, and `CHANGELOG.md` with problem, solution, validation evidence, data impact, and follow-ups. Call out schema considerations only when that future phase is reintroduced.

## Pull Request & Change Workflow Rules
- These rules apply to every contributor and **all automated agents (including Codex)**.

### PR Size Rules
- PRs must be as small as reasonably possible; target **< 200 lines changed**.
- PRs should be reviewable in **< 20 minutes**.
- If a PR becomes too large, it must be split before submission.

### PR Scope Rules
- **One Work Order = One PR.**
- PRs must have **one intent** and only modify files required for that intent.
- Do not mix in a single PR:
  - Refactors + behavior changes
  - Cleanup + feature work
  - Logging changes + export logic changes
  - Multiple unrelated fixes
  - Major documentation rewrites + code updates

### Branching Rules
- One branch per work order.
- Branch naming:
  - `wo-<ID>-short-description`
  - Example: `wo-logging-001-central-logging`

### Commit Hygiene
- Commits must be:
  - Small
  - Logically grouped
  - Free of drive-by changes
  - Free of leftover commented-out code
- Recommended commit grouping:
  1. Deletes/moves
  2. Documentation updates
  3. Logic/config updates
  4. Final polish

### Review Rules
- Every PR description must include:
  - Work Order ID
  - “This PR Does”
  - “This PR Does NOT Do”
  - Summary of files touched
  - Testing performed
- PRs must be understandable top-to-bottom without external context.

### Documentation Alignment
- If a PR changes behavior or expectations, the contributor must:
  - Update README
  - Update relevant `/docs/` files
  - Update `todo.md` (mark relevant tasks complete)
  - Remove completed Work Orders from `work_orders.md` (and `.codex/work_orders.md` when present) and clear completed tasks from `todo.md` so backlogs stay accurate when changes merge.

### Safety Rules
- No stealth changes.
- No mixed concerns in a single PR.
- No hidden dependency changes.
- No formatting + logic changes in the same commit.
- All new behavior must be explicitly described in the PR description.

## Error-Derived Rules
- _None yet — add the first entry here when a recurring issue is resolved._
