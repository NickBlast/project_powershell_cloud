#
# PowerShell Logging Module with Redaction and Retry Logic
#

#region Module-Scoped Variables

# Default redaction patterns. Users can add more with Set-LogRedactionPatterns.
$script:RedactionPatterns = @(
    # Emails
    '[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
    # GUIDs
    '[a-fA-F0-9]{8}-([a-fA-F0-9]{4}-){3}[a-fA-F0-9]{12}',
    # Common secret-like patterns (e.g., base64 encoded strings of 32+ chars)
    '(?i)(key|secret|token|password|cred|auth|bearer)\s*[:=]\s*\S+',
    '[A-Za-z0-9+/]{32,}='
)

$script:CorrelationId = [guid]::NewGuid().ToString()

#endregion

#region Private Helper Functions

function Protect-String {
    param(
        [string]$InputString
    )

    $redactedString = $InputString
    foreach ($pattern in $script:RedactionPatterns) {
        $redactedString = $redactedString -replace $pattern, '***REDACTED***'
    }
    return $redactedString
}

#endregion

#region Public Functions

<#
.SYNOPSIS
    Creates a new logging context object.
.DESCRIPTION
    Returns a hashtable containing a new, unique correlation_id and optional tenant_id and dataset.
    This is useful for tracking a specific operation or transaction.
.PARAMETER TenantId
    An optional identifier for the tenant associated with the log entries.
.PARAMETER DataSet
    An optional identifier for the dataset being processed.
.EXAMPLE
    PS> $context = New-LogContext -TenantId 'tenant-abc-123' -DataSet 'Azure.RBAC'
    PS> Write-StructuredLog -Level Info -Message "Starting export..." -Context $context
.NOTES
    The correlation_id is a unique GUID generated for each new context.
#>
function New-LogContext {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [string]$TenantId,
        [string]$DataSet
    )

    $context = @{
        correlation_id = [guid]::NewGuid().ToString()
    }

    if ($TenantId) { $context['tenant_id'] = $TenantId }
    if ($DataSet) { $context['dataset'] = $DataSet }

    if ($PSCmdlet.ShouldProcess('LogContext','Create')) {
        # Creation acknowledged by ShouldProcess; nothing special to do.
    }

    return $context
}

<#
.SYNOPSIS
    Sets custom regex patterns for redacting sensitive information from logs.
.DESCRIPTION
    Overwrites the default redaction patterns with a new set of regex patterns.
    These patterns are used by Write-StructuredLog to mask secrets, PII, or other sensitive data.
.PARAMETER Patterns
    An array of strings, where each string is a regular expression pattern to be redacted.
.EXAMPLE
    PS> $myPatterns = @(
        'user/d+',
        'api-key-[a-zA-Z0-9]+'
    )
    PS> Set-LogRedactionPattern -Patterns $myPatterns
.OUTPUTS
    None
.NOTES
    This function overwrites any existing patterns. Use with caution.
#>
function Set-LogRedactionPattern {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string[]]$Patterns
    )

    if ($PSCmdlet.ShouldProcess('LogRedactionPatterns','Update')) {
        $script:RedactionPatterns = $Patterns
        Write-Verbose "Log redaction patterns have been updated."
    }
}

<#
.SYNOPSIS
    Gets the correlation ID for the current session.
.DESCRIPTION
    Returns the correlation ID that was generated when the module was imported.
    This provides a consistent ID for an entire script execution or session.
.EXAMPLE
    PS> $sessionId = Get-CorrelationId
.OUTPUTS
    [string]
.NOTES
    The correlation ID is generated once when the module is first imported.
#>
function Get-CorrelationId {
    [CmdletBinding()]
    param()

    return $script:CorrelationId
}

<#
.SYNOPSIS
    Writes a structured, redacted log message to the console and optionally to a file.
.DESCRIPTION
    A comprehensive logging function that redacts sensitive information based on configured patterns.
    It can output plain text to the console with color-coding for severity, or structured JSON.
    It supports writing to a file in plain text or JSON Lines format.
.PARAMETER Level
    The severity level of the log message. (Info, Warn, Error, Verbose, Debug)
.PARAMETER Message
    The log message content.
.PARAMETER Context
    A hashtable containing contextual information, such as a correlation_id or tenant_id.
.PARAMETER ToJson
    If specified, the console output will be a single JSON string instead of plain text.
.PARAMETER ToFile
    The absolute path to a log file. The message will be appended to this file.
.EXAMPLE
    PS> Write-StructuredLog -Level Info -Message "User logged in" -Context (New-LogContext)
.EXAMPLE
    PS> Write-StructuredLog -Level Error -Message "Failed to connect" -ToFile C:\logs\app.log -ToJson
.OUTPUTS
    None
