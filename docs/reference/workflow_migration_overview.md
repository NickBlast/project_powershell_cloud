# Workflow Migration Overview

## Goal
- Migrate from work_orders.md + todo.md to GitHub Issues as the canonical backlog.

## Principles
- One work item per Work Order or Issue.
- One branch per work item.
- One Pull Request per work item.
- Every work item starts with a short "Research & Plan" step using official documentation where needed.

## Stages
- **Stage 1: Define labels and GitHub Issue templates (Work Order, Bug, Research).**
  - Outline label taxonomy for type and status, and draft Issue templates.
- **Stage 2: Freeze markdown for new work; use Issues for new work only.**
  - Add migration banners to work_orders.md and todo.md once templates exist.
- **Stage 3: Migrate open Work Orders and todos into Issues.**
  - Create Issues for remaining items using the new templates and archive migrated entries.
- **Stage 4: Enforce the new workflow in AI agent rules and GitHub Actions.**
  - Update guardrails and automation so every work item flows Issue → branch → Pull Request.

## Where detailed rules live
- See `ai_project_rules.md` and `AGENTS.md` for authoritative process and coding instructions.
