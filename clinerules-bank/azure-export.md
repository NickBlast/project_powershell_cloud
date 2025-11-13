# Azure Export Overlay

Use with Azure RBAC/Resource export tasks.

- Require `Az.Accounts` + `Az.Resources` submodules only; authenticate via `Connect-AzAccount -Tenant` with device code unless automation credentials are supplied.
- Apply `Invoke-WithRetry` (or equivalent) around `Get-Az*` calls; default: 6 attempts, base delay 1s, factor 2, jitter +-20%.
- Validate scope coverage (MG -> Subscription -> RG -> Resource) before writing outputs.
- Include `tenant_id` and `scope` fields in structured logs for correlation.
- Cross-check counts against portal CSV exports for sanity.
