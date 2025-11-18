# AGENTS.md — Unified Runbook

This file is the single source of truth for every assistant (Codex, Gemini, Cline, Cursor, Copilot, etc.) working in `project_powershell_cloud`. Read this runbook, `ai_project_rules.md`, and `todo.md` before touching code.

## 1. Overview & Mission
- Build a PowerShell-only IAM inventory/export tool that emits deterministic CSV + JSON for Azure-first datasets (extend to AWS/GCP only when scripts exist).
- Deliver audit-grade evidence: deterministic outputs with `generated_at`, `tool_version`, and future-friendly `dataset_version` fields. Schema governance is paused during the raw-export phase; never store secrets/PII in the repo.
- Source-of-record docs: `docs/reference/repo_contract.md`, `docs/reference/powershell_repo_design.md`, `docs/reference/powershell_standards.md`, `docs/reference/powershell_sources_of_record.md`, `docs/reference/help_authoring.md`, `docs/reference/psscriptanalyzer_ruleset.md`.

## 2. Project Structure & Key Paths
- `modules/` — reusable logic (`entra_connection/`, `export/`, `logging/`); keep normalization and logging here.
- `scripts/` — thin CLI entry points such as `scripts/export-*.ps1` and `scripts/ensure-prereqs.ps1`.
- `docs/` — reference docs, compliance mappings, prompt banks. (Schemas are archived for a future phase.)
- `audit_notes/` — per-wave evidence; log artifacts after each wave/micro-PR.
- `reports/`, `logs/`, `outputs/` — generated artifacts (never commit secrets); `examples/` for sanitized samples.
- Root helpers: `.editorconfig`, `.github/workflows/`.

## 3. Governance Files & Read Order
1. `AGENTS.md` (this runbook).
2. `ai_project_rules.md` for project-specific guardrails and error-derived lessons.
3. `todo.md` as the single backlog.
4. `docs/reference/*.md` for detailed standards.
Other prompt banks (`.clinerules/`, `.gemini/`, `docs/prompts/`, `clinerules-bank/`) are reference only.

## 4. First-Run Environment Review
- Skim `README.md`, `CHANGELOG.md`, and `todo.md` to understand current priorities.
- Confirm PowerShell 7.4+; run `pwsh -File ./scripts/ensure-prereqs.ps1` to install modules via PSResourceGet.
- Review relevant modules/scripts and `docs/compliance` entries before editing. Schema definitions will return in a later phase.
- Capture blockers or context gaps in `todo.md` or `audit_notes/`.

## 5. Build, Test & Validation Commands
- `pwsh -File ./scripts/ensure-prereqs.ps1` — dependency bootstrap and lint sanity check.
- `pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse"` — treat warnings as errors; document suppressions.
- `pwsh -Command "Invoke-Pester"` — contract tests (`-Output Detailed` when needed).
- `pwsh -File ./scripts/export-<dataset>.ps1 -WhatIf` — dry-run dataset inspection.
- Store sanitized sample outputs under `examples/` (or redacted `outputs/`), never committing secrets.

## 6. Planning & Micro-PR Workflow
1. **Plan** — produce a short checklist (touched files, data/test impact, validation steps) before coding; keep waves small.
2. **Implement** — PowerShell only, no aliases, comment-based help for exported functions, structured logging via `modules/logging`, retry/backoff for throttling.
3. **Validate** — rerun ScriptAnalyzer, Pester, and exports; address all findings.
4. **Document** — update `CHANGELOG.md`, affected docs, and `audit_notes/wave<N>_*.md` with changes and evidence.
5. **Review posture** — present results as proposals, summarize validation output, and wait for explicit approval before proceeding.

## 7. Coding Style & Naming
- Directories use `lower_case_with_underscores`.
- Functions/scripts follow approved `Verb-Noun`; underscores allowed inside nouns.
- Parameters and exported function names use PascalCase; locals use lowerCamelCase.
- Keep modules focused on reusable logic, scripts as orchestrators, and include comment-based help per `docs/reference/help_authoring.md`.

## 8. Schema, Logging & Data Discipline
- Current phase: raw CSV/JSON exports only. Keep metadata fields (`generated_at`, `tool_version`, optional `dataset_version`) but **do not** enforce schemas.
- Future phase: schema definitions and validation will return once datasets stabilize.
- Use `Write-StructuredLog` with correlation IDs and redaction; keep generated artifacts under `logs/`, `reports/`, or `outputs/` only after sanitization.

## 9. Work Tracking via `todo.md`
- Treat `todo.md` as the authoritative backlog; add actionable checkboxes with owners or context.
- Update status immediately after work completes or requirements change to keep other agents aligned.
- When a Work Order is completed and merged, remove its section from `work_orders.md` (and `.codex/work_orders.md` if present) and add any needed summary to `CHANGELOG.md`.
- Clear or remove tasks in `todo.md` that were completed in the same PR so the backlog remains accurate.

## 10. Project Rules & Learning Loop (`ai_project_rules.md`)
- Capture project-specific behaviors (logging expectations, retries, tooling quirks, and future-phase schema notes) in `ai_project_rules.md`.
- Log new lessons as “Error-Derived Rules” with dates and context; update the “Last Updated” stamp whenever the file changes.

## 11. Execution Guardrails & Agent Etiquette
- Default to read-only commands; request approval before running anything that writes outside sanctioned folders.
- Never commit secrets, agent-local files, or sensitive host details.
- Follow branch naming `feat|fix|docs/<area>__<slug>` (or `type/topic-wave-N-slug`) and Conventional Commits; keep waves under ~25 files/600 lines when possible.
- Summarize validation steps in responses/PRs and pause for human review after each wave.

## 12. Optional References & Prompt Banks
- `.clinerules/*`, `.gemini/*`, `docs/prompts/*`, and `clinerules-bank/*` provide historical prompts/templates. Use them for context only; they do not override this runbook.
- If you extend those archives, mention it in `ai_project_rules.md` for discoverability.

## 13. Runbook Change Notes
- When updating this file, reference the change in your PR summary and ensure related guardrails are captured in `ai_project_rules.md`.
