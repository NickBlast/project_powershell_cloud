# Repository Guidelines

## Project Structure & Module Organization
- `modules/`: PowerShell modules
  - `connect/` → tenant/auth helpers (`Connect.psm1`)
  - `export/` → dataset/schema + export logic (`Export.psm1`)
  - `logging/` → structured logging utilities (`Logging.psm1`)
- `scripts/`: runnable entrypoints (e.g., `export-azure_rbac_assignments.ps1`)
- `docs/`: procedures, runbooks, schemas, repo design
- `reports/` and `logs/`: generated output (do not commit secrets)
- Root helpers: `.export_schema_test.ps1`, `.editorconfig`, `.github/workflows/`

## Build, Test, and Development Commands
- Prereqs + lint: `pwsh ./scripts/ensure-prereqs.ps1`
- Static analysis: `pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse"`
- Try an export (dry run):
  - `pwsh -File ./scripts/export-azure_rbac_assignments.ps1 -WhatIf`
- Schema sanity check:
  - `pwsh -File ./.export_schema_test.ps1`
- Pester tests (if present in `tests/`): `pwsh -Command "Invoke-Pester"`

## Coding Style & Naming Conventions
- Indentation: 4 spaces for PowerShell; LF line endings (`.editorconfig`).
- Functions: Verb-Noun, PascalCase (e.g., `Get-DatasetSchema`). Use approved verbs.
- Filenames: modules `PascalCase.psm1`; manifests `lowercase.psd1`; scripts `kebab-case.ps1` grouped by domain (e.g., `export-entra_*`).
- Lint with PSScriptAnalyzer; aim for zero errors/warnings.

## Testing Guidelines
- Framework: Pester 5. Place tests in `tests/` named `*.Tests.ps1` mirroring module paths.
- Cover: parameter contracts, schema validation, and critical branches.
- Run locally: `pwsh -Command "Invoke-Pester -Output Detailed"`.

## Commit & Pull Request Guidelines
- Style: Conventional Commit prefixes (e.g., `feat:`, `fix:`, `docs:`, `chore:`); use scopes (`docs(runbooks): ...`).
- Commits: small, focused, with imperative mood.
- PRs: include summary, linked issues, sample output or logs (redacted), and steps to validate. Add screenshots when UI/portal steps apply.

## Security & Configuration Tips
- PowerShell 7.4+ required. Modules install to CurrentUser via `ensure-prereqs.ps1`.
- Never commit secrets; prefer `Microsoft.PowerShell.SecretManagement` and environment-based auth.
- Validate output paths under `reports/` and avoid committing sensitive artifacts.

## Architectural Notes
- Scripts are thin entrypoints; modules hold reusable logic. Keep schemas in `docs/schemas/`, add runbooks in `docs/runbooks/`, and update `ensure-prereqs.ps1` when adding dependencies.

