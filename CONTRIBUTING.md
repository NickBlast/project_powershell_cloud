# Contributing Guidelines

This repository uses a strict, minimal, Work-Order-driven workflow.

## Branching

- One Work Order = One PR = One Branch
- Branch naming:
  - `wo-<ID>-short-description`
  - Example: `wo-schema-001-remove-schema-files`

## Pull Requests

- PR MUST reference its Work Order ID in the title.
- PR MUST contain only one logical change.
- PR MUST follow the PR template.
- Keep PRs under ~200 changed lines whenever possible.
- Commits must be small and logical:
  - File removal/moves
  - Documentation updates
  - Logic modifications
  - Final polish

## Review Expectations

- PR must be readable in under 20 minutes.
- No “stealth changes.”
- No mixing:
  - Cleanup + feature work
  - Logging + logic changes
  - Schema + export modifications

## Documentation

If a PR affects behavior:

- Update README
- Update `/docs/`
- Update `backlog.md` (mark relevant tasks complete)

## Testing

- Every PR must be runnable in isolation.

Refer to `docs/reference/repo_contract.md` and `ai_project_rules.md` for the authoritative workflow contract and additional guardrails.
