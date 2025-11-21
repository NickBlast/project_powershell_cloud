# Workflow Migration Overview

## 1. Goal
- Migrate from `work_orders.md` + `todo.md` to GitHub Issues as the canonical backlog.

## 2. Principles
- One work item per Work Order or Issue.
- One branch per work item.
- One Pull Request per work item.
- Every work item starts with a short “Research & Plan” step using official documentation where needed.

## 3. Stages
- **Stage 1: Define labels and GitHub Issue templates (Work Order, Bug, Research).**
  - Establish shared labels for type and status and add Issue templates for each work item type.
- **Stage 2: Freeze markdown for new work; use Issues for new work only.**
  - Add clear banners to `work_orders.md` and `todo.md` once templates exist; direct new items to GitHub Issues.
- **Stage 3: Migrate open Work Orders and todos into Issues.**
  - Create Issues for remaining backlog entries and mark migrated items as archived in the markdown trackers.
- **Stage 4: Enforce the new workflow in AI agent rules and GitHub Actions.**
  - Update guardrails and automation so contributors follow the Issue → branch → Pull Request flow.

## 4. Where detailed rules live
- Detailed standards remain in `ai_project_rules.md` and `AGENTS.md`.