.NOTES
    This is the primary logging function for the repository. It provides structured, redacted logging.
#>
function Write-StructuredLog {
    [CmdletBinding()]
    param(
        [ValidateSet('Info', 'Warn', 'Error', 'Verbose', 'Debug')]
        [string]$Level = 'Info',
        [string]$Message,
        [hashtable]$Context,
        [switch]$ToJson,
        [string]$ToFile
    )

    $timestamp = [datetime]::UtcNow.ToString("o")
    $redactedMessage = Protect-String -InputString $Message

    $logEntry = @{
        timestamp = $timestamp
        level = $Level
        message = $redactedMessage
    }

    if ($Context) {
        $logEntry += $Context
    }

    # Console Output
    if ($ToJson) {
        $outputString = $logEntry | ConvertTo-Json -Compress -Depth 5
        # Use Write-Information so the log can participate in standard stream handling instead of Write-Host.
        Write-Information -MessageData $outputString -InformationAction Continue -Tags 'StructuredLog', $Level
    } else {
        $outputString = "$timestamp [$Level] $redactedMessage"
        # Write-Information keeps console visibility by default while allowing suppression/redirection as needed.
        Write-Information -MessageData $outputString -InformationAction Continue -Tags 'StructuredLog', $Level
    }

    # File Output
    if ($ToFile) {
        try {
            if ($ToJson) {
                ($logEntry | ConvertTo-Json -Compress -Depth 5) | Add-Content -Path $ToFile
            } else {
                "$timestamp [$Level] $redactedMessage" | Add-Content -Path $ToFile
            }
        }
        catch {
            Write-Error "Failed to write to log file '$ToFile'. Error: $_"
        }
    }
}

<#
.SYNOPSIS
    Executes a scriptblock with a retry policy for transient errors.
.DESCRIPTION
    Wraps a command or scriptblock, automatically retrying it upon failure.
    It uses an exponential backoff algorithm with jitter to avoid overwhelming an endpoint.
    It is designed to handle transient HTTP errors like 429 (Too Many Requests) and 5xx (Server Error),
    but will retry on any exception.
.PARAMETER ScriptBlock
    The scriptblock to execute and retry on failure.
.PARAMETER MaxRetries
    The maximum number of times to retry the scriptblock. Default is 6.
.PARAMETER InitialDelaySeconds
    The initial delay in seconds before the first retry. Default is 1.
.PARAMETER BackoffFactor
    The multiplier for the delay. Default is 2.0 (doubles the delay each time).
.PARAMETER JitterFactor
    The percentage of jitter to apply to the delay to prevent thundering herd scenarios. Default is 0.2 (20%).
.EXAMPLE
    PS> Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri 'https://api.example.com/data' }
.EXAMPLE
    PS> $sb = {
        $user = Get-MgUser -UserId 'user@example.com'
        if (-not $user) { throw "User not found" }
        return $user
    }
    PS> Invoke-WithRetry -ScriptBlock $sb -MaxRetries 3 -InitialDelaySeconds 2
.OUTPUTS
    [object]
.NOTES
    This function returns the output of the scriptblock if it succeeds. It re-throws the last exception upon failure.
#>
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,
        [int]$MaxRetries = 6,
        [int]$InitialDelaySeconds = 1,
        [double]$BackoffFactor = 2.0,
        [double]$JitterFactor = 0.2
    )

    $attempt = 0
    $delay = $InitialDelaySeconds

    while ($attempt -lt $MaxRetries) {
        $attempt++
        try {
            Write-Verbose "Attempt $attempt of $MaxRetries..."
            return $ScriptBlock.Invoke()
        }
        catch {
            $errorMessage = "Attempt $attempt failed. Error: $($_.Exception.Message)"
            Write-StructuredLog -Level Warn -Message $errorMessage -Context @{ correlation_id = (Get-CorrelationId) }

            if ($attempt -ge $MaxRetries) {
                Write-StructuredLog -Level Error -Message "Max retries reached. Operation failed." -Context @{ correlation_id = (Get-CorrelationId) }
                throw # Re-throw the last exception
            }

            $jitter = ($delay * $JitterFactor) * ((Get-Random -Minimum -1.0 -Maximum 1.0))
            $sleepSeconds = [math]::Max(1, $delay + $jitter)

            Write-StructuredLog -Level Info -Message "Waiting for $($sleepSeconds.ToString('F2')) seconds before next attempt." -Context @{ correlation_id = (Get-CorrelationId) }
            Start-Sleep -Seconds $sleepSeconds

            $delay = $delay * $BackoffFactor
        }
    }
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'New-LogContext',
    'Set-LogRedactionPattern',
    'Write-StructuredLog',
    'Get-CorrelationId',
    'Invoke-WithRetry'
)

#endregion
