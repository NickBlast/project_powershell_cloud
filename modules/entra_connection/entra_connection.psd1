@{
    RootModule = 'entra_connection.psm1'
    ModuleVersion = '0.2.0'
    GUID = '4a1e2b3c-9d8f-45a6-8b7c-2e3f4a5b6c7d'
    Author = 'PrimaryJob'
    CompanyName = 'PrimaryJob'
    Copyright = '(c) PrimaryJob'
    Description = 'Microsoft Entra connection helpers for Microsoft Graph and Azure Resource Manager.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    RequiredModules = @(
        'Az.Accounts',
        'Az.Resources',
        'Microsoft.Graph',
        'Microsoft.PowerShell.SecretManagement'
    )
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
