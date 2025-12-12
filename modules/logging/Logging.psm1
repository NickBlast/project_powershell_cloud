<#
    PowerShell Logging Module with redaction, retry helpers, and a centralized
    run logging API.

    Usage (PowerShell 7+):

        Import-Module "$PSScriptRoot/Logging.psm1"
        $run = Start-RunLog -ScriptName 'export-azure_scopes' -DatasetName 'azure_scopes' -TenantId '0000-1111' -ToolVersion '0.3.0'
        Write-RunLog -RunContext $run -Level Info -Message 'Connecting to tenant'
        # ... script logic ...
        Complete-RunLog -RunContext $run -Status 'Success' -Summary @{ items_processed = 42 }

    Guarantees for callers:
    - Each run receives a unique correlation identifier that is present on every log entry.
    - Logs are written to `logs/<yyyyMMdd-HHmmss>-<scriptname>-run.log` in newline-delimited JSON for machine parsing.
    - `RunContext` objects include absolute and repository-relative log paths for operator messaging.
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

function ConvertTo-RunLogEntry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [pscustomobject]$RunContext,
        [Parameter(Mandatory)]
        [string]$Level,
        [Parameter(Mandatory)]
        [string]$Message,
        [hashtable]$Metadata
    )

    $entry = [ordered]@{
        timestamp      = [datetime]::UtcNow.ToString('o')
        level          = $Level
        correlation_id = $RunContext.CorrelationId
        script_name    = $RunContext.ScriptName
    }

    if ($RunContext.DatasetName) { $entry['dataset_name'] = $RunContext.DatasetName }
    if ($RunContext.TenantId) { $entry['tenant_id'] = $RunContext.TenantId }
    if ($RunContext.TenantLabel) { $entry['tenant_label'] = $RunContext.TenantLabel }
    if ($RunContext.ToolVersion) { $entry['tool_version'] = $RunContext.ToolVersion }
    if ($RunContext.ScriptVersion) { $entry['script_version'] = $RunContext.ScriptVersion }

    $entry['message'] = Protect-String -InputString $Message

    if ($Metadata) {
        $sanitizedMetadata = @{}
        foreach ($key in $Metadata.Keys) {
            $value = $Metadata[$key]
            if ($null -eq $value) { continue }

            if ($value -is [string]) {
                $sanitizedMetadata[$key] = Protect-String -InputString $value
            }
            else {
                $sanitizedMetadata[$key] = $value
            }
        }

        if ($sanitizedMetadata.Count -gt 0) {
            $entry['metadata'] = $sanitizedMetadata
        }
    }

    return $entry
}

#endregion

#region Public Functions

function Start-RunLog {
    <#
    .SYNOPSIS
        Starts a run log and returns the run context for the caller.
    .DESCRIPTION
        Creates a structured log file under the repository `logs/` directory with a
        standardized name (`yyyyMMdd-HHmmss-<script>-run.log`). Every log entry includes
        a correlation identifier to tie a run together across modules.
    .PARAMETER ScriptName
        Name of the script or entrypoint running.
    .PARAMETER DatasetName
        Optional dataset name associated with the run.
    .PARAMETER TenantId
        Optional tenant identifier associated with the run.
    .PARAMETER TenantLabel
        Optional friendly label for the tenant.
    .PARAMETER ToolVersion
        Optional tool or module version stamp for the run.
    .PARAMETER ScriptVersion
        Optional script version stamp for the run.
    .OUTPUTS
        [pscustomobject] run context with correlation ID, log paths, and metadata.
    #>
    [CmdletBinding(SupportsShouldProcess = $true)]
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

    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $sanitizedName = [System.IO.Path]::GetFileNameWithoutExtension($ScriptName)
    $logFileName = "$timestamp-$sanitizedName-run.log"
    $logPath = Join-Path -Path $logsRoot -ChildPath $logFileName
    $relativeLogPath = [System.IO.Path]::GetRelativePath($repoRoot, $logPath)
    $correlationId = [guid]::NewGuid().ToString()

    $runContext = [pscustomobject]@{
        ScriptName      = $sanitizedName
        DatasetName     = $DatasetName
        TenantId        = $TenantId
        TenantLabel     = $TenantLabel
        ToolVersion     = $ToolVersion
        ScriptVersion   = $ScriptVersion
        CorrelationId   = $correlationId
        LogPath         = $logPath
        RelativeLogPath = $relativeLogPath
        StartedAt       = [datetime]::UtcNow
    }

    # Align other helpers (Get-CorrelationId, Invoke-WithRetry) to the run-level correlation ID.
    $script:CorrelationId = $correlationId
    $script:RunLogContext = $runContext

    if ($PSCmdlet.ShouldProcess($logPath, 'Create run log file')) {
        if (-not (Test-Path -Path $logsRoot)) {
            New-Item -ItemType Directory -Path $logsRoot -Force | Out-Null
        }

        if (-not (Test-Path -Path $logPath)) {
            New-Item -ItemType File -Path $logPath -Force | Out-Null
        }

        Write-RunLog -RunContext $runContext -Level 'Info' -Message 'Run started' -Metadata @{
            script_version = $ScriptVersion
            tool_version   = $ToolVersion
        }
    }

    return $runContext
}

