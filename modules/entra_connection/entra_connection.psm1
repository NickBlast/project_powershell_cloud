# Centralized test tenant connection helpers

#region Private Helpers
function Get-EntraTestEnvironment {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $tenantId = $env:ENTRA_TEST_TENANT_ID
    $clientId = $env:ENTRA_TEST_CLIENT_ID
    $subscriptionId = $env:ENTRA_TEST_SUBSCRIPTION_ID
    $clientSecret = $env:ENTRA_TEST_SECRET_VALUE

    $missing = @()
    if (-not $tenantId) { $missing += 'ENTRA_TEST_TENANT_ID' }
    if (-not $clientId) { $missing += 'ENTRA_TEST_CLIENT_ID' }
    if (-not $clientSecret) { $missing += 'ENTRA_TEST_SECRET_VALUE' }

    if ($missing.Count -gt 0) {
        throw "Missing required environment variables: $($missing -join ', ')"
    }

    [pscustomobject]@{
        TenantId       = $tenantId
        ClientId       = $clientId
        SubscriptionId = $subscriptionId
        ClientSecret   = $clientSecret
    }
}
#endregion

#region Public Functions
function Connect-EntraTestTenant {
    [CmdletBinding()]
    param(
        [switch]$SkipAzure
    )

    $config = Get-EntraTestEnvironment

    Write-Verbose "Connecting to Microsoft Graph for tenant $($config.TenantId)"
    Connect-MgGraph -TenantId $config.TenantId -ClientId $config.ClientId -ClientSecret $config.ClientSecret -NoWelcome -ContextScope Process | Out-Null

    $azConnected = $false
    if (-not $SkipAzure) {
        if ($config.SubscriptionId) {
            Write-Verbose "Connecting to Azure subscription $($config.SubscriptionId) with service principal $($config.ClientId)"
        } else {
            Write-Verbose "Connecting to Azure without subscription context because ENTRA_TEST_SUBSCRIPTION_ID is not set."
        }

        $secureSecret = ConvertTo-SecureString -String $config.ClientSecret -AsPlainText -Force
        $credential = New-Object System.Management.Automation.PSCredential($config.ClientId, $secureSecret)
        $azAccount = Connect-AzAccount -Tenant $config.TenantId -ServicePrincipal -Credential $credential -ErrorAction Stop

        if ($config.SubscriptionId) {
            Set-AzContext -Subscription $config.SubscriptionId -Tenant $config.TenantId -Account $azAccount.Account.Id | Out-Null
        }

        $azConnected = $true
    }

    Get-EntraTestContext -SkipValidation
}

function Get-EntraTestContext {
    [CmdletBinding()]
    param(
        [switch]$SkipValidation
    )

    $config = Get-EntraTestEnvironment
    $graphStatus = $false
    $azureStatus = $false

    if ($SkipValidation) {
        $graphStatus = $true
        $azureStatus = $true
    } else {
        try {
            $mgCtx = Get-MgContext -ErrorAction Stop
            $graphStatus = ($mgCtx.TenantId -eq $config.TenantId)
        } catch {
            $graphStatus = $false
        }

        try {
            $azCtx = Get-AzContext -ErrorAction Stop
            if ($azCtx -and $azCtx.Tenant.Id -eq $config.TenantId) {
                $azureStatus = $true
            }
        } catch {
            $azureStatus = $false
        }
    }

    [pscustomobject]@{
        TenantId       = $config.TenantId
        SubscriptionId = $config.SubscriptionId
        ClientId       = $config.ClientId
        GraphConnected = $graphStatus
        AzureConnected = $azureStatus
    }
}
#endregion

Export-ModuleMember -Function @(
    'Connect-EntraTestTenant',
    'Get-EntraTestContext'
)
