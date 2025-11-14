# Project Tasks

Use this file as the single backlog. Keep entries actionable, cite evidence when available, and remove them immediately once finished.

## Active Tasks
- [ ] Review `.gemini/*` prompt/agent configuration for accuracy and alignment with current repo rules.
- [ ] Review `docs/` (reference, runbooks, schemas guidance) for outdated statements or gaps, focusing on AI and documentation rules.
- [ ] Instrument every export script with `Write-StructuredLog` so runs emit correlation-aware logs rather than `Write-Verbose` only.
- [ ] Stand up a `tests/` suite (Pester 5) that exercises module parameter contracts and validates sample objects against schemas.
- [ ] Enhance `Test-ObjectAgainstSchema` to enforce property types/additional-fields (consider `Test-Json` with the schema) so exports fail fast on incompatible data.
- [ ] Expose `-TenantId`/`-TenantLabel` (or similar) parameters on CLI scripts so operators are not forced to edit `.config/tenants.json` for each run.
- [ ] Apply `Invoke-WithRetry` (or chunked pagination) to Azure exports (`Get-Az*` calls) the same way Graph scripts already do to avoid throttling failures on large tenants.
- [x] Update `scripts/ensure-prereqs.ps1` to ensure proper syntax and fix all PowerShell errors encountered during setup. (2025-11-13)