function Write-RunLog {
    <#
    .SYNOPSIS
        Appends a structured log entry to the current run log.
    .DESCRIPTION
        Writes newline-delimited JSON entries to the run log file created by Start-RunLog.
        Messages are redacted using repository redaction patterns.
    .PARAMETER RunContext
        Run context object returned from Start-RunLog.
    .PARAMETER Level
        Severity level for the entry. Accepted values: Info, Warning, Error, Debug.
    .PARAMETER Message
        Message to record in the log entry.
    .PARAMETER Metadata
        Optional hashtable of additional fields to capture.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$RunContext,
        [Parameter(Mandatory = $true)][ValidateSet('Info', 'Warning', 'Error', 'Debug')][string]$Level,
        [Parameter(Mandatory = $true)][string]$Message,
        [hashtable]$Metadata
    )

    if (-not $RunContext.LogPath) {
        throw 'RunContext is missing a LogPath value.'
    }

    $logDirectory = Split-Path -Path $RunContext.LogPath -Parent
    if (-not (Test-Path -Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }

    if (-not (Test-Path -Path $RunContext.LogPath)) {
        New-Item -ItemType File -Path $RunContext.LogPath -Force | Out-Null
    }

    $entry = ConvertTo-RunLogEntry -RunContext $RunContext -Level $Level -Message $Message -Metadata $Metadata
    ($entry | ConvertTo-Json -Compress -Depth 6) | Add-Content -Path $RunContext.LogPath -Encoding UTF8
}

function Complete-RunLog {
    <#
    .SYNOPSIS
        Writes a completion entry with optional summary metadata.
    .DESCRIPTION
        Appends a final Info entry noting completion status and duration. Does not close the file
        (files are written and closed per entry), but provides a clear terminus for downstream parsing.
    .PARAMETER RunContext
        Run context object returned from Start-RunLog.
    .PARAMETER Status
        Optional status string. Defaults to Success.
    .PARAMETER Summary
        Optional hashtable of summary fields (counts, flags, warnings).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$RunContext,
        [string]$Status = 'Success',
        [hashtable]$Summary
    )

    $durationSeconds = $null
    if ($RunContext.StartedAt) {
        $durationSeconds = [math]::Round(([datetime]::UtcNow - $RunContext.StartedAt).TotalSeconds, 2)
    }

    $metadata = @{
        status = $Status
    }

    if ($durationSeconds) { $metadata['duration_seconds'] = $durationSeconds }
    if ($Summary) { $metadata['summary'] = $Summary }

    Write-RunLog -RunContext $RunContext -Level 'Info' -Message 'Run completed' -Metadata $metadata
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
    'Start-RunLog',
    'Write-RunLog',
    'Complete-RunLog',
    'New-LogContext',
    'Set-LogRedactionPattern',
    'Write-StructuredLog',
    'Get-CorrelationId',
    'Invoke-WithRunLogging',
    'Invoke-WithRetry',
    'Write-ExportLogStart',
    'Write-ExportLogResult'
)

#endregion
