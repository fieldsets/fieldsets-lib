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
    # Do nothing by default
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
    addActionHook -name 'myActionHook' -callback 'myFunction' -priority 25

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function addActionHook {
    Param (
        [Parameter(Mandatory=$true)][String]$name,
        [Parameter(Mandatory=$false,ParameterSetName='Callback')][String]$callback = $null,
        [Parameter(Mandatory=$false,ParameterSetName='Scriptblock')][ScriptBlock]$scriptblock = $null,
        [Parameter(Mandatory=$false)][Int]$priority = 10
    )
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/' -ChildPath "pwsh"))
    $cache_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./cache.psm1"))
    $utils_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./utils.psm1"))
    Import-Module -Function session_cache_set, session_cache_get, session_cache_key_exists -Name "$($cache_module_path)"
    Import-Module -Function hasKey -Name "$($utils_module_path)"

    # If no key exists, then it has been flushed. Load it from a data file
    $key_exists = session_cache_key_exists -key "actionhook_$($name)"
    $priority_queue = [ordered]@{}
    $existing_priority_queue = @{}
    if ($key_exists) {
        $existing_priority_queue = session_cache_get -key "actionhook_$($name)"
    }

    $parser = $callback
    if ($null -ne $scriptblock) {
        $parser = $scriptblock.ToString()
    }

    $padded_priority = '{0:d2}' -f [Int]$priority
    $priority_key = "priority-$($padded_priority)"
    $has_key = hasKey -Object $existing_priority_queue -Key $priority_key
    if ($has_key) {
        $existing_priority_queue["$($priority_key)"] += $parser
    } else {
        $existing_priority_queue["$($priority_key)"] = @($parser)
    }

    $existing_priority_queue.GetEnumerator() | Sort-Object Name | ForEach-Object{
        if (($null -ne $_.Key) -and ($null -ne $_.Value)) {
            $priority_queue[$_.Key] = $_.Value
        }
    }

    $priority_queue_json = ConvertTo-Json -InputObject $priority_queue -Compress -Depth 10
    session_cache_set -Key "actionhook_$($name)" -Type 'hook' -Value "$($priority_queue_json)" -Expires 0
}
Export-ModuleMember -Function addActionHook

<#
.SYNOPSIS
    Adds an data parsing hook to the data hook priority queue

.EXAMPLE
    addDataHook -name 'myDataHook' -callback 'myFunction' -priority 25

.NOTES
    Added: v0.0
    Updated Date: July 11 2025
