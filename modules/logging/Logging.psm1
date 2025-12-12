<#
.SYNOPSIS
    Centralized, structured logging helpers for repository entrypoints.
.DESCRIPTION
    Provides a minimal, reusable API for run logging so every script emits
    consistent metadata (script name, dataset, tenant label, correlation ID)
    to the `logs/` directory. The core API consists of:

    - Start-RunLog: Initializes a run context with correlation identifier and
      establishes the log file path using the pattern
      `logs/<yyyyMMdd-HHmmss>-<ScriptName>-run.log`.
    - Write-RunLog: Appends structured log entries to the run log using
      key-value formatting that is machine-parseable and redacted.
    - Complete-RunLog: Writes a terminal summary entry and closes the run.

    Callers should create a run context once per script invocation, pass the
    context to Write-RunLog for important milestones, and always call
    Complete-RunLog in a finally block so the run is marked finished even on
    error. Correlation identifiers are guaranteed for every run and every log
    line.
#>

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

# Correlation ID scoped to the module for backward compatibility; run logging
# functions generate per-run identifiers in their contexts.
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

function New-RunLogContextObject {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [string]$DatasetName,
        [string]$TenantId,
        [string]$TenantLabel,
        [string]$ToolVersion,
        [string]$ScriptVersion,
        [string]$LogFilePath,
        [string]$RelativeLogPath,
        [datetime]$StartTime
    )

    $context = [pscustomobject]@{
        ScriptName     = $ScriptName
        DatasetName    = $DatasetName
        TenantId       = $TenantId
        TenantLabel    = $TenantLabel
        ToolVersion    = $ToolVersion
        ScriptVersion  = $ScriptVersion
        LogFilePath    = $LogFilePath
        RelativeLogPath = $RelativeLogPath
        StartTime      = $StartTime
        CorrelationId  = [guid]::NewGuid().ToString()
    }

    if ($PSCmdlet.ShouldProcess('RunLogContext', 'Create')) {
        return $context
    }
}

<#
.SYNOPSIS
    Initializes a run log and returns a reusable context object.
.DESCRIPTION
    Creates a run-specific context containing correlation identifier, script metadata, and the log file path under `logs/`.
    The log file name follows the pattern `yyyyMMdd-HHmmss-<ScriptName>-run.log`. A start entry is written immediately.
.PARAMETER ScriptName
    Name of the calling script (used in the log filename and entries).
.PARAMETER DatasetName
    Dataset identifier associated with the run (optional).
.PARAMETER TenantId
    Tenant identifier associated with the run (optional).
.PARAMETER TenantLabel
    Friendly tenant label for operator references (optional).
.PARAMETER ToolVersion
    Tool or script version to stamp on log entries (optional).
.PARAMETER ScriptVersion
    Script version string (optional).
.OUTPUTS
    [pscustomobject] representing the run context.
#>
function Start-RunLog {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [string]$DatasetName,
        [string]$TenantId,
        [string]$TenantLabel,
        [string]$ToolVersion,
        [string]$ScriptVersion
    )

    $modulesRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $repoRoot = (Resolve-Path -Path (Join-Path -Path $modulesRoot -ChildPath '..')).Path
    $logsRoot = Join-Path -Path $repoRoot -ChildPath 'logs'

    if (-not (Test-Path -Path $logsRoot)) {
        New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $sanitizedName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptName)
    $logFileName = "$timestamp-$sanitizedName-run.log"
    $logPath = Join-Path -Path $logsRoot -ChildPath $logFileName
    $relativeLogPath = [System.IO.Path]::GetRelativePath($repoRoot, $logPath)
    $startTime = Get-Date

    $context = New-RunLogContextObject -ScriptName $sanitizedName -DatasetName $DatasetName -TenantId $TenantId -TenantLabel $TenantLabel -ToolVersion $ToolVersion -ScriptVersion $ScriptVersion -LogFilePath $logPath -RelativeLogPath $relativeLogPath -StartTime $startTime

    if ($PSCmdlet.ShouldProcess($logPath, 'Create run log')) {
        Write-RunLog -RunContext $context -Level Info -Message 'Run started' -AdditionalData @{ start_time = $startTime.ToUniversalTime().ToString('o') }
    }

    return $context
}

<#
.SYNOPSIS
    Writes a structured log entry for the active run context.
.DESCRIPTION
    Appends a redacted, key-value formatted line to the run log file using UTC timestamps and the run correlation identifier.
.PARAMETER RunContext
    The run context created by Start-RunLog.
