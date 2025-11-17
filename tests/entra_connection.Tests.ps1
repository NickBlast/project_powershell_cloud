#requires -Version 7.4

$repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$moduleManifest = Join-Path -Path $repoRoot -ChildPath 'modules/entra_connection/entra_connection.psd1'

Describe 'entra_connection module' -Tag 'entra_connection' {
    It 'imports without error' {
        { Import-Module -Name $moduleManifest -Force } | Should -Not -Throw
    }

    It 'requires ENTRA_TEST_* environment variables' {
        $originalTenant = $env:ENTRA_TEST_TENANT_ID
        $env:ENTRA_TEST_TENANT_ID = $null
        Import-Module -Name $moduleManifest -Force | Out-Null
        { Get-EntraTestContext } | Should -Throw
        $env:ENTRA_TEST_TENANT_ID = $originalTenant
    }

    Context 'Get-EntraTestContext' {
        BeforeAll {
            Import-Module -Name $moduleManifest -Force | Out-Null
        }

        It 'returns a context object when env vars exist' {
            if (-not $env:ENTRA_TEST_TENANT_ID -or -not $env:ENTRA_TEST_CLIENT_ID -or -not $env:ENTRA_TEST_SECRET_VALUE) {
                Set-ItResult -Inconclusive -Because 'ENTRA_TEST_* environment variables are not set in this environment.'
            }
            else {
                $context = Get-EntraTestContext -SkipValidation
                $context.TenantId | Should -Be $env:ENTRA_TEST_TENANT_ID
                $context.ClientId | Should -Be $env:ENTRA_TEST_CLIENT_ID
            }
        }
    }
}
