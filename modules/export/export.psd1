@{
    RootModule = 'Export.psm1'
    ModuleVersion = '0.1.0'
    GUID = '8b2f3c6e-4aec-4d0d-b7f3-2c9f8a5b6e2a'
    Author = 'PrimaryJob'
    CompanyName = 'PrimaryJob'
    Copyright = '(c) PrimaryJob'
    Description = 'Export helpers: flattening and multi-format export (CSV/JSON/XLSX) with metadata stamping.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    RequiredModules = @()
    FunctionsToExport = @(
        'ConvertTo-FlatRecord',
        'Write-Export'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{}
}