.PARAMETER Level
    Log level to stamp on the entry (Info, Warning, Error).
.PARAMETER Message
    Message body for the log entry.
.PARAMETER AdditionalData
    Optional hashtable of additional key/value pairs to append to the entry.
#>
function Write-RunLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$RunContext,
        [ValidateSet('Info', 'Warning', 'Error')][string]$Level = 'Info',
        [Parameter(Mandatory = $true)][string]$Message,
        [hashtable]$AdditionalData
    )

    $timestamp = [datetime]::UtcNow.ToString('o')
    $redactedMessage = Protect-String -InputString $Message

    $entry = [ordered]@{
        timestamp      = $timestamp
        level          = $Level
        correlation_id = $RunContext.CorrelationId
        script_name    = $RunContext.ScriptName
        dataset_name   = $RunContext.DatasetName
        tenant_id      = $RunContext.TenantId
        tenant_label   = $RunContext.TenantLabel
        tool_version   = $RunContext.ToolVersion
        script_version = $RunContext.ScriptVersion
        message        = $redactedMessage
    }

    if ($AdditionalData) {
        foreach ($key in $AdditionalData.Keys) {
            $value = $AdditionalData[$key]
            $entry[$key] = if ($value -is [string]) { Protect-String -InputString $value } else { $value }
        }
    }

    $line = ($entry.GetEnumerator() | ForEach-Object { "{0}={1}" -f $_.Key, $_.Value }) -join ' | '
    Add-Content -Path $RunContext.LogFilePath -Value $line -Encoding UTF8
}

<#
.SYNOPSIS
    Writes a completion entry for the run and records summary details.
.DESCRIPTION
    Adds a final log entry containing the run status, duration, and any supplied summary metadata. Use in a finally block.
.PARAMETER RunContext
    The run context created by Start-RunLog.
.PARAMETER Status
    Overall run status (Success, Failed, Warning).
.PARAMETER AdditionalData
    Optional summary metadata to append to the completion record.
#>
function Complete-RunLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$RunContext,
        [ValidateSet('Success', 'Failed', 'Warning')][string]$Status = 'Success',
        [hashtable]$AdditionalData
    )

    $duration = $null
    if ($RunContext.StartTime) {
        $duration = (Get-Date) - $RunContext.StartTime
    }

    $completionData = @{ status = $Status }
    if ($duration) { $completionData['duration_seconds'] = [math]::Round($duration.TotalSeconds, 2) }
    if ($AdditionalData) {
        $completionData += $AdditionalData
    }

    Write-RunLog -RunContext $RunContext -Level Info -Message 'Run completed' -AdditionalData $completionData
}

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
        Write-Information -MessageData $outputString -Tags 'StructuredLog', $Level
    } else {
        $outputString = "$timestamp [$Level] $redactedMessage"
        # Write-Information keeps console visibility by default while allowing suppression/redirection as needed.
        Write-Information -MessageData $outputString -Tags 'StructuredLog', $Level
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
    Executes a scriptblock while capturing all output streams to a run log file.
.DESCRIPTION
    Generates a log file under the repository's logs directory using the pattern
    `yyyyMMdd-HHmmss-<scriptname>-run.log`. All streams (Information, Verbose,
    Warning, Error, Output, Debug) are redirected into the log file while the
    console remains quiet. A hashtable is returned with success status and both
    absolute and repository-relative log paths.
.PARAMETER ScriptName
    The name of the script being executed. This is used to name the log file.
.PARAMETER ScriptBlock
    The scriptblock containing the core script logic to execute.
.OUTPUTS
    [hashtable] with the keys: Succeeded (bool), LogPath (string), and
    RelativeLogPath (string).
#>
function Invoke-WithRunLogging {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [Parameter(Mandatory = $true)][scriptblock]$ScriptBlock
    )

    $modulesRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '..')).Path
    $repoRoot = (Resolve-Path -Path (Join-Path -Path $modulesRoot -ChildPath '..')).Path
    $logsRoot = Join-Path -Path $repoRoot -ChildPath 'logs'

    if (-not (Test-Path -Path $logsRoot)) {
        New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null
    }

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $sanitizedName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptName)
    $logFileName = "$timestamp-$sanitizedName-run.log"
    $logPath = Join-Path -Path $logsRoot -ChildPath $logFileName
    $relativeLogPath = [System.IO.Path]::GetRelativePath($repoRoot, $logPath)

    $logWriter = [System.IO.StreamWriter]::new($logPath, $false, [System.Text.Encoding]::UTF8)
    try {
        & $ScriptBlock 6>&1 5>&1 4>&1 3>&1 2>&1 |
            Out-String -Stream |
            ForEach-Object { $logWriter.WriteLine($_) }

        return @{ Succeeded = $true; LogPath = $logPath; RelativeLogPath = $relativeLogPath }
    }
    catch {
        $logWriter.WriteLine(($_ | Out-String))
        return @{ Succeeded = $false; LogPath = $logPath; RelativeLogPath = $relativeLogPath }
    }
    finally {
        $logWriter.Flush()
        $logWriter.Dispose()
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

<#
.SYNOPSIS
    Writes a standardized log entry when an export begins.
.DESCRIPTION
    Records dataset, tenant, and output metadata at the start of an export run using Write-StructuredLog.
.PARAMETER ScriptName
    Name of the calling script.
.PARAMETER DatasetName
    Name of the dataset being exported.
.PARAMETER OutputPath
    Destination path for export artifacts (optional).
.PARAMETER TenantId
    Tenant identifier (optional).
.PARAMETER SubscriptionId
    Subscription identifier (optional).
#>
function Write-ExportLogStart {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [Parameter(Mandatory = $true)][string]$DatasetName,
        [string]$OutputPath,
        [string]$TenantId,
        [string]$SubscriptionId
    )

    $message = "Starting export for $DatasetName via $ScriptName"
    $context = @{ dataset_name = $DatasetName }
    if ($TenantId) { $context['tenant_id'] = $TenantId }
    if ($SubscriptionId) { $context['subscription_id'] = $SubscriptionId }
    if ($OutputPath) { $context['output_path'] = $OutputPath }

    Write-StructuredLog -Level Info -Message $message -Context $context
}

