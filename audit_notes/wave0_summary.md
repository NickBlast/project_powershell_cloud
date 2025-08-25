# Wave 0 — Self-Configure (Summary)

## Scope

- Propose Model Context Protocol (MCP) client configuration for read-only servers and an optional, disabled-by-default PowerShell execution server (analyzer-only).
- Create the Reference Cache: sources of record, standards, analyzer ruleset summary, and help authoring guidance.

## Artifacts Added

- docs/reference/powershell_sources_of_record.md
- docs/reference/powershell_standards.md
- docs/reference/psscriptanalyzer_ruleset.md
- docs/reference/help_authoring.md
- docs/reference/mcp_client_config.example.yaml (proposal)

## Guardrails & Decisions

- Default read-only posture; no execution performed in Wave 0.
- Analyzer execution (if/when needed) will be limited to `Invoke-ScriptAnalyzer` and `Get-Verb`, then disabled immediately.
- Microsoft Learn is the authoritative source for cmdlet/module semantics; official GitHub repos used only when Learn defers (e.g., PlatyPS).

## Open Questions

- Do you prefer external help (PlatyPS) for all modules or a hybrid (inline for small, external for large)?
- Any additional domains to allowlist for `fetch-ro` beyond Microsoft Learn and official GitHub repos?
- Confirm minimum module versions to pin via PSResourceGet in `scripts/ensure-prereqs.ps1`.

## Next Gate (Wave 1 Plan)

- Inventory all scripts/modules/functions.
- Extract cmdlets and draft docs/command_appendix.csv.
- Produce audit_notes/wave1_inventory.md calling out unknown/suspicious cmdlets.
