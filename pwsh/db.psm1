<#
.SYNOPSIS
    Gets the Authentication info to create a DB connection. This is the default function for the get_db_connect_info Data Hook.

.PARAMETER -data
    Data passed by the Data Hook

.OUTPUTS
    [Hashtable] @{
        type = 'postgres'
        dbname = 'fieldsets'
        hostname = '0.0.0.0'
        schema = 'fieldsets'
        port = 1022
        user = 'postgres'
        password = 'fieldsets'
        dotnet_ver = '8.0'
    }

.NOTES
    Added: v0.0
    Updated Date: July 30 2025
#>
function getDBConnectInfo {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data=$null
    )
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/pwsh' -ChildPath "./cache.psm1"))
    Import-Module -Function session_cache_get, session_cache_key_exists -Name "$($module_path)"
    if ($null -eq $data) {
        # Check environment variables
        $db_type = [System.Environment]::GetEnvironmentVariable('FIELDSETS_DB')
        $db_user = [System.Environment]::GetEnvironmentVariable('FIELDSETS_DB_USER')
        $db_password = [System.Environment]::GetEnvironmentVariable('FIELDSETS_DB_PASSWORD')
        $db_name = [System.Environment]::GetEnvironmentVariable('FIELDSETS_DB_NAME')
        $db_schema = [System.Environment]::GetEnvironmentVariable('FIELDSETS_DB_SCHEMA')
        $db_host = [System.Environment]::GetEnvironmentVariable('FIELDSETS_DB_HOST')
        $db_port = [System.Environment]::GetEnvironmentVariable('FIELDSETS_DB_PORT')
        $dotnet_ver = [System.Environment]::GetEnvironmentVariable('DOTNET_VERSION')
        if (($null -ne $db_type) -and ($db_type.Length -gt 0)) {
            $data = @{
                type = $db_type
                dbname = $db_name
                hostname = $db_host
                schema = $db_schema
                port = $db_port
                user = $db_user
                password = $db_password
                dotnet_ver = $dotnet_ver
            }
        }
    } else {
        if ('postgres' -eq "$($data['type'])") {
            if (($data.ContainsKey('hostname')) -and ("0.0.0.0" -eq "$($data['hostname'])")) {
                $data['hostname'] = 'localhost'
            }
            if ((!($data.ContainsKey('dotnet_ver'))) -or ($null -eq $data['dotnet_ver'])) {
                $data['dotnet_ver'] = '8.0'
            }
        }
    }
    return $data
}
Export-ModuleMember -Function getDBConnectInfo

<#
.SYNOPSIS
    Cache the Authentication info to create a DB connection. This is the default function for the get_db_connect_info Data Hook.

.PARAMETER -data
    Data passed by the Data Hook

.OUTPUTS
    [Hashtable] @{
        type = 'postgres'
        dbname = 'fieldsets'
        hostname = '0.0.0.0'
        schema = 'fieldsets'
        port = 1022
        user = 'postgres'
        password = 'fieldsets'
        dotnet_ver = '8.0'
    }

.NOTES
    Added: v0.0
    Updated Date: July 30 2025
#>
function cacheDBConnectInfo {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data=@{}
    )
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/pwsh' -ChildPath "./cache.psm1"))
    Import-Module -Function session_cache_set -Name "$($module_path)"

    $db_type = $data['type']
    $default_connection_key = 'db_connect_info_default'
    if (($null -eq $db_type) -or ($db_type.Length -eq 0)) {
        # Try and use the environment but it may not be set
        $db_connection_key = 'db_connect_info_default'
        # No data, grabbed last cached value.
        if (session_cache_key_exists -Key $db_connection_key) {
            $data = session_cache_get -Key $db_connection_key
        } else {
            # Defaults
            $data = @{
                type = 'postgres'
                dbname = 'fieldsets'
                hostname = 'localhost'
                schema = 'fieldsets'
                port = 1022
                user = $null
                password = $null
                dotnet_ver = '8.0'
            }
        }
    } else {
        $db_connection_key = "db_connect_info_$($db_type)"
        $data_json = ConvertTo-JSON -Compress -Depth 3 -InputObject $data
        session_cache_set -Key "$($db_connection_key)" -Type 'object' -Value $data_json -Expires 0
        if ($db_connection_key -ne $default_connection_key) {
            session_cache_set -Key "$($default_connection_key)" -Type 'object' -Value $data_json -Expires 0
        }
    }

    return $data
}
Export-ModuleMember -Function cacheDBConnectInfo

