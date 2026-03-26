# Post-Mortem: Entra Connect Sync — Emergency SQL Express Migration

**Date:** March 2026
**Duration:** ~9 hours
**Outcome:** Successful — sync operational on remote full SQL Server instance

---

## Executive Summary

A P1 incident caused by the SQL Express 10GB hard limit required an emergency migration of the ADSync database to a remote full SQL Server instance. The migration succeeded but was significantly extended by underdocumented installation requirements, permission gaps, conditional access interference, and extended wait times caused by incorrect assumptions and early Microsoft guidance. Total elapsed time was approximately 9 hours, the majority of which was consumed by troubleshooting rather than actual migration work.

---

## Timeline of Challenges

### Challenge 1 — Unknown `/useexistingdatabase` Installation Behavior

**What happened:**
The Entra Connect wizard has a "Use Existing Database" option in the GUI, but selecting it in the normal installer flow does **not** actually invoke existing-database mode. The correct method is to run the MSI once to lay down the installation files, close the wizard immediately, then relaunch via PowerShell with the `/useexistingdatabase` argument. This is not prominently documented.

**Impact:**
The wizard treated the existing database as a new one and attempted a fresh configuration. This led to multiple false starts and the DBA having to drop and recreate the database multiple times.

**What we'd do differently:**
Know the correct two-step installation pattern before beginning. This is now documented in the SOP.

---

### Challenge 2 — Empty Database Assumption & Full Sync Wait Time

**What happened:**
Not knowing about the `/useexistingdatabase` issue, and uncertain whether database drift would cause problems, the team made a decision to proceed with an empty database and let a full sync repopulate it. This assumption was incorrect. A full initial sync and import/export with 150,000+ objects takes several hours. The team burned significant time waiting on a fundamentally flawed approach.

**Microsoft confirmation (received mid-incident):**
Database drift is not a problem. You can restore from any prior backup regardless of time elapsed since last sync. The sync engine will self-correct on the next cycle.

**What we'd do differently:**
Always restore from backup. Never proceed with an empty database in a large-object-count environment. Confirm this with Microsoft pre-migration, not during.

---

### Challenge 3 — Service Account Lacked Enterprise/Domain Admin (On-Prem AD)

**What happened:**
The service account provisioned for the installation did not have Enterprise Admin or Domain Admin rights in on-premises Active Directory. The wizard silently hung with no error, no loading bar progress, and no log entries indicating failure. The team waited ~30 minutes before reaching out to Microsoft, who initially said to wait longer (up to an hour). Another full hour was lost waiting before a second Microsoft rep correctly identified the permission issue.

**Impact:**
~1.5–2 hours lost to silent failure + bad wait guidance.

**What we'd do differently:**
Establish up front that the **installing user** must have Enterprise Admin or Domain Admin for the on-prem AD connector step. This is documented but scattered across multiple Microsoft Learn pages. A consolidated pre-flight permission checklist is the fix.

---

### Challenge 4 — Conditional Access Blocking the Entra ID Wizard Account

**What happened:**
The cloud-only account intended for authenticating to Entra ID during the wizard was blocked by a Conditional Access policy enforcing hybrid join compliance. Because it is a cloud-only account, it cannot satisfy a hybrid join requirement — but it also wasn't excluded from the policy.

