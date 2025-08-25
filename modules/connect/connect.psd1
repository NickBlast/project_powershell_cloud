@{
    RootModule = 'Connect.psm1'
    ModuleVersion = '0.1.0'
    GUID = '4a1e2b3c-9d8f-45a6-8b7c-2e3f4a5b6c7d'
    Author = 'PrimaryJob'
    CompanyName = 'PrimaryJob'
    Copyright = '(c) PrimaryJob'
    Description = 'Connection helpers for Microsoft Graph and Azure (tenant selection, auth wrappers).'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    RequiredModules = @()
    FunctionsToExport = @(
        'Get-TenantCatalog',
        'Select-Tenant',
        'Connect-GraphContext',
        'Connect-AzureContext',
        'Get-ActiveContext'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{}
}
