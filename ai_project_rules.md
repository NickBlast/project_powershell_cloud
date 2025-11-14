# AI Project Rules
_Last Updated: 2025-11-13_

## General Principles
- **Universal runbooks:** Read the root `AGENTS.md` (plus any nested overrides) and `.clinerules/*.md` before coding. Those documents already consolidate mission, operating steps, coding standards, schema discipline, and acceptance snippets—reuse them instead of creating parallel guidance.
- **Shared task tracking:** Treat `todo.md` as the canonical, cross-agent plan. Add micro-PR steps before implementation and remove entries once work is completed and reviewed.
- **PowerShell-only toolchain:** Use the prescribed commands (`pwsh ./scripts/ensure-prereqs.ps1`, `Invoke-ScriptAnalyzer`, `Invoke-Pester`, `./.export_schema_test.ps1`) and keep logic in PowerShell modules/scripts with structured logging from `/modules/logging`.
- **Schema + logging safeguards:** Never emit fields absent from `docs/schemas/<dataset>.schema.json`; ensure `generated_at`, `tool_version`, and `dataset_version` headers exist; log via `Write-StructuredLog` with redaction.
- **Project learning loop:** When a recurring, project-specific issue is fixed, document the prevention rule under “Error-Derived Rules” (with context and optional example) so every assistant benefits.

## Error-Derived Rules
- _None yet; add entries when project-specific issues are discovered._
