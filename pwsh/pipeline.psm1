<#
.SYNOPSIS
    Add our data extraction scraper script targets.

.EXAMPLE
    addExtractTargets

.NOTES
    Added: v0.0
    Updated Date: July 27 2025
#>
function addExtractTargets {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data = @{}
    )
    return $data
}
Export-ModuleMember -Function addExtractTargets

<#
.SYNOPSIS
    Add our data transformation parser script targets.

.EXAMPLE
    addTransformTargets

.NOTES
    Added: v0.0
    Updated Date: July 27 2025
#>
function addTransformTargets {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data = @{}
    )
    return $data
}
Export-ModuleMember -Function addTransformTargets


<#
.SYNOPSIS
    Add our data loader script targets.

.EXAMPLE
    addLoadTargets

.OUTPUTS
    $data["callback_$($FUNCTION_NAME)"] = @{
        trigger = 'watch'
        callback = 'importJSONFileToDB'
        path = "$($SOURCE_PATH)"
        source = "$($SOURCE_TOKEN)"
        targets = @(
            @{
                target = 'token1.json'
                args = @{
                    token = 'token1'
                    type = 'data'
                    source = "$($SOURCE_TOKEN)"
                    priority = 21
                }
            }
            @{
                target = 'token2.json'
                args = @{
                    token = 'token2'
                    type = 'data'
                    source = "$($SOURCE_TOKEN)"
                    priority = 22
                }
            },
            @{
                target = 'token3.json'
                args = @{
                    token = 'token3'
                    type = 'data'
                    source = "$($SOURCE_TOKEN)"
                    priority = 23
                }
            }
        )
    }

.NOTES
    Added: v0.0
    Updated Date: July 27 2025
#>
function addLoadTargets {
    Param(
        [Parameter(Mandatory=$false)][Hashtable]$data = @{}
    )
    return $data
}
Export-ModuleMember -Function addLoadTargets

<#
.SYNOPSIS
    Watch a given pipeline target file for changes

.EXAMPLE
    watchPipelineTarget

.NOTES
    Added: v0.0
    Updated Date: Aug 6 2025
#>
function watchPipelineTarget {
    Param(
        [Parameter(Mandatory=$true)][String]$location,
        [Parameter(Mandatory=$false,ParameterSetName='Callback')][String]$callback = $null,
        [Parameter(Mandatory=$false,ParameterSetName='Scriptblock')][ScriptBlock]$scriptblock = $null
    )


}
Export-ModuleMember -Function watchPipelineTarget

<#
.SYNOPSIS
    Watch all extract phase target files for changes. Called by action hook fieldsets_watch_extract_targets.

.EXAMPLE
    watchPipelineExtractTargets

.NOTES
    Added: v0.0
    Updated Date: Aug 6 2025
#>
function watchPipelineExtractTargets {
    return
}
Export-ModuleMember -Function watchPipelineExtractTargets

<#
.SYNOPSIS
    Watch all transform phase target files for changes. Called by action hook fieldsets_watch_transform_targets

.EXAMPLE
    watchPipelineTransformTargets

.NOTES
    Added: v0.0
    Updated Date: Aug 6 2025
#>
function watchPipelineTransformTargets {
    return
}
Export-ModuleMember -Function watchPipelineTransformTargets

<#
.SYNOPSIS
    Watch all load phase target files for changes. Called by action hook

.EXAMPLE
    watchPipelineLoadTargets

.NOTES
    Added: v0.0
    Updated Date: Aug 6 2025
#>
function watchPipelineLoadTargets {
    Write-Host "Initializing Watch for load targets."

    $hooks_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/pwsh' -ChildPath "./hooks.psm1"))
    $utils_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/pwsh' -ChildPath "./utils.psm1"))
    Import-Module -Function parseDataHook -Name "$($hooks_module_path)"
    Import-Module -Function hasKey -Name "$($utils_module_path)"
    $stdErrLog = "/data/logs/pipeline.stderr.log"
    $stdOutLog = "/data/logs/pipeline.stdout.log"

    $nohup = (Get-Command nohup).Source

    $load_targets = parseDataHook -Name 'fieldsets_load_targets'

    $load_targets.GetEnumerator() | ForEach-Object {
        $hook_name = $_.Key
        $hook_data = $_.Value
        Write-Host "Hook: $($hook_name)"
        $trigger = $null
        $callback = $null
        $path = $null
        $data_source = $null
        if (hasKey -object $hook_data -key 'trigger') {
            $trigger = $hook_data.('trigger')
            if ($trigger -eq 'watch') {
                $callback = $hook_data.('callback')
                $path = $hook_data.('path')
                if (Test-Path $path) {
                    $data_source = $hook_data.('source')
                    $targets = ConvertTo-JSON -InputObject $hook_data.('targets') -Compress -Depth 10
                    # Encode Target Data to passh to CLI
                    Write-Host "Targets Data: $($targets)"
                    $bytes = [System.Text.Encoding]::Unicode.GetBytes($targets)
                    $encoded_targets = [Convert]::ToBase64String($bytes)
                    #$callback_args = ConvertTo-JSON -InputObject $target_info['args'] -Compress -Depth 10
                    # Start new watcher process for each target
                    $watcherOptions = @{
                        FilePath = $nohup
                        ArgumentList = @("/usr/local/fieldsets/bin/watcher.sh",'load',$data_source,$path,$callback,$encoded_targets)
                        RedirectStandardInput = "/dev/null"
                        RedirectStandardError = $stdErrLog
                        RedirectStandardOutput = $stdOutLog
                    }
                    Write-Host "$(ConvertTo-JSON $watcherOptions)"
                    Start-Process @watcherOptions
                }
            }
        }
    }
    return
}
Export-ModuleMember -Function watchPipelineLoadTargets

<#
.SYNOPSIS
    Schedule all extract phase target files for changes. Called by action hook fieldsets_schedule_extract_targets

.EXAMPLE
    schedulePipelineExtractTargets

.NOTES
    Added: v0.0
    Updated Date: Aug 6 2025
#>
function schedulePipelineExtractTargets {
    return
}
Export-ModuleMember -Function schedulePipelineExtractTargets

<#
.SYNOPSIS
    Schedule all load phase target files for changes. Called by action hook fieldsets_schedule_load_targets

.EXAMPLE
    schedulePipelineLoadTargets

.NOTES
    Added: v0.0
    Updated Date: Aug 6 2025
#>
function schedulePipelineLoadTargets {
    return
}
Export-ModuleMember -Function schedulePipelineLoadTargets

<#
.SYNOPSIS
    Schedule all transform phase target files for changes. Called by action hook fieldsets_schedule_transform_targets

.EXAMPLE
    schedulePipelineTransformTargets

.NOTES
    Added: v0.0
    Updated Date: Aug 6 2025
#>
function schedulePipelineTransformTargets {
    return
}
Export-ModuleMember -Function schedulePipelineTransformTargets