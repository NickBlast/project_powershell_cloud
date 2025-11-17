# Repo Contract — PowerShell IAM Inventory (Canonical)

> **Status:** Approved baseline for all implementation and research activity.  
> **Applies to:** entire repository (code, docs, CI).  
> **Normative keywords:** **MUST**, **SHOULD**, **MAY** are used as defined in RFC 2119.

---

## 1) Scope & Principles

- **PowerShell-only MVP.** The project **MUST** target PowerShell **7.4+** exclusively. No Python, Node, .NET services, or web UI in MVP.
- **Determinism.** A fresh clone **MUST** become buildable and runnable via a single command: `pwsh -NoProfile -File scripts/ensure-prereqs.ps1`.
- **Idempotency.** All exports **MUST** be safe to re-run without side effects; repeated runs produce the same results for the same inputs.
- **Least privilege.** All access paths **MUST** use read-only roles/permissions documented in `/docs/compliance`.
- **Evidence-first.** Outputs **MUST** be suitable as audit evidence (traceable, timestamped, schema-valid).

---

## 2) Runtime & Environment

- **Shell:** PowerShell **7.4+** (cross-platform).
- **Host OS:** Windows, macOS, Linux are supported; scripts **MUST NOT** assume Windows-only features.
- **Invocation:** All CI and examples use `pwsh -NoProfile`.
- **Locale:** Scripts **SHOULD** avoid locale-dependent formatting; outputs **MUST** use ISO 8601 timestamps (UTC).

---

## 3) Repository Layout & Naming

- **Directories:** lower_case_with_underscores
```
/docs
  /schemas
  /compliance
  repo_contract.md
/modules
  /logging
  /export
  /entra_connection
/scripts
/tests
/examples
/.config
/ai
CHANGELOG.md
README.md
```
- **PowerShell names:** `Verb-Noun` with underscores allowed in the **Noun** when needed.  
  Examples: `Export-Role_Assignments.ps1`, `Get-Group_Memberships.ps1`, `Ensure-Prereqs.ps1`.
- **File locations (normative):**
  - New CLI entry points → `/scripts/*.ps1`
  - Reusable logic → `/modules/<area>/*.psm1`
  - Schemas → `/docs/schemas/*.schema.json`
  - Compliance maps → `/docs/compliance/*.csv`
  - AI rules → `/ai/*.md`
  - Tenant descriptors (non-secret) → `/.config/tenants.json`

---

## 4) Package & Module Management

- **Package manager:** **PSResourceGet** (fallback: PowerShellGet v2).
- **Bootstrap:** `/scripts/ensure-prereqs.ps1` **MUST**:
  1. Verify PowerShell 7.4+.
  2. Ensure PSResourceGet.
  3. Install/upgrade **pinned minimum versions** for required modules to **CurrentUser**.
  4. Normalize `PSModulePath`.
  5. Run ScriptAnalyzer over the repo and emit a machine-readable prereq report (`/examples/prereq_report.json`).
- **Required modules (baseline, minimum versions pinned in `ensure-prereqs.ps1`):**
  - `Microsoft.Graph` (select submodules only)
  - `Microsoft.Graph.Entra`
  - `Az.Accounts`, `Az.Resources` (select submodules only)
  - `ImportExcel`
  - `PSScriptAnalyzer`, `Pester`
  - `Microsoft.PowerShell.SecretManagement`

> **Rule:** Only import submodules actually used; avoid loading the entire roll-up where unnecessary.

---

## 5) Security Controls

- **Secrets:** No secrets on disk. **MUST** use SecretManagement vaults. Redact secrets and PII in logs and sample outputs.
- **Authentication:** Support **device code** for interactive and **service principal** for automation; prefer **read-only** scopes/roles.
- **Code signing:**
  - CI **MUST** enforce `AllSigned`.
  - Developer workstations **MAY** use `RemoteSigned`.
  - Only signed artifacts **MAY** be published or attached to releases.
- **Permissions catalog:** `/docs/compliance/permissions.csv` **MUST** list the least-privilege roles/permissions per dataset and cloud.
- **PII policy:** Emails, UPNs, token hints, and tenant-sensitive identifiers **MUST** be redacted in logs (see Logging module).

---

## 6) Logging, Telemetry & Errors

- **Common logging:** All scripts **MUST** use `/modules/logging`:
  - Structured logs (text + optional JSONL).
  - `correlation_id`, `tenant_id`, `dataset`, `severity`, `message`, `exception?`.
  - Built-in **redaction** filter (apply before write).
- **Operator visibility:** Prefer `Write-Verbose` for operator detail; reserve `Write-Error` for actionable failures.
- **Error policy:** Fail fast with clear remediation steps.
- **Retry policy:** For HTTP 429/throttling and transient network errors:
  - Exponential backoff: base 1s, factor 2.0, jitter ±20%, max 6 attempts.

---

## 7) Data Outputs & Schemas

- **Formats:** Every dataset **MUST** export **CSV** and **JSON** (Parquet MAY be added later).
- **Headers/metadata:** Each output file **MUST** include:
  - `generated_at` (UTC ISO 8601)
  - `tool_version` (SemVer of this tool)
  - `dataset_version` (schema version for the dataset)
