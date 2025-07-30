<#
.Synopsis
Check if current container should execute plugin phases
#>
function isPluginPhaseContainer {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String]$plugin
    )
    $hostname = [System.Environment]::GetEnvironmentVariable('HOSTNAME')
    if (Test-Path -Path "/usr/local/fieldsets/plugins/$($plugin)/dependencies.json") {
        $plugin_deps = Get-Content -Raw -Path "/usr/local/fieldsets/plugins/$($plugin)/dependencies.json" | ConvertFrom-Json
        # If containers are specified, then we make sure we are on the correct container to execute the phase script.
        if ($plugin_deps.containers.Length -gt 0) {
            if ($hostname -in $plugin_deps.containers) {
                return $true
            }
        }
    }
    return $false
}
Export-ModuleMember -Function isPluginPhaseContainer

<#
.Synopsis
Checks a given dependency and returns a boolean if they are met or not. Can return $true, $false or $null. A $null value means the current container is not subject to a dependency check.
#>
function checkDependencies {
    $dependencies_met = $true
    $hostname = [System.Environment]::GetEnvironmentVariable('HOSTNAME')
    $plugin_dirs = Get-ChildItem -Path "/usr/local/fieldsets/plugins/*" -Directory |
    Select-Object FullName, Name, LastWriteTime, CreationTime

    # Check to make sure all plugin dependencies are met.
    foreach ($plugin in $plugin_dirs) {
        if (Test-Path -Path "$($plugin.FullName)/dependencies.json") {
            Set-Location -Path $plugin.FullName
            $plugin_deps = Get-Content -Raw -Path "$($plugin.FullName)/dependencies.json" | ConvertFrom-Json -Depth 6
            # If containers are specified, then we make sure we are on the correct container to execute the phase script.
            if ($plugin_deps.containers.Length -gt 0) {
                if ($hostname -in $plugin_deps.containers) {
                    if ($plugin_deps.packages.Length -gt 0) {
                        try {
                            & "apt-get" update
                            & "apt-get" install -y --no-install-recommends $($plugin_deps.packages)
                        } catch {
                            $dependencies_met = $false
                            Throw "A required package could not be installed"
                        } finally {
                            & "apt-get" autoremove -y
                            & "apt-get" clean -y
                        }
                    }
                }
            }
            if ($plugin_deps.plugins.Length -gt 0) {
                foreach ($plu in $plugin_deps.plugins) {
                    if (Test-Path -Path "/usr/local/fieldsets/plugins/$($plu.token)/") {
                        Continue
                    } else {
                        #TODO: Install plugin if url is specified.
                        $dependencies_met = $false
                        Throw "The plugin $plu is not installed."
                    }
                }
            }
        }
    }
    return $dependencies_met
}
Export-ModuleMember -Function checkDependencies

<#
.SYNOPSIS
    Check the plugin directory and builds a list of plugin priorities. If no plugin.json is found with the priority defined. The default priority of 99 is assigned

.OUTPUTS
    [IOrderedDictionary] An ordered by priority dictionary of plugin directories

.EXAMPLE
    getPluginPriorityList
    Returns: @{"priority-00" = @('/usr/local/fieldsets/plugins/plugin1', '/usr/local/fieldsets/plugins/plugin2');"priority-10"= @('/usr/local/fieldsets/plugins/plugin3'}

.NOTES
    Added: v0.0
    Updated Date: Apr 16 2025
#>
function getPluginPriorityList {
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/' -ChildPath "pwsh"))
    $cache_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./cache.psm1"))
    $priority_list = [Ordered]@{}
    Import-Module -Function session_cache_set, session_cache_get, session_cache_key_exists -Name "$($cache_module_path)"
    if (session_cache_key_exists -key 'fieldsets_plugin_priority') {
        $priority_list = session_cache_get -key 'fieldsets_plugin_priority'
    } else {
        $plugin_dirs = Get-ChildItem -Path "/usr/local/fieldsets/plugins/*" -Directory | Select-Object FullName, Name, BaseName, LastWriteTime, CreationTime
        $plugins = @{}
        foreach ($plugin in $plugin_dirs) {
            $plugin_key = 'plugin-priority-99'
            $plugin_enabled = $true # Enabled by default
            if (Test-Path -Path "$($plugin.FullName)/plugin.json") {
                $plugin_json = Get-Content "$($plugin.FullName)/plugin.json" -Raw | ConvertFrom-Json -Depth 10 -AsHashtable
                if ($plugin_json.ContainsKey('enabled')) {
                    # Make sure it is explicitly set to false. A null or anyother value should mean that it is enabled.
                    if ($false -eq $plugin_json['enabled']) {
                        $plugin_enabled = $false
                    }
                }

                if ($plugin_json.ContainsKey('priority')) {
                    $plugin_priority = $plugin_json['priority']
                    $plugin_key = "plugin-priority-$($plugin_priority)"
                }
            }

            if ($plugin_enabled) {
                if (!($plugins.ContainsKey($plugin_key))) {
                    $plugins[$plugin_key] = [System.Collections.Generic.List[String]]::new()
                }
                $plugins[$plugin_key] += "$($plugin.FullName)"
            }
        }

        $priority_list = [Ordered]@{}
        $plugins.GetEnumerator() | Sort-Object Name | ForEach-Object{
            if (($null -ne $_.Key) -and ($null -ne $_.Value)) {
                $priority_list[$_.Key] = $_.Value
            }
        }
        $priority_list_json = ConvertTo-JSON -Compress -Depth 10 -InputObject $priority_list
        session_cache_set -Key 'fieldsets_plugin_priority' -Type 'object' -Value $priority_list_json -Expires 0
    }
    return $priority_list
}
Export-ModuleMember -Function getPluginPriorityList
