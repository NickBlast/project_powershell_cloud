# Wave 8 — Entra Connection Refactor

## Scope
- Rename the shared tenant connection module to `entra_connection` and update every import/reference.
- Align Azure/Graph connection flows with current Microsoft guidance (process-scoped contexts, SecretManagement guards, Microsoft.Graph.Entra docs).
- Extend `scripts/ensure-prereqs.ps1`, documentation, and the test suite to cover the renamed module plus a smoke path through `ensure-prereqs` and `Connect-GraphContext`.

## Changes
1. **Module rename + auth hardening**
   - Moved `modules/connect` → `modules/entra_connection` and refreshed comment-based help to emphasize Microsoft Entra terminology and delegated scopes.
   - Updated `Connect-GraphContext` to use process-scoped `Connect-MgGraph` calls with `-NoWelcome`, graceful SecretManagement failures, and documented read-only scopes.
   - Added `Disable-AzContextAutosave` + SecretManagement error handling to `Connect-AzureContext`, ensuring Azure contexts stay process-bound and service principal secrets are validated.

2. **Prereqs + smoke tests**
   - Reworked `scripts/ensure-prereqs.ps1` to treat module pins as minimum versions, skip downgrades, and ensure `Microsoft.Graph.Entra` is installed alongside Az, Graph, Pester, PSScriptAnalyzer, SecretManagement, and ImportExcel.
   - Created `tests/entra_connection.Tests.ps1` (Pester 5) to cover module import, service principal secret validation, and a WhatIf smoke call through `scripts/ensure-prereqs.ps1` + `Connect-GraphContext`.

3. **Docs + change tracking**
   - Updated README, CHANGELOG, AGENTS, repo contract/design docs, command appendix, and historical audit notes to reference `modules/entra_connection` and document the Graph.Entra dependency.

## Validation
- Not run here: `pwsh -NoProfile -File scripts/ensure-prereqs.ps1`, `Invoke-ScriptAnalyzer -Path . -Recurse`, or `Invoke-Pester`. The new tests plus module rename can be validated locally with:
  - `pwsh -NoProfile -File scripts/ensure-prereqs.ps1`
  - `pwsh -NoProfile -Command "Invoke-Pester -Path tests/entra_connection.Tests.ps1 -Output Detailed"`
