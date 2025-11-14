You are my Staff Research Analyst.

Objective: produce a rigorous, source-cited deep-research package for the **PowerShell IAM Inventory MVP**. The goal is to validate feasibility, nail least-privilege access, and define data schemas/limits across Azure/Entra ID, AWS, and GCP — WITHOUT writing a PRD. Keep scope PowerShell-only (PS 7.4+), CLI-first, no web UI or service runtime.

========================
OPERATING RULES
========================
- Browse the web extensively. For each nontrivial claim, cite ≥2 authoritative sources (official docs, standards, reputable vendor whitepapers). Avoid forums unless triangulated.
- Output in Markdown. Prefer short paragraphs + tables. Include Mermaid when useful. Provide CSV snippets when listing columns.
- Structure work in TWO PASSES:
  1) **Outline & Source Plan** (1–2 pages). Stop for my “continue”.
  2) **Main Report** (detailed, with tables/figures), following the outline.

========================
CONTEXT (CANONICAL CONSTRAINTS)
========================
- Runtime: PowerShell **7.4+**; packaging via **PSResourceGet**; modules: **Microsoft.Graph** (select submodules), **Az.Accounts/Az.Resources** (select), **ImportExcel**, **PSScriptAnalyzer**, **Pester**, **Microsoft.PowerShell.SecretManagement**.
- Naming: directories lower_case_with_underscores; PowerShell uses **Verb-Noun** with underscores allowed inside the noun (e.g., `Export-Role_Assignments.ps1`).
- Security posture: **AllSigned** in CI, **RemoteSigned** in dev; no secrets on disk; **SecretManagement** vault abstraction; strict redaction in logs/exports.
- Deliverables: dual exports **CSV + JSON** (optionally Parquet later), with headers `generated_at`, `tool_version`, `dataset_version`; schemas versioned in `/docs/schemas`.
- MVP datasets (acceptance-criteria driven): Azure scopes (MG/Subscription/RG), Azure RBAC role definitions + all assignments, Entra directory roles + assignments (privileged flagged), Entra apps & service principals (permissions + consents), Entra cloud-only groups + memberships. Focus on deterministic, idempotent exports.

========================
PASS 1 — OUTLINE & SOURCE PLAN
========================
Produce 1–2 pages that include:
A) **Research Questions (exhaustive, prioritized)**  
   - Exact least-privilege roles/permissions per dataset for: Azure/Entra, AWS, GCP.  
   - Required Microsoft Graph permissions (Application/Delegated) for directory roles, apps/SPs, groups, and consent discovery.  
   - Azure RBAC API coverage & limits for role definitions/assignments across MG/Subscription/RG; how to ensure no principal loss vs. portal CSV.  
   - API throttling, pagination, and recommended retry windows (Graph, ARM, AWS IAM/Organizations, GCP Cloud Resource Manager/IAM).  
   - Expected export sizes & performance envelopes (per tenant size bands).  
   - Data fields/columns for each dataset (minimum viable schema); normalization approach.  
   - Authentication patterns (device code vs. SPN) and secure storage strategy (SecretManagement).  
   - Code signing setup and trust policy that works on Windows/macOS/Linux.  
   - Evidence mapping to NIST SP 800-53, CSA CCM, FFIEC CAT for each dataset.  
   - Known pitfalls (e.g., Graph directoryRole vs. unifiedRole APIs; custom role nuances; guest users; orphaned SPs; consent scoping).
B) **Search Terms (literal strings to use)** per cloud and dataset.  
C) **Target Sources** (Microsoft Learn/Docs, Azure REST/Graph refs; AWS docs; Google Cloud docs; NIST/CSA/FFIEC primary).  
D) **Evaluation Criteria** (recency, authority, specificity to MVP, operational feasibility).  
E) **Deliverable Inventory** (tables/figures you will produce in Pass 2).

Stop after PASS 1 and wait for my “continue”.

========================
PASS 2 — MAIN REPORT (DETAILED)
========================
Follow your approved outline. Produce the following sections:

1) **Executive Synthesis (≤12 bullets)**  
   - Feasibility verdict, biggest blockers, top decisions, and go/no-go risks.

2) **IAM Data Access — Least Privilege Matrices (per cloud)**  
   - Tables that map each dataset → exact roles/permissions needed (e.g., Azure built-in roles, Graph scopes; AWS IAM read-only policies; GCP viewer/iam.securityReviewer, etc.).  
   - Call out where elevated rights are unavoidable and propose safer read paths.

3) **API Coverage & Limits**  
   - Endpoints/PowerShell modules per dataset (e.g., Graph beta vs v1.0 where applicable; ARM/Az equivalents).  
   - Quotas, throttling behaviors, pagination, and **recommended retry/backoff** strategies.  
   - Include code-oriented notes (just enough) to show the canonical call path.

4) **Dataset Schemas (Draft v1)**  
   - For each dataset, provide: **purpose, primary keys, required columns (name:type), nullable rules, joins/relationships**, and a CSV header example.  
   - Note any sensitive fields to redact from logs.

5) **Authentication Patterns**  
   - Compare device code vs. service principal for each cloud; enumerate minimal app registrations/SPNs and Graph scopes for automation; vault integration pattern.

6) **Security, Compliance & Evidence Mapping**  
   - Table mapping dataset → NIST SP 800-53/CSA CCM/FFIEC CAT control families served (1–3 per dataset).  
   - Logging/redaction policy recommendations.

7) **Performance & Scale Expectations**  
   - Time-to-export targets by tenant size bands; where parallelization is safe.

8) **Risks, Unknowns, and Experiments**  
   - Top 10 unknowns with concrete spike/experiment plans and pass/fail criteria.  
   - Assumptions requiring confirmation (e.g., Graph consistency for app consents).

9) **Bibliography**  
   - Link-rich, authoritative references (title + date). Keep it tight but strong.

========================
FORMATTING & ARTIFACTS
========================
- Use tables generously. Include CSV header snippets for each dataset.  
- Include 1 Mermaid diagram for the end-to-end collection flow.  
- Where helpful, include tiny PowerShell pseudo-snippets to disambiguate APIs (do not over-code).

========================
GUARDRAILS
========================
- Do NOT propose a service runtime, web UI, or Python deliverables. PowerShell CLI only.  
- Align to our naming, packaging, and signing constraints.  
- If sources disagree, present both and mark the uncertainty.

Attachments available for context (read before starting): **powershell_repo_design.md**, **prd_best_practices_template.md**, **research_and_discovery_template_reference.md**.

Begin with PASS 1 now.
