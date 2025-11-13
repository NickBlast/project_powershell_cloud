# Testing Overlay

- Add/maintain Pester tests under `/tests/*.Tests.ps1`; mirror module/script names.
- Cover: parameter validation, schema conformance of sample objects, and error paths for invalid data.
- CI requires `Invoke-Pester -Output Detailed`; keep tests deterministic and independent of live cloud calls.
- Store sanitized sample objects in `/tests/data/` or `/examples/` to avoid live dependencies.
