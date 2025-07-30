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