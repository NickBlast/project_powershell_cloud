#
# PowerShell Connection Module for Azure and Microsoft Graph
#

#region Public Functions

<#
.SYNOPSIS
    Reads the tenant catalog from the .config/tenants.json file.
.DESCRIPTION
    Loads the list of tenant configurations. This file is expected to be non-secret and contains
    metadata for connecting to different tenants.
.EXAMPLE
    PS> $tenants = Get-TenantCatalog
    PS> $tenants | Format-Table
.NOTES
    The tenant catalog is expected at ./.config/tenants.json. This function returns an empty array
    if the file is missing or invalid.
#>
function Get-TenantCatalog {
    [CmdletBinding()]
    [OutputType([object[]])]
    param()

    $configDir = Join-Path -Path $PSScriptRoot -ChildPath '..'
    $configDir = Join-Path -Path $configDir -ChildPath '..'
    $configDir = Join-Path -Path $configDir -ChildPath '.config'
    $configPath = Join-Path -Path $configDir -ChildPath 'tenants.json'
    $configPath = Resolve-Path -Path $configPath -ErrorAction SilentlyContinue

    if (-not (Test-Path -Path $configPath)) {
        Write-Warning "Tenant catalog file not found at: $configPath"
        return @()
    }

    try {
        return Get-Content -Path $configPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to read or parse tenant catalog '$configPath'. Error: $_"
        return @()
    }
}

<#
.SYNOPSIS
    Selects a single tenant from the catalog based on ID or label.
.DESCRIPTION
    Filters the tenant list to find a specific tenant. If no filter is provided, it returns the tenant
    only if there is exactly one defined in the catalog. It errors with guidance in ambiguous situations.
.PARAMETER TenantId
    The GUID of the tenant to select.
.PARAMETER Label
    The friendly name (label) of the tenant to select.
.EXAMPLE
    PS> $tenant = Select-Tenant -Label 'production'
.EXAMPLE
    PS> # Selects the default tenant if only one exists
    PS> $tenant = Select-Tenant
.OUTPUTS
    [psobject]
.NOTES
    This helper is a thin selector and will throw if the catalog is missing or ambiguous. Use Get-TenantCatalog
    to inspect the available entries.
#>
function Select-Tenant {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$TenantId,
        [Parameter(Mandatory = $false)]
        [string]$Label
    )

    $tenants = Get-TenantCatalog
    if ($tenants.Count -eq 0) {
        throw "Tenant catalog is empty or not found. Please configure ./.config/tenants.json"
    }

    if ($TenantId) {
        $selected = $tenants | Where-Object { $_.tenant_id -eq $TenantId }
    } elseif ($Label) {
        $selected = $tenants | Where-Object { $_.label -eq $Label }
    } elseif ($tenants.Count -eq 1) {
        $selected = $tenants[0]
    } else {
        throw "Multiple tenants exist. Please specify which to connect to using -TenantId or -Label."
    }

    if ($selected.Count -eq 0) {
        throw "No tenant found matching the specified criteria."
    }
    if ($selected.Count -gt 1) {
        throw "Multiple tenants found matching the specified criteria. Please be more specific."
    }

    return $selected
}

<#
.SYNOPSIS
    Connects to Microsoft Graph with a specific context.
.DESCRIPTION
    Handles authentication to Microsoft Graph using either an interactive device code flow or a non-interactive
    service principal flow. For service principals, credentials should be stored in a SecretManagement vault.
.PARAMETER TenantId
    The ID of the tenant to connect to.
.PARAMETER AuthMode
    The authentication method to use. (DeviceCode, ServicePrincipal)
.PARAMETER ClientId
    The Application (client) ID for the service principal. Required for ServicePrincipal auth.
.PARAMETER VaultName
    The name of the SecretManagement vault where the client secret is stored.
.PARAMETER SecretName
    The name of the secret in the vault.
.EXAMPLE
    PS> Connect-GraphContext -TenantId $tenant.tenant_id -AuthMode DeviceCode
.EXAMPLE
    PS> Connect-GraphContext -TenantId $tenant.tenant_id -AuthMode ServicePrincipal -ClientId $appId -VaultName 'MyVault' -SecretName 'GraphSecret'
.OUTPUTS
    None
.NOTES
    This function will call Connect-MgGraph. For ServicePrincipal auth, secrets are retrieved via SecretManagement;
    ensure your vault and permissions are configured. The function does not persist secrets to disk.
