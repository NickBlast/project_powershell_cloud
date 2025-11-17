<#!
.SYNOPSIS
    Smoke tests for the entra_connection module.
.DESCRIPTION
    Verifies the module manifest loads in PowerShell 7.4+ and confirms that required ENTRA_TEST_* config
    accessors are exposed without throwing. Provides quick feedback that the test tenant configuration
    is discoverable before heavier integration tests run.
#>
#requires -Version 7.4

Describe 'entra_connection test helpers' {
    BeforeAll {
        # Resolve paths to the repo root and module manifest regardless of where the tests are invoked.
        $script:scriptRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Path $MyInvocation.MyCommand.Path -Parent }
        $script:repoRoot = (Resolve-Path -Path (Join-Path -Path $scriptRoot -ChildPath '..')).Path
        $script:moduleManifest = Join-Path -Path $repoRoot -ChildPath 'modules/entra_connection/entra_connection.psd1'
    }

    It 'imports without error' {
        # Basic import ensures the manifest and module dependencies are present.
        { Import-Module -Name $script:moduleManifest -Force } | Should -Not -Throw
    }

    It 'surfaces required ENTRA_TEST_* environment variables' {
        # Get-EntraTestConfig should read the ENTRA_TEST_* settings without failing.
        Import-Module -Name $script:moduleManifest -Force | Out-Null
        { Get-EntraTestConfig } | Should -Not -Throw
    }
}
