# Prompt Sheet v2 — PowerShell AI Readiness (Config + Sources + Reference Cache)

This prompt sheet gives AI coding agents and contributors the minimal, high‑signal context needed to work safely and effectively in this PowerShell repo.

## Objectives
- Understand repo structure and naming patterns.
- Use standard commands for setup, lint, schema checks, and exports.
- Locate source of truth for auth, export, logging, and schemas.
- Reference a compact function inventory and command cheat sheet.
- Follow safe defaults: no secrets, WhatIf by default, Pester for validation.

## Repo Snapshot (Source Map)
- modules/
  - connect/ → tenant + auth helpers (`Connect.psm1`, `connect.psd1`)
  - export/ → dataset/schema + export logic (`Export.psm1`, `export.psd1`)
  - logging/ → structured logging utilities (`Logging.psm1`, `logging.psd1`)
- scripts/
  - `ensure-prereqs.ps1` (installs required modules to CurrentUser)
  - Entrypoints (dry-run friendly):
    - `export-azure_rbac_assignments.ps1`
    - `export-azure_rbac_definitions.ps1`
    - `export-azure_scopes.ps1`
    - `export-entra_apps_service_principals.ps1`
    - `export-entra_directory_roles.ps1`
    - `export-entra_group_memberships.ps1`
    - `export-entra_groups_cloud_only.ps1`
    - `export-entra_role_assignments.ps1`
- docs/
  - prompts/ (this file + prompt templates)
  - schemas/ (dataset schemas; keep updated with exports)
  - runbooks/ (operational procedures)
  - procedures/, repo_design/, testing/
- Root helpers
  - `.export_schema_test.ps1`, `.editorconfig`, `.github/workflows/`
- Output
  - `reports/` and `logs/` (generated; don’t commit secrets)

## Setup & Config
- Prereqs + lint: `pwsh ./scripts/ensure-prereqs.ps1`
- Static analysis: `pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse"`
- PowerShell: 7.4+
- Secrets: use `Microsoft.PowerShell.SecretManagement`; never commit secrets.
- Tenants catalog: `.config/tenants.json` (non-secret identifiers only)
- Logging: use `Write-Log` via `modules/logging/Logging.psm1`; redact via `Set-LogRedactionPatterns`.

## Function Inventory (Reference Cache)
Quick, non-exhaustive inventory of key functions by module to anchor LLM context windows. For details, open the module and jump to the function.

- modules/connect/Connect.psm1
  - `Get-TenantCatalog`
  - `Select-Tenant`
  - `Connect-GraphContext`
  - `Connect-AzureContext`
  - `Get-ActiveContexts`

- modules/export/Export.psm1
  - `Get-DatasetSchema`
  - `Test-ObjectAgainstSchema`
  - `ConvertTo-FlatRecord`
  - `Write-Export`

- modules/logging/Logging.psm1
  - `Redact-String`
  - `New-LogContext`
  - `Set-LogRedactionPatterns`
  - `Get-CorrelationId`
  - `Write-Log`
  - `Invoke-WithRetry`

Rebuild inventory (optional, if adding functions):
- Ripgrep: `rg -n "function\s+([A-Za-z0-9-]+)" modules` (lists function names + lines)

## Command Cheat Sheet
- Ensure deps: `pwsh ./scripts/ensure-prereqs.ps1`
- Lint all: `pwsh -Command "Invoke-ScriptAnalyzer -Path . -Recurse"`
- Dry-run export: `pwsh -File ./scripts/export-azure_rbac_assignments.ps1 -WhatIf`
- Schema test: `pwsh -File ./.export_schema_test.ps1`
- Pester tests: `pwsh -Command "Invoke-Pester"`

## Common Workflows
- Connect and context check (no secrets logged):
  ```powershell
  Import-Module ./modules/connect/Connect.psm1 -Force
  Import-Module ./modules/logging/Logging.psm1 -Force

  $tenant = Select-Tenant -TenantFilter "contoso"   # fuzzy or exact
  $graph  = Connect-GraphContext -Tenant $tenant    # secret via SecretManagement
  $azure  = Connect-AzureContext -Tenant $tenant
  Get-ActiveContexts | Write-Log -Level Information
  ```

- Validate and export (safe by default with WhatIf):
  ```powershell
  Import-Module ./modules/export/Export.psm1 -Force

  $schema = Get-DatasetSchema -Name "AzureRbacAssignments"
  # ... build $records ... then validate each
  $records | ForEach-Object { $_ | Test-ObjectAgainstSchema -Schema $schema -ErrorAction Stop }

  $records | Write-Export -Schema $schema -OutputPath ./reports/azure/rbac_assignments -WhatIf
  ```

- Structured logging with redaction and retries:
  ```powershell
  Import-Module ./modules/logging/Logging.psm1 -Force

  Set-LogRedactionPatterns -Patterns @("(?i)secret", "(?i)password")
  Write-Log -Level Information -Message "Starting export" -Context (New-LogContext -Area "Export" -Operation "RBAC")

  Invoke-WithRetry -ScriptBlock {
    # transient operation here
  } -RetryCount 3 -BaseDelaySeconds 2
  ```

## AI Usage Guide (for Agents)
- Read first: `README.md`, `AGENTS.md`, this prompt sheet, and targeted modules for your task.
- Respect style: Verb-Noun PascalCase functions; approved verbs; 4-space indent; LF endings.
- Safe defaults: prefer `-WhatIf`; never print or persist secrets; use `SecretManagement` for auth.
- Thin scripts, rich modules: add reusable logic inside `modules/*/*.psm1`; keep scripts minimal.
- Schema source of truth: update under `docs/schemas/` and validate with `.export_schema_test.ps1`.
- Tests: if `tests/` exists, add or update Pester tests mirroring module paths.
- Output hygiene: write to `reports/` and `logs/`; avoid committing sensitive artifacts.

Recommended kickoff prompts:
- “Scan `modules/export/Export.psm1` and outline how `Write-Export` handles `-WhatIf` and schema binding. Propose a small extension to support CSV delimiter customization.”
- “Add a new export script mirroring `export-azure_scopes.ps1`; wire to `Get-DatasetSchema` and `Write-Export`, with PSScriptAnalyzer clean.”

## Validation & CI Guardrails
- Local checks: lint, schema test, and any Pester tests.
- GitHub Actions: ensure `.github/workflows/` stays green; keep PSScriptAnalyzer noise to zero.

## Output & Security
- Do not commit secrets or tokens.
- Redact sensitive values in logs using `Set-LogRedactionPatterns`.
- Keep report paths under `./reports/`; prefer structured formats (CSV/JSON) and deterministic filenames.

## Context Anchors (Open These First)
- `modules/connect/Connect.psm1` — tenant catalog, Azure/Graph auth, context summaries
- `modules/export/Export.psm1` — schema retrieval/validation, flattening, export writer
- `modules/logging/Logging.psm1` — structured logs, correlation IDs, retries, redaction
- `scripts/ensure-prereqs.ps1` — module installation and environment prep
- `.export_schema_test.ps1` — schema sanity validation entrypoint
- `docs/schemas/` — dataset schema definitions

---
Use this sheet as your quick reference. Keep edits surgical, follow conventions, and validate with the cheat‑sheet commands before opening a PR.