<#
.SYNOPSIS
    Writes a standardized log entry when an export completes.
.DESCRIPTION
    Captures export status, output path, and row counts, and persists a summary JSON record for the last run.
.PARAMETER ScriptName
    Name of the calling script.
.PARAMETER DatasetName
    Name of the dataset being exported.
.PARAMETER Succeeded
    Indicates whether the export completed successfully.
.PARAMETER OutputPath
    Destination path for export artifacts (optional).
.PARAMETER RowCount
    Number of records exported (optional).
.PARAMETER Message
    Additional status message to include.
.PARAMETER ResultsPath
    Path to the summary JSON file that tracks last run results.
#>
function Write-ExportLogResult {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [Parameter(Mandatory = $true)][string]$DatasetName,
        [Parameter(Mandatory = $true)][bool]$Succeeded,
        [string]$OutputPath,
        [int]$RowCount,
        [string]$Message,
        [string]$ResultsPath = (Join-Path -Path $PSScriptRoot -ChildPath '../../tests/results/last_run.json')
    )

    $status = if ($Succeeded) { 'Success' } else { 'Failed' }
    $logContext = @{ dataset_name = $DatasetName; status = $status }
    if ($OutputPath) { $logContext['output_path'] = $OutputPath }
    if ($RowCount -ge 0) { $logContext['row_count'] = $RowCount }

    Write-StructuredLog -Level Info -Message ($Message ? $Message : "Completed with status: $status") -Context $logContext

    $resultEntry = [pscustomobject]@{
        timestamp    = [datetime]::UtcNow.ToString('o')
        script_name  = $ScriptName
        dataset_name = $DatasetName
        status       = $status
        output_path  = $OutputPath
        row_count    = $RowCount
        message      = $Message
    }

    $resultsDir = Split-Path -Path $ResultsPath -Parent
    if (-not (Test-Path -Path $resultsDir)) {
        New-Item -Path $resultsDir -ItemType Directory -Force | Out-Null
    }

    $existing = @()
    if (Test-Path -Path $ResultsPath) {
        try { $existing = Get-Content -Path $ResultsPath -Raw | ConvertFrom-Json } catch { $existing = @() }
    }

    $updated = @($existing + $resultEntry)
    $updated | ConvertTo-Json -Depth 5 | Set-Content -Path $ResultsPath
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'New-LogContext',
    'Set-LogRedactionPattern',
    'Write-StructuredLog',
    'Get-CorrelationId',
    'Invoke-WithRunLogging',
    'Invoke-WithRetry',
    'Write-ExportLogStart',
    'Write-ExportLogResult',
    'Start-RunLog',
    'Write-RunLog',
    'Complete-RunLog'
)

#endregion
