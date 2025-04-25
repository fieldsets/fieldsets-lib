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
        [Parameter(Mandatory=$false)][String]$type='postgres'
    )
    $db_connection = $null
    if ('postgres' -eq "$($type)") {
        $dotnet_ver = [System.Environment]::GetEnvironmentVariable('DOTNET_VERSION')
        $db_host = [System.Environment]::GetEnvironmentVariable('POSTGRES_HOST')
        $db_port = [System.Environment]::GetEnvironmentVariable('POSTGRES_PORT')
        $db_user = [System.Environment]::GetEnvironmentVariable('POSTGRES_USER')
        $db_password = [System.Environment]::GetEnvironmentVariable('POSTGRES_PASSWORD')
        $db_name = [System.Environment]::GetEnvironmentVariable('POSTGRES_DB')
        [System.Environment]::SetEnvironmentVariable('PGUSER', $db_user) | Out-Null
        [System.Environment]::SetEnvironmentVariable('PGPASSWORD', $db_password) | Out-Null

        $npgsql_package_path = (Get-Package "Npgsql").Source
        $npgsql_path = [System.IO.Path]::GetFullPath((Join-Path -Path "$((Get-Item -Path "$($npgsql_package_path)").Directory)" -ChildPath "./lib/net$($dotnet_ver)/"))
        Push-Location $npgsql_path
        Add-Type -AssemblyName "Npgsql"
        Pop-Location

        $ms_logging_abs_package_path = (Get-Package "Microsoft.Extensions.Logging.Abstractions" -RequiredVersion 8.0.0.0).Source
        $ms_logging_abs_path = [System.IO.Path]::GetFullPath((Join-Path -Path "$((Get-Item -Path "$($ms_logging_abs_package_path)").Directory)" -ChildPath "./lib/net$($dotnet_ver)/"))
        Push-Location $ms_logging_abs_path
        Add-Type -AssemblyName "Microsoft.Extensions.Logging.Abstractions"
        Pop-Location

        if ("0.0.0.0" -eq "$($db_host)") {
            $db_host = 'localhost'
        }

        $db_connection_string = "Host=$($db_host);Port=$($db_port);Username=$($db_user);Password=$($db_password);Database=$($db_name);"
        $db_connection = New-Object Npgsql.NpgsqlConnection($db_connection_string)

    }
    return $db_connection
}
Export-ModuleMember -Function getDBConnection
