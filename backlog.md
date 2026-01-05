```markdown
# Backlog — Single Source of Truth

This file replaces the prior `todo.md` and `work_orders.md` files and serves as the canonical backlog and Work Order registry for the repository.

---

## Legend

- **Type**
  - `BUG`  – Fixing broken behavior or test failures.
  - `ENH`  – Enhancements or feature improvements.
  - `META` – Repository structure, logging, build, or cross-cutting refinements.
  - `DOC`  – Documentation, comments, or metadata improvements.

- **Area**
  - `LOGGING`        – Run logs, diagnostics, and observability.
  - `EXPORTS`        – Export scripts and output behavior.
  - `MODULES`        – Shared modules (for example, connection, helpers).
  - `DOCS`           – README, runbooks, and reference documentation.
  - `SCHEMA-FUTURE`  – Schema and validation work deferred to a later phase.
  - `APP-REG`        – Entra ID application registration script development.

- **Priority**
  - `P1` – High priority / near-term.
  - `P2` – Medium priority.
  - `P3` – Lower priority / future phase.

---

## Work Orders Snapshot

List Work Orders here (one per line). Each Work Order should be small and focused, mapping to a single PR/branch.

- `WO-LOGGING-001` — Centralize run logging for entrypoint scripts.
- `WO-AUDIT-001` — Audit and migrate artifacts (example record; remove when complete).
- `WO-TODO-001` — Restructure backlog and consolidate work orders (this file).
- `WO-APP-REG-001` — Implement Entra ID application registration script (post_entra_app_registration.ps1).

---

## Tasks by Area

### LOGGING

- [ ] [META][LOGGING][P1] Implement centralized run logging (`modules/logging/Logging.psm1`).
- [ ] [ENH][LOGGING][P2] Ensure correlation IDs persist across module boundaries.

### DOCS

- [ ] [DOC][DOCS][P1] Review `docs/` reference files for outdated statements.

### EXPORTS

- [ ] [ENH][EXPORTS][P1] Add tenant parameters to entrypoint scripts.

### MODULES

- [ ] [BUG][MODULES][P1] Validate `modules/entra_connection/entra_connection.psm1` in a test environment.

### SCHEMA-FUTURE

- [ ] [ENH][SCHEMA-FUTURE][P3] Reintroduce schema helpers only after exports stabilize.

### APP-REG

#### Foundation & Setup
- [ ] [ENH][APP-REG][P1] Add comment-based help header to `scripts/post_entra_app_registration.ps1` with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE` per standards.
- [ ] [META][APP-REG][P1] Import `Microsoft.Graph` module at script start (validate 2.9.0+ available).
- [ ] [META][APP-REG][P1] Import `modules/logging/Logging.psm1` module via `.psd1` manifest.
- [ ] [META][APP-REG][P1] Set `$ErrorActionPreference = 'Stop'` and initialize error handling structure.
- [ ] [ENH][APP-REG][P1] Load `System.Windows.Forms` assembly using `[System.Reflection.Assembly]::LoadWithPartialName()`.

#### Section 1: Windows Form for User Input
- [ ] [ENH][APP-REG][P1] Create main form object with `TopMost = $true` and `StartPosition = 'CenterScreen'` properties.
- [ ] [ENH][APP-REG][P1] Add "Business Application ID" label and TextBox control to form.
- [ ] [ENH][APP-REG][P1] Add "Environment" label and ComboBox control with fixed items: `dv`, `qa`, `ut`, `pd`.
- [ ] [ENH][APP-REG][P1] Add "Scope" label and ComboBox control with fixed items: `m365`, `tnr`, `mg`, `sub`, `rg`.
- [ ] [ENH][APP-REG][P1] Add "App Name Abbreviation" label and TextBox control (max 16 chars).
- [ ] [ENH][APP-REG][P1] Add "Access Level" label and ComboBox control with fixed items: `read`, `write`, `admin`.
- [ ] [ENH][APP-REG][P1] Add "Description" label and multi-line TextBox control.
- [ ] [ENH][APP-REG][P1] Add "Redirect URI (Optional)" label and TextBox control.
- [ ] [ENH][APP-REG][P1] Add "Submit" and "Cancel" buttons with `DialogResult` properties (`OK`, `Cancel`).
- [ ] [ENH][APP-REG][P1] Implement form validation logic (required fields non-empty, AppName <16 chars, Redirect URI format check).
- [ ] [META][APP-REG][P1] Add form cancellation handler (log event, exit gracefully with `Write-StructuredLog`).

#### Section 2: Construct & Validate Registration Name
- [ ] [ENH][APP-REG][P1] Extract form input values into variables (`$appId`, `$env`, `$scope`, `$appName`, `$access`, `$description`, `$redirectUri`).
- [ ] [ENH][APP-REG][P1] Validate AppId is non-empty and alphanumeric (regex check).
- [ ] [ENH][APP-REG][P1] Validate AppName is non-empty, <16 chars, and alphanumeric (regex check).
- [ ] [ENH][APP-REG][P1] Validate Description is non-empty.
- [ ] [ENH][APP-REG][P1] If provided, validate Redirect URI matches URI format (regex `^https?://` or custom scheme).
- [ ] [ENH][APP-REG][P1] Construct registration name: `$registrationName = "$appId-$env-$scope-$appName-$access"`.
- [ ] [ENH][APP-REG][P1] Validate constructed name length is <256 chars (Entra DisplayName limit).
- [ ] [ENH][APP-REG][P1] Validate name contains only alphanumeric + hyphens, no consecutive hyphens (regex check).
- [ ] [ENH][APP-REG][P1] Check for duplicate app registration using `Get-MgApplication -Filter "displayName eq '$registrationName'"`.
- [ ] [META][APP-REG][P1] Log constructed name and validation results with `Write-StructuredLog`.

