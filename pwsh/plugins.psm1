<#
.Synopsis
Check if current container should execute plugin phases
#>
function isPluginPhaseContainer {
    Param(
        [Parameter(Mandatory=$true,Position=0)][String]$plugin
    )
    $hostname = [System.Environment]::GetEnvironmentVariable('HOSTNAME')

    if (Test-Path -Path "/fieldsets-plugins/$($plugin)/dependencies.json") {
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
    $plugin_dirs = Get-ChildItem -Path "/fieldsets-plugins/*" -Directory |
    Select-Object FullName, Name, LastWriteTime, CreationTime

    # Check to make sure all plugin dependencies are met.
    foreach ($plugin in $plugin_dirs) {
        if (Test-Path -Path "$($plugin.FullName)/dependencies.json") {
            Set-Location -Path $plugin.FullName
            $plugin_deps = Get-Content -Raw -Path "$($plugin.FullName)/dependencies.json" | ConvertFrom-Json -Depth 6
            # If containers are specified, then we make sure we are on the correct container to execute the phase script.
            $hostname = [System.Environment]::GetEnvironmentVariable('HOSTNAME')
            if ($plugin_deps.containers.Length -gt 0) {
                if ($hostname -in $plugin_deps.containers) {
                    Continue
                } else {
                    $dependencies_met = $null
                    Break
                }
            }
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

            if ($plugin_deps.plugins.Length -gt 0) {
                foreach ($plu in $plugin_deps.plugins) {
                    if (Test-Path -Path "/fieldsets-plugins/$($plu.token)/") {
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