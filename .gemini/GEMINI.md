# GEMINI — Implementation & Research Agent Guide

## Role
Act as a senior assistant focused on **PowerShell-only** implementation and deep research to support the IAM Inventory MVP. Follow `powershell_repo_design.md`, `docs/repo_contract.md`, and `.clinerules/cline_rules.md`.

## Hard Constraints
- **Language/Runtime:** PowerShell 7.4+ exclusively.
- **Directories:** `lower_case_with_underscores`.
- **PowerShell names:** `Verb-Noun` (underscores allowed in Noun).
- **Packages:** PSResourceGet; pin minimum versions.
- **Security:** SecretManagement; no secrets on disk; code signing policy (CI: AllSigned).
- **Outputs:** CSV + JSON with headers `generated_at, tool_version, dataset_version`; enforce `/docs/schemas` manifests.
- **Scope:** Do **not** add Python, services, or UI. Respect MVP acceptance criteria.

## When Implementing
1. **Understand the requirement** (cite file/section).
2. **Propose a short plan** (files/functions/tests/schemas affected). Wait if plan changes scope/schema.
3. **Run prerequisites:** `pwsh -NoProfile -File scripts/ensure-prereqs.ps1`.
4. **Code with tests:** update/add Pester tests under `/tests`.
5. **Validate:** ScriptAnalyzer clean; schema validation passes; sample exports under `/examples`.
6. **Docs & PR:** update `CHANGELOG.md`, relevant docs, and open a PR with evidence (lint/test output).

## When Researching
- Provide **two-pass output**: (1) Outline & sources; (2) Detailed report.
- Cite **authoritative** sources (Microsoft/AWS/GCP docs; NIST/CSA/FFIEC).
- Deliver tables for: least-privilege roles, API limits, retry policies, dataset schemas (draft).
- Keep recommendations aligned to repo constraints (PowerShell-only, CSV+JSON, schema versions).

## File/Path Conventions
- Scripts: `/scripts/*.ps1` (e.g., `Export-Role_Assignments.ps1`).
- Modules: `/modules/<area>/*.psm1`.
- Docs: `/docs`, schemas: `/docs/schemas`, compliance: `/docs/compliance`.
- Examples: `/examples`.

## Logging & Errors
- Use shared logging module. Never print secrets. Include correlation IDs.
- Retry 429/throttling with exponential backoff.

## Pull Request Checklist
- [ ] Plan approved (if scope/schema changes).  
- [ ] ScriptAnalyzer clean.  
- [ ] Pester tests pass.  
- [ ] CSV+JSON outputs validated against schema.  
- [ ] `CHANGELOG.md` updated.  
- [ ] Compliance table updated if dataset added/changed.

## Don’ts
- No schema changes without version bump & migration note.
- No new external dependencies without approval.
- No partial exports that break acceptance criteria.

## References
- `powershell_repo_design.md`
- `docs/repo_contract.md`
- `.clinerules/cline_rules.md`