#### Section 3: Create Application Registration in Entra ID
- [ ] [ENH][APP-REG][P1] Implement Graph authentication using `Connect-MgGraph -Scopes "Application.ReadWrite.All"`.
- [ ] [ENH][APP-REG][P1] Verify authenticated context with `Get-MgContext` (check TenantId and Scopes).
- [ ] [ENH][APP-REG][P1] Call `New-MgApplication` with `-DisplayName $registrationName`, `-SignInAudience "AzureADMyOrg"`, `-Description $description`.
- [ ] [ENH][APP-REG][P1] If Redirect URI provided, add using `-ReplyUrls @($redirectUri)` parameter.
- [ ] [ENH][APP-REG][P2] Optionally call `New-MgServicePrincipal -AppId $app.AppId` (confirm requirement with user).
- [ ] [META][APP-REG][P1] Log registration success with app details (AppId, DisplayName, TenantId) via `Write-StructuredLog`.

#### Error Handling & Validation
- [ ] [META][APP-REG][P1] Wrap form creation in try/catch block with error logging.
- [ ] [META][APP-REG][P1] Wrap name construction in try/catch block with validation failure logging.
- [ ] [META][APP-REG][P1] Wrap Graph API calls in try/catch block with retry logic for rate limiting (HTTP 429).
- [ ] [META][APP-REG][P1] Handle authorization errors (missing `Application.ReadWrite.All` scope) with clear error message.
- [ ] [META][APP-REG][P1] Handle duplicate app name scenario (prompt user or exit with error).
- [ ] [META][APP-REG][P1] Log all errors with correlation IDs, status codes, and full exception messages.

#### Testing & Validation
- [ ] [BUG][APP-REG][P1] Run `Invoke-ScriptAnalyzer` on `scripts/post_entra_app_registration.ps1` and fix all warnings.
- [ ] [ENH][APP-REG][P2] Create Pester test for form validation logic.
- [ ] [ENH][APP-REG][P2] Create Pester test for name construction validation.
- [ ] [ENH][APP-REG][P2] Test script end-to-end in test tenant (dry-run with WhatIf pattern if possible).
- [ ] [DOC][APP-REG][P2] Add example output to `examples/` folder (sanitized app registration details).

---

## Per-Script / Per-Module Bring-Up

Use this section to list a small set of baseline tasks for each script/module.

### scripts/ensure-prereqs.ps1

- [ ] [BUG][EXPORTS][P1] Debug in a representative host environment.
- [ ] [ENH][EXPORTS][P2] Improve messaging and parameter handling.
- [ ] [META][LOGGING][P2] Verify logging emitted during prereq checks.

### scripts/seed-entra_test_assets.ps1

- [ ] [BUG][EXPORTS][P2] Validate seeding workflow is idempotent and safe.
- [ ] [ENH][EXPORTS][P2] Add a `-WhatIf` safety switch.

### modules/entra_connection/entra_connection.psm1

- [ ] [DOC][MODULES][P2] Add clear comments and metadata for each code block.

### modules/export/Export.psm1

- [ ] [BUG][MODULES][P1] Confirm deterministic column ordering for CSV exports.

### modules/logging/Logging.psm1

- [ ] [BUG][LOGGING][P1] Ensure Start/Write/Complete log functions exist and emit consistent metadata.

### scripts/post_entra_app_registration.ps1

- [ ] [ENH][APP-REG][P1] Complete foundation setup (comment-based help, module imports, error handling).
- [ ] [ENH][APP-REG][P1] Build Windows Form with all required input controls and validation.
- [ ] [ENH][APP-REG][P1] Implement name construction and duplicate checking logic.
- [ ] [ENH][APP-REG][P1] Implement Entra ID app registration creation with Graph API.
- [ ] [META][APP-REG][P1] Add comprehensive error handling and structured logging throughout.
- [ ] [BUG][APP-REG][P1] Validate script passes `Invoke-ScriptAnalyzer` with zero warnings.

---

## Work Order Template

Each work order should include:

- **Title**: short descriptive name
- **Context**: why this matters
- **Objective**: clear acceptance criteria
- **Tasks**: small, verifiable steps
- **Validation**: tests/commands to run

---

## General Backlog Notes

- Keep items small and evidence-driven.
- Tag each item with `[TYPE][AREA][PRIORITY]`.
- Remove tasks immediately after completing and merging the change.

---

## How to Use This File

- When opening a PR, reference the Work Order ID (if present), update this file with progress, and record any follow-ups as new items.
- Maintain a single line-per-work-order in the snapshot; move completed work orders to the changelog or archive section if desired.

```
