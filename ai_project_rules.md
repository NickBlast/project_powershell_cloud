# AI Project Rules
_Last Updated: 2025-11-13_

## General Principles
- Anchor every task to `AGENTS.md` plus the repo contract/design docs; implement exclusively in PowerShell 7.4+ with `lower_case_with_underscores` directories and approved Verb-Noun naming.
- Run `scripts/ensure-prereqs.ps1`, `Invoke-ScriptAnalyzer -Path . -Recurse`, `Invoke-Pester`, and `./.export_schema_test.ps1` (when exports change) during each wave; do not merge with analyzer warnings or failing tests.
- Keep schema discipline absolute: exports must include `generated_at`, `tool_version`, `dataset_version`, validate against `docs/schemas/<dataset>.schema.json`, and trigger compliance/doc updates plus dataset version bumps whenever schemas change.
- Logging is mandatory: instrument scripts with `modules/logging` (`Write-StructuredLog`, correlation IDs, redaction) and store sanitized samples only under `examples/`, `logs/`, `reports/`, or `outputs/`.
- Use SecretManagement for credentials, pin module versions via PSResourceGet, and document required permissions in `docs/compliance`.
- Maintain the wave/micro-PR cadence by updating `todo.md`, `audit_notes/`, and `CHANGELOG.md` with problem, solution, validation evidence, schema impact, and follow-ups.

## Error-Derived Rules
- _None yet — add the first entry here when a recurring issue is resolved._