#>
function addDataHook {
    Param (
        [Parameter(Mandatory=$true)][String]$name,
        [Parameter(Mandatory=$false,ParameterSetName='Callback')][String]$callback = $null,
        [Parameter(Mandatory=$false,ParameterSetName='Scriptblock')][ScriptBlock]$scriptblock = $null,
        [Parameter(Mandatory=$false)][Int]$priority = 10
    )
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/' -ChildPath "pwsh"))
    $cache_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./cache.psm1"))
    $utils_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./utils.psm1"))
    Import-Module -Function session_cache_set, session_cache_get, session_cache_key_exists -Name "$($cache_module_path)"
    Import-Module -Function hasKey -Name "$($utils_module_path)"

    # If no key exists, then it has been flushed. Load it from a data file
    $key_exists = session_cache_key_exists -key "datahook_$($name)"
    $priority_queue = [ordered]@{}
    $existing_priority_queue = @{}
    if ($key_exists) {
        $existing_priority_queue = session_cache_get -key "datahook_$($name)"
    }

    $parser = $callback
    if ($null -ne $scriptblock) {
        $parser = $scriptblock.ToString()
    }

    $padded_priority = '{0:d2}' -f [Int]$priority
    $priority_key = "priority-$($padded_priority)"
    $has_key = hasKey -Object $existing_priority_queue -Key $priority_key
    if ($has_key) {
        if ($existing_priority_queue["$($priority_key)"] -notcontains $parser) {
            $existing_priority_queue["$($priority_key)"] += $parser
        }
    } else {
        $existing_priority_queue["$($priority_key)"] = @($parser)
    }

    $existing_priority_queue.GetEnumerator() | Sort-Object Name | ForEach-Object{
        if (($null -ne $_.Key) -and ($null -ne $_.Value)) {
            $priority_queue[$_.Key] = $_.Value
        }
    }

    $priority_queue_json = ConvertTo-Json -InputObject $priority_queue -Compress -Depth 10
    session_cache_set -Key "datahook_$($name)" -Type 'hook' -Value $($priority_queue_json) -Expires 0
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
    Param(
        [Parameter(Mandatory=$true)][String]$name
    )
    $module_path = [System.IO.Path]::GetFullPath("/usr/local/fieldsets/lib")
    Import-Module -Name "$($module_path)/fieldsets.psm1"
    $callbacks = session_cache_get -key "actionhook_$($name)"
    if ($null -ne $callbacks) {
        $callbacks.GetEnumerator() | ForEach-Object {
            if (($null -ne $_.Key) -and ($null -ne $_.Value)) {
                $action_list = $_.Value
                foreach ($action in $action_list) {
                    # Check if function exists in scope, otheriwse convert to a scriptblock and execute
                    if (Get-Command "$($action)" -ErrorAction SilentlyContinue) {
                        & "$($action)"
                    } else {
                        $script_block = [ScriptBlock]::Create($action)
                        try {
                            & $script_block
                        } catch {
                            Write-Host "Invalid Command In Action Hook $($name): $($action)"
                        }
                    }
                }
            }
        }
    }
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
    $module_path = [System.IO.Path]::GetFullPath("/usr/local/fieldsets/lib")
    Import-Module -Name "$($module_path)/fieldsets.psm1"
    $callbacks = session_cache_get -key "datahook_$($name)"
    if ($null -ne $callbacks) {
        $callbacks.GetEnumerator() | ForEach-Object {
            if (($null -ne $_.Key) -and ($null -ne $_.Value)) {
                $parser_list = $_.Value
                foreach ($parser in $parser_list) {
                    # Check if function exists in scope, otheriwse convert to a scriptblock and execute
                    if (Get-Command "$($parser)" -ErrorAction SilentlyContinue) {
                        $data = & "$($parser)" -Data $data
                    } else {
                        $script_block = [ScriptBlock]::Create($parser)
                        $parameters = @{
                            ScriptBlock = $script_block
                            ArgumentList = $data
                        }
                        try {
                            $data = Invoke-Command @parameters
                        } catch {
                            Write-Host "Invalid Command In Data Hook $($name): $($parser)"
                        }
                    }
                }
            }
        }
    }
    return $data
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
    addActionHook -Name 'fieldsets_set_local_env' -Callback 'defaultActionHook' -Priority 10
    addActionHook -Name 'fieldsets_set_session_env' -Callback 'defaultActionHook' -Priority 10
    addDataHook -Name 'fieldsets_session_connect_info' -Callback 'getSessionConnectInfo' -Priority 10
    addActionHook -Name 'fieldsets_pre_init_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_init_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_post_init_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_pre_config_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_config_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_post_config_phase' -Callback 'defaultActionHook' -priority 10
    addDataHook -Name 'fieldsets_db_connect_info' -Callback 'getDBConnectInfo' -Priority 10

    addActionHook -Name 'fieldsets_pre_import_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_import_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_post_import_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_pre_run_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_run_phase' -Callback 'defaultActionHook' -priority 10
    addActionHook -Name 'fieldsets_post_run_phase' -Callback 'defaultActionHook' -priority 10

    addDataHook -Name 'fieldsets_add_extract_targets' -Callback 'addExtractTargets' -priority 10
    addDataHook -Name 'fieldsets_add_transform_targets' -Callback 'addTransformTargets' -priority 10
    addDataHook -Name 'fieldsets_add_load_targets' -Callback 'addLoadTargets' -priority 10
}
Export-ModuleMember -Function addCoreHooks