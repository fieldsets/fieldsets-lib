<#
.Synopsis
Imports variables from a dotenv (.env) file

.Example
# Create regular vars instead of env vars
dotenv -path "~/.env"
#>
function dotenv {
    [CmdletBinding(SupportsShouldProcess)]
    Param(
        [Parameter(Mandatory=$false,Position=0)][ValidateNotNullOrEmpty()][String] $path = '.env'
    )
    if([System.IO.File]::Exists($path)) {
        $env = Get-Content -raw $path | ConvertFrom-StringData
        $env.GetEnumerator() | Foreach-Object {
            $name, $value = $_.Name, $_.Value.Trim("'", '"', " ")
            if ($PSCmdlet.ShouldProcess($name, "Importing Variable")) {
                [Environment]::SetEnvironmentVariable($name, $value)
            }
        }
    } else {
        Throw [System.IO.FileNotFoundException] "$path not found."
    }
}
Export-ModuleMember -Function dotenv

<#
.SYNOPSIS
    Sanitize a token for the DB
.DESCRIPTION
    Remove unwanted characters from a string
.PARAMETER -token [String]
    The token you want to sanitize.
.OUTPUTS
    [string] Returns a tokenized string.
.EXAMPLE
    sanitizeToken -token "Some Token"
    Returns: 'some_token'
.NOTES
    Added: v0.0
    Updated Date: Apr 16 2025
#>
function sanitizeToken {
    param(
        [Parameter(Mandatory=$true)][String]$token
    )
    $invalidChars = '[]/|\+={}-$%^&*() ,~`"^$#@?.;:!'
    $arrInvalidChars = "$($invalidChars)'".ToCharArray() + [IO.Path]::GetInvalidFileNameChars()
    $split_token_array = [regex]::Unescape($token).ToLower().Split([Char[]]$arrInvalidChars)
    $token = @($split_token_array | Where-Object { $null -ne $_ -and $_ -ne ""}) -join '_'
    return ($token -replace '_+', '_').TrimEnd('_')
} #end function sanitizeToken
Export-ModuleMember -Function sanitizeToken

<#
.Synopsis
    Checks if a string is not empty
#>
function notEmpty{
    Param(
        [Parameter(Mandatory=$true,Position=0)][String] $s
    )
    return (($null -ne $s) -and ($s.Length -gt 0))
}
Export-ModuleMember -Function notEmpty

<#
.Synopsis
Checks if a string is empty
#>
function isEmpty{
    Param(
        [Parameter(Mandatory=$true,Position=0)][String] $s
    )
    return (($null -eq $s) -or ($s.Length -eq 0))
}
Export-ModuleMember -Function isEmpty

<#
.Synopsis
Check if a lockfile exists for a given script.
#>
function lockfileExists {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String] $lockfile
    )
    return (Test-Path -Path $lockfile)
}
Export-ModuleMember -Function lockfileExists

<#
.Synopsis
Remove a lockfile
#>
function removeLockfile {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String] $lockfile
    )
    if (lockfileExists $lockfile) {
        Remove-Item $lockfile -Force
    }
}
Export-ModuleMember -Function removeLockfile

<#
.Synopsis
Create a new lockfile
#>
function createLockfile {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String] $lockfile,
        [Parameter(Mandatory=$false,Position=1)][String] $lockfile_path = "/data/lockfiles/"
    )
    # Make sure our lockfile path exists.
    if (-not (Test-Path -Path $lockfile_path)) {
        New-Item -Path $lockfile_path -ItemType Directory -Force | Out-Null
    }
    $lock = [System.IO.Path]::GetFullPath((Join-Path -Path "$($lockfile_path)" -ChildPath "./$($lockfile)"))
    if (lockfileExists $lock) {
        $pidlist = Get-content $lock
        if (! $pidlist) {
            $PID | Out-File $lock
        }
        $currentproclist = Get-Process | Where-Object { $_.id -match $pidlist }
        if ($currentproclist) {
            Write-Information -MessageData "lockfile in use by other process" -InformationAction Continue
            Throw "lockfile in use by other process (pid: $($pidlist))"
        } else {
            removeLockfile $lock
            $PID | Out-File $lock
        }
    } else {
        $PID | Out-File $lock
    }
}
Export-ModuleMember -Function createLockfile

<#
.Synopsis
    Continuously monitors a directory tree and write to the output the path of the file that has changed.
.Description
    This powershell cmdlet continuously monitors a directory tree and write to the output the path of the file that has changed.
    This allows you to create an script that for instance, run a suite of unit tests when an specific file has changed using powershell pipelining.
.Parameter $location
    The directory to watch. Optional, default to current directory.
.Parameter $includeSubdirectories
.Parameter $includeChanged
.Parameter $includeRenamed
.Parameter $includeCreated
.Parameter $includeDeleted
.Example
    watch "Myfolder\Other" | %{
        Write-Host "$_.Path has changed!"
        RunUnitTests.exe $_.Path
    }

    Description
    -----------
    A simple example.
.Example
    watch | Get-Item | Where-Object { $_.Extension -eq ".js" } | %{
        do the magic...
    }

    Description
    -----------
    You can filter by using powershell pipelining.
