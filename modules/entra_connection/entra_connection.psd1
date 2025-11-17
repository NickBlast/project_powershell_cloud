@{
    RootModule = 'entra_connection.psm1'
    ModuleVersion = '0.3.0'
    GUID = '4a1e2b3c-9d8f-45a6-8b7c-2e3f4a5b6c7d'
    Author = 'project_powershell_cloud'
    CompanyName = 'project_powershell_cloud'
    Copyright = '(c) project_powershell_cloud'
    Description = 'Microsoft Entra test tenant connection helpers for Graph and Azure Resource Manager.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    RequiredModules = @(
        'Az.Accounts',
        'Az.Resources',
        'Microsoft.Graph'
    )
    FunctionsToExport = @(
        'Get-EntraTestConfig',
        'Connect-EntraTestTenant',
        'Get-EntraTestContext',
        'Get-ActiveContext'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{}
}
