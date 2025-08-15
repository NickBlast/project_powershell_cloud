# Contributing

This file summarizes contribution rules for this repository. See `docs/repo_contract.md` for the authoritative contract and rationale.

Prerequisites
- Ensure local prerequisites are installed before development:
  pwsh -NoProfile -File scripts/ensure-prereqs.ps1

Branching
- Use feature branches with the following prefixes:
  - feat/<area>__<short> — new features
  - fix/<area>__<short> — bug fixes
  - docs/<area>__<short> — documentation updates

Examples:
- feat/storage__upload-progress
- fix/cli__arg-parsing

Commits
- Follow Conventional Commits (type(scope): subject). Examples:
  - feat(cli): add upload command
  - fix(vm): handle null response

Code style and quality
- PSScriptAnalyzer must be clean for changed files. CI will run PSScriptAnalyzer.
- PowerShell source uses 4-space indentation for scripts and modules.
- Comment-based help is required for all public functions, exported cmdlets, and top-level scripts.

Security
- Do not commit secrets, API keys, or credentials to the repository or workspace.
- Redact sensitive values in logs and test output before committing or publishing artifacts.
- CI runs with script signing policy AllSigned; ensure artifacts and scripts are signed where required.

Schemas and dataset changes
- Any change that affects datasets must include schema validation tests and updates under `docs/schemas/`.
- Breaking dataset changes must bump `dataset_version` in the schema, and include a migration note in the PR describing upgrade steps.

Pull Request checklist
- Include lint and test output in the PR description (or link to CI run).
- Note whether the change affects schemas/datasets and link to the schema file(s).
- State the acceptance criteria and include steps to verify them.
- Describe risk and rollback steps (how to revert or mitigate if the change causes regressions).

Links
- Repo contract (authoritative): `docs/repo_contract.md`
- Conventional Commits: https://www.conventionalcommits.org/
