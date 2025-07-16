
<#
.SYNOPSIS
    session_cache_connect Connect via SSH to our PSSession.

.OUTPUTS
    N/A

.EXAMPLE
    session_cache_connect

.NOTES
    Added: v0.0
    Updated Date: July 5 2025
#>
function session_cache_connect {
    $is_session = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_CACHE')
    $cache_type = [System.Environment]::GetEnvironmentVariable('FIELDSETS_CACHE')
    $cache_host = [System.Environment]::GetEnvironmentVariable('FIELDSETS_CACHE_HOST')
    $cache_port = [System.Environment]::GetEnvironmentVariable('FIELDSETS_CACHE_PORT')

    if ($null -eq $cache_host) {
        $cache_host = 'localhost'
    }
    if ($null -eq $cache_port) {
        $cache_host = 11211
    }
    if ($null -eq $cache_type) {
        $cache_type = 'memcached'
    }
    # If we are already connected, the environment variable will be set.
    if (($null -eq $is_session) -or ($false -eq $is_session)) {
        $home_path = [System.Environment]::GetEnvironmentVariable('HOME')
        $fieldsets_session_host = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_HOST')
        $session_port = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_PORT')
        $ssh_key_path = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_KEY_PATH')
        $session_key = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_KEY')
        if ($ssh_key_path.StartsWith('~')) {
            $ssh_key_path = $ssh_key_path.Replace('~', "$($home_path)")
        }
        $session_key_path = [System.IO.Path]::GetFullPath((Join-Path -Path $ssh_key_path -ChildPath $session_key))
        Enter-PSSession -HostName $fieldsets_session_host -Options @{StrictHostKeyChecking='no'} -Port $session_port -KeyFilePath $session_key_path
        [System.Environment]::SetEnvironmentVariable('FIELDSETS_SESSION_CACHE', $true)
        [System.Environment]::SetEnvironmentVariable('FIELDSETS_CACHE',$cache_type)
        [System.Environment]::SetEnvironmentVariable('FIELDSETS_CACHE_HOST', $cache_host)
        [System.Environment]::SetEnvironmentVariable('FIELDSETS_CACHE_PORT', $cache_port)
    }
}
Export-ModuleMember -Function session_cache_connect

<#
.SYNOPSIS
    session_cache_disconnect Disconnect our SSH PSSession.

.OUTPUTS
    N/A

.EXAMPLE
    session_cache_disconnect

.NOTES
    Added: v0.0
    Updated Date: July 5 2025
#>
function session_cache_disconnect {
    $is_session = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_CACHE')
    # Connect if not connected.
    if ($true -eq $is_session) {
        Exit-PSSession
    }
}
Export-ModuleMember -Function session_cache_disconnect

<#
.SYNOPSIS
    session_cache_init The default in memory session cache. Called by wrapper function cache_init.

.OUTPUTS
    [PSSession] Returns the PSSession object used for caching.

.EXAMPLE
    $session_cache = session_cache_init

.NOTES
    Added: v0.0
    Updated Date: May 6 2025
