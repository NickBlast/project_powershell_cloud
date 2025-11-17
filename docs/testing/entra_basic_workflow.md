# Minimal testing workflow for Entra / Azure exports

## Environment contract
These environment variables must be present (in the shell, CI, or container configuration):

- `ENTRA_TEST_TENANT_ID` (tenant/directory ID)
- `ENTRA_TEST_CLIENT_ID` (app registration client ID)
- `ENTRA_TEST_SUBSCRIPTION_ID` (Azure subscription ID)
- `ENTRA_TEST_SECRET_VALUE` (client secret; **do not log**)
- `ENTRA_TEST_SECRET_ID` is metadata only and not used for auth.

## Minimal test checklist
1. Seed the test assets (run once per tenant refresh):
   ```pwsh
   pwsh -NoProfile -File scripts/seed-entra_test_assets.ps1
   ```
2. Run the basic validation suite:
   ```pwsh
   pwsh -NoProfile -File tests/run-tests-basic.ps1
   ```
3. Review results:
   - Console summary from the test script.
   - CSV/JSON under `outputs/entra` and `outputs/azure`.
   - Last run logs in `tests/results/`.

## Test asset package
The seeding script creates/reuses prefixed objects:
- Users: `pctest-user-01`, `pctest-user-02`, `pctest-user-03` (cloud-only).
- Groups: `pctest-group-owners`, `pctest-group-members` with all pctest users added.
- App registration and service principal: `pctest-app-basic`.
- Azure role assignment: `pctest-app-basic` granted Reader on the test subscription when permitted.

Rerunning the seeding script is idempotent: it reuses existing prefixed assets instead of duplicating them.

## Tooling notes
- **Static analysis:** `tests/run-tests-basic.ps1` runs PSScriptAnalyzer over `modules/` and `scripts/`.
- **Smoke tests:** the same script connects to the test tenant using `Connect-EntraTestTenant` and runs the core export scripts.
- **Pester:** only minimal module-import checks remain under `tests/`.

## Adding a new export script
1. Import `modules/entra_connection`, `modules/logging`, and `modules/export`.
2. Call `Connect-EntraTestTenant` (add `-ConnectAzure` when using Az cmdlets).
3. Query Microsoft Graph or Azure for the data and project a small object set.
4. Call `Write-Export` with `DatasetName`, `OutputPath` (`outputs/entra` or `outputs/azure`), and the object list.
5. Add the script path to `tests/run-tests-basic.ps1` so it participates in smoke tests.
