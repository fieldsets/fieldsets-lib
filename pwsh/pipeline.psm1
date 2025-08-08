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
    return
}
Export-ModuleMember -Function watchPipelineLoadTargets

