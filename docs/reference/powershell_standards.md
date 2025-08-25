# PowerShell Standards

This repository adopts conservative, Microsoft-aligned authoring standards for financial-grade automation.

Naming & Structure

- Functions: Verb–Noun using Approved Verbs only; validate with `Get-Verb`.
- File names: modules `PascalCase.psm1`, manifests `lowercase.psd1`, scripts `kebab-case.ps1`.
- Scripts are thin entry points; reusable logic lives in modules.
- Indentation: 4 spaces; LF endings (per `.editorconfig`).

Static Analysis

- Use PSScriptAnalyzer; treat warnings as errors.
- Enforce `UseApprovedVerbs` and help/compatibility rules (see ruleset reference).

Help & Docs

- Every exported function must have comment-based help or appear in PlatyPS output.
- Keep README/CHANGELOG and runbooks aligned with current modules and schemas.

Packaging & Runtime

- PowerShell 7.4+.
- Manage dependencies via PSResourceGet; pin minimum versions.
- Prefer CurrentUser scope installs (see `scripts/ensure-prereqs.ps1`).

Repository Conventions (recap)

- Modules: `modules/connect`, `modules/export`, `modules/logging`.
- Scripts: `scripts/` entry points (support `-WhatIf` where relevant).
- Schemas: `docs/schemas/`; runbooks: `docs/runbooks/`.