<#
.SYNOPSIS
    Gets the DB connection.

.PARAMETER -type [String]
    Currently only value of 'postgres' is supported.

.OUTPUTS
    [Npgsql.NpgsqlConnection] A Npgsql Connection

.EXAMPLE
    getDBConnection
    Returns: [Npgsql.NpgsqlConnection]

.NOTES
    Added: v0.0
    Updated Date: Apr 25 2025
#>
function getDBConnection {
    Param(
        [Parameter(Mandatory=$false)][String]$type='postgres',
        [Parameter(Mandatory=$false)][String]$dbname = 'fieldsets',
        [Parameter(Mandatory=$false)][String]$hostname = '0.0.0.0',
        [Parameter(Mandatory=$false)][String]$schema = 'fieldsets',
        [Parameter(Mandatory=$false)][Int]$port = 5432,
        [Parameter(Mandatory=$true)][String]$user,
        [Parameter(Mandatory=$true)][String]$password,
        [Parameter(Mandatory=$false)][String]$dotnet_ver = '8.0'
    )
    $db_connection = $null
    if ('postgres' -eq "$($type)") {
        [System.Environment]::SetEnvironmentVariable('PGUSER', $user) | Out-Null
        [System.Environment]::SetEnvironmentVariable('PGPASSWORD', $password) | Out-Null

        $npgsql_package_path = (Get-Package "Npgsql").Source
        $npgsql_path = [System.IO.Path]::GetFullPath((Join-Path -Path "$((Get-Item -Path "$($npgsql_package_path)").Directory)" -ChildPath "./lib/net$($dotnet_ver)/"))
        Push-Location $npgsql_path
        Add-Type -AssemblyName "Npgsql"
        Pop-Location

        $ms_logging_abs_package_path = (Get-Package "Microsoft.Extensions.Logging.Abstractions" -RequiredVersion "$($dotnet_ver).0.0").Source
        $ms_logging_abs_path = [System.IO.Path]::GetFullPath((Join-Path -Path "$((Get-Item -Path "$($ms_logging_abs_package_path)").Directory)" -ChildPath "./lib/net$($dotnet_ver)/"))
        Push-Location $ms_logging_abs_path
        Add-Type -AssemblyName "Microsoft.Extensions.Logging.Abstractions"
        Pop-Location

        if ("0.0.0.0" -eq "$($hostname)") {
            $hostname = 'localhost'
        }

        $db_connection_string = "Host=$($hostname);Port=$($port);Username=$($user);Password=$($password);Database=$($dbname);"

        Write-Host $db_connection_string
        $db_connection = New-Object Npgsql.NpgsqlConnection($db_connection_string)

    }
    return $db_connection
}
Export-ModuleMember -Function getDBConnection



function importJSONFileToDB {
    Param(
        [Parameter(Mandatory=$true)][PSCustomObject]$connection,
        [Parameter(Mandatory=$true)][String]$path,
        [Parameter(Mandatory=$true)][String]$token,
        [Parameter(Mandatory=$true)][String]$source,
        [Parameter(Mandatory=$true)][String]$type,
        [Parameter(Mandatory=$true)][Int]$priority,
        [Parameter(Mandatory=$false)][String]$db_type = 'postgres'
    )

    Write-Host "Importing JSON Data to DB."
    if ("$($db_type)" -eq 'postgres') {
        # On startup always import any schemas and data

        $json =  Get-Content $path -Raw
        $connection.Open()
        $db_command = $connection.CreateCommand()

        $escaped_json = [string]::Format('$JSON${0}$JSON$::JSONB',$json)
        $insert_stmt = "INSERT INTO pipeline.imports(token, source, type, priority, data) VALUES ('$($token)', '$($source)', '$($type)', $($priority), $($escaped_json)) ON CONFLICT DO NOTHING;"

        Write-Host "Executing Statement $($insert_stmt)"
        $db_command.CommandText = $insert_stmt
        $db_command.ExecuteNonQuery() | Out-Null

        $db_command.CommandText = "CALL fieldsets.import_json_data();"
        $db_command.ExecuteNonQuery() | Out-Null

        $connection.Close()
    }
}
Export-ModuleMember -Function importJSONFileToDB