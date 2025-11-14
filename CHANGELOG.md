# Changelog

## [Unreleased] - 2025-11-13
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
