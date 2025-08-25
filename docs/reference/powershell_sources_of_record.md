# PowerShell Sources of Record

Authoritative references used for repository decisions and citations. Prefer Microsoft Learn for cmdlet/module semantics; use official GitHub repos only when Learn defers to them.

- Microsoft Learn — PowerShell: Root docs, language and module browser.
  - https://learn.microsoft.com/powershell/
- Approved Verbs for PowerShell Commands: Canonical verb list for Verb–Noun.
  - https://learn.microsoft.com/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands
- PSScriptAnalyzer: Official static analysis rules and guidance.
  - Overview/rules: https://learn.microsoft.com/powershell/utility-modules/psscriptanalyzer/overview
- Comment-Based Help: Syntax and authoring guidance.
  - https://learn.microsoft.com/powershell/module/microsoft.powershell.core/about/about_Comment_Based_Help
- PlatyPS: External help generation for modules.
  - Learn: https://learn.microsoft.com/powershell/scripting/dev-cross-plat/vscode/using-platyps
  - GitHub: https://github.com/PowerShell/platyPS
- PSResourceGet: Discover/install/update modules, pin versions.
  - https://learn.microsoft.com/powershell/gallery/psresourceget/overview
- Azure PowerShell: Module docs and reference.
  - https://learn.microsoft.com/powershell/azure/
- Microsoft Graph PowerShell: SDK, auth, and module references.
  - https://learn.microsoft.com/powershell/microsoftgraph/

Rules for use

- Validate all cmdlet/module/parameter info against Microsoft Learn pages.
- If Learn defers to a tool’s GitHub repo (e.g., PlatyPS, PSScriptAnalyzer), use that README as secondary.
- Ignore community forums for authoritative semantics.

