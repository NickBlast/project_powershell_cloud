# Wave 3 — Static Analysis Remediation

## Status: Remediation Complete

- Analyzer run on the repository, and all reported issues have been resolved. The analyzer now runs clean.

## Summary of Changes

- **`scripts/export-entra_role_assignments.ps1`**:
  - **PSAvoidTrailingWhitespace**: Removed trailing whitespace from the comment-based help block.
  - **PSAvoidUsingPositionalParameters**: Changed the `Join-Path` command to use named parameters (`-Path` and `-ChildPath`) instead of positional parameters.
  - **Comment-based help**: Fixed a typo (`[.EXAMPLE` to `.EXAMPLE`) in the comment-based help.

## Analyzer Output

- `Invoke-ScriptAnalyzer -Path . -Recurse` now returns no warnings or errors.

## Next Steps

- Proceed to Wave 4 (Naming and Variables).