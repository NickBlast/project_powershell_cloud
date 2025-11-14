# PRD Best Practices Template (Solo Dev, MVP-First)

This document defines how we write Product Requirements Documents (PRDs) for solo-developer MVPs. It is intentionally lean, opinionated, and designed to prevent scope drift while still providing enough depth for stakeholders and future you. Treat this as a **living document**—PRDs evolve as discovery clarifies the problem and solution.

---

## Operating Principles

- **Why/What over How:** PRD captures the problem, outcomes, and constraints. Implementation details belong in technical plans and code, not here.
- **MVP ruthlessness:** Use **MoSCoW** (Must, Should, Could, Won’t) to gate features. MVP ships once **Musts** meet acceptance criteria.
- **Single source of truth:** The PRD is canonical for *scope*. Link out to research, designs, and implementation artifacts rather than duplicating them.
- **Traceability:** Every requirement should map to a research insight, a user need, or a business outcome.
- **Testable by reading:** Each requirement includes **acceptance criteria** readable by a human (no code necessary).

---

## PRD Structure (Copy this into new PRDs)

### 1. Project Summary
- **Title:**  
- **Owner:**  
- **Status:** Draft / Review / Approved / Deprecated  
- **Target Release:**  
- **Doc Links:** Research, design mocks, Implementation Charter (annex), roadmap

### 2. Executive Summary
A tight narrative:
- **Problem:** What hurts, for whom, and why now?
- **Outcome:** The measurable change we want.
- **Approach:** One paragraph on the solution direction appropriate to an MVP.

### 3. Users & Jobs To Be Done
- **Primary users:** Roles or personas (keep them real, not archetypes).
- **Top JTBD statements:**  
  `When [situation], I want to [motivation], so I can [expected outcome].`
- **Context & constraints:** Environments, devices, security posture.

### 4. Scope (MVP via MoSCoW)
- **Must Have:**  
  - [REQ-M-01] … *(with acceptance criteria)*
- **Should Have:**  
- **Could Have:**  
- **Won’t Have (Now):** Explicit de-scopes to prevent drift.

> **Acceptance Criteria pattern:**  
> *Given* [precondition], *when* [user action/system condition], *then* [observable outcome+measurement].

### 5. Non-Functional Requirements
- **Performance:** e.g., complete dataset export under N minutes for T tenants.  
- **Security:** authentication model, least privilege, data handling, code signing.  
- **Reliability:** error budgets, retriable operations, idempotency.  
- **Operability:** logs, metrics, diagnostics, upgrade policy.  
- **Compliance:** frameworks that guide scope (list, don’t explain).

### 6. Success Metrics (KPIs)
- **Activation:** % of intended users who complete first successful run.  
- **Time to value:** median minutes from zero to first useful output.  
- **Data coverage:** % of targeted resources successfully inventoried.  
- **Quality:** schema compliance rate, error rate, user-reported issues.  
- **Retention/Reuse:** % users who run again within 30 days (if applicable).

### 7. Risks & Mitigations
- **Tech risks:** API limits, throttling, permissions variance across tenants.  
- **Product risks:** unclear value vs. complexity, mis-scoped MVP.  
- **Mitigations:** concrete experiments, phased rollouts, feature toggles.

### 8. Dependencies & Assumptions
- **Dependencies:** external APIs, credentials, cloud quotas, data access.  
- **Assumptions:** environment, user skill level, available test tenants.

### 9. Future Roadmap (Post-MVP, 3–6 months)
Bullet the next likely phases with decision gates and learnings needed.

---

## Authoring Checklist

- [ ] Every **Must** has unambiguous acceptance criteria.  
- [ ] De-scopes are explicit in **Won’t Have (Now)**.  
- [ ] Each requirement traces to research or user evidence.  
- [ ] Metrics are measurable with the available telemetry.  
- [ ] Security and compliance constraints are stated up front.

---

## Annex A: Implementation Charter (Reference Only; do **not** expand here)

This annex constrains implementation without bloating the PRD.

- **Runtime:** PowerShell 7.4+ (cross-platform).  
- **Packaging:** PSResourceGet packages; private feed optional.  
- **Quality gates:** PSScriptAnalyzer, Pester (contract tests), schema validation.  
- **Security:** AllSigned in CI; RemoteSigned in dev; no secrets written to disk; SecretManagement for credentials.  
- **CI/CD:** validate → test → sign → package → publish, with changelog required.  
- **Data outputs:** CSV + JSON (and/or Parquet), versioned schemas.