**Resolution:**
Used a global admin account (the engineer's own account) as a temporary workaround. CA team will add proper exclusion for this account class going forward.

**What we'd do differently:**
Pre-validate that the designated Entra ID wizard account (must be `@*.onmicrosoft.com` or cloud-only) is excluded from any device compliance or hybrid join Conditional Access policies before the migration window opens.

---

### Challenge 5 — Multi-Team Dependency Coordination (Firewall, DBA, AD, CA)

**What happened:**
The following distinct teams/roles were required and had to be pulled in reactively during the incident:

| Role | Requirement | Notes |
|---|---|---|
| DBA | SA rights on SQL instance; database setup and attach | Port/firewall config also needed |
| Network/Firewall team | Open ports between Entra Connect server and SQL instance | Resolved quickly once engaged |
| Active Directory team | Enterprise/Domain Admin to run installer | Brought in same-day; did screen share |
| Conditional Access team | Exclude wizard account from hybrid join CA policy | Temporary workaround used; permanent fix pending |
| Entra Connect engineer | Drive installation, staging, delta sync validation | |

**Impact:**
Each dependency not pre-arranged added latency to the call. Some waits were sequential and blocking.

**What we'd do differently:**
Pre-stage all of these people in a change management request and a pre-migration call. Nobody should be getting pulled in reactively during a P1. This is standard change management and will be enforced for the planned Phase 1 (staging) migration.

---

### Challenge 6 — Local SQL Accounts on the Connector Server (Undiscovered State)

**What happened:**
During the installation, it was discovered that the Entra Connect server has 4 local MSSQL accounts that have likely never had their passwords rotated. The installer appeared to reuse an existing account and silently rotated its password, which ended up working — but the overall state of these accounts is unknown.

**Status:** Unresolved — flagged as a post-incident action item.

**What we'd do differently:**
Audit these accounts as a follow-up action before the next planned migration window. Understand which accounts are created by the Entra Connect installer, which are residual from prior installs, and establish a password rotation process.

---

### Challenge 7 — Deletion Threshold Exceeded on First Export

**What happened:**
After running staging mode delta syncs, the pending export showed ~2,500 deletes — exceeding the configured deletion threshold of 500. Investigation confirmed the deletes were legitimate (valid and expected object removals).

**Resolution:**
Temporarily disabled the deletion threshold, ran the export successfully, then re-enabled the threshold (reset to 500) and restored run history retention to 7 days.

**What we'd do differently:**
During pre-migration planning, evaluate pending delete volume in staging mode before the export window. If a large delete backlog is anticipated, pre-approve a threshold exception rather than discovering it live.

---

## Lessons Learned Summary

| # | Lesson | Action |
|---|---|---|
| 1 | `/useexistingdatabase` requires a two-step install process — GUI does not invoke it | Document in SOP ✅ (already done) |
| 2 | Always restore from backup; empty DB + full sync = hours of wait time | Codified in SOP ✅ |
| 3 | Installing user must have Enterprise/Domain Admin for on-prem AD | Add to pre-flight checklist |
| 4 | Entra ID wizard account must be excluded from device compliance CA policies | CA team to add permanent exclusion |
| 5 | All 4 teams (DBA, network, AD, CA) must be pre-arranged — not reactive | Change request template to include all stakeholders |
| 6 | 4 local MSSQL accounts on connector server need audit and rotation plan | **Open action item** |
| 7 | Validate pending delete volume in staging before export window | Add to Phase 4 pre-export checklist |
| 8 | Microsoft Support quality was inconsistent — first rep gave incorrect wait guidance | Escalate faster; get a second rep if guidance doesn't resolve in 30 min |

---

## Open Action Items

| Priority | Item | Owner |
|---|---|---|
| High | Audit 4 local MSSQL accounts on Entra Connect server — identify, document, rotation plan | Entra Connect engineer |
| High | CA team: add permanent exclusion for cloud-only Entra wizard accounts from hybrid join policy | CA team |
| Medium | Build consolidated pre-flight permission checklist for Phase 1 planned migration | Entra Connect engineer |
| Medium | Draft change request template that pre-stages all 4 team dependencies | Entra Connect engineer |
| Low | Confirm deletion threshold behavior for anticipated future delete waves | Entra Connect engineer |

---

## Interim Documentation Plan

### What Needs to Exist Before Phase 1 Executes

| Deliverable | Purpose | Status |
|---|---|---|
| Post-mortem (this document) | Institutional memory; feeds the SOP gaps | Draft complete — needs review |
| Updated SOP (.docx + .md) | Step-by-step execution guide for Phase 1 | Exists — needs patches from today |
| Pre-flight permission checklist | Single-page reference for all accounts and access required before the change window opens | Does not exist yet |
| Change request template | Formally pre-stages all 4 team dependencies (DBA/network, firewall, AD, CA) | Does not exist yet |
| CA exclusion confirmation | Verification that the wizard account is permanently excluded before Phase 1 | Pending CA team |

---

### SOP Gaps Identified Today

The existing SOP already covers the core migration path correctly. These are the specific patches it needs based on today:

1. **Pre-flight checklist section** — the SOP has a checklist but it doesn't capture the installer permission requirements with enough specificity. Needs a dedicated table covering every account, what it needs, and who owns it.
2. **`/useexistingdatabase` callout** — already in the SOP but should be elevated with a stronger warning. Today confirmed this is the single highest-risk failure point.
3. **Deletion threshold pre-check** — add a step in Phase 1 verification (Step 9) to explicitly assess pending delete volume before the Phase 2 switchover, not just after.
4. **CA policy pre-validation** — add a checklist item confirming wizard account exclusion is in place before opening the change window.
5. **Microsoft Support escalation note** — add a callout that Support quality is inconsistent and to escalate or request a second engineer if guidance doesn't produce forward progress within 30 minutes.

---

### Suggested Sequencing

**This week (while it's fresh):**

- Review and finalize this post-mortem
- Patch the SOP — targeted edits only, not a rewrite
- Draft the pre-flight permission checklist

**Before Phase 1 change request is submitted:**

- CA exclusion confirmed and documented
- Change request template drafted with all 4 team dependencies named
- Pre-flight checklist reviewed by at least the AD and DBA contacts

**Before Phase 1 execution window:**

- All 4 teams confirmed and scheduled
- Checklist signed off
- SOP walk-through with anyone executing alongside you

---

### Proposed Next Steps

1. **Patch the SOP** — targeted edits only against the existing document
2. **Build the pre-flight permission checklist** — single Confluence page, table format, organized by account type and team owner
3. **Build the change request template** — structured around the 4 pre-arranged dependencies
