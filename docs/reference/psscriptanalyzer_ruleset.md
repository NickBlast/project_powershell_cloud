# PSScriptAnalyzer Ruleset (Documented)

Policy

- Run PSScriptAnalyzer across `modules/` and `scripts/` with warnings treated as errors.
- Prefer fixing issues over suppressing; any suppression must be justified and documented here.

How to Run (locally)

- Requires PowerShell 7.4+ and PSScriptAnalyzer installed for CurrentUser.
- Example install: `Install-PSResource -Name PSScriptAnalyzer -Scope CurrentUser -MinimumVersion 1.21.0 -Repository PSGallery`
- Example run: `Invoke-ScriptAnalyzer -Path . -Recurse`

Recommended Baseline Rules (non-exhaustive)

- PSUseApprovedVerbs
- PSProvideCommentHelp (or external help via PlatyPS)
- PSAvoidUsingCmdletAliases
- PSAvoidUsingPositionalParameters (in exported functions and scripts)
- PSUseSingularNouns (use judgment; prefer approved noun forms)
- PSUseConsistentIndentation
- PSUseConsistentWhitespace
- PSUseDeclaredVarsMoreThanAssignments
- PSAvoidUsingWriteHost
- PSUseCompatibleSyntax (target: PowerShell 7.4)

Suggested Settings File (example)

```powershell
@{
  IncludeRules = @(
    'PSUseApprovedVerbs',
    'PSProvideCommentHelp',
    'PSAvoidUsingCmdletAliases',
    'PSAvoidUsingPositionalParameters',
    'PSUseSingularNouns',
    'PSUseConsistentIndentation',
    'PSUseConsistentWhitespace',
    'PSUseDeclaredVarsMoreThanAssignments',
    'PSAvoidUsingWriteHost',
    'PSUseCompatibleSyntax'
  )
  Settings = @{
    Severity = 'Error'
  }
}
```

Suppressions (placeholder)

- None yet. If added, include: rule name, file/function, justification, and a link to Microsoft Learn or internal policy supporting the exception.
