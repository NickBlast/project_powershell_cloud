# Minimal testing workflow for Entra / Azure exports

## Goal
Provide a quick, reliable way to validate Entra and Azure export scripts against the sandbox tenant while keeping tooling lightweight and discoverable.

## Environment contract
Set the following variables in your shell or CI environment (do not commit values):

- `ENTRA_TEST_TENANT_ID` (tenant ID, GUID)
- `ENTRA_TEST_CLIENT_ID` (app registration client ID)
- `ENTRA_TEST_SECRET_VALUE` (client secret value; do not log)
- `ENTRA_TEST_SUBSCRIPTION_ID` (Azure subscription ID, optional for Entra-only runs)
- `ENTRA_TEST_SECRET_ID` is metadata only and unused for auth.

## Minimal test checklist
1. Verify `ENTRA_TEST_*` environment variables are present.
2. Seed the test assets once (idempotent):
   ```pwsh
   pwsh -NoProfile -File ./scripts/seed-entra_test_assets.ps1
   ```
3. Run the basic tests:
   ```pwsh
   pwsh -NoProfile -File ./tests/run-tests-basic.ps1
   ```
   Add `-SkipSmoke` to run only static analysis when offline.
4. Review outputs and logs:
   - `outputs/entra/*.csv` and `outputs/azure/*.csv`
   - `tests/results/last_run.json` for the latest smoke summary

## Test assets package (pctest-*)
The seeding script creates or reuses a minimal set of resources:
- Users: `pctest-user-01/02/03@<tenant domain>`
- Groups: `pctest-group-owners`, `pctest-group-readers` with pctest users as members
- App registration + service principal: `pctest-app-sample`
- Directory role membership: `pctest-group-readers` added to **Directory Readers**
- Azure RBAC: service principal assigned **Reader** at the configured subscription (when available)

These objects live only in the sandbox tenant and are safe to rerun; the script will reuse existing pctest-* assets.

## Tooling in scope
- **PSScriptAnalyzer**: run by `tests/run-tests-basic.ps1` across `modules/` and `scripts/`; findings print to console.
- **Pester**: limited to module import and environment sanity checks in `tests/entra_connection.Tests.ps1`.
- **Live smoke tests**: the canonical validation step; runs key export scripts against the tenant and summarizes row counts.

## Adding a new export script
1. Import the helpers:
   ```pwsh
   Import-Module ./modules/entra_connection/entra_connection.psm1
   Import-Module ./modules/logging/Logging.psm1
   Import-Module ./modules/export/Export.psm1
   Connect-EntraTestTenant
   ```
2. Query Entra/Azure using the shared connection.
3. Write output to `outputs/entra` or `outputs/azure` using `Write-Export` with the standard metadata fields (`generated_at`, `tool_version`, `dataset_name`).
4. Add the script path to `tests/run-tests-basic.ps1` to include it in the smoke list.
