<#
.SYNOPSIS
    getSessionConnectInfo Set the variables use to connect to the powershell session and called by the data Hook 'fieldsets_session_connect_info'

.OUTPUTS
    [Hashtable] @{
        HostName = 'localhost'
        Port = 1022
        Key = '/root/.ssh/fieldsets_rsa'
    }

.EXAMPLE
    getSessionConnectInfo

.NOTES
    Added: v0.0
    Updated Date: July 18 2025
#>
function getSessionConnectInfo {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data = @{}
    )
    $cache_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/pwsh' -ChildPath "./cache.psm1"))
    $utils_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/pwsh' -ChildPath "./utils.psm1"))
    Import-Module -Function session_cache_set, session_cache_get, session_cache_key_exists -Name "$($cache_module_path)"
    Import-Module -Function hasKey -Name "$($utils_module_path)"

    $port = $null
    $key = $null
    $hostname = $null

    if (($data.ContainsKey('Hostname')) -and ($data['Hostname'] -ne '')) {
        $hostname = $data['Hostname']
    }
    if (($data.ContainsKey('Port')) -and ($data['Port'] -ne '')) {
        $port = $data['Port']
    }
    if (($data.ContainsKey('Key')) -and ($data['Key'] -ne '')) {
        $key = $data['Key']
    }

    if ($null -eq $hostname) {
        # Try and use the environment but it may not be set
        $cache_session_key = 'session_connect_info_default'
    } else {
        $cache_session_key = "session_connect_info_$($hostname)"
    }

    $is_cached = session_cache_key_exists -key "$($cache_session_key)"
    if ($is_cached) {
        $cached_data = session_cache_get -key "$($cache_session_key)"
        if ($null -eq $hostname) {
            $has_hostname_key = hasKey -Object $cached_data -Key 'Hostname'
            if ($has_hostname_key) {
                $hostname = $cached_data['Hostname']
            } else {
                $hostname = $null
            }
        }
        if ($null -eq $key) {
            $has_auth_key = hasKey -Object $cached_data -Key 'Key'
            if ($has_auth_key) {
                $key = $cached_data['Key']
            } else {
                $key = $null
            }
        }
        if ($null -eq $port) {
            $has_port_key = hasKey -Object $cached_data -Key 'Port'
            if ($has_port_key) {
                $port = $cached_data['Port']
            } else {
                $port = $null
            }
        }
    }

    # Set Defaults if still empty
    if ($null -eq $hostname) {
        $hostname = '0.0.0.0'
    }
    if ($null -eq $port) {
        $port = 1022
    }
    if ($null -eq $key) {
        $key = '/root/.ssh/fieldsets_rsa'
    }

    $data['Hostname'] = $hostname
    $data['Port'] = $port
    $data['Key'] = $key

    return $data
}
Export-ModuleMember -Function getSessionConnectInfo


<#
.SYNOPSIS
    cacheSessionConnectInfo ensure hook data is written to the cache.

.OUTPUTS
    [Hashtable] @{
        HostName = 'localhost'
        Port = 1022
        Key = '/root/.ssh/fieldsets_rsa'
    }

.EXAMPLE
    cacheSessionConnectInfo

.NOTES
    Added: v0.0
    Updated Date: July 18 2025
#>
function cacheSessionConnectInfo {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data = @{}
    )
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/pwsh' -ChildPath "./cache.psm1"))
    Import-Module -Function session_cache_set -Name "$($module_path)"

    $hostname = $data['Hostname']
    if ($null -eq $hostname) {
        # Try and use the environment but it may not be set
        $cache_session_key = 'session_connect_info_default'
    } else {
        $cache_session_key = "session_connect_info_$($hostname)"
    }
    $data_json = ConvertTo-JSON -Compress -Depth 3 -InputObject $data
    session_cache_set -Key "$($cache_session_key)" -Type 'object' -Value $data_json -Expires 0

    return $data
}
Export-ModuleMember -Function cacheSessionConnectInfo


<#
.SYNOPSIS
    session_connect Connect via SSH to our PSSession.

.OUTPUTS
    N/A

.EXAMPLE
    session_connect

.NOTES
    Added: v0.0
    Updated Date: July 5 2025
#>
function session_connect {
    Param(
        [Parameter(Mandatory=$false)][String]$hostname = 0.0.0.0,
        [Parameter(Mandatory=$false)][Int]$port = 1022,
        [Parameter(Mandatory=$false)][String]$key = '/root/.ssh/fieldsets_rsa'
    )

    $session_client = [System.Environment]::GetEnvironmentVariable('SSH_CLIENT')

    # If we are already connected, the SSH_CLIENT environment variable will be set.
    if (($null -eq $session_client) -or ($session_name -eq '')) {
        if (("$($key)").StartsWith('~')) {
            $home_path = [System.Environment]::GetEnvironmentVariable('HOME')
            $truncated_path = ("$($key)").Replace('~', '')
            $key = Join-Path -Path $home_path -ChildPath $truncated_path
        }

        if (Test-Path -Path $key) {
            Enter-PSSession -HostName $hostname -Options @{StrictHostKeyChecking='no'} -Port $port -KeyFilePath $key
        } else {
            Write-Error "Invalid Session Key File: $($key)"
        }
    }
}
Export-ModuleMember -Function session_connect

<#
.SYNOPSIS
    session_disconnect Disconnect our SSH PSSession.

.OUTPUTS
    N/A

.EXAMPLE
    session_disconnect

.NOTES
    Added: v0.0
    Updated Date: July 5 2025
#>
function session_disconnect {
    $session_name = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_NAME')
    if ('fieldsets_session' -eq $session_name) {
        Exit-PSSession
    }
}
Export-ModuleMember -Function session_disconnect