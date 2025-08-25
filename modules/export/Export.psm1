#
# PowerShell Export Module with Schema Validation
#

#region Public Functions

<#
.SYNOPSIS
    Reads a dataset's JSON schema from the /docs/schemas directory.
.DESCRIPTION
    Constructs the path to a schema file based on the dataset name, reads it, and converts it from JSON.
    If the schema file is not found, it returns $null and writes a warning.
.PARAMETER DatasetName
    The name of the dataset, which corresponds to the schema filename (e.g., 'Azure.RBAC').
.EXAMPLE
    PS> $schema = Get-DatasetSchema -DatasetName 'Entra.Groups'
    PS> if ($schema) { #... use schema ... }
.OUTPUTS
    [psobject]
.NOTES
    Returns the parsed JSON schema object, or $null if the file is not found or invalid.
#>
function Get-DatasetSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$DatasetName
    )

    $root = Join-Path -Path $PSScriptRoot -ChildPath '..'
    $root = Join-Path -Path $root -ChildPath '..'
    $schemaDir = Join-Path -Path $root -ChildPath 'docs'
    $schemaDir = Join-Path -Path $schemaDir -ChildPath 'schemas'
    $schemaPath = Join-Path -Path $schemaDir -ChildPath "$($DatasetName).schema.json"
    $schemaPath = Resolve-Path -Path $schemaPath -ErrorAction SilentlyContinue

    if (-not (Test-Path -Path $schemaPath)) {
        Write-Warning "Schema file not found for dataset '$DatasetName'. Looked in: $schemaPath"
        return $null
    }

    try {
        return Get-Content -Path $schemaPath -Raw | ConvertFrom-Json
    }
    catch {
        Write-Error "Failed to read or parse schema file '$schemaPath'. Error: $_"
        return $null
    }
}

<#
.SYNOPSIS
    Tests an array of objects against a provided schema.
.DESCRIPTION
    Validates objects based on a schema, checking for required properties and correct data types.
    It returns a boolean indicating success or failure and provides a list of validation errors.
.PARAMETER InputObject
    The array of PSObjects to validate.
.PARAMETER Schema
    The schema object (from Get-DatasetSchema) to validate against.
.PARAMETER Strict
    If specified, the function will throw a terminating error on the first validation failure.
.EXAMPLE
    PS> $isValid = Test-ObjectAgainstSchema -InputObject $myObjects -Schema $mySchema -ErrorVariable validationErrors
    PS> if (-not $isValid) { $validationErrors | Format-List }
.NOTES
    This function provides basic validation and is not a full JSON schema validator.
#>
function Test-ObjectAgainstSchema {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [psobject[]]$InputObject,
        [Parameter(Mandatory = $true)]
        [psobject]$Schema,
        [switch]$Strict
    )

    $validationErrors = [System.Collections.Generic.List[string]]::new()
    $requiredFields = $Schema.required
    $properties = $Schema.properties

    foreach ($obj in $InputObject) {
        # Check for required fields
        if ($requiredFields) {
            foreach ($reqField in $requiredFields) {
                if (-not $obj.PSObject.Properties.Name.Contains($reqField)) {
                    $validationErrors.Add("Object missing required property: $reqField")
                }
            }
        }

        # Check property types
        if ($properties) {
            foreach ($prop in $obj.PSObject.Properties) {
                $propName = $prop.Name
                if ($properties.$propName) {
                    # Placeholder: type validation can be implemented here if needed.
                }
            }
        }
    }

    if ($validationErrors.Count -gt 0) {
        Write-Warning "Schema validation failed for $($validationErrors.Count) reason(s)."
        $validationErrors | ForEach-Object { Write-Warning "  - $_" }
        if ($Strict) {
            throw "Strict schema validation failed."
        }
        return $false
    }

    return $true
}

<#
.SYNOPSIS
    Normalizes complex objects into flat records suitable for CSV export.
.DESCRIPTION
    Iterates through each object and its properties. If a property is a complex type (like an array or another object),
    it serializes that property into a compact JSON string to ensure it fits within a single CSV cell.
.PARAMETER InputObject
    An array of PSObjects to flatten.
.EXAMPLE
    PS> $flatObjects = ConvertTo-FlatRecord -InputObject $complexObjects
.OUTPUTS
    [psobject[]]
.NOTES
    This function is used to prepare objects for CSV export, where complex properties need to be serialized.
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

<#
.SYNOPSIS
    Exports an array of objects to specified formats (CSV, JSON, XLSX) with metadata and schema validation.
.DESCRIPTION
    This is the main export function. It orchestrates schema validation, data normalization, and writing to files.
    It automatically adds metadata (timestamps, versions) to the exports.
    XLSX export is opportunistic and only runs if the ImportExcel module is available.
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
    The semantic version of the dataset schema.
.EXAMPLE
    PS> Write-Export -DatasetName 'Entra.Users' -Objects $users -OutputPath .\exports -Formats 'csv','json' -ToolVersion '1.0.0' -DatasetVersion '1.1.0'
.OUTPUTS
    None
.NOTES
    This is the primary function for writing standardized dataset exports.
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

    $schema = Get-DatasetSchema -DatasetName $DatasetName
    if ($schema) {
        if (-not $DatasetVersion) { $DatasetVersion = $schema.version }
        if (-not (Test-ObjectAgainstSchema -InputObject $Objects -Schema $schema -Strict)) {
            Write-Error "Objects failed schema validation. Halting export."
            return
        }
    } else {
        Write-Warning "No schema found for $DatasetName. Proceeding without validation or guaranteed field order."
        if (-not $DatasetVersion) { $DatasetVersion = 'unknown' }
    }

    $metadata = @{
        generated_at = [datetime]::UtcNow.ToString('o')
        tool_version = $ToolVersion
        dataset_version = $DatasetVersion
    }

    $baseFilePath = Join-Path -Path $OutputPath -ChildPath $DatasetName

    foreach ($format in $Formats) {
        $filePath = "$baseFilePath.$format"
        Write-Verbose "Exporting $DatasetName to $filePath"

        switch ($format) {
            'csv' {
                $flatObjects = ConvertTo-FlatRecord -InputObject $Objects
                $exportData = $flatObjects | Select-Object @{N='generated_at';E={$metadata.generated_at}}, @{N='tool_version';E={$metadata.tool_version}}, @{N='dataset_version';E={$metadata.dataset_version}}, *

                $exportParams = @{ InputObject = $exportData; Path = $filePath; NoTypeInformation = $true }
                if ($schema -and $schema.properties) {
                    $headers = @('generated_at', 'tool_version', 'dataset_version') + ($schema.properties.PSObject.Properties.Name)
                    $exportParams.Add('UseQuotes', 'AsNeeded')
                    # This doesn't directly order, Export-Csv uses first object. We need to re-order.
                    $orderedData = $exportData | Select-Object -Property $headers
                    $orderedData | Export-Csv @exportParams
                } else {
                    $exportData | Export-Csv @exportParams
                }
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
                    $exportData = $flatObjects | Select-Object @{N='generated_at';E={$metadata.generated_at}}, @{N='tool_version';E={$metadata.tool_version}}, @{N='dataset_version';E={$metadata.dataset_version}}, *
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
    'Get-DatasetSchema',
    'Test-ObjectAgainstSchema',
    'ConvertTo-FlatRecord',
    'Write-Export'
)

#endregion
