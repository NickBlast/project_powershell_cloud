# Wave 5 — Help Authoring

## Status: Complete

A full review of the repository's modules was conducted to ensure all exported functions have complete and accurate comment-based help, conforming to the standards in `docs/reference/help_authoring.md`.

### Summary of Changes

Help documentation was added or corrected for nearly every function across all three modules. The primary changes involved adding missing `.OUTPUTS` and `.NOTES` sections to provide better clarity on what each function returns and its intended use. Several typos in examples and descriptions were also corrected.

**`modules/entra_connection/entra_connection.psm1`**
- **`Select-Tenant`**: Added `.OUTPUTS` section.
- **`Connect-GraphContext`**: Added `.OUTPUTS` section.
- **`Connect-AzureContext`**: Added `.OUTPUTS` section.
- **`Get-ActiveContext`**: Added `.OUTPUTS` section and corrected a typo in the `.EXAMPLE`.

**`modules/export/Export.psm1`**
- **`Get-DatasetSchema`**: Added `.OUTPUTS` and `.NOTES` sections.
- **`Test-ObjectAgainstSchema`**: Added `.NOTES` section.
- **`ConvertTo-FlatRecord`**: Added `.OUTPUTS` and `.NOTES` sections.
- **`Write-Export`**: Added `.OUTPUTS` and `.NOTES` sections.

**`modules/logging/Logging.psm1`**
- **`New-LogContext`**: Added `.NOTES` section and corrected a typo in the `.EXAMPLE`.
- **`Set-LogRedactionPattern`**: Added `.OUTPUTS` and `.NOTES` sections and corrected typos in the `.DESCRIPTION` and `.EXAMPLE`.
- **`Get-CorrelationId`**: Added `.OUTPUTS` and `.NOTES` sections.
- **`Write-StructuredLog`**: Added `.OUTPUTS` and `.NOTES` sections and corrected a typo in the `.EXAMPLE`.
- **`Invoke-WithRetry`**: Added `.OUTPUTS` and `.NOTES` sections.

## Next Steps

Proceed to Wave 6 (Documentation Refresh).