#>
function Connect-GraphContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        [Parameter(Mandatory = $true)]
        [ValidateSet('DeviceCode', 'ServicePrincipal')]
        [string]$AuthMode,
        [Parameter(Mandatory = $false)]
        [string]$ClientId,
        [Parameter(Mandatory = $false)]
        [string]$VaultName,
        [Parameter(Mandatory = $false)]
        [string]$SecretName
    )

    # Define core read-only scopes
    $scopes = @(
        'Directory.Read.All',
        'Group.Read.All',
        'Application.Read.All',
        'Policy.Read.All',
        'RoleManagement.Read.Directory'
    )

    switch ($AuthMode) {
        'DeviceCode' {
            Connect-MgGraph -TenantId $TenantId -Scopes $scopes
        }
        'ServicePrincipal' {
            if (-not ($ClientId -and $VaultName -and $SecretName)) {
                throw "For ServicePrincipal auth, -ClientId, -VaultName, and -SecretName are required."
            }
            $clientSecret = Get-Secret -Vault $VaultName -Name $SecretName -AsPlainText
            if (-not $clientSecret) {
                throw "Failed to retrieve secret '$SecretName' from vault '$VaultName'."
            }
            Connect-MgGraph -TenantId $TenantId -ClientId $ClientId -ClientSecret $clientSecret
        }
    }
}

<#
.SYNOPSIS
    Connects to Azure (ARM) with a specific context.
.DESCRIPTION
    Handles authentication to Azure Resource Manager using either device code or service principal flow.
.PARAMETER TenantId
    The ID of the tenant to connect to.
.PARAMETER AuthMode
    The authentication method to use. (DeviceCode, ServicePrincipal)
.PARAMETER ClientId
    The Application (client) ID for the service principal. Required for ServicePrincipal auth.
.PARAMETER VaultName
    The name of the SecretManagement vault where the client secret is stored.
.PARAMETER SecretName
    The name of the secret in the vault.
.EXAMPLE
    PS> Connect-AzureContext -TenantId $tenant.tenant_id -AuthMode DeviceCode
.OUTPUTS
    None
.NOTES
    For ServicePrincipal authentication the function will retrieve secrets using SecretManagement and create
    a PSCredential; ensure the vault returns a SecureString secret.
#>
function Connect-AzureContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TenantId,
        [Parameter(Mandatory = $true)]
        [ValidateSet('DeviceCode', 'ServicePrincipal')]
        [string]$AuthMode,
        [Parameter(Mandatory = $false)]
        [string]$ClientId,
        [Parameter(Mandatory = $false)]
        [string]$VaultName,
        [Parameter(Mandatory = $false)]
        [string]$SecretName
    )

    switch ($AuthMode) {
        'DeviceCode' {
            Connect-AzAccount -Tenant $TenantId -UseDeviceAuthentication
        }
        'ServicePrincipal' {
            if (-not ($ClientId -and $VaultName -and $SecretName)) {
                throw "For ServicePrincipal auth, -ClientId, -VaultName, and -SecretName are required."
            }
            $clientSecret = Get-Secret -Vault $VaultName -Name $SecretName
            $credential = New-Object System.Management.Automation.PSCredential($ClientId, $clientSecret)
            Connect-AzAccount -Tenant $TenantId -ServicePrincipal -Credential $credential | Out-Null
        }
    }
}

<#
.SYNOPSIS
    Gets a summary of the current Azure and Microsoft Graph connection contexts.
.DESCRIPTION
    Provides a sanitized, non-secret object describing the active tenants, accounts, and scopes
    for both Az and MgGraph connections. Useful for diagnostics.
.EXAMPLE
    PS> Get-ActiveContext | Format-List
.OUTPUTS
    [pscustomobject]
.NOTES
    This function returns lightweight, non-secret summaries suitable for logging or diagnostics.
#>
function Get-ActiveContext {
    [CmdletBinding()]
    param()

    $contexts = [PSCustomObject]@{
        Graph = $null
        Azure = $null
    }

    try {
        $graphContext = Get-MgContext -ErrorAction Stop
        $contexts.Graph = $graphContext | Select-Object TenantId, Account, Scopes, ClientId
    } catch {
        $contexts.Graph = 'Not connected'
    }

    try {
        $azContext = Get-AzContext -ErrorAction Stop
        $contexts.Azure = $azContext.Tenant | Select-Object Id, Domain
        $contexts.Azure | Add-Member -MemberType NoteProperty -Name Account -Value $azContext.Account.Id
    } catch {
        $contexts.Azure = 'Not connected'
    }

    return $contexts
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'Get-TenantCatalog',
    'Select-Tenant',
    'Connect-GraphContext',
    'Connect-AzureContext',
    'Get-ActiveContext'
)

#endregion