#>
function session_cache_init {
    Param (
        [Parameter(Mandatory=$false)][Int]$expires = 86400 #24hrs in seconds by default
    )

    $is_session = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_CACHE')
    # Connect if not connected.
    if (($null -eq $is_session) -or ($false -eq $is_session)) {
        session_cache_connect
    }
    $cache_host = 'localhost'
    $cache_port = 11211
    $data_value = ''
    $encoding = New-Object System.Text.AsciiEncoding
    $buffer = New-Object System.Byte[] 1024

    $socket = New-Object System.Net.Sockets.TcpClient("$($cache_host)", $cache_port)
    if ($null -eq $socket) {
        return
    }
    $stream = $socket.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $command = 'get fieldsets_session_cache'
    $writer.WriteLine($command)
    $writer.Flush()
    # Wait for stream Write
    Start-Sleep -Milliseconds 1

    $cache_initialized = $false

    while ($stream.DataAvailable) {
        $read = $stream.Read($buffer, 0, 1024)
        $lines = ($encoding.GetString($buffer, 0, $read)).Trim(" ","`r","`t").Split("`n")
        foreach ($line in $lines){
            $readline_value = ("$($line)").Trim(" ","`r","`n","`t")
            if (
                ("$($readline_value)".Length -gt 0 ) -and
                (!($readline_value.StartsWith('VALUE fieldsets_session_cache'))) -and
                ($readline_value -ne 'END')
            ) {
                $data_value = "$($data_value)$($readline_value)"
            }
        }
    }

    if ($data_value.Length -gt 0) {
        $cache_initialized = $true
    } else {
        $cache_initialized = $false
    }


    if ($false -eq $cache_initialized) {
        $data_value = ConvertTo-Json -InputObject @{'initialized' = $true} -Compress -Depth 10
        $data_value_bytes = [System.Text.Encoding]::ASCII.GetBytes($data_value)
        $command = "set fieldsets_session_cache 6 $($expires) $($data_value_bytes.Length)`r`n$($data_value)`r`n"
        $writer.WriteLine($command)
        $writer.Flush()
        # Wait for stream Write
        Start-Sleep -Milliseconds 1
    }
    $socket.Close()

    return $data_value
}
Export-ModuleMember -Function session_cache_init

<#
.SYNOPSIS
    session_cache_get fuction that uses global session variables as our cache. When querying the cache, this function may be overridden using an alternate cache option outside of global session variables.

.PARAMETER -key [String] [Optional]
    The cache key of the value. An empty string or null will return the entire cache.

.PARAMETER -session [PSSession] [Optional]
    Optional PSSession object to use for caching. If not provided, the HostName will be used.

.OUTPUTS
    [Mixed] The value assiociated with the given key.

.EXAMPLE
    session_cache_get -Key 'blah'
    Returns: Value of $global:cache['blah']

.NOTES
    Added: v0.0
    Updated Date: Apr 24 2025
#>
function session_cache_get {
    Param(
        [Parameter(Mandatory=$true)][String]$key
    )
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/' -ChildPath "pwsh"))
    $utils_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./utils.psm1"))
    Import-Module -Function getFieldType -Name $utils_module_path

    $cache_host = 'localhost'
    $cache_port = 11211
    $data_value = ''
    $encoding = New-Object System.Text.AsciiEncoding
    $buffer = New-Object System.Byte[] 1024

    $socket = New-Object System.Net.Sockets.TcpClient("$($cache_host)", $cache_port)
    if ($null -eq $socket) {
        return
    }


    $stream = $socket.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $command = "get $($key)"
    $writer.WriteLine($command)
    $writer.Flush()

    # Wait for stream Write
    Start-Sleep -Milliseconds 1
    $type = 'string'
    while ($stream.DataAvailable) {
        $read = $stream.Read($buffer, 0, 1024)
        $lines = ($encoding.GetString($buffer, 0, $read)).Trim(" ","`r","`t").Split("`n")
        foreach ($line in $lines){
            $readline_value = ("$($line)").Trim(" ","`r","`n","`t")
            if ($readline_value.StartsWith("VALUE $($key)")) {
                $key_info = ($readline_value).Split(' ')
                $type_info = getFieldType -data_type "$($key_info[2])"
                $type = $type_info[1]
            } elseif (
                ("$($readline_value)".Length -gt 0 ) -and
                ($readline_value -ne 'END')
            ) {
                $data_value = "$($data_value)$($readline_value)"
            }
        }
    }

    $socket.Close()

    if ($data_value.Length -gt 0) {
        switch ($type) {
            ({
                ($_ -eq 'string')
            }) {
                return "$($data_value)"
            }
            ({
                ($_ -eq 'decimal')
            }) {
                return [Decimal]$data_value
            }
            ({
                ($_ -eq 'number')
            }) {
                return [Int]$data_value
            }
            ({
                ($_ -eq 'list')
            }) {
                if ($PSVersionTable.PSVersion.Major -eq 5) {
                    $return_val = ConvertFrom-Json -Depth 10 -InputObject $data_value
                    return $return_val
                } else {
                    $return_val = ConvertFrom-Json -Depth 10 -InputObject $data_value -AsHashtable -NoEnumerate
                    return $return_val
                }
            }
            ({
                ($_ -eq 'object')
            }) {
                if ($PSVersionTable.PSVersion.Major -eq 5) {
                    $return_val = ConvertFrom-Json -Depth 10 -InputObject $data_value
                    return $return_val
                } else {
                    $return_val = ConvertFrom-Json -Depth 10 -InputObject $data_value -AsHashtable -NoEnumerate
                    return $return_val
                }
            }
            ({
                ($_ -eq 'bool')
            }) {
                if (("$($data_value)".ToLower() -eq 'false') -or ("$($data_value)" -eq '')) {
                    return $false
                }
                return $true
            }
            # TODO: Add timestamp
            Default {
                return $data_value
            }
        }
    }
    return
}
Export-ModuleMember -Function session_cache_get

