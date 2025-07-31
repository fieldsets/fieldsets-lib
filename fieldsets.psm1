$core_module_path = '/usr/local/fieldsets/lib/pwsh/'

$core_modules = Get-Item -Path "$($core_module_path)*.psm1" | Select-Object FullName, Name, BaseName, LastWriteTime, CreationTime

foreach ($core_module in $core_modules) {
    Import-Module $core_module.FullName
}

# After core modules have loaded. Iterate through plugin libs and clobber any aliases or functions.
$plugins_priority_list = getPluginPriorityList
foreach ($plugin_dirs in $plugins_priority_list.Values) {
    foreach ($plugin_dir in $plugin_dirs) {
        $plugin_lib = [System.IO.Path]::GetFullPath((Join-Path -Path $plugin_dir -ChildPath './lib/'))
        if (Test-Path -Path "$($plugin_lib)") {
            $plugin_modules = Get-Item -Path "$($plugin_lib)*.psm1" | Select-Object FullName, Name, BaseName, LastWriteTime, CreationTime
            foreach ($plugin_module in $plugin_modules) {
                # If a plugin utilizes the fieldsets-lib, we want to avoid nesting our libraries. So we won't load any libs named fieldsets.psm1
                if ($plugin_module.Name -ne 'fieldsets.psm1') {
                    Import-Module $plugin_module.FullName
                }
            }
        }
    }
}
Export-ModuleMember -Function *