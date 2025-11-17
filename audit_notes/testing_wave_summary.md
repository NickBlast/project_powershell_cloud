# Testing workflow refresh summary

- New helpers: `modules/entra_connection` now reads ENTRA_TEST_* env vars and exposes `Connect-EntraTestTenant` + `Get-EntraTestContext`; logging adds export start/result helpers.
- New scripts: `scripts/seed-entra_test_assets.ps1` seeds pctest users/groups/app and Azure Reader assignment; `tests/run-tests-basic.ps1` runs ScriptAnalyzer plus smoke exports.
- Export updates: core Entra/Azure export scripts now write to `outputs/entra` or `outputs/azure` with `generated_at`, `tool_version`, and `dataset_name` headers.
- Docs: see `docs/testing/entra_basic_workflow.md` for environment contract, seeding steps, and running the basic checklist.

Quick usage:
- Seed assets: `pwsh -NoProfile -File scripts/seed-entra_test_assets.ps1`
- Run tests: `pwsh -NoProfile -File tests/run-tests-basic.ps1`
- Outputs/logs: CSV/JSON in `outputs/entra` and `outputs/azure`; latest run info in `tests/results/last_run.json` and `tests/results/last_seed.json`.

Assumptions:
- The test app has application permissions to read directory data and assign Reader at the subscription scope.
- Core smoke exports cover Entra groups, memberships, apps/SPs, directory role assignments, and Azure RBAC definitions/assignments.
