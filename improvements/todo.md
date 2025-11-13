# Improvement Backlog

This list tracks Codex-recommended improvements. Update entries as soon as items are completed (remove them when done) so the directory always reflects current work.

## Active Items

1. [ ] Review `.cline/*` guidance to ensure AI prompt rules and tooling docs are accurate; note any conflicts or stale instructions.
2. [ ] Review `.gemini/*` prompt/agent configuration for accuracy and alignment with current repo rules.
3. [ ] Review `docs/` (reference, runbooks, schemas guidance) for outdated statements or gaps, focusing on AI and documentation rules.
4. [ ] Instrument every export script with `Write-StructuredLog` calls so runs emit correlation-aware logs rather than `Write-Verbose` only.
5. [ ] Stand up a `tests/` suite (Pester 5) that exercises module parameter contracts and validates sample objects against schemas.
6. [ ] Enhance `Test-ObjectAgainstSchema` to enforce property types/additional-fields (consider `Test-Json` with the schema) so exports fail fast on incompatible data.
7. [ ] Expose `-TenantId`/`-TenantLabel` (or similar) parameters on CLI scripts so operators are not forced to edit `.config/tenants.json` for each run.
8. [ ] Apply `Invoke-WithRetry` (or chunked pagination) to Azure exports (`Get-Az*` calls) the same way Graph scripts already do to avoid throttling failures on large tenants.
