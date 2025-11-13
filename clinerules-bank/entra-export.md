# Entra Export Overlay

Use for Microsoft Graph directory roles, groups, apps.

- Import only required Microsoft.Graph submodules (e.g., `Microsoft.Graph.Groups`, `Microsoft.Graph.DirectoryObjects`).
- Prefer `Get-Mg*` cmdlets; add throttling retry logic for 429s.
- Redact UPNs/emails in logs using logging module helpers.
- Ensure `privileged_role` flags, owner lists, and API permissions match schema definitions.
- Validate membership counts vs. Graph portal samples when possible.
