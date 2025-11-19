# Agent Onboarding — Single Source of Truth (Read Me First)

This document is the **first stop** for any agent (Gemini Command Line Interface, Codex Command Line Interface, Cline for Visual Studio Code, GitHub Copilot) working in this repository. It tells you **how to learn the project**, **what to update locally**, **how to work in safe waves**, and **what “done” means**.

---

## 1) Operating Principles

- **Learn before acting.** Read the entire repository and these reference files before proposing changes.
- **Local agent files only.** Your agent-specific instruction file (for example, `gemini.md`, `codex.md`, `cline_rules.md`, `copilot-instructions.md`) is **local to your machine** and **must never be committed**.
- **Authoritative truth for PowerShell.** Use Microsoft official documentation as the source of truth for all command-lets, modules, and parameters. Do not rely on community forums for semantic correctness.
- **Work in waves with review gates.** Keep each wave small, open a pull request (pull request) per wave, pause for human review, then proceed.
- **Non-destructive by default.** Prefer read-only analysis. Only run safe analyzers when explicitly required.

---

## 2) Read This Repository End-to-End (Required)

Review the following before doing any work:

- **Core project files**
  - `README.md`
  - `CHANGELOG.md`
  - `CONTRIBUTING.md`
  - Any process or product requirement documents stored in this repository

- **Standards and reference (single source of truth)**
  - `docs/reference/powershell_standards.md`  
    Describes naming rules, analyzer posture, help requirements, and module lifecycle expectations.
  - `docs/reference/sources_of_record.md`  
    Curated links to Microsoft official documentation for PowerShell modules and command-lets with brief rationale.
  - `docs/reference/psscriptanalyzer_ruleset.md`  
    Shows the active rule set, including any **narrow, justified** suppressions with reasoning.
  - `docs/reference/help_authoring.md`  
    Explains comment-based help, examples, parameter documentation, and external help generation.
  - `docs/command_appendix.csv`  
    The command-let catalog for this repository with columns: `Cmdlet, Module, Synopsis, Parameters (comma-separated), Official Documentation URL`.

- **Context and change history**
  - `CHANGELOG.md` and `todo.md` (per-wave history, follow-ups, and backlog)

---

## 3) Your Local Agent File (Update Before Work; Never Commit)

Before starting any task, update your **local** agent file to reflect the current state of this repository:

- Gemini Command Line Interface → `gemini.md` (local)
- Codex Command Line Interface → `codex.md` or `AGENTS.md` (local)
- Cline for Visual Studio Code → `cline_rules.md` (local)
- GitHub Copilot → `copilot-instructions.md` (local)

### Required sections in your local agent file

1. **Purpose and Scope for this repository**  
   What you will and will not do here (for example, “audit and fix PowerShell; avoid destructive operations”).
2. **Quick Start (This Run)**  
   One-page checklist of actions for this session based on the most recent wave notes.
3. **Sources of Record**  
   Relative links back to the files in Section 2. State that Microsoft official documentation is authoritative.
4. **Workflow and Stage Gates**  
   Short summary of Waves 0–7. State the review pause after each wave.
5. **Branch and Commit Conventions**  
   Branch naming pattern; Conventional Commit format; pull request template; merge policy.
6. **Analyzer and Naming Requirements**  
   Treat PowerShell Script Analyzer findings as **errors**. Enforce Verb-Noun with **approved verbs**. Apply the repository’s variable naming convention.
7. **Last Run Snapshot**
   Date and time (Coordinated Universal Time), current wave, completed waves, open follow-ups, and links to the latest `CHANGELOG.md` and `todo.md` entries.
8. **Change Log (Documentation)**  
   A short human-readable history of changes to this local file.

> **Never** include tokens, credentials, hostnames, machine paths, or secrets in any file. Do not commit agent files.

---

## 4) PowerShell Standards (high-signal summary)

- **Naming**
  - Functions: `Verb-Noun` with **approved verbs** only.
  - Public module function names must be discoverable and explicit.
  - Variable naming for this repository: **lowerCamelCase** for local variables; **PascalCase** for parameters and exported function names.
  - Singular nouns preferred unless the command operates on collections by design.

- **Analyzer posture**
  - Treat all **PowerShell Script Analyzer** warnings as errors unless narrowly justified.
  - Required rule families include: approved verbs, use of ShouldProcess for state-changing functions, avoidance of aliases, help completeness, unused or shadowed parameters, indentation and whitespace consistency, and compatibility checks.
  - Any suppression must appear in `docs/reference/psscriptanalyzer_ruleset.md` with rationale.

