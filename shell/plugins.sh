#===
# Plugin Functions
# See shell coding standards for details of formatting. 
# https://github.com/Fieldsets/fieldsets-pipeline/blob/main/docs/developer/coding-standards/shell.md
#===

#===
# Functions
#===

##
# build_plugins: Run commands during Docker build phase.
# @param : current_container
# @return JSON
# @requires VOLUME: /fieldsets-plugins/
##
build_plugins() {
    local current_container="$1"
    local plugin
    for plugin in /fieldsets-plugins/*/; do
        echo "${plugin}"
    done
}

##
# init_plugins: Run commands during Docker build phase.
# @param : current_container
# @return JSON
# @requires VOLUME: /fieldsets-plugins/
##
init_plugins() {
    local current_container="$1"
    local plugin
    for plugin in /fieldsets-plugins/*/; do
        echo "${plugin}"
    done
}

run_plugins() {

}