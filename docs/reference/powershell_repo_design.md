# PowerShell IAM Inventory — Repository Design (Canonical)

## Purpose

This repository contains all **PowerShell** scripting used to connect to **AWS**, **Azure (including Entra ID)**, and **GCP** to extract IAM-relevant inventory: objects, attributes, memberships, policies/permissions, and usage metadata.  
The outputs feed:
- **Audit evidence** (who has what, where, and why),
- **Access decision support** (access ↔ resources/services mapping),
- **Risk & posture improvements** aligned to **NIST SP 800-53**, **CSA CCM**, **FFIEC CAT**, and each cloud’s **Well-Architected** guidance.

All access must meet strict metadata requirements; this repo evaluates and enforces those requirements.

---

## Naming Conventions

- **Directories:** `lower_case_with_underscores` only (e.g., `docs`, `ai/tools_internal`).
- **PowerShell scripts/functions/cmdlets:** `Verb-Noun` casing, **hyphen** between Verb and Noun (standard PowerShell), and use **underscores within the Noun** if it contains multiple words.  
  - Examples: `Export-Role_Assignments.ps1`, `Get-Group_Memberships.ps1`, `Ensure-Prereqs.ps1`.
- **Files:** No restriction beyond common practice; keep `README.md`, `CHANGELOG.md`, etc.

> Rationale: predictable path parsing for automation + clear PowerShell naming for discoverability.

---

## Tech Stack

### Cloud Platforms (control planes)
- **AWS** (Management Console, IAM, Organizations, CloudTrail readers)
- **Azure / Entra ID** (Azure Resource Manager, Azure RBAC, Microsoft Graph)
- **GCP** (Cloud Resource Manager, IAM)

### Runtime & Packaging
- **PowerShell:** 7.4+ (cross-platform)
- **Package manager:** **PSResourceGet** (fallback: PowerShellGet v2)
- **Modules (minimum set):**
  - **Microsoft.Graph** (select submodules only) — Graph directory/app/role queries  
    <https://learn.microsoft.com/powershell/microsoftgraph/>
  - **Az.Accounts**, **Az.Resources** (select submodules only)  
    <https://learn.microsoft.com/powershell/azure/>
  - **ImportExcel** (Excel exports without needing Excel installed)  
    <https://github.com/dfinke/ImportExcel>
  - **PSScriptAnalyzer** (linting), **Pester** (contract tests)  
  - **Microsoft.PowerShell.SecretManagement** (credential abstraction)

---

## Repository Structure (Directories are lower_case_with_underscores)

```
/docs
  /compliance             # Control mappings and evidence index
  repo_contract.md        # Deterministic rules for tools & outputs
/modules
  /logging                # Structured logging + redaction
  /export                 # CSV/JSON/XLSX writers (schema validation paused)
  /entra_connection       # Microsoft Entra + Azure auth/context helpers
/scripts
  ensure-prereqs.ps1      # Idempotent environment bootstrap (Verb-Noun)
  export-*.ps1            # Top-level entrypoints by dataset (Verb-Noun)
/tests                    # Pester contract tests (params and behaviors)
/examples
/.config
  tenants.json            # Non-secret tenant descriptors (ids, labels)
/ai
  contributing_ai.md      # Guardrails & prompts for AI/agents
CHANGELOG.md
README.md
```

---

## Scripting Requirements (Deterministic & Idempotent)

- **Pin minimum module versions** and restore via Ensure-Prereqs.  
- **Do not** store secrets on disk; use SecretManagement vaults.  
- **Idempotency:** re-running exports overwrites versioned outputs safely.  
- **Observability:** structured logs (JSON lines optional), correlation IDs.  
- **Error policy:** fail fast with actionable messages; retry on known transient faults (429s, throttling) with exponential backoff.

---

## Security & Compliance Posture (Bank-Grade)

- **Code signing:** All scripts/modules signed before publish.  
  - **CI:** `AllSigned`; **dev:** `RemoteSigned`.  
- **Least privilege:** Document exact roles/permissions per dataset (see table below).  
- **Redaction:** Emails, secrets, tokens, and tenant-sensitive fields **must** be redacted in logs and samples.  
- **Evidence catalog:** Maintain a lightweight mapping from dataset → control families → evidence artifacts.

| Dataset / Script                         | Cloud | Primary Controls              | Evidence Produced                                   |
|---|---|---|---|
| management groups / subscriptions / rg   | Azure | NIST AC-2, AC-3; Azure W-A    | Hierarchy, scopes, properties                       |
| azure rbac definitions & assignments     | Azure | NIST AC-2(7), AC-6            | Role defs, assignments with scope and principals    |
| directory roles & assignments            | Entra | NIST AC-2, AC-5, AC-6         | Roles (incl. privileged flag), member listings      |
| app registrations & service principals   | Entra | NIST IA-2, AC-3               | Apps/SPs, API permissions, consents, owners         |
| groups (cloud-only) & memberships        | Entra | NIST AC-2                      | Groups, membership, non-member roles as explicit rows |
| aws accounts / roles / policies          | AWS   | NIST AC-2, AC-6               | Roles, trust policies, inline/attached policies     |
| gcp projects / iam bindings              | GCP   | NIST AC-2, AC-3               | Roles, bindings, members                            |

