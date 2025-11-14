#requires -Version 7.4

$repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
$moduleManifest = Join-Path -Path $repoRoot -ChildPath 'modules/entra_connection/entra_connection.psd1'
$prereqScript = Join-Path -Path $repoRoot -ChildPath 'scripts/ensure-prereqs.ps1'

Describe 'entra_connection module' -Tag 'entra_connection' {
    BeforeAll {
        $script:moduleManifest = $moduleManifest
        $script:prereqScript = $prereqScript
    }

    It 'imports without error' {
        if (Get-Module -Name entra_connection) {
            Remove-Module -Name entra_connection -Force
        }

        { Import-Module -Name $script:moduleManifest -Force } | Should -Not -Throw
    }

    Context 'Connect-GraphContext' {
        BeforeEach {
            Import-Module -Name $script:moduleManifest -Force | Out-Null
        }

        It 'throws a helpful error when the Graph secret is missing' {
            $tenantId = [Guid]::NewGuid().ToString()

            InModuleScope entra_connection {
                Mock -CommandName Get-Secret -ModuleName entra_connection { return $null }

                { Connect-GraphContext -TenantId $tenantId -AuthMode ServicePrincipal -ClientId '00000000-0000-0000-0000-000000000000' -VaultName 'TestVault' -SecretName 'GraphSecret' } |
                    Should -Throw -ErrorMessage "Failed to retrieve secret 'GraphSecret' from vault 'TestVault'."
            }
        }
    }

    Context 'Smoke validation' {
        BeforeAll {
            Import-Module -Name $moduleManifest -Force | Out-Null
        }

        It 'runs ensure-prereqs (WhatIf) and connects via device code without calling live services' {
            { & $script:prereqScript -Quiet -WhatIf } | Should -Not -Throw

            $tenantId = [Guid]::NewGuid().ToString()

            InModuleScope entra_connection {
                Mock -CommandName Connect-MgGraph -ModuleName entra_connection {}

                { Connect-GraphContext -TenantId $tenantId -AuthMode DeviceCode } | Should -Not -Throw

                Assert-MockCalled -CommandName Connect-MgGraph -ModuleName entra_connection -Times 1
            }
        }
    }
}