<#
.SYNOPSIS
    session_cache_set Sets the PS Session global session_cache hash table variable key.

.PARAMETER -key [String]
    The cache key of the value.

.PARAMETER -value [PSCustomObject]
    The value to be cached.

.PARAMETER -session [PSSession] [Optional]
    Optional PSSession object to use for caching. If not provided, the HostName will be used.

.OUTPUTS
    None

.EXAMPLE
    session_cache_set -key 'foo' -value 'bar'

.NOTES
    Added: v0.0
    Updated Date: July 5, 2025
#>
function session_cache_set {
    Param(
        [Parameter(Mandatory=$true)][String]$key,
        [Parameter(Mandatory=$true)][PSCustomObject]$value,
        [Parameter(Mandatory=$false)][String]$type = $null,
        [Parameter(Mandatory=$false)][Int]$expires = 86400 #24hrs in seconds by default
    )

    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/' -ChildPath "pwsh"))
    $utils_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./utils.psm1"))
    Import-Module -Function getFieldType -Name $utils_module_path
    $cache_host = 'localhost'
    $cache_port = 11211
    $data_value = ''

    $socket = New-Object System.Net.Sockets.TcpClient("$($cache_host)", $cache_port)
    if ($null -eq $socket) {
        return
    }
    $stream = $socket.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $data_type = $type
    if ($null -eq $data_type) {
        $data_type = $value.GetType().Name
    }

    $field_type = getFieldType -data_type $data_type

    $data_object = $value
    # Make sure we properly parse arrays and objects
    if ($field_type[1] -eq 'object') {
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $data_object = ConvertFrom-Json -InputObject $value -Depth 10
        } else {
            $data_object = ConvertFrom-Json -InputObject $value -Depth 10 -NoEnumerate -AsHashtable
        }
    } elseif ($field_type[1] -eq 'list') {
        if ($PSVersionTable.PSVersion.Major -eq 5) {
            $data_object = ConvertFrom-Json -InputObject $value -Depth 10
        } else {
            $data_object = ConvertFrom-Json -InputObject $value -Depth 10 -NoEnumerate
        }
    }
    $data_value = ConvertTo-Json -InputObject $data_object -Compress -Depth 10

    $data_value_bytes = [System.Text.Encoding]::ASCII.GetBytes($data_value)
    $command = "set $($key) $($field_type[0]) $($expires) $($data_value_bytes.Length)`r`n$($data_value)`r`n"
    $writer.WriteLine($command)
    $writer.Flush()
    # Wait for stream Write
    Start-Sleep -Milliseconds 1

    $socket.Close()
    return $data_value
}
Export-ModuleMember -Function session_cache_set

<#
.SYNOPSIS
    session_cache_key_exists Fuction that uses global session variables as our cache. When querying the cache, this function may be overridden using an alternate cache option outside of global session variables.

.PARAMETER -key [String]
    The cache key to check.

.OUTPUTS
    [Boolean] $true if key exists, otherwise $false

.EXAMPLE
    session_cache_key_exists -Key 'blah'
    Returns: $true

.NOTES
    Added: v0.0
    Updated Date: July 5, 2025
