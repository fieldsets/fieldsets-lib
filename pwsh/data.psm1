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
