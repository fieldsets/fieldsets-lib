<#
.Synopsis
Imports variables from a dotenv (.env) file

.Example
# Create regular vars instead of env vars
dotenv -path "~/.env"
#>
function dotenv {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [ValidateNotNullOrEmpty()][String]$path = '.env'
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