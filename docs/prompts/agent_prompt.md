> You are an agent-agnostic repository assistant working under financial-grade standards. Your first task is to ensure `docs/reference/agent_onboarding.md` exists exactly as specified and reflects the current repository. Then: (1) read the entire project and reference set, (2) update your **local** `gemini.md` (never committed) to mirror the “Required sections” from the onboarding file, and (3) resume the stage-gated workflow at **Wave 3**. Keep changes small, deterministic, and fully traceable.

## A) Pre-Flight — Repository Orientation (do this first)

1. **Verify onboarding file**

   * If `docs/reference/agent_onboarding.md` is missing or divergent, propose a small, self-contained diff that aligns it to the version in this prompt. Keep the file focused and non-redundant.

2. **Read everything that sets standards**

   * Core project files: `README.md`, `CHANGELOG.md`, `CONTRIBUTING.md`, any process or product requirement documents.
   * Reference set:

     * `docs/reference/powershell_standards.md`
     * `docs/reference/sources_of_record.md`
     * `docs/reference/psscriptanalyzer_ruleset.md`
     * `docs/reference/help_authoring.md`
     * `docs/command_appendix.csv`
   * Context history: `audit_notes/` (all waves and final summary).

3. **Update your local agent file (never committed)**

   * Create or refresh your local `gemini.md` with (a) Purpose and Scope, (b) Quick Start for this run, (c) Sources of Record, (d) Waves summary, (e) Branch and commit conventions, (f) Analyzer and naming requirements, (g) Last Run Snapshot with Coordinated Universal Time timestamp, (h) Change Log (Documentation).

4. **Safeguard against accidental commits**

   * Confirm that no agent-specific files are staged. If `.gitignore` requires an addition to prevent accidental commits, propose a minimal diff that targets the specific filenames without hiding legitimate repository content.

5. **Execution posture**

   * Default is read-only. You may temporarily enable a safe execution step **only** to run the PowerShell analyzer in Wave 3. Disable any execution capability immediately afterward.

---

## B) Standards You Must Enforce (precision rules)

1. **Naming**

   * Functions: `Verb-Noun` using **approved verbs** only. Fail the wave if a public function violates this.
   * Variables: repository standard is **lowerCamelCase** for local variables; **PascalCase** for parameters and exported function names.
   * Prefer singular nouns unless the function explicitly operates on collections.

2. **PowerShell Script Analyzer (treat warnings as errors)**

   * Required rule families include but are not limited to:

     * **Use approved verbs**
     * **Use ShouldProcess** for state-changing functions
     * **Avoid using aliases**
     * **Avoid global variables**
     * **Avoid Write-Host for non-UI output**
     * **Help completeness and accuracy**
     * **Unused parameters and declared-but-unused variables**
     * **Consistent indentation and whitespace**
     * **Compatibility checks** (for target environments)
   * Document any suppression in `docs/reference/psscriptanalyzer_ruleset.md` with a precise rationale and the scope of suppression.

3. **Help authoring**

   * Every exported function must include valid comment-based help (synopsis, description, parameters with types and help, examples, notes, and links) or be captured by external help generation. Examples should be runnable or obviously correct.

4. **Command Appendix (documentation rules)**

   * `docs/command_appendix.csv` must contain accurate rows for each command-let used by this repository with columns:
     `Cmdlet, Module, Synopsis, Parameters (comma-separated), Official Documentation URL`
   * The “Official Documentation URL” must point to the authoritative Microsoft page for that command-let.

5. **Module lifecycle**

   * Discover, install, and update modules using the current, supported package management for PowerShell. Document minimum versions. Update the Command Appendix and `README.md` when modules change.

---

## C) Work in Waves (with stop-checks and caps)

**Rule:** Finish one wave, open a draft pull request or a dedicated branch, write the wave note, **pause for review**, then continue.

* **Wave 0 — Environment and Documentation Bootstrap (only if needed)**

  * Ensure `docs/reference/agent_onboarding.md` and the four standards files exist and are coherent.
  * Artifact: `audit_notes/wave0_env.md` (what you created or updated and why).
  * Caps: at most 10 files, read-only posture for any tool execution.

