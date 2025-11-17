#
# PowerShell Export Module (schema governance paused)
#

#region Public Functions

<#!
.SYNOPSIS
    Normalizes complex objects into flat records suitable for CSV export.
.DESCRIPTION
    Iterates through each object and its properties. If a property is a complex type (like an array or another object),
    it serializes that property into a compact JSON string to ensure it fits within a single CSV cell.
.PARAMETER InputObject
    The array of PSObjects to convert.
.EXAMPLE
    PS> $flat = ConvertTo-FlatRecord -InputObject $objects
    PS> $flat | Export-Csv -Path './output.csv' -NoTypeInformation
.OUTPUTS
    [pscustomobject]
.NOTES
    This function is useful for flattening nested objects for CSV export.
#>
function ConvertTo-FlatRecord {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [psobject[]]$InputObject
    )

    $outputRecords = foreach ($obj in $InputObject) {
        $flatObject = [PSCustomObject]@{}
        foreach ($prop in $obj.PSObject.Properties) {
            $propName = $prop.Name
            $propValue = $prop.Value
            if ($propValue -is [array] -or $propValue -is [psobject]) {
                $flatObject | Add-Member -MemberType NoteProperty -Name $propName -Value ($propValue | ConvertTo-Json -Compress -Depth 5)
            } else {
                $flatObject | Add-Member -MemberType NoteProperty -Name $propName -Value $propValue
            }
        }
        $flatObject
    }
    return $outputRecords
}

<#!
.SYNOPSIS
    Exports an array of objects to specified formats (CSV, JSON, XLSX) with metadata.
.DESCRIPTION
    This is the main export function. It focuses on raw data exports during the current phase while schema validation is paused.
    It automatically adds metadata (timestamps, versions) to the exports. The optional dataset version is retained for future
    schema alignment but is not enforced today. XLSX export is opportunistic and only runs if the ImportExcel module is available.
.PARAMETER DatasetName
    The name of the dataset being exported.
.PARAMETER Objects
    The array of PSObjects to export.
.PARAMETER OutputPath
    The directory path where the export files will be saved.
.PARAMETER Formats
    An array of strings specifying the desired output formats. Supported: 'csv', 'json', 'xlsx'.
.PARAMETER ToolVersion
    The semantic version of the tool creating the export.
.PARAMETER DatasetVersion
    The semantic version of the dataset schema (future-phase metadata; not validated currently).
.EXAMPLE
    PS> Write-Export -DatasetName 'Entra.Users' -Objects $users -OutputPath .\exports -Formats 'csv','json' -ToolVersion '1.0.0' -DatasetVersion '1.1.0'
.OUTPUTS
    None
.NOTES
    This is the primary function for writing standardized dataset exports during the raw-export-first phase.
#>
function Write-Export {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DatasetName,
        [Parameter(Mandatory = $true)]
        [psobject[]]$Objects,
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,
        [string[]]$Formats = @('csv', 'json'),
        [string]$ToolVersion = '0.1.0',
        [string]$DatasetVersion
    )

    if (-not (Test-Path -Path $OutputPath)) {
        Write-Verbose "Output path does not exist. Creating it..."
        New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
    }

    $metadata = @{
        generated_at = [datetime]::UtcNow.ToString('o')
        tool_version = $ToolVersion
        dataset_name = $DatasetName
    }
    if ($DatasetVersion) { $metadata['dataset_version'] = $DatasetVersion }

    $baseFilePath = Join-Path -Path $OutputPath -ChildPath $DatasetName

    foreach ($format in $Formats) {
        $filePath = "$baseFilePath.$format"
        Write-Verbose "Exporting $DatasetName to $filePath"

        switch ($format) {
            'csv' {
                $flatObjects = ConvertTo-FlatRecord -InputObject $Objects
                $exportData = $flatObjects | Select-Object @{N='generated_at';E={$metadata.generated_at}}, @{N='tool_version';E={$metadata.tool_version}}, @{N='dataset_name';E={$metadata.dataset_name}}, @{N='dataset_version';E={$metadata.dataset_version}}, *
                $exportData | Export-Csv -Path $filePath -NoTypeInformation
            }
            'json' {
                $jsonData = @{
                    metadata = $metadata
                    data = $Objects
                }
                $jsonData | ConvertTo-Json -Depth 10 | Out-File -FilePath $filePath -Encoding UTF8
            }
            'xlsx' {
                if (Get-Module -ListAvailable -Name ImportExcel) {
                    $flatObjects = ConvertTo-FlatRecord -InputObject $Objects
                    $exportData = $flatObjects | Select-Object @{N='generated_at';E={$metadata.generated_at}}, @{N='tool_version';E={$metadata.tool_version}}, @{N='dataset_name';E={$metadata.dataset_name}}, @{N='dataset_version';E={$metadata.dataset_version}}, *
                    $exportData | Export-Excel -Path $filePath -TableName $DatasetName -AutoSize -AutoFilter
                } else {
                    Write-Warning "Module 'ImportExcel' is not available. Skipping XLSX export."
                }
            }
            default {
                Write-Warning "Format '$format' is not supported. Supported formats are csv, json, xlsx."
            }
        }
    }
}

#endregion

#region Module Export

Export-ModuleMember -Function @(
    'ConvertTo-FlatRecord',
    'Write-Export'
)

#endregion