- **Help**
  - All **exported functions** must have valid comment-based help (synopsis, description, parameters with types and help, examples, notes, and links) or be included in generated external help.
  - Examples must run or be obviously correct.

- **Modules and lifecycle**
  - Discover, install, and update modules using the current, supported package management for PowerShell.
  - Pin minimum versions in documentation and update the Command Appendix when modules change.

- **Official documentation links**
  - Link format in the Command Appendix should follow the standard Microsoft documentation pattern for PowerShell module pages.
  - One command-let → one official documentation link.

---

## 5) Stage-Gated Work Model (Waves)

**Stop after every wave for review and approval**. If a wave would exceed the caps below, split it into sub-waves.

- **Wave 0 — Environment and Documentation Bootstrap (lightweight)**
  Create or refresh this file and the four standards files in Section 2 if needed.
  Artifact tracking: record outcomes in `CHANGELOG.md` and backlog items in `todo.md`.

- **Wave 1 — Inventory and Mapping**
  Enumerate scripts, modules, exported functions. Draft `docs/command_appendix.csv`.
  Artifact tracking: record outcomes in `CHANGELOG.md` and backlog items in `todo.md`.

- **Wave 2 — Command-let Reality Fixes**
  Replace non-existent, deprecated, or misspelled command-lets. Update official documentation links.
  Artifact tracking: record outcomes in `CHANGELOG.md` and backlog items in `todo.md`.

- **Wave 3 — Static Analysis Remediation**
  Run PowerShell Script Analyzer; treat warnings as errors. Fix findings including approved verbs, ShouldProcess usage, help, and compatibility.
  Artifact tracking: record outcomes in `CHANGELOG.md` and backlog items in `todo.md`.

- **Wave 4 — Naming and Variables**
  Enforce Verb-Noun with approved verbs. Normalize variable naming to repository standard. Provide a migration note for any exported rename.
  Artifact tracking: record outcomes in `CHANGELOG.md` and backlog items in `todo.md`.

- **Wave 5 — Help Authoring**
  Ensure comment-based help for all exported functions or generate as external help; refresh module help outputs.
  Artifact tracking: record outcomes in `CHANGELOG.md` and backlog items in `todo.md`.

- **Wave 6 — Documentation Refresh**
  Update `README.md` and `CHANGELOG.md`. Finalize `docs/command_appendix.csv`.
  Artifact tracking: record outcomes in `CHANGELOG.md` and backlog items in `todo.md`.

- **Wave 7 — Final Assembly**
  Curate commits and open a clean pull request with a one-page summary recorded in `CHANGELOG.md` and any follow-ups in `todo.md`.

**Caps per wave:** at most **25 files** or **600 changed lines**.

---

## 6) Branch, Commit, and Pull Request Conventions

- **Branch naming**  
  `type/topic-wave-N-short-slug`  
  Examples:  
  - `fix/pwsh-wave-3-analyzer`  
  - `refactor/pwsh-wave-4-naming-and-variables`  
  - `docs/pwsh-wave-6-readme-changelog`

- **Commit messages (Conventional Commits)**  
  `type(scope)!: short imperative summary`  
  Body explains **what** and **why**, references the wave, and lists notable files.  
  Use `BREAKING CHANGE:` footer when applicable.

- **Pull request template (include in description)**
  - **Scope** — what this wave covers
  - **Changes** — concise bullets of notable diffs
  - **Checks** — analyzer status, command appendix links validated, help present, documentation updated
  - **Risks and trade-offs** — deprecations, renames, compatibility notes
  - **Follow-ups** — items queued for next wave
  - **Artifacts** — link to relevant `CHANGELOG.md` sections and `todo.md` entries

- **Merge policy**  
  Use **Squash and merge** per wave unless preserving history is explicitly required.

---

## 7) Acceptance Criteria (repository level)

- Analyzer is clean or has narrowly justified suppressions recorded in `psscriptanalyzer_ruleset.md`.
- All commands exist and match Microsoft official documentation. Every command-let is linked correctly in the Command Appendix.
- Naming conforms (Verb-Noun with approved verbs). Variable naming is consistent to repository standard.
- Exported functions include valid help.
- `README.md`, `CHANGELOG.md`, standards files, and the Command Appendix are current and coherent.
- Each wave has a corresponding note in `CHANGELOG.md`, with open follow-ups tracked in `todo.md`.

---

## 8) Do-Not-Commit Reminder

Do **not** commit any agent-specific file (for example, `gemini.md`, `codex.md`, `cline_rules.md`, `copilot-instructions.md`) or any secrets, tokens, hostnames, or machine paths.

