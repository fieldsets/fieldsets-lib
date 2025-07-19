<#
.SYNOPSIS
    get_session_connect_info Set the variables use to connect to the powershell session and called by the data Hook 'fieldsets_session_connect_info'

.OUTPUTS
    [Hashtable] @{
        HostName = 'localhost'
        Port = 1022
        Key = '/root/.ssh/fieldsets_rsa'
    }

.EXAMPLE
    session_connect

.NOTES
    Added: v0.0
    Updated Date: July 18 2025
#>
function get_session_connect_info {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data = @{}
    )
    $port = $null
    $key = $null
    $hostname = $null

    if ($data.ContainsKey('Hostname')) {
        $hostname = $data['Hostname']
    }
    if ($data.ContainsKey('Port')) {
        $port = $data['Port']
    }
    if ($data.ContainsKey('Key')) {
        $key = $data['Key']
    }

    if (($null -eq $hostname) -or ($hostname -eq '')) {
        $hostname = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_HOST')
    }
    if (($null -eq $key) -or ($key -eq '')) {
        $session_key = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_KEY')
        $session_key_path = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_KEY_PATH')
        if ($null -eq $session_key_path) {
            # Fall back on ssh dir path
            $session_key_path = [System.Environment]::GetEnvironmentVariable('SSH_KEY_PATH')
        }
        if ($session_key_path.StartsWith('~')) {
            $home_path = [System.Environment]::GetEnvironmentVariable('HOME')
            $session_key_path = $session_key_path.Replace('~', "$($home_path)")
        }
        $key = [System.IO.Path]::GetFullPath((Join-Path -Path $session_key_path -ChildPath $session_key))
    }
    if (($null -eq $port) -or ($port -eq '')) {
        $port = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_PORT')
    }
    return @{
        Hostname = $hostname
        Port = $port
        Key = $key
    }
}
Export-ModuleMember -Function session_connect

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
        [Parameter(Mandatory=$false,Position=0)][String]$hostname = $null,
        [Parameter(Mandatory=$false,Position=1)][Int]$port = $null,
        [Parameter(Mandatory=$false,Position=2)][String]$key = $null
    )
    $session_name = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_NAME')
    # If we are already connected, the environment variable will be set.
    if (($null -eq $session_name) -or ($false -eq $session_name) -or ($session_name -eq '') -or ('false' -eq ("$($session_name)").ToLower())) {
        if ($null -eq $hostname) {
            $hostname = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_HOST')
        }
        if ($null -eq $port) {
            $port = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_PORT')
        }
        if ($null -eq $key) {
            $session_key = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_KEY')
            $session_key_path = [System.Environment]::GetEnvironmentVariable('FIELDSETS_SESSION_KEY_PATH')
            if ($null -eq $session_key_path) {
                # Fall back on ssh dir path
                $session_key_path = [System.Environment]::GetEnvironmentVariable('SSH_KEY_PATH')
            }
            if ($session_key_path.StartsWith('~')) {
                $home_path = [System.Environment]::GetEnvironmentVariable('HOME')
                $session_key_path = $session_key_path.Replace('~', "$($home_path)")
            }
            $key = [System.IO.Path]::GetFullPath((Join-Path -Path $session_key_path -ChildPath $session_key))
        }
        if (Test-Path -LiteralPath $key) {
            $key_file = Get-Item $key
            $session_key  = $key_file.BaseName
            $session_key_path = $key_file.DirectoryName

            Enter-PSSession -HostName $hostname -Options @{StrictHostKeyChecking='no'} -Port $port -KeyFilePath $key
            [System.Environment]::SetEnvironmentVariable('FIELDSETS_SESSION_NAME', 'fieldsets_session')
            [System.Environment]::SetEnvironmentVariable('FIELDSETS_SESSION_HOST', $hostname)
            [System.Environment]::SetEnvironmentVariable('FIELDSETS_SESSION_PORT', $port)
            [System.Environment]::SetEnvironmentVariable('FIELDSETS_SESSION_KEY', $session_key)
            [System.Environment]::SetEnvironmentVariable('FIELDSETS_SESSION_KEY_PATH', $session_key_path)
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