#>
function session_cache_key_exists {
    Param(
        [Parameter(Mandatory=$true)][String]$key
    )
    $cache_val = session_cache_get -Key "$($key)"
    if ($null -eq $cache_val) {
        return $false
    } else {
        return $true
    }
}
Export-ModuleMember -Function session_cache_key_exists

function session_cache_delete {
    Param(
        [Parameter(Mandatory=$true)][String]$key
    )
    $cache_host = 'localhost'
    $cache_port = 11211
    $socket = New-Object System.Net.Sockets.TcpClient("$($cache_host)", $cache_port)
    if ($null -eq $socket) {
        return
    }
    $stream = $socket.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $command = "delete $($key)"
    $writer.WriteLine($command)
    $writer.Flush()
    # Wait for stream Write
    Start-Sleep -Milliseconds 1

    $socket.Close()
    return
}
Export-ModuleMember -Function session_cache_delete

function session_cache_flush {
    $cache_host = 'localhost'
    $cache_port = 11211
    $socket = New-Object System.Net.Sockets.TcpClient("$($cache_host)", $cache_port)
    if ($null -eq $socket) {
        return
    }
    $stream = $socket.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $command = "flush_all"
    $writer.WriteLine($command)
    $writer.Flush()
    # Wait for stream Write
    Start-Sleep -Milliseconds 1

    $socket.Close()
    return
}
Export-ModuleMember -Function session_cache_flush



<#
.SYNOPSIS
    cache_init This fuction initializes the framework cache. It serves as a wrapper function with the intention of being clobbered.

.OUTPUTS
    [None]

.EXAMPLE
    cache_init

.NOTES
    Added: v0.0
    Updated Date: May 6 2025
#>
function cache_init {
    return session_cache_init
}
Export-ModuleMember -Function cache_init

<#
.SYNOPSIS
    cache_get A wrapper function to query the cache. The default cache is a persistant session. When querying the cache, this function may be overridden using an alternate cache option outside of global session variables.

.PARAMETER -key [String]
    The cache key of the value.

.OUTPUTS
    [Mixed] The value assiociated with the given key.

.EXAMPLE
    cache_get -Key 'blah'
    Returns: Value of $global:cache['blah']

.NOTES
    Added: v0.0
    Updated Date: Apr 24 2025
#>
function cache_get {
    Param(
        [Parameter(Mandatory=$true)][String]$key
    )
    return session_cache_get -key $key
}
Export-ModuleMember -Function cache_get

<#
.SYNOPSIS
    cache_set fuction A wrapper function to set a cache value. The default cache is a persistant session. When setting the cache, this function may be overridden(clobbered) using an alternate cache option outside of global session variables.

.PARAMETER -key [String]
    The cache key of the value.

.PARAMETER -value [PSCustomObject]
    The value to be cached.

.OUTPUTS
    None

.EXAMPLE
    cache_set -key 'foo' -value 'bar'

.NOTES
    Added: v0.0
    Updated Date: Apr 24 2025
#>
function cache_set {
    Param(
        [Parameter(Mandatory=$true)][String]$key,
        [Parameter(Mandatory=$true)][PSCustomObject]$value,
        [Parameter(Mandatory=$false)][String]$type = $null,
        [Parameter(Mandatory=$false)][Int]$expires = 86400 #24hrs in seconds by default
    )
    session_cache_set -key $key -value $value -type $type -expires $expires
}
Export-ModuleMember -Function cache_set

<#
.SYNOPSIS
    cache_key_exists A wrapper function to check the existance of a value in the cache. When querying the cache, this function may be overridden using an alternate cache option outside of global session variables.

.PARAMETER -key [String]
    The cache key to check.

.OUTPUTS
    [Boolean] $true if key exists, otherwise $false

.EXAMPLE
    cache_key_exists -Key 'blah'
    Returns: $true

.NOTES
    Added: v0.0
    Updated Date: Apr 24 2025
#>
function cache_key_exists {
    Param(
        [Parameter(Mandatory=$true)][String]$key
    )

    return session_cache_key_exists -key $key
}
Export-ModuleMember -Function cache_key_exists
