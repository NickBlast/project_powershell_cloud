#requires -Version 7.4

Describe 'entra_connection test helpers' {
    BeforeAll {
        $script:scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
        $script:repoRoot = (Resolve-Path -Path (Join-Path -Path $scriptRoot -ChildPath '..')).Path
        $script:moduleManifest = Join-Path -Path $repoRoot -ChildPath 'modules/entra_connection/entra_connection.psd1'
    }

    It 'imports without error' {
        { Import-Module -Name $script:moduleManifest -Force } | Should -Not -Throw
    }

    It 'surfaces required ENTRA_TEST_* environment variables' {
        Import-Module -Name $script:moduleManifest -Force | Out-Null
        { Get-EntraTestConfig } | Should -Not -Throw
    }
}
