# AGENTS.md — AI Agent Runbook

This document is the authoritative runbook for **all** assistants (Codex CLI, Gemini CLI, Cline, Cursor, Copilot, etc.) working in `project_powershell_cloud`. Always read this file, `todo.md`, and `ai_project_rules.md` before you touch code. Nested `AGENTS.md` files (if ever added) override instructions only for their directory tree.

---

## 1. Overview & Mission
- Build a **PowerShell-only IAM inventory** tool that exports deterministic CSV + JSON data for Azure-first scenarios (AWS optional where scripts exist).
- Mission reminders (from `.clinerules/00-overview.md` & `01-mission.md`):
  - Deliver audit-grade exports with schemas stored under `docs/schemas/`.
  - No secrets on disk; use SecretManagement.
  - Operate in wave-sized chunks, pausing for human review.
- Source-of-record docs every agent must know:
  - `docs/reference/repo_contract.md`
  - `docs/reference/powershell_repo_design.md`
  - `docs/reference/powershell_standards.md`
  - `.clinerules/*.md` for additional color (overview, steps, coding standards, schema quality, acceptance snippets).

## 2. Project Structure & Ownership
- `modules/`
  - `connect/` tenant/auth helpers (`Connect.psm1`)
  - `export/` dataset & schema-aware logic (`Export.psm1`)
  - `logging/` structured logging utilities (`Logging.psm1`)
- `scripts/` — runnable entrypoints (`export-*.ps1`)
- `docs/` — runbooks, schemas, compliance tables, appendices
- `reports/`, `logs/`, `outputs/` — generated artifacts (never commit secrets)
- Root helpers: `.export_schema_test.ps1`, `.editorconfig`, `.github/workflows/`
- Keep schemas in `docs/schemas/`; update `docs/compliance` when datasets change.

## 3. Required Governance Files
- `todo.md` — shared Active Tasks checklist. Sync every plan and mark completed work. Include validation steps or references when possible.
- `ai_project_rules.md` — project-specific behavior and the “Error-Derived Rules” log (update the “Last Updated” stamp when editing).
- `audit_notes/` — wave-by-wave evidence (environment bootstrap through final summary).

## 4. Build, Test & Validation
- Install prereqs + lint bootstrap: `pwsh ./scripts/ensure-prereqs.ps1`
- Static analysis (treat warnings as errors): `pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse"`
- Run exports (dry run encouraged): `pwsh -File ./scripts/export-azure_rbac_assignments.ps1 -WhatIf`
- Schema sanity: `pwsh -File ./.export_schema_test.ps1`
- Tests: `pwsh -Command "Invoke-Pester"` (use `-Output Detailed` when needed)
- Sample outputs: store under `/examples/` or `/outputs/` and redact sensitive data.

## 5. Operating Steps (per `.clinerules/02-operating-steps.md`)
1. **Read context** — repo contract, design doc, target module/script, schemas/runbooks.
2. **Plan first** — short checklist covering touched files, schema impact, tests, acceptance.
3. **Pre-flight** — run `ensure-prereqs` and ScriptAnalyzer; note/fix findings.
4. **Implement** — PowerShell with comment-based help, structured logging (`/modules/logging`), retry/backoff for throttling, official cmdlets only.
5. **Schema discipline** — outputs must match `docs/schemas/<dataset>.schema.json`; pause for approval before changing schemas and bump dataset versions when needed.
6. **Validation** — rerun Pester, ScriptAnalyzer, generate sample exports.
7. **Changelog & PR prep** — update `CHANGELOG.md`, craft PR summary (problem, solution, acceptance, lint/test evidence, schema notes, compliance updates).

## 6. Coding Style & Naming (see `.clinerules/03-coding-standards.md`)
- PowerShell indentation = 4 spaces; LF endings.
- Functions: Verb-Noun (approved verbs only), PascalCase for exported functions, lowerCamelCase locals.
- Modules contain reusable logic; scripts stay thin.
- Include comment-based help with runnable examples for every exported function or script.
- Explicit cmdlet imports; no aliases; prefer pure functions returning objects (formatting occurs in export layer).

## 7. Schema, Logging & Quality Gates (`.clinerules/04-schema-and-quality.md`)
- Never emit fields absent from `docs/schemas/<dataset>.schema.json`.
- Each dataset output requires `generated_at`, `tool_version`, `dataset_version`.
- Exports must be idempotent (safe overwrites for same dataset_version).
- Use `Write-StructuredLog` with redaction before logging PII/secrets.
- Do not merge with ScriptAnalyzer warnings or failing tests; document narrow suppressions in `docs/reference/psscriptanalyzer_ruleset.md`.
- Avoid unapproved external CLIs/modules; stick to Microsoft-supported tooling.

## 8. Acceptance Criteria Templates (`.clinerules/05-acceptance-snippets.md`)
- Example: **Azure RBAC Assignments**
  - All scopes covered; counts match portal samples.
  - CSV/JSON validate against `/docs/schemas/azure_rbac_assignments.schema.json` (v1.0).
  - Deterministic reruns; logs redact PII.
- Use these snippets when defining new datasets or enhancements; add new entries as datasets expand.

## 9. Commit, Branch & PR Workflow
- Branch naming: `feat/<area>__<slug>`, `fix/<area>__<slug>`, `docs/<area>__<slug>` (wave-specific names allowed, e.g., `fix/pwsh-wave-3-analyzer`).
- Commits: Conventional Commits (`type(scope): summary`), single-purpose, imperative.
- PR requirements:
  - Summary of changes, linked issues, sample outputs/logs (redacted), validation steps.
  - Annotate schema or compliance impacts.
  - Include analyzer/test status and follow-up tasks referencing `todo.md`.
  - Pause after each wave for human review.

## 10. Security & Configuration
- Use PowerShell 7.4+; modules install to CurrentUser via `scripts/ensure-prereqs.ps1`.
- No secrets in repo; rely on SecretManagement + environment auth.
- Validate that generated artifacts stay in `reports/`, `logs/`, or `outputs/` and remain uncommitted unless scrubbed for documentation.
- Respect policy: CI uses `AllSigned`, developers may use `RemoteSigned`.

## 11. Cross-Agent Expectations
- Share findings in `todo.md` and `ai_project_rules.md` so every assistant has the same context.
- Before editing any file:
  - Read this AGENTS runbook plus any nested version within the directory.
  - Check `todo.md` for existing tasks to avoid duplication.
  - Review `ai_project_rules.md` for project-specific lessons/errors.
- If you create new runbooks or schema notes, reference them here and in `ai_project_rules.md`.

---

**Always** treat the user (Product Owner) as the merge authority. Present work as proposals, include validation evidence, and wait for explicit approval before assuming anything is final.
