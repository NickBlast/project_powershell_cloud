# Research & Discovery Template (Solo Dev, MVP-First)

The goal of this template is to produce a fast, credible research base that constrains an MVP to something shippable. The output should be a **structured outline + key sources**, not a PRD. Keep it evidence-driven and vendor-agnostic.

---

## 1. Problem & Context

- **Problem statement:**  
- **For whom:**  
- **Why now:** trends, costs, risks, or opportunities that make this urgent.  
- **Prior art / internal attempts:** what exists and why it’s insufficient.

---

## 2. Research Questions

List the concrete questions you must answer to scope an MVP. Examples:
- What data sources are essential vs. optional for the first release?
- What permissions are minimally required (least privilege) to read inventory?
- What is the simplest path for cross-tenant auth without storing secrets?
- What are the expected data volumes and API throttling limits?
- What are audit/compliance must-haves vs. nice-to-haves?

---

## 3. Search Plan & Source Targets

- **Search terms:** write the exact queries you’ll use (include cloud-specific API names).
- **Primary sources:** official docs (cloud providers, SDKs), standards bodies, reputable vendor whitepapers.
- **Evaluation criteria:** recency, authority, specificity to MVP scope, and operational feasibility.
- **Out-of-scope sources:** forums and opinion pieces may inform but not define requirements.

---

## 4. Market Scan (Right-Sized)

- **Target users:** roles, environments, constraints.  
- **Competitors/alternatives:** list and summarize.  
- **Differentiation for MVP:** smallest wedge of unique value worth shipping.

---

## 5. Technical Feasibility

- **APIs and SDKs:** enumerate endpoints/modules needed and known limits.  
- **Auth patterns:** device code vs. service principals; trade-offs.  
- **Data model:** initial schema(s) for the outputs you will emit.  
- **Performance envelope:** time-to-export targets and constraints.

> ### Note on Platform Constraint (PowerShell-First)
> For this project, the MVP is **PowerShell-only** (7.4+). Favor built-in or official modules (e.g., Microsoft.Graph, Az submodules) and **PSResourceGet** for package management. Defer service runtimes, web UIs, and background daemons to post-MVP phases or to the separate Python Micro-SaaS track.

---

## 6. Security & Compliance

- **Least privilege:** exact roles/permissions required per cloud.  
- **Secret handling:** SecretManagement vault strategy; no tokens on disk.  
- **Code integrity:** signing requirements and trust policy.  
- **Audit outputs:** which artifacts double as evidence (who/what/when).  
- **Standards mapping:** NIST SP 800-53, CSA CCM, FFIEC CAT—state the relevant control families, not full text.

---

## 7. MVP Recommendation

- **MVP scope** (1 paragraph + MoSCoW bullets).  
- **Acceptance criteria** (testable statements).  
- **De-scopes for now** (explicit).  
- **Open questions** with a plan to resolve (experiments, spikes).

---

## 8. Initial Execution Plan

- **Week 1–2:** discovery spikes, auth prototypes, schema draft.  
- **Week 3–4:** end-to-end thin slice (one tenant, one cloud).  
- **Week 5:** hardening (logging, redaction, schema validation).  
- **Week 6:** docs, packaging, release.

---

## 9. Bibliography (Link-Rich)

Cite official docs and high-quality sources with titles and dates. Keep this list short but strong.

---

### Research Output Checklist

- [ ] Each claim has a source or a clear experiment plan.  
- [ ] MVP scope fits a 4–6 week solo build.  
- [ ] Security/compliance constraints are explicit and practical.  
- [ ] Data schemas exist (even if provisional).