*(Keep the table small; expand as datasets grow.)*

---

## Connection Strategy (Multi-Tenant Friendly)

- **Entra connection module:** Centralizes Microsoft Graph (Entra ID) and Azure Resource Manager auth; future AWS/GCP modules will mirror the same contract.  
- **Auth modes:** device code for interactive; **preferred** service principals for automation with **read-only** scopes/roles.  
- **Tenants file:** `.config/tenants.json` stores tenant IDs, clouds, labels, and preferred auth mode (non-secret).  
- **Context reuse:** detect existing sessions; prompt reuse vs. reconnect.  
- **Retry & throttling:** standard policy across modules.

---

## Data & Export Schemas (paused during raw-export phase)

- **Formats:** CSV + JSON (optionally Parquet later).
- **Schema manifests:** Schema definitions are deferred; keep `dataset_version` metadata future-friendly but do not enforce schemas.
- **Headers:** each file includes `generated_at`, `tool_version`, `dataset_name`, and optional `dataset_version`.
- **Excel:** continue to support `.xlsx` via ImportExcel for analysts; note Excel row limits in docs.

---

## CI/CD & Quality Gates

- **Pipeline stages:** validate (PSScriptAnalyzer) → test (Pester) → sign → package → publish.  
- **Fail on warnings:** treat analyzer warnings as build failures (configurable).  
- **Changelog:** required for every change; follow SemVer.  
- **Artifacts:** example exports from synthetic tenants where feasible.

---

## MVP Scope (Clarified with Acceptance Criteria)

- **Azure scopes hierarchy**  
  **AC:** Enumerates all Management Groups, Subscriptions, and Resource Groups. Cross-checks counts with `Get-AzManagementGroup` and `Get-AzSubscription`.

- **Azure RBAC definitions & assignments**  
  **AC:** Exports built-in + custom roles and **all** assignments per scope; validates no principal loss compared to portal CSV export for a sample subscription.

- **Entra directory roles & assignments (privileged flagged)**  
  **AC:** Every directory role present whether or not it has members; “no-member” rows are explicit; privileged roles identified.

- **Applications & Service Principals (incl. API permissions & consents)**  
  **AC:** Registered apps and orphaned SPs are both present; API permissions and tenant consents captured; totals match Graph query counts.

- **Groups (cloud-only) & memberships**  
  **AC:** Exclude synchronized groups where required; document detection logic; membership counts consistent across repeated runs.

- **Exports (dual-format)**
  **AC:** Each dataset emits CSV and JSON with metadata headers (`generated_at`, `tool_version`, optional `dataset_version`). Schema validation is deferred until definitions return.

---

## Ensure-Prereqs.ps1 (Standard)

1. Detect PowerShell 7.4+.  
2. Ensure **PSResourceGet** is available (install if missing).  
3. Install/upgrade pinned module versions (scope: CurrentUser).  
4. Normalize `PSModulePath`.  
5. Run PSScriptAnalyzer over repo; print actionable summary.  
6. Output a machine-readable **Prereq Report** (JSON) plus console summary.

---

## Glossary (for LLM/Human Precision)

- **Azure RBAC:** Role assignments at management group, subscription, resource group, or resource scope.  
- **Directory role (Entra ID):** Built-in role for tenant administration (e.g., Global Administrator).  
- **Service principal:** Application identity in a tenant, often tied to an app registration.  
- **App registration:** Application object with permissions/consents, from which service principals are instantiated.  
- **Cloud-only group:** Group created in Entra ID, not synchronized from on-premises.

---

## Visual — End-to-End Flow

```mermaid
flowchart LR
  A[entra_connection module] --> B[azure: scopes & rbac]
  A --> C[entra: roles, groups, apps, sps]
  A --> D[aws (later)]
  A --> E[gcp (later)]
  B --> F[normalize]
  C --> F
  F --> G[logging & redaction]
  G --> H[export: csv / json / xlsx]
  H --> I[compliance catalog]
```

---

## Required Modules (Pinned & Correct)

- **ImportExcel**  
- **Microsoft.Graph** (select submodules only; avoid installing the full roll-up unless necessary)  
- **Microsoft.Graph.Entra** (modern Entra ID cmdlets built on Microsoft Graph)  
- **Az** (select submodules only; e.g., `Az.Accounts`, `Az.Resources`)  
- **PSScriptAnalyzer**, **Pester**, **Microsoft.PowerShell.SecretManagement**

> **Corrections applied:**  
> - “Microsoft.Grape” → **Microsoft.Graph**  
> - “PSGAllary” → **PSGallery**  
> - Numerous spelling/grammar fixes across the document.

---

## repo_contract.md (Summary — see `/docs/repo_contract.md` for full text)

- **Runtime:** PowerShell 7.4+  
- **Packaging:** PSResourceGet; pinned minimum versions  
- **Quality gates:** PSScriptAnalyzer (fail on warn), Pester contracts (schema validation paused)
- **Security:** AllSigned in CI; RemoteSigned in dev; SecretManagement; no secrets on disk
- **Outputs:** CSV + JSON with metadata headers (`generated_at`, `tool_version`, optional `dataset_version`); schema manifests will return in a future phase
- **Change control:** SemVer + mandatory CHANGELOG entries
