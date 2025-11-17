# Wave 9 – Minimal testing workflow

## Changes
- Centralized tenant connection helpers (modules/entra_connection) and lightweight export logging (modules/logging).
- Simplified export writer metadata (generated_at, tool_version, dataset_name) and updated export scripts to target outputs/entra and outputs/azure.
- Added test asset seeding script plus minimal smoke runner in `tests/run-tests-basic.ps1`.
- Documented the workflow in `docs/testing/entra_basic_workflow.md` and clarified outputs layout.

## How to seed assets
```
pwsh -NoProfile -File ./scripts/seed-entra_test_assets.ps1
```
Creates/reuses pctest-* users, groups, app/service principal, directory role membership, and Azure Reader assignment (when subscription ID is available).

## How to run basic tests
```
pwsh -NoProfile -File ./tests/run-tests-basic.ps1
```
- Includes ScriptAnalyzer linting and live smoke exports for core datasets.
- Use `-SkipSmoke` when offline to run only static checks.

## Outputs and logs
- CSV exports land under `outputs/entra/` and `outputs/azure/`.
- Smoke run details aggregate at `tests/results/last_run.json`.

## Assumptions
- ENTRA_TEST_* environment variables are configured with application permissions to read directory and subscription data.
- Core smoke scripts: entra_groups_cloud_only, entra_group_memberships, entra_role_assignments, azure_rbac_assignments (others can be added later).
