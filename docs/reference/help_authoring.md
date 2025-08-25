# Help Authoring

Goal: Every exported function has discoverable, accurate help via comment-based help or PlatyPS-generated external help.

Comment-Based Help (inline)

Template:

```powershell
function Verb-Noun {
    <#
    .SYNOPSIS
    Short description.

    .DESCRIPTION
    Longer description with important details and caveats.

    .PARAMETER ParameterName
    What this parameter does and expected values.

    .EXAMPLE
    Verb-Noun -Parameter Example
    Demonstrates a typical use.

    .OUTPUTS
    TypeName (or None)

    .NOTES
    Author, links, etc.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]
        [string]$ParameterName
    )
    # implementation
}
```

External Help with PlatyPS

- Install via PSResourceGet (CurrentUser): `Install-PSResource -Name PlatyPS -Scope CurrentUser`.
- Generate stubs: `New-MarkdownHelp -Module <ModuleName> -OutputFolder docs/help/<ModuleName>`
- Update from code changes: `Update-MarkdownHelp -Path docs/help/<ModuleName>`
- Build external help: `New-ExternalHelp -Path docs/help/<ModuleName> -OutputPath modules/<ModuleName>`

Guidance

- Exported functions must have complete help for synopsis, parameters, examples, outputs.
- Keep examples runnable and aligned with current parameter sets.
- Prefer external help for larger modules; keep inline help minimal but correct.

