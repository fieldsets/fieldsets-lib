<#
.SYNOPSIS
    Gets the Authentication infor to create a DB connection. This is the default function for the get_db_connect_info Data Hook.

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
        [Parameter(Mandatory=$false)][Hashtable]$data=@{}
    )
    if ('postgres' -eq "$($data['type'])") {
        if (($data.ContainsKey('hostname')) -and ("0.0.0.0" -eq "$($data['hostname'])")) {
            $data['hostname'] = 'localhost'
        }
        if (!($data.ContainsKey('dotnet_ver'))) {
            $data['dotnet_ver'] = '8.0'
        }
    }
    return $data
}
Export-ModuleMember -Function getDBConnectInfo

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
        $db_connection = New-Object Npgsql.NpgsqlConnection($db_connection_string)

    }
    return $db_connection
}
Export-ModuleMember -Function getDBConnection
