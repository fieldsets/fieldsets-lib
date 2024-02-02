#===
# Util Includes For Shell Scripting
# See shell coding standards for details of formatting. 
# https://github.com/Fieldsets/fieldsets-pipeline/blob/main/docs/developer/coding-standards/shell.md
#===

#===
# Variables
#===

pids=${pids:-()}
last_checkpoint="${last_checkpoint:-}"

#===
# Functions
#===

##
# log: Print a message to STDOUT
# @param STRING: message
##
log() {
    if [[ "${DEBUG_MODE:-true}" = "true" ]]; then
        local message="$1"
        echo "${message}"
    fi
}

##
# traperr: Better error handling
# @depends VAR: ${last_checkpoint}
##
traperr() {
    log "ERROR: Message ${BASH_SOURCE[3]}"
    log "ERROR: ${BASH_COMMAND} failed with error code $?"
    log "ERROR: Function ${FUNCNAME[1]} in ${BASH_SOURCE[1]} at about ${BASH_LINENO[0]}"
    log "Last Checkpoint: ${last_checkpoint}"
    exit
}

##
# wait_for_threads: Look at pids array and wait for all pids to complete.
# @depends VAR: ${pids}
##
wait_for_threads() {
    # Our threads are running in the background. Lets wait for all of them to complete.
    for p in "${pids[@]}";
    do
        log "Waiting for process id ${p}......"
        wait "${p}" 2>/dev/null
        log "Thread with PID ${p} has completed"
    done

    pids=()
}
