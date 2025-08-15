@{
    RootModule = 'Logging.psm1'
    ModuleVersion = '0.1.0'
    GUID = 'd9b6d1f7-6bfb-4e8d-9a3a-9c2a2b1b7d3e'
    Author = 'PrimaryJob'
    CompanyName = 'PrimaryJob'
    Copyright = '(c) PrimaryJob'
    Description = 'Logging helpers: redaction, structured logging, and retry helper.'
    PowerShellVersion = '7.4'
    CompatiblePSEditions = @('Core')
    RequiredModules = @()
    FunctionsToExport = @(
        'New-LogContext',
        'Set-LogRedactionPatterns',
        'Write-Log',
        'Get-CorrelationId',
        'Invoke-WithRetry'
    )
    CmdletsToExport = @()
    VariablesToExport = @()
    AliasesToExport = @()
    PrivateData = @{}
}
