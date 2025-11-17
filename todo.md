# Project Tasks

Use this file as the single backlog. Keep entries actionable, cite evidence when available, and remove them immediately once finished.

## Active Tasks
- [ ] Review `docs/` (reference, runbooks, governance) for outdated statements or gaps, focusing on AI and documentation rules.
- [ ] Instrument every export script with `Write-StructuredLog` so runs emit correlation-aware logs rather than `Write-Verbose` only.
- [ ] Expose `-TenantId`/`-TenantLabel` (or similar) parameters on CLI scripts so operators are not forced to edit `.config/tenants.json` for each run.
- [ ] Apply `Invoke-WithRetry` (or chunked pagination) to Azure exports (`Get-Az*` calls) the same way Graph scripts already do to avoid throttling failures on large tenants.
- [ ] Update entra_connect.psm1 module with strong comments and metadata for each code block.

## SCHEMA-FUTURE
- [ ] Reintroduce schema validation helpers and tests once datasets stabilize; include property/type enforcement when schemas return.
- [ ] Define the schema storage location and contract when the future schema phase is approved.
