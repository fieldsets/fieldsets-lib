<#
.SYNOPSIS
Converts an Excel sheet from a workbook to JSON. Utilizes Import-Excel (https://github.com/dfinke/ImportExcel) Module for multi-OS compatibility.

.DESCRIPTION
To allow for parsing of Excel Workbooks suitably in PowerShell, this script converts a sheet from a spreadsheet into a JSON file of the same structure as the sheet.

.PARAMETER InputFile
The Excel Workbook to be converted. Can be FileInfo or a String.

.PARAMETER OutputFileName
The path to a JSON file to be created.

.PARAMETER SheetName
The name of the sheet from the Excel Workbook to convert. If only one sheet exists, it will convert that one.

.EXAMPLE
Convert-ExcelSheetToJson -InputFile MyExcelWorkbook.xlsx

.EXAMPLE
Get-Item MyExcelWorkbook.xlsx | Convert-ExcelSheetToJson -OutputFileName MyConvertedFile.json -SheetName Sheet2
#>
function xlsToJSON {
    [CmdletBinding()]
    Param(
        [Parameter(
            ValueFromPipeline=$true,
            Mandatory=$true
            )]
        [Object]$InputFile,

        [Parameter()]
        [string]$OutputFileName,

        [Parameter()]
        [string]$SheetName
        )

    #region prep
    # Check what type of file $InputFile is, and update the variable accordingly
    if ($InputFile -is "System.IO.FileSystemInfo") {
        $InputFile = $InputFile.FullName.ToString()
    }
    # Make sure the input file path is fully qualified
    $InputFile = [System.IO.Path]::GetFullPath($InputFile)
    Write-Verbose "Converting '$InputFile' to JSON"

    # If no OutputfileName was specified, make one up
    if (-not $OutputFileName) {
        $OutputFileName = [System.IO.Path]::GetFileNameWithoutExtension($(Split-Path $InputFile -Leaf))
        $OutputFileName = Join-Path $pwd ($OutputFileName + ".json")
    }
    # Make sure the output file path is fully qualified
    $OutputFileName = [System.IO.Path]::GetFullPath($OutputFileName)

    # Instantiate Excel
    $excelApplication = New-Object -ComObject Excel.Application
    $excelApplication.DisplayAlerts = $false
    $Workbook = $excelApplication.Workbooks.Open($InputFile)

    # If SheetName wasn't specified, make sure there's only one sheet
    if (-not $SheetName) {
        if ($Workbook.Sheets.Count -eq 1) {
            $SheetName = @($Workbook.Sheets)[0].Name
            Write-Verbose "SheetName was not specified, but only one sheet exists. Converting '$SheetName'"
        } else {
            throw "SheetName was not specified and more than one sheet exists."
        }
    } else {
        # If SheetName was specified, make sure the sheet exists
        $theSheet = $Workbook.Sheets | Where-Object {$_.Name -eq $SheetName}
        if (-not $theSheet) {
            throw "Could not locate SheetName '$SheetName' in the workbook"
        }
    }
    Write-Verbose "Outputting sheet '$SheetName' to '$OutputFileName'"
    #endregion prep

    # Grab the sheet to work with
    $theSheet = $Workbook.Sheets | Where-Object {$_.Name -eq $SheetName}

    #region headers
    # Get the row of headers
    $Headers = @{}
    $NumberOfColumns = 0
    $FoundHeaderValue = $true
    while ($FoundHeaderValue -eq $true) {
        $cellValue = $theSheet.Cells.Item(1, $NumberOfColumns+1).Text
        if ($cellValue.Trim().Length -eq 0) {
            $FoundHeaderValue = $false
        } else {
            $NumberOfColumns++
            $Headers.$NumberOfColumns = $cellValue
        }
    }
    #endregion headers

    # Count the number of rows in use, ignore the header row
    $rowsToIterate = $theSheet.UsedRange.Rows.Count

    #region rows
    $results = @()
    foreach ($rowNumber in 2..$rowsToIterate+1) {
        if ($rowNumber -gt 1) {
            $result = @{}
            foreach ($columnNumber in $Headers.GetEnumerator()) {
                $ColumnName = $columnNumber.Value
                $CellValue = $theSheet.Cells.Item($rowNumber, $columnNumber.Name).Value2
                $result.Add($ColumnName,$cellValue)
            }
            $results += $result
        }
    }
    #endregion rows


    $results | ConvertTo-Json | Out-File -Encoding ASCII -FilePath $OutputFileName

    Get-Item $OutputFileName

    # Close the Workbook
    $excelApplication.Workbooks.Close()
    # Close Excel
    [void][System.Runtime.InteropServices.Marshal]::ReleaseComObject($excelApplication)
}
Export-ModuleMember -Function xlsToJSON

<#
.SYNOPSIS
    Import data from a JSON file to a powershell object
.PARAMETER -path [String]
    The JSONdata file you would like to import.
.OUTPUTS
    [OrderedHashtable] Returns an ordered hashtable.
.EXAMPLE
    $data = importJSON -path "/somepath/file.json"
.NOTES
    Added: v0.0
    Updated Date: Apr 16 2025
#>
function importJSON {
    param(
        [Parameter(Mandatory=$true,Position=0)][String] $path
    )
    return Get-Content "$($path)" -Raw | ConvertFrom-Json -AsHashtable
}
Export-ModuleMember -Function importJSON


<#
.SYNOPSIS
    Take a data type string and return a field type string
.PARAMETER -data_type [String]
    The name of the data type.
.OUTPUTS
    [Array] Returns an array containing the db id and string of the field type. @(id,field_type)
.EXAMPLE
    $field_type = getFieldType -data_type $value.GetType().Name
.NOTES
    Added: v0.0
    Updated Date: May 9 2025
    Number IDs associated with DB table data defined in 10-fieldsets.fields.sql.
    Not all ids are accounted for in this function.
#>
function getFieldType {
    param(
        [Parameter(Mandatory=$true,Position=0)][String]$data_type
    )
    $field_type_id = 0
    $field_type = 'none'
    switch ($data_type.ToLower()) {
        ({
            ($_ -eq 'hashtable') -or
            ($_ -eq 'object') -or
            ($_ -eq 'drdereddictionary') -or
            ($_ -eq 'dictionary')
        }) {
            $field_type_id = 6
            $field_type = 'object'
            break
        }
        ({
            ($_ -eq 'double') -or
            ($_ -eq 'float') -or
            ($_ -eq 'decimal')
        }) {
            $field_type_id = 5
            $field_type = 'decimal'
            break
        }
        ({
            ($_ -eq 'int') -or
            ($_ -eq 'int16') -or
            ($_ -eq 'int32') -or
            ($_ -eq 'int64')
        }) {
            $field_type_id = 4
            $field_type = 'number'
            break
        }
        ({
            ($_ -eq 'string') -or
            ($_ -eq 'char') -or
            ($_ -eq 'text')
        }) {
            $field_type_id = 3
            $field_type = 'string'
            break
        }
        ({
            ($_ -eq 'datetime') -or
            ($_ -eq 'timestamp')
        }) {
            $field_type_id = 12
            $field_type = 'ts'
            break
        }
        ({
            ($_ -eq 'object[]') -or
            ($_ -eq 'string[]') -or
            ($_ -eq 'int[]') -or
            ($_ -eq 'array') -or
            ($_ -eq 'list')
        }) {
            $field_type_id = 7
            $field_type = 'list'
            break
        }
        ({
            ($_ -eq 'bool') -or
            ($_ -eq 'boolean')
        }) {
            $field_type_id = 10
            $field_type = 'bool'
            break
        }
        Default {
            $field_type_id = 6
            $field_type = 'object'
        }
    }
    return @($field_type_id,$field_type)
}
Export-ModuleMember -Function getFieldType