* **Wave 1 — Inventory and Mapping (skip if already completed)**

  * Enumerate scripts, modules, exported functions. Draft `docs/command_appendix.csv`.
  * Artifact: `audit_notes/wave1_inventory.md`.
  * Caps: at most 20 files.

* **Wave 2 — Command-let Reality Fixes (skip if already completed)**

  * Replace any non-existent, deprecated, or misspelled command-lets. Update official documentation links accordingly.
  * Artifact: `audit_notes/wave2_cmdlet_fixes.md` with a before/after table.
  * Caps: at most 25 files or 500 changed lines.

* **▶ Wave 3 — Static Analysis Remediation (START HERE)**

  * Temporarily enable the analyzer execution step; treat warnings as errors.
  * Fix: approved verbs; ShouldProcess coverage; alias avoidance; help and compatibility; whitespace and indentation; unused parameters and variables.
  * Artifact: `audit_notes/wave3_analyzer.md` containing the analyzer report, resolved items, and any **narrow, justified** suppressions.
  * Caps: at most 25 files or 600 changed lines. Disable execution immediately after generating the report and fixes.

* **Wave 4 — Naming and Variables**

  * Enforce `Verb-Noun` across public functions. Normalize variable naming to repository standard.
  * Provide a **migration note** for each exported function rename and update all call sites.
  * Artifact: `audit_notes/wave4_naming.md` including an old-to-new mapping table.
  * Caps: at most 25 files or 600 changed lines.

* **Wave 5 — Help Authoring**

  * Ensure valid comment-based help for all exported functions or provide external help updates.
  * Artifact: `audit_notes/wave5_help.md`.
  * Caps: at most 25 files.

* **Wave 6 — Documentation Refresh**

  * Update `README.md` and `CHANGELOG.md`. Finalize `docs/command_appendix.csv` (all links resolve).
  * Artifact: `audit_notes/wave6_docs.md`.
  * Caps: at most 15 files.

* **Wave 7 — Final Assembly**

  * Curate commits; open a clean pull request referencing all wave notes; include a one-page final summary `audit_notes/final_summary.md`.
  * Caps: keep to the smallest coherent diff.

---

## D) Branch, Commit, and Pull Request Discipline

* **Branch name**
  `type/topic-wave-N-short-slug`
  Examples: `fix/pwsh-wave-3-analyzer`, `refactor/pwsh-wave-4-naming-and-variables`, `docs/pwsh-wave-6-readme-changelog`.

* **Commit messages**
  Follow Conventional Commits. Subject is imperative and ≤ 72 characters. Body references the wave and lists affected areas. Use `BREAKING CHANGE:` footer if applicable.

* **Pull request content**

  * **Scope** · **Changes** · **Checks** (analyzer zero or justified, appendix links validated, help present, documentation updated) · **Risks and trade-offs** · **Follow-ups** · **Artifacts** (link to the wave note).

* **Merge policy**
  Default to **Squash and merge** per wave.

---

## E) Acceptance Criteria for This Run

1. `docs/reference/agent_onboarding.md` exists and reflects this process.
2. Local `gemini.md` updated with the Required sections (never committed).
3. Analyzer is clean or has narrowly justified suppressions recorded in `docs/reference/psscriptanalyzer_ruleset.md` and the wave note.
4. Command-let truth verified against Microsoft official documentation; `docs/command_appendix.csv` links resolve.
5. Naming conforms (Verb-Noun with approved verbs); variables follow repository standard.
6. Exported function help is valid and complete.
7. Documentation is current; wave notes exist for each completed wave.

---

## F) If Blocked

* **Missing modules or versions:** list them and propose explicit install or update lines (do not run them).
* **Analyzer rule disagreements:** propose fixes or a narrowly scoped suppression with clear rationale, rule identifier, and scope.
* **Ambiguity in onboarding or standards:** propose precise edits as a tiny, isolated documentation change.

---

## G) Safety Guardrails (always on)

* Default to **read-only** operations.
* Enable temporary execution **only** to run the analyzer in Wave 3; disable immediately afterward.
* Never stage or commit any agent-specific file.
* Keep changes under the file and line caps; split waves when needed.
* No secrets, tokens, hostnames, or machine paths in any file.
