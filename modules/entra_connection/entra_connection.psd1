@{
    RootModule = 'entra_connection.psm1'
    ModuleVersion = '0.3.0'
    GUID = '4a1e2b3c-9d8f-45a6-8b7c-2e3f4a5b6c7d'
    Author = 'PrimaryJob'
    CompanyName = 'PrimaryJob'
    Copyright = '(c) PrimaryJob'
    Description = 'Centralized Microsoft Entra / Azure connection helpers for the test tenant.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    RequiredModules = @(
        'Az.Accounts',
        'Az.Resources',
        'Microsoft.Graph'
    )
    FunctionsToExport = @(
        'Connect-EntraTestTenant',
        'Get-EntraTestContext'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{}
}
