# Changelog

## [Unreleased] - 2025-11-17
### Added
- Added `tests/entra_connection.Tests.ps1` to smoke-test module import, SecretManagement error handling, and the `ensure-prereqs.ps1` + `Connect-GraphContext` workflow without touching live tenants.
- Introduced centralized run logging for all entrypoint scripts, emitting timestamped log files under `logs/`.

### Changed
- Completed WO-PR-RULES-000 by codifying small-PR and branch-per-work-order workflows, updating CONTRIBUTING, adding a PR template, and documenting PR philosophy in README and governance docs.
- Renamed the tenant connection module to `modules/entra_connection/entra_connection.psm1`, refreshed its Microsoft Entra documentation, and updated every script/doc import along with SecretManagement/Connect-* patterns that follow current Microsoft guidance.
- Updated `scripts/ensure-prereqs.ps1`, README, and contract docs to treat module versions as minimums, ensure Microsoft.Graph.Entra is installed, and avoid downgrading newer Az/Graph bits.
- Completed WO-SCHEMA-001 — Remove all schema assets and scrub schema references:
  - Completed removal of all schema JSON assets and legacy schema helpers.
  - Updated README, repo_contract, AGENTS, standards, runbooks, and AI rules to reflect schema as a future-phase requirement.
  - Ensured all export modules run without schema dependencies.
  - Verified module syntax, corrected invalid comment-based help, and passed ScriptAnalyzer checks.
  - Finalized raw-exports-first design for MVP.
- Documented cleanup expectations for AI agents to update work orders and todo backlogs when tasks complete.

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
