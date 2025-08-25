# project_powershell_cloud — PowerShell IAM inventory

## What this is

This repository provides PowerShell-only tooling to produce an IAM inventory for cloud environments.
The initial MVP focuses on Azure, with AWS exports supported where noted. See the authoritative repo contract for contribution and operational rules: `docs/repo_contract.md`.

## Supported clouds (MVP)

- Azure (MVP)
- AWS (planned / supported where scripts exist)

## Quick start

1. Install prerequisites (runs platform checks and installs tools):

    ```powershell
    pwsh -NoProfile -File scripts/ensure-prereqs.ps1
    ```

2. Run an Azure export (example):

    ```powershell
    pwsh -NoProfile -File scripts/export-azure_scopes.ps1 -Verbose
    ```

3. Run an AWS export (example — if the script is present):

    ```powershell
    pwsh -NoProfile -File scripts/export-aws_scopes.ps1 -Verbose
    ```

## Required Modules

Installed via `scripts/ensure-prereqs.ps1` (CurrentUser scope; minimum versions pinned):

- Az.Accounts, Az.Resources
- Microsoft.Graph (SDK)
- Microsoft.PowerShell.SecretManagement
- PSScriptAnalyzer, Pester
- ImportExcel (optional for XLSX)
- PSResourceGet (module lifecycle), PowerShellGet (bootstrap)

## Where outputs go

Exports are written to the repository `outputs/` directory by default (or the location printed by the export script).
Each exported dataset must include a minimal header with these top-level fields:

- `generated_at` — UTC timestamp when the export was produced
- `tool_version` — version identifier of the exporting tool/script
- `dataset_version` — semantic dataset version; bump when introducing breaking schema changes

Schema and headers are expected to live under `docs/schemas/` and CI validates schema changes.

## Minimal troubleshooting

- Authentication / Graph issues
  - Ensure you're signed in: `Connect-AzAccount` (Azure) or `aws configure` / `Set-AWSCredential` (AWS).
  - For Microsoft Graph permissions, verify the account has delegated or application permissions required by the script.

- Throttling / rate limits
  - Exports may throttle. Retry with exponential backoff and consider running with -Throttle or pagination-aware flags where supported.
  - When running large exports, run during off-peak hours and consider increasing the batching delay.

- General diagnostics
  - Run scripts with `-Verbose` and capture output.
  - Review any `*.log` files in the `outputs/` folder.

## Links and governance

- Repo contract (authoritative): `docs/repo_design/repo_contract.md`
- Contribution guidelines: `CONTRIBUTING.md`

## License and changelog

See `LICENSE` and `CHANGELOG.md` for release history.

---

If you'd like, I can add example outputs, a sample `outputs/` README, or CI workflows to validate exports and PSScriptAnalyzer rules.
