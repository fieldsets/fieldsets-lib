<#
.SYNOPSIS
    The default Action hook.

.EXAMPLE
    defaultActionHook

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function defaultActionHook {

    return
}
Export-ModuleMember -Function defaultActionHook

<#
.SYNOPSIS
    The default data parser hook.

.EXAMPLE
    defaultDataHook

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function defaultDataHook {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data = @{}
    )
    return $data
}
Export-ModuleMember -Function defaultDataHook


<#
.SYNOPSIS
    Adds an action hook to the action hook priority queue

.EXAMPLE
    addActionHook

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function addActionHook {

    return
}
Export-ModuleMember -Function addActionHook

<#
.SYNOPSIS
    Adds an data parsing hook to the data hook priority queue

.EXAMPLE
    addDataHook

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function addDataHook {
    Param (
        [Parameter(Mandatory=$true)][String]$name,
        [Parameter(Mandatory=$false)][String]$callback = $null,
        [Parameter(Mandatory=$false)][Int]$priority = 99,
        [Parameter(Mandatory=$false)][ScriptBlock]$scriptblock = $null
    )
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/' -ChildPath "pwsh"))
    $cache_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./cache.psm1"))
    Import-Module -Function session_cache_set, session_cache_get, session_cache_key_exists -Name $cache_module_path

    # If no key exists, then it has been flushed. Load it from a data file
    $key_exists = session_cache_key_exists -Name $name
    if ($key_exists) {
        $priority_queue = session_cache_get -Name $name
    } else {
        # See if a local hard copy exists to load into memory. If not just create a new ordered dictionary.
    }
    return
}
Export-ModuleMember -Function addDataHook

<#
.SYNOPSIS
    Perform an action hook using the action hook priority queue

.EXAMPLE
    addActionHook

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function performActionHook {

}
Export-ModuleMember -Function performActionHook

<#
.SYNOPSIS
    Parse data from a data hook using the priority queue

.EXAMPLE
    parseDataHook

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function parseDataHook {
    Param(
        [Parameter(Mandatory=$true)][String]$name,
        [Parameter(Mandatory=$false)][hashtable]$data = @{}
    )
    $module_path = [System.IO.Path]::GetFullPath("/usr/local/fieldsets/lib/pwsh")
    Import-Module -Function -Name "$($module_path)/session.psm1"



}
Export-ModuleMember -Function parseDataHook


<#
.SYNOPSIS
    Add our core action hooks.

.EXAMPLE
    addCoreActionHooks

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function addCoreHooks {
    addActionHook -Name 'fieldsets_init_phase' -Callback 'init_phase' -priority 0 # Non-Existant function. Clobber in plugin to add local services
    addActionHook -Name 'fieldsets_init_local_env' -Callback 'init_local_env' -Priority 0 # Non-Existant function. Clobber in plugin to add local services
    addActionHook -Name 'fieldsets_init_session_env' -Callback 'init_session_env' -Priority 0 # Non-Existant function. Clobber in plugin to add local services
    addDataHook -Name 'fieldsets_session_connect_info' -Callback 'get_session_connect_info' -Priority 0
}
Export-ModuleMember -Function addCoreHooks