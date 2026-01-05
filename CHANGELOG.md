# Changelog

## [Unreleased] - 2025-11-17
### Added
- Added `tests/entra_connection.Tests.ps1` to smoke-test module import, SecretManagement error handling, and the `ensure-prereqs.ps1` + `Connect-GraphContext` workflow without touching live tenants.
- Added centralized run logging for all entrypoint scripts, writing timestamped logs under `logs/` with minimal console noise and consistent filenames.
- Documented the Entra/Azure testing workflow refresh, including new `Connect-EntraTestTenant` helpers, seeding script (`scripts/seed-entra_test_assets.ps1`), and `tests/run-tests-basic.ps1` for smoke coverage with outputs under `outputs/entra` and `outputs/azure`.

### Changed
- Completed WO-AI-001 by removing artificial intelligence/tooling references from scripts, modules, and operator-facing documentation; verified remaining mentions exist only in AI rules/agent-only files (for example `.codex/**`, `AGENTS.md`, `ai_project_rules.md`) and clearly labeled internal reference docs (`docs/reference/repo_contract.md`, `docs/reference/powershell_repo_design.md`), ensuring exported artifacts no longer claim AI generation or dependencies.
- Completed WO-PR-RULES-000 by codifying small-PR and branch-per-work-order workflows, updating CONTRIBUTING, adding a PR template, and documenting PR philosophy in README and governance docs.
- Renamed the tenant connection module to `modules/entra_connection/entra_connection.psm1`, refreshed its Microsoft Entra documentation, and updated every script/doc import along with SecretManagement/Connect-* patterns that follow current Microsoft guidance.
- Updated `scripts/ensure-prereqs.ps1`, README, and contract docs to treat module versions as minimums, ensure Microsoft.Graph.Entra is installed, and avoid downgrading newer Az/Graph bits.
- Completed WO-SCHEMA-001 — Remove all schema assets and scrub schema references:
  - Completed removal of all schema JSON assets and legacy schema helpers.
  - Updated README, repo_contract, AGENTS, standards, runbooks, and AI rules to reflect schema as a future-phase requirement.
  - Ensured all export modules run without schema dependencies.
  - Verified module syntax, corrected invalid comment-based help, and passed ScriptAnalyzer checks.
  - Finalized raw-exports-first design for MVP.
  - Completed WO-AUDIT-001 by migrating `audit_notes` into long-term records, removing the folder, and recording wave outcomes and follow-ups in `CHANGELOG.md` and `backlog.md`:
  - Wave 0 established a reference cache (sources of record, standards, analyzer ruleset, help authoring guidance) with a read-only posture and an MCP client proposal.
  - Wave 1 captured the initial inventory/mapping by enumerating scripts/modules/functions, drafting the command appendix, and logging follow-up questions for the appendix extraction.
  - Wave 2 validated cmdlet usage, cleaned the command appendix (removing false positives, adding module family context), and updated README dependencies while flagging a device-code parameter verification follow-up.
  - Wave 3 resolved all PSScriptAnalyzer findings, including trailing whitespace and positional parameter fixes in `scripts/export-entra_role_assignments.ps1`.
  - Wave 4 confirmed function and variable naming already aligned with `Verb-Noun` and casing standards, requiring no renames.
  - Wave 5 expanded comment-based help across `entra_connection`, `Export`, and `Logging` modules with `.OUTPUTS`/`.NOTES` additions and typo fixes.
  - Wave 6 finalized `docs/command_appendix.csv` Learn URLs and documented the wave results in the changelog.
  - Wave 7 hardened `scripts/ensure-prereqs.ps1` with deterministic module pins, quiet/WhatIf-aware logging, analyzer output exports, and typed analyzer target lists.
  - Wave 8 completed the `entra_connection` rename/refactor, aligned Azure/Graph connection flows with updated guidance, expanded prereq coverage, and added Pester smoke tests.
  - The final audit summary captures improved code quality, consistent naming, and complete documentation aligned to financial-grade standards.

### Fixed
- Hardened `scripts/ensure-prereqs.ps1` to pin PSResourceGet/PSGallery module versions, respect Quiet/WhatIf, normalize PSModulePath, and fail when PSScriptAnalyzer warnings or errors are detected.
- Reworked the analyzer phase in `scripts/ensure-prereqs.ps1` to enumerate PowerShell files explicitly and skip generated folders, eliminating the intermittent `Invoke-ScriptAnalyzer` null-reference failure.
- Ensured analyzer targets are passed as a strongly typed `string[]` list so `Invoke-ScriptAnalyzer` no longer receives `System.Object[]` and fails parameter binding.

## [0.2.0] - 2025-08-25
### Fixed
- Resolved all PSScriptAnalyzer warnings, including fixing trailing whitespace and ensuring the use of named parameters for `Join-Path` in `scripts/export-entra_role_assignments.ps1`.

### Changed
- Improved comment-based help for all exported functions in all modules, adding missing `.OUTPUTS` and `.NOTES` sections and correcting typos to align with documentation standards.
- Verified that all function and variable names conform to the repository's `Verb-Noun` and `PascalCase`/`lowerCamelCase` standards. No changes were required.
- Updated `docs/command_appendix.csv` with official Microsoft Learn documentation URLs for all referenced cmdlets.

All notable changes to this project will be documented in this file.

The format is based on "Keep a Changelog" and this project follows Semantic Versioning.

## [0.1.0] - 2025-08-15
### Added
- Initial project scaffolding and export scripts (Azure export example)
- Repository hygiene files (.gitattributes, .editorconfig, .gitignore)
- CONTRIBUTING.md

### Changed
- N/A

### Fixed
- N/A

### Security
- N/A
