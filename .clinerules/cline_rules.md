# Cline Rule Set — PowerShell IAM Inventory (Canonical)

## Mission
Operate as a disciplined implementation agent for the **PowerShell-only** IAM Inventory MVP. Obey this file, `docs/repo_contract.md`, and `powershell_repo_design.md` as single sources of truth.

## Hard Constraints
- **Language/Runtime:** PowerShell 7.4+ only. No Python/runtime services/UI.
- **Directories:** `lower_case_with_underscores` (e.g., `/docs/schemas`).
- **PowerShell names:** `Verb-Noun` (use underscores inside the noun, e.g., `Export-Role_Assignments.ps1`).
- **Packages:** PSResourceGet; pin minimum versions; install to CurrentUser.
- **Security:** No secrets on disk; use SecretManagement. Code signing required in CI (`AllSigned`), `RemoteSigned` in dev.
- **Outputs:** CSV + JSON with headers: `generated_at, tool_version, dataset_version`. Validate against `/docs/schemas/*.schema.json`.
- **Compliance:** Keep `/docs/compliance` table current when adding datasets.
- **Scope Guard:** Do **not** change MVP scope, acceptance criteria, or schemas without an explicit request in the user’s message.

## Operating Steps (every task)
1. **Read Context**
   - Parse: `powershell_repo_design.md`, `docs/repo_contract.md`, related files in `/docs`, target script/module, and any referenced schema(s).

2. **Draft Plan (print first)**
   - Output a short checklist (bullets) with: files to touch, functions to add/modify, schema impact (yes/no), tests to update, and acceptance criteria.

3. **Pre-flight**
   - Run `./scripts/ensure-prereqs.ps1` (or `pwsh -NoProfile -File scripts/ensure-prereqs.ps1`).
   - Lint the repo: `Invoke-ScriptAnalyzer -Path . -Recurse`.
   - If warnings/errors: propose fixes before coding.

4. **Implement**
   - Write PowerShell with comment-based help and examples.
   - Centralize logging via `/modules/logging`; never print secrets; call redaction helpers.
   - For API calls, implement retry/backoff for 429/throttling. Prefer official cmdlets over raw REST unless required by missing coverage.

5. **Schema Discipline**
   - If a dataset is touched: confirm the **schema manifest** in `/docs/schemas/<dataset>.schema.json` covers all fields.
   - If schema changes are necessary: 
     - Propose a **version bump** (`dataset_version`).
     - Provide a migration note and CSV header example.
     - Update tests and docs accordingly.
     - Stop and wait for user approval before applying breaking changes.

6. **Validation**
   - Run Pester tests (contract-level) from `/tests`.
   - Generate **sample exports** (CSV+JSON) to `./examples/` with synthetic data when possible.
   - Re-run ScriptAnalyzer; fix all warnings.

7. **Changelog & PR**
   - Update `CHANGELOG.md` with **Added/Changed/Fixed** and reference files touched.
   - Open a PR with:
     - **Title:** `<type>: <scope> — <short summary>`
     - **Body:** Problem, Solution, Acceptance Criteria, Test evidence (lint/test output), Schema note (if any).

## Coding Rules
- Prefer **small pure functions**; return objects, not strings. Format once in Export layer.
- Use **Write-Verbose** for operator insights; **Write-Error** for failures with actionable guidance.
- Always **idempotent**: re-running exports safely overwrites same-version outputs.
- Keep imports explicit; only load required `Microsoft.Graph` or `Az.*` submodules.

## File/Path Conventions
- New scripts → `/scripts` (e.g., `export-entra_directory_Role_Assignments.ps1`).
- Reusable logic → `/modules/<area>/` as `.psm1`.
- Docs → `/docs`, schemas in `/docs/schemas`, compliance in `/docs/compliance`.

## Branch & Commit
- **Branch:** `feat/<area>__<short>`, `fix/<area>__<short>`, `docs/<area>__<short>`
- **Commit style:** Conventional Commits. Keep diffs minimal; one concern per commit.

## Don’ts
- Don’t introduce external CLIs or non-official modules without approval.
- Don’t weaken logging/redaction. Don’t bypass schema validation.
- Don’t merge on ScriptAnalyzer warnings or failing tests.

## Acceptance Snippet (example)
- “**Azure RBAC assignments** export includes all scopes; portal CSV principal count parity on sample subscription; CSV+JSON produced with required headers; schema v1.0 validated.”
