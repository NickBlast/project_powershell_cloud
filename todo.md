# Improvement Backlog

This list tracks Codex-recommended improvements. Update entries as soon as items are completed (remove them when done) so the directory always reflects current work.

## Active Items

1. [ ] Review `.gemini/*` prompt/agent configuration for accuracy and alignment with current repo rules.
2. [ ] Review `docs/` (reference, runbooks, schemas guidance) for outdated statements or gaps, focusing on AI and documentation rules.
3. [ ] Instrument every export script with `Write-StructuredLog` calls so runs emit correlation-aware logs rather than `Write-Verbose` only.
4. [ ] Stand up a `tests/` suite (Pester 5) that exercises module parameter contracts and validates sample objects against schemas.
5. [ ] Enhance `Test-ObjectAgainstSchema` to enforce property types/additional-fields (consider `Test-Json` with the schema) so exports fail fast on incompatible data.
6. [ ] Expose `-TenantId`/`-TenantLabel` (or similar) parameters on CLI scripts so operators are not forced to edit `.config/tenants.json` for each run.
7. [ ] Apply `Invoke-WithRetry` (or chunked pagination) to Azure exports (`Get-Az*` calls) the same way Graph scripts already do to avoid throttling failures on large tenants.
8. [ ] Update `scripts/ensure-prereqs.ps1` to ensure proper syntax and fix all PowerShell errors encountered during setup.