- **Schemas:** `/docs/schemas/<dataset>.schema.json` **MUST** define:
  - Column names (ordered), types, nullability, and primary key(s).
- **Validation:** The Export module **MUST** validate objects against the schema before writing files.
- **Output paths:** CLI scripts **MUST** accept `-OutputPath` (default: current directory).  
  Samples for docs/testing **SHOULD** go under `/examples/`.

---

## 8) Testing & Quality Gates

- **Linting:** `Invoke-ScriptAnalyzer -Recurse` **MUST** be clean (warnings fail CI).
- **Tests:** Use **Pester** for contract-level tests:
  - Function parameters and basic behaviors.
  - Schema shape validation of emitted objects prior to export.
- **Samples:** Provide small, sanitized sample outputs in `/examples/` where feasible.

---

## 9) CI/CD Pipeline (normative stages)

1. **validate** — Ensure prereqs; ScriptAnalyzer clean.  
2. **test** — Run Pester in CI mode.  
3. **sign** — Code signing of modules and scripts.  
4. **package** — Produce nupkg/zip if applicable.  
5. **publish** — Publish to private feed or attach signed artifacts.  
6. **artifacts** — Save build logs, analyzer report, and (optional) synthetic sample exports.

> Pipelines **MUST** fail on any analyzer warning, test failure, or schema validation error.

---

## 10) Change Control

- **Versioning:** Semantic Versioning (SemVer) for tool releases; `dataset_version` for schema changes.
- **Breaking schema changes:**
  - **REQUIRES** `dataset_version` bump and migration note in the dataset’s schema file.
  - Update `/docs/compliance` and tests accordingly.
  - Announce in `CHANGELOG.md` with **Changed** and **Breaking** sections.
- **Changelog:** Every PR **MUST** update `CHANGELOG.md` under **Added / Changed / Fixed** with affected files and rationale.

---

## 11) Branching, Commits & PRs

- **Branches:** `feat/<area>__<short>`, `fix/<area>__<short>`, `docs/<area>__<short>`
- **Commits:** Conventional Commits; one concern per commit; meaningful messages.
- **Pull Requests MUST include:**
  - Problem statement & solution summary.
  - Acceptance criteria and evidence (lint/test output).
  - Schema impact (version, migration note, CSV header example).
  - Compliance updates (if dataset/permissions changed).
  - Risk/rollback plan.

---

## Repository Workflow Contract

- **Small PRs:** Keep diffs minimal and reviewable in under 20 minutes; target under ~200 changed lines. Split oversized PRs before review.
- **One Work Order per PR:** Each PR and branch maps to a single work order and a single intent with only the files needed for that change.
- **Minimal diff surface:** Avoid mixing refactors with behavior changes or unrelated cleanups; no stealth or hidden dependency changes.
- **Branch-per-work-order:** Create focused branches (e.g., `wo-<ID>-short-description`) that align to the active work order.
- **Template adherence:** Use the repository PR template and include work order ID, scope, files touched, and testing details.
- **Agent alignment:** All contributors and automated agents **MUST** follow the “Pull Request & Change Workflow Rules” in `ai_project_rules.md`.

---

## 12) AI/Agent Guardrails

- Agents **MUST** read this file, `/docs/repo_contract.md`, `/docs/schemas/*`, and `powershell_repo_design.md` before edits.
- Agents **MUST** propose a short plan (files, functions, tests, schema impact) before making changes.
- Agents **MUST NOT** introduce new runtimes, external CLIs, or unapproved modules without explicit user approval.
- Any schema change **REQUIRES** user approval prior to implementation.

---

## 13) Acceptance Criteria Template

When adding or modifying a dataset/export, include explicit AC like:

- **AC-1 (Coverage):** Export includes all records for scope _S_ (validated by cross-check command N).
- **AC-2 (Parity):** Principal/resource count parity with portal/API reference sample ±0%.
- **AC-3 (Schema):** CSV and JSON conform to `/docs/schemas/<dataset>.schema.json`; headers include `generated_at`, `tool_version`, `dataset_version`.
- **AC-4 (Idempotency):** Re-running with the same inputs overwrites outputs deterministically.
- **AC-5 (Security):** No secrets or PII written to logs; redaction verified.

---

## 14) Glossary (selected)

- **Azure RBAC:** Role assignments at MG/Subscription/RG/Resource scope.
- **Directory role (Entra ID):** Built-in tenant admin roles (e.g., Global Administrator).
- **Service principal:** App identity in a tenant, usually created from an app registration.
- **Cloud-only group:** Entra ID group not synchronized from on-prem.

---

## 15) Visual — Collection Flow (informative)

```mermaid
flowchart LR
  A[entra_connection module] --> B[azure: scopes & rbac]
  A --> C[entra: roles, groups, apps, sps]
  A --> D[aws (later)]
  A --> E[gcp (later)]
  B --> F[normalize]
  C --> F
  F --> G[logging & redaction]
  G --> H[export: csv / json]
  H --> I[compliance catalog]
```

---

### Conformance

Any contribution (human or agent) that violates this contract may be rejected in review or blocked by CI. Exceptions require explicit approval and **MUST** be documented in `CHANGELOG.md` with rationale and scope.
