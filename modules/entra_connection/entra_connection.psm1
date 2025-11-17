# Microsoft Entra / Azure connection helpers for the test tenant

$ErrorActionPreference = 'Stop'

function Get-EntraTestConfig {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $envMapping = @{
        TenantId       = 'ENTRA_TEST_TENANT_ID'
        ClientId       = 'ENTRA_TEST_CLIENT_ID'
        SubscriptionId = 'ENTRA_TEST_SUBSCRIPTION_ID'
        ClientSecret   = 'ENTRA_TEST_SECRET_VALUE'
    }

    $config = @{}
    foreach ($key in $envMapping.Keys) {
        $value = [Environment]::GetEnvironmentVariable($envMapping[$key])
        if (-not $value) {
            throw "Missing required environment variable: $($envMapping[$key])"
        }
        $config[$key] = $value
    }

    return $config
}

function Connect-EntraTestTenant {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [switch]$ConnectAzure
    )

    $config = Get-EntraTestConfig

    Write-Verbose "Connecting to Microsoft Graph for tenant $($config.TenantId) with app $($config.ClientId)"
    Connect-MgGraph -TenantId $config.TenantId -ClientId $config.ClientId -ClientSecret $config.ClientSecret -NoWelcome -ContextScope Process | Out-Null

    $azureStatus = $false
    if ($ConnectAzure) {
        Write-Verbose "Connecting to Azure subscription $($config.SubscriptionId)"
        Disable-AzContextAutosave -Scope Process -ErrorAction SilentlyContinue | Out-Null
        $secureSecret = ConvertTo-SecureString -String $config.ClientSecret -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($config.ClientId, $secureSecret)
        Connect-AzAccount -ServicePrincipal -Tenant $config.TenantId -Subscription $config.SubscriptionId -Credential $credential | Out-Null
        $azureStatus = $true
    }

    return Get-EntraTestContext -GraphConnected -AzureConnected:$azureStatus
}

function Get-EntraTestContext {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [switch]$GraphConnected,
        [switch]$AzureConnected
    )

    $config = Get-EntraTestConfig

    return [pscustomobject]@{
        TenantId        = $config.TenantId
        SubscriptionId  = $config.SubscriptionId
        ClientId        = $config.ClientId
        GraphConnected  = [bool]$GraphConnected
        AzureConnected  = [bool]$AzureConnected
    }
}

function Get-ActiveContext {
    [CmdletBinding()]
    param()

    $graphStatus = $null
    $azStatus = $null

    try {
        $graphStatus = Get-MgContext | Select-Object TenantId, Account, ClientId, Scopes
    } catch {
        $graphStatus = 'Not connected'
    }

    try {
        $az = Get-AzContext
        $azStatus = [pscustomobject]@{
            TenantId       = $az.Tenant.Id
            SubscriptionId = $az.Subscription.Id
            Account        = $az.Account.Id
        }
    } catch {
        $azStatus = 'Not connected'
    }

    return [pscustomobject]@{
        Graph = $graphStatus
        Azure = $azStatus
    }
}

Export-ModuleMember -Function @(
    'Get-EntraTestConfig',
    'Connect-EntraTestTenant',
    'Get-EntraTestContext',
    'Get-ActiveContext'
)
