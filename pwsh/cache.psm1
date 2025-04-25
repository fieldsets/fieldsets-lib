<#
.SYNOPSIS
    cache_get fuction that uses global session variables as our cache. When querying the cache, this function may be overridden using an alternate cache option outside of global session variables.

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

    if ($null -eq $Global:session_cache) {
        Set-Variable -Name session_cache -Value (@{}) -Scope Global -Description "Fieldsets Session Cache"
    }
    $current_cache = (Get-Variable -Name session_cache -Scope Global).Value
    if ($current_cache.ContainsKey($key)) {
        return $current_cache[$key]
    }
    return $null
}
Export-ModuleMember -Function cache_get

<#
.SYNOPSIS
    Aliased cache_set fuction that uses global session variables as our cache. When setting the cache, this function may be overridden(clobbered) using an alternate cache option outside of global session variables.

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
    if ($null -eq $Global:session_cache) {
        Set-Variable -Name session_cache -Value (@{}) -Scope Global -Description "Fieldsets Session Cache"
    }
    $current_cache = (Get-Variable -Name session_cache -Scope Global).Value
    if ($current_cache.ContainsKey($key)) {
        $current_cache.($key) = $value
    } else {
        $current_cache.Add($key,$value)
    }
    Set-Variable -Name session_cache -Value $current_cache -Scope Global -Description "Fieldsets Session Cache"
}
Export-ModuleMember -Function cache_set


<#
.SYNOPSIS
    Aliased cache_key_exists fuction that uses global session variables as our cache. When querying the cache, this function may be overridden using an alternate cache option outside of global session variables.

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

    if ($null -eq $Global:session_cache) {
        Set-Variable -Name session_cache -Value (@{}) -Scope Global -Description "Fieldsets Session Cache"
    }
    $current_cache = (Get-Variable -Name session_cache -Scope Global).Value
    return $current_cache.ContainsKey($key)
}
Export-ModuleMember -Function cache_key_exists
