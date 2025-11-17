#requires -Version 7.4

function Script:Get-RepoRoot {
    param()

    return (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
}

function Script:Get-ModuleManifestPath {
    param()

    $repoRoot = Get-RepoRoot
    return Join-Path -Path $repoRoot -ChildPath 'modules/entra_connection/entra_connection.psm1'
}

function Script:Get-PrereqScriptPath {
    param()

    $repoRoot = Get-RepoRoot
    return Join-Path -Path $repoRoot -ChildPath 'scripts/ensure-prereqs.ps1'
}

Describe 'entra_connection module' -Tag 'entra_connection' {
    It 'imports without error' {
        if (Get-Module -Name entra_connection) {
            Remove-Module -Name entra_connection -Force
        }

        $manifestPath = Get-ModuleManifestPath
        { Import-Module -Name $manifestPath -Force -ErrorAction Stop } | Should -Not -Throw
    }

    Context 'Connect-GraphContext' {
        BeforeEach {
            $manifestPath = Get-ModuleManifestPath
            Import-Module -Name $manifestPath -Force -ErrorAction Stop | Out-Null
        }

        It 'throws a helpful error when the Graph secret is missing' {
            $tenantId = [Guid]::NewGuid().ToString()

            Mock -CommandName Get-Secret -ModuleName entra_connection { return $null }

            Should -Throw -ActualValue { Connect-GraphContext -TenantId $tenantId -AuthMode ServicePrincipal -ClientId '00000000-0000-0000-0000-000000000000' -VaultName 'TestVault' -SecretName 'GraphSecret' } -ExpectedMessage "Failed to retrieve secret 'GraphSecret' from vault 'TestVault'."
        }
    }

    Context 'Connect-EntraTenant' {
        BeforeEach {
            $manifestPath = Get-ModuleManifestPath
            Import-Module -Name $manifestPath -Force -ErrorAction Stop | Out-Null
        }

        It 'returns a structured error when Graph service principal details are missing' {
            $tenantId = [Guid]::NewGuid().ToString()

            Mock -CommandName Select-Tenant -ModuleName entra_connection {
                param([string]$TenantId, [string]$Label)
                return [pscustomobject]@{ tenant_id = if ($TenantId) { $TenantId } else { [Guid]::NewGuid().ToString() }; label = $Label }
            }
            Mock -CommandName Get-ActiveContext -ModuleName entra_connection { [pscustomobject]@{ Graph = 'Not connected'; Azure = 'Not connected' } }

            Should -Not -Throw -ActualValue { $script:result = Connect-EntraTenant -TenantId $tenantId -GraphAuthMode ServicePrincipal -SkipAzure }
            $result = $script:result
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain 'Graph service principal authentication requires -GraphClientId, -GraphVaultName, and -GraphSecretName.'
        }

        It 'captures Graph connection failures without throwing' {
            $tenantId = [Guid]::NewGuid().ToString()

            Mock -CommandName Select-Tenant -ModuleName entra_connection {
                param([string]$TenantId, [string]$Label)
                return [pscustomobject]@{ tenant_id = if ($TenantId) { $TenantId } else { [Guid]::NewGuid().ToString() }; label = $Label }
            }

            Mock -CommandName Connect-GraphContext -ModuleName entra_connection {
                throw (New-Object System.Exception 'Graph connection failed')
            }
            Mock -CommandName Get-ActiveContext -ModuleName entra_connection { [pscustomobject]@{ Graph = 'Not connected'; Azure = 'Not connected' } }

            Should -Not -Throw -ActualValue { $script:result = Connect-EntraTenant -TenantId $tenantId -GraphAuthMode DeviceCode -SkipAzure }
            $result = $script:result
            $result.Success | Should -BeFalse
            $result.Errors | Should -Contain 'Graph connection failed'
            $result.ErrorRecords.Count | Should -Be 1
        }

        It 'succeeds when both contexts connect and returns diagnostics' {
            $tenantId = [Guid]::NewGuid().ToString()

            Mock -CommandName Select-Tenant -ModuleName entra_connection {
                param([string]$TenantId, [string]$Label)
                return [pscustomobject]@{ tenant_id = if ($TenantId) { $TenantId } else { [Guid]::NewGuid().ToString() }; label = $Label }
            }

            Mock -CommandName Connect-GraphContext -ModuleName entra_connection { }
            Mock -CommandName Connect-AzureContext -ModuleName entra_connection { }
            Mock -CommandName Get-ActiveContext -ModuleName entra_connection {
                return [pscustomobject]@{ Graph = 'Connected'; Azure = 'Connected' }
            }

            Should -Not -Throw -ActualValue { $script:result = Connect-EntraTenant -TenantId $tenantId -GraphAuthMode DeviceCode -AzureAuthMode DeviceCode }
            $result = $script:result
            $result.Success | Should -BeTrue
            $result.GraphConnected | Should -BeTrue
            $result.AzureConnected | Should -BeTrue
            $result.Context.Graph | Should -Be 'Connected'
            Assert-MockCalled -CommandName Connect-GraphContext -ModuleName entra_connection -Times 1
            Assert-MockCalled -CommandName Connect-AzureContext -ModuleName entra_connection -Times 1
        }
    }

    Context 'Smoke validation' {
        BeforeAll {
            $manifestPath = Get-ModuleManifestPath
            Import-Module -Name $manifestPath -Force -ErrorAction Stop | Out-Null
        }

        It 'runs ensure-prereqs (WhatIf) and connects via device code without calling live services' {
            $prereqPath = Get-PrereqScriptPath
            Mock -CommandName Invoke-ScriptAnalyzer { @() }
            Mock -CommandName Get-ChildItem { @() }
            Mock -CommandName Get-Module -ParameterFilter { param($Name, $ListAvailable) $Name -eq 'Microsoft.PowerShell.PSResourceGet' -and $ListAvailable } {
                [pscustomobject]@{ Name = 'Microsoft.PowerShell.PSResourceGet'; Version = [Version]'1.0.7' }
            }
            Mock -CommandName Import-Module -ParameterFilter { param($Name) $Name -eq 'Microsoft.PowerShell.PSResourceGet' } { }
            Should -Not -Throw -ActualValue { & $prereqPath -Quiet -WhatIf }

            $tenantId = [Guid]::NewGuid().ToString()

            Mock -CommandName Connect-MgGraph -ModuleName entra_connection {}

            Should -Not -Throw -ActualValue { Connect-GraphContext -TenantId $tenantId -AuthMode DeviceCode }

            Assert-MockCalled -CommandName Connect-MgGraph -ModuleName entra_connection -Times 1
        }
    }
}
