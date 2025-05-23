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
    # The session cache should always be run on local host. If an alternate cache is used and uses the envvar $FIELDSEST_CACHE_HOST, you can still instantiate the session host if needed and call the session cache functions without the wrapper functions.
    $fieldsets_local_host = [System.Environment]::GetEnvironmentVariable('FIELDSETS_LOCAL_HOST')
    $home_path = [System.Environment]::GetEnvironmentVariable('HOME')
    $session_port = [System.Environment]::GetEnvironmentVariable('SSH_PORT')
    $ssh_key_path = [System.Environment]::GetEnvironmentVariable('SSH_KEY_PATH')
    $session_key = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_KEY')
    if ($ssh_key_path.StartsWith('~')) {
        $ssh_key_path = $ssh_key_path.Replace('~', "$($home_path)")
    }
    $session_key_path = [System.IO.Path]::GetFullPath((Join-Path -Path $ssh_key_path -ChildPath $session_key))

    $session = Get-PSSession -Name 'fieldsets-cache' -ErrorAction SilentlyContinue
    if ($null -eq $session) {
        $session = New-PSSession -Name 'fieldsets-cache' -HostName $fieldsets_local_host -Options @{StrictHostKeyChecking='no'} -Port $session_port -KeyFilePath $session_key_path
    }
    Invoke-Command -Session $session -ScriptBlock {
        Param(
            $cache_host,
            $cache_port
        )
        $encoding = New-Object System.Text.AsciiEncoding
	    $buffer = New-Object System.Byte[] 1024

        $socket = New-Object System.Net.Sockets.TcpClient("$($cache_host)", $cache_port)
        if ($null -eq $socket) {
            return
        }
        $stream = $socket.GetStream()
        $writer = New-Object System.IO.StreamWriter($stream)
        $command = 'get fieldsets_cache'
        $writer.WriteLine($command)
        $writer.Flush()
        $cache_initialized = $false
        if ($stream.DataAvailable) {
            $read = $stream.Read($buffer, 0, 1024)
            $data_val = ($encoding.GetString($buffer, 0, $read))
            Write-Output $data_val
        }

        if ($false -eq $cache_initialized) {
            $command = 'set fieldsets_cache'
        }

        Set-Variable -Name session_cache -Value (@{'initialized' = $true}) -Scope Global
    } -ArgumentList 'localhost', 11211


    return $session
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
        [Parameter(Mandatory=$false)][String]$key = $null,
        [Parameter(Mandatory=$false)][System.Management.Automation.Runspaces.PSSession]$session = $null
    )
    $current_cache = @{}
    if ($null -eq $session) {
        $session = session_cache_init
    }

    $current_cache = Invoke-Command -Session $session -ScriptBlock {
        (Get-Variable -Name session_cache -Scope Global).Value
    }
    if (($null -eq $key) -or ($key.Length -eq 0)) {
        return $current_cache
    }
    if ($current_cache.ContainsKey($key)) {
        return $current_cache[$key]
    }
    return $null
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
    Updated Date: Apr 24 2025
#>
function session_cache_set {
    Param(
        [Parameter(Mandatory=$true)][String]$key,
        [Parameter(Mandatory=$true)][PSCustomObject]$value,
        [Parameter(Mandatory=$false)][System.Management.Automation.Runspaces.PSSession]$session = $null
    )
    if ($null -eq $session) {
        $session = session_cache_init
    }

    $current_cache = Invoke-Command -Session $session -ScriptBlock {
        (Get-Variable -Name session_cache -Scope Global).Value
    }

    if ($current_cache.ContainsKey($key)) {
        $current_cache[$key] = $value
    } else {
        $current_cache.Add($key,$value)
    }

    Invoke-Command -Session $session -ScriptBlock {
        param($current_cache)
        Set-Variable -Name session_cache -Value ($current_cache) -Scope Global
    } -ArgumentList ($current_cache)
}
Export-ModuleMember -Function session_cache_set

<#
.SYNOPSIS
    session_cache_key_exists Fuction that uses global session variables as our cache. When querying the cache, this function may be overridden using an alternate cache option outside of global session variables.

.PARAMETER -key [String]
    The cache key to check.

.PARAMETER -session [PSSession] [Optional]
    Optional PSSession object to use for caching. If not provided, the HostName will be used.

.OUTPUTS
    [Boolean] $true if key exists, otherwise $false

.EXAMPLE
    session_cache_key_exists -Key 'blah'
    Returns: $true

.NOTES
    Added: v0.0
    Updated Date: Apr 24 2025
#>
function session_cache_key_exists {
    Param(
        [Parameter(Mandatory=$true)][String]$key,
        [Parameter(Mandatory=$false)][System.Management.Automation.Runspaces.PSSession]$session = $null
    )
    $current_cache = @{}
    if ($null -eq $session) {
        $session = session_cache_init
    }
    $current_cache = Invoke-Command -Session $session -ScriptBlock {
        (Get-Variable -Name session_cache -Scope Global).Value
    }

    return $current_cache.ContainsKey($key)
}
Export-ModuleMember -Function session_cache_key_exists

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
        [Parameter(Mandatory=$true)][PSCustomObject]$value
    )
    session_cache_set -key $key -value $value
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
