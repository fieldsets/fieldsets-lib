<#
    .SYNOPSIS
    Get the field schema as a powershell dictionary

    .PARAMETER -defaults [System.Collections.IDictionary]
    Default values to use in the schema

    .OUTPUTS
    [System.Collections.Specialized.IOrderedDictionary] An ordered dictionary representing the schema

    .EXAMPLE
    fetchFieldSchema -defaults (@{type='field'})
    Returns:
        [ordered]@{
            id = $null;
            token = $null
            label = $null
            type = 'field'
            parent = $null
            parent_token = $null
            default_value = $null
            store = $null
            meta = @{}
        }

    .NOTES
    Added Version: 1.0.0
    Added Date: Apr 23 2025
    Updated Date: Apr 23 2025
#>
function fetchFieldSchema {
    Param(
        [Parameter(Mandatory=$false)][System.Collections.IDictionary]$defaults = $null
    )
    $schema = [ordered]@{
        id = $null
        token = $null
        label = $null
        type = $null
        parent = $null
        parent_token = $null
        default_value = $null
        store = $null
        meta = @{}
    }
    if ($null -ne $defaults) {
        foreach ($entry in $defaults.GetEnumerator()) {
            $schema.("$($entry.Key)") = $entry.Value
        }
    }
    return [System.Collections.Specialized.IOrderedDictionary]$schema
}
Export-ModuleMember -Function fetchFieldSchema

<#
    .SYNOPSIS
    Get the set schema as a powershell dictionary

    .PARAMETER -defaults [System.Collections.IDictionary]
    Default values to use in the schema

    .OUTPUTS
    [System.Collections.Specialized.IOrderedDictionary] An ordered dictionary representing the schema

    .EXAMPLE
    fetchSetSchema -defaults (@{id=1;token='set';label='Default Set'})
    Returns:
        [ordered]@{
            id = 1;
            token = 'set'
            label = 'Default Set'
            parent = $null
            parent_token = $null
            meta = @{}
        }

    .NOTES
    Added Version: 1.0.0
    Added Date: Apr 23 2025
    Updated Date: Apr 23 2025
#>
function fetchSetSchema {
    Param(
        [Parameter(Mandatory=$false)][System.Collections.IDictionary]$defaults = $null
    )
    $schema = [ordered]@{
        id = $null
        token = $null
        label = $null
        parent = $null
        parent_token = $null
        meta = @{}
    }
    if ($null -ne $defaults) {
        foreach ($entry in $defaults.GetEnumerator()) {
            $schema.("$($entry.Key)") = $entry.Value
        }
    }
    return [System.Collections.Specialized.IOrderedDictionary]$schema

}
Export-ModuleMember -Function fetchSetSchema

<#
    .SYNOPSIS
    Get the fieldset schema as a powershell dictionary

    .PARAMETER -defaults [System.Collections.IDictionary]
    Default values to use in the schema

    .OUTPUTS
    [System.Collections.Specialized.IOrderedDictionary] An ordered dictionary representing the schema

    .EXAMPLE
    fetchFieldSetSchema -defaults (@{type='field'})
    Returns:
        [ordered]@{
            id = $null;
            token = $null
            label = $null
            parent = $null
            parent_token = $null
            set_id = $null
            set_token = $null
            field_id = $null
            field_token = $null
            type = 'field'
            store = $null
        }

    .NOTES
    Added Version: 1.0.0
    Added Date: Apr 23 2025
    Updated Date: Apr 23 2025
#>
function fetchFieldSetSchema {
    Param(
        [Parameter(Mandatory=$false)][System.Collections.IDictionary]$defaults = $null
    )
    $schema = [ordered]@{
        id = $null
        token = $null
        label = $null
        parent = $null
        parent_token = $null
        set_id = $null
        set_token = $null
        field_id = $null
        field_token = $null
        type = $null
        store = $null
    }
    if ($null -ne $defaults) {
        foreach ($entry in $defaults.GetEnumerator()) {
            $schema.("$($entry.Key)") = $entry.Value
        }
    }
    return [System.Collections.Specialized.IOrderedDictionary]$schema

}
Export-ModuleMember -Function fetchFieldSetSchema

function loadSchemas {
    $module_path = [System.IO.Path]::GetFullPath((Join-Path -Path '/usr/local/fieldsets/lib/' -ChildPath "pwsh"))
    $plugins_module_path = [System.IO.Path]::GetFullPath((Join-Path -Path $module_path -ChildPath "./plugins.psm1"))
    Import-Module -Function buildPluginPriortyList -Name $plugins_module_path

    # Iterate through plugins and export individual functions
    #. (Join-Path -Path $module_path -ChildPath "getDisplayNameEmailAddress.ps1")
    #. (Join-Path -Path $module_path -ChildPath "getMailboxMessages.ps1")
    #. (Join-Path -Path $module_path -ChildPath "moveEmailMessage.ps1")

    #Export-ModuleMember -Function getDisplayNameEmailAddress, getMailboxMessages, moveEmailMessage
}