#>
function watch{
    Param (
        [Parameter(Mandatory=$false,Position=0)][string]$location = "",
        [Parameter(Mandatory=$false,Position=1)][switch]$includeSubdirectories = $false,
        [Parameter(Mandatory=$false,Position=2)][switch]$includeChanged = $false,
        [Parameter(Mandatory=$false,Position=3)][switch]$includeRenamed = $false,
        [Parameter(Mandatory=$false,Position=4)][switch]$includeCreated = $false,
        [Parameter(Mandatory=$false,Position=5)][switch]$includeDeleted = $false
    )

    if ($location -eq "") {
        $location = Get-Location
    }

    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $location
    $watcher.IncludeSubdirectories = $includeSubdirectories
    $watcher.EnableRaisingEvents = $false
    $watcher.NotifyFilter = [System.IO.NotifyFilters]::LastWrite -bor [System.IO.NotifyFilters]::FileName

    $conditions = 0
    if ($includeChanged) {
        $conditions = [System.IO.WatcherChangeTypes]::Changed
    }

    if ($includeRenamed) {
        $conditions = $conditions -bOr [System.IO.WatcherChangeTypes]::Renamed
    }

    if ($includeCreated) {
        $conditions = $conditions -bOr [System.IO.WatcherChangeTypes]::Created
    }

    if ($includeDeleted) {
        $conditions = $conditions -bOr [System.IO.WatcherChangeTypes]::Deleted
    }

    while($true){
        $result = $watcher.WaitForChanged($conditions, 1000);
        if($result.TimedOut){
            continue;
        }
        $filepath = [System.IO.Path]::Combine($location, $result.Name)
        New-Object Object |
            Add-Member NoteProperty Path $filepath -passThru |
            Add-Member NoteProperty Operation $result.ChangeType.ToString() -passThru |
            Write-Output
    }
}
Export-ModuleMember -Function watch

<#
.SYNOPSIS
    getFieldType Return Field Type ID and Field Type Token from external data type strings (primarily PWSH).

.OUTPUTS
    [Array] Returns an array in format @([INT]$field_type_id, [STRING]$field_type_token)

.EXAMPLE
    $value = 'A String'
    $data_type = $value.GetType().Name
    $field_type = getFieldType -data_type $data_type

.NOTES
    Added: v0.0
    Updated Date: July 5, 2025
#>
function getFieldType {
    param(
        [Parameter(Mandatory=$true,Position=0)][String]$data_type
    )
    $field_type_id = 0
    $field_type = 'none'
    switch ($data_type.ToLower()) {
        ({
            ($_ -eq '0') -or
            ($_ -eq 'hook') -or
            ($_ -eq 'datahook') -or
            ($_ -eq 'actionhook') -or
            ($_ -eq 'none')
        }) {
            $field_type_id = 0
            $field_type = 'hook'
            break
        }
        ({
            ($_ -eq '6') -or
            ($_ -eq 'hashtable') -or
            ($_ -eq 'object') -or
            ($_ -eq 'ordereddictionary') -or
            ($_ -eq 'dictionary')
        }) {
            $field_type_id = 6
            $field_type = 'object'
            break
        }
        ({
            ($_ -eq '5') -or
            ($_ -eq 'double') -or
            ($_ -eq 'float') -or
            ($_ -eq 'decimal')
        }) {
            $field_type_id = 5
            $field_type = 'decimal'
            break
        }
        ({
            ($_ -eq '4') -or
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
            ($_ -eq '3') -or
            ($_ -eq 'string') -or
            ($_ -eq 'char') -or
            ($_ -eq 'text')
        }) {
            $field_type_id = 3
            $field_type = 'string'
            break
        }
        ({
            ($_ -eq '12') -or
            ($_ -eq 'datetime') -or
            ($_ -eq 'timestamp')
        }) {
            $field_type_id = 12
            $field_type = 'ts'
            break
        }
        ({
            ($_ -eq '7') -or
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
            ($_ -eq '10') -or
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


<#
.SYNOPSIS
    hasKey fuction will return a true or false if a key/property exists in a hashtable, dictionary or object.

.PARAMETER -object [PSCustomObject]
    The object to check

.PARAMETER -key [String]
    The key to check for within the object

.OUTPUTS
    [Boolean]

.EXAMPLE
    hasKey -object @{mykey=1} -key 'mykey'
    Returns: $true

.NOTES
    Added: v0.0
    Updated Date: July 29 2025
#>
function hasKey {
    Param(
        [Parameter(Mandatory=$true)][Object]$object,
        [Parameter(Mandatory=$true)][String]$key
    )

    $data_type = $object.GetType()
    $haskey = $false
    if (
        ("$($data_type.BaseType)" -eq 'hashtable') -or
        ("$($data_type.BaseType)" -eq 'object') -or
        ("$($data_type.BaseType)" -eq 'dictionary') -or
        ("$($data_type.BaseType)" -eq 'System.Object') -or
        ("$($data_type.BaseType)" -eq 'System.Collections.Hashtable') -or
        ("$($data_type.BaseType)" -eq 'System.Management.Automation.OrderedHashtable')
    ) {
        switch ($data_type.Name) {
            'OrderedDictionary' {
                $haskey = $object.Contains($key)
                break
            }
            'PSCustomObject' {
                $haskey = ($key -in $object.PSObject.Properties.Name)
                break
            }
            ({
                ($_ -eq 'Hashtable') -or
                ($_ -eq 'OrderedHashtable')
            }) {
                $haskey = $object.ContainsKey($key)
                break
            }
            default {
                $haskey = $object.Contains($key)
                break
            }
        }
    } else {
        Write-Host "hasKey: Invalid Object. Please use an Object, Hashtable or Dictionary."
    }
    return $haskey
}
Export-ModuleMember -Function hasKey

