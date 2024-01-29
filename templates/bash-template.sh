#!/usr/bin/env bash

#===
# bash-template.sh: A template for your bash scripts
# See shell coding standards for details of formatting.
# https://github.com/Fieldsets/fieldsets-pipeline/blob/main/docs/developer/coding-standards/shell.md
#
# @envvar VERSION | String
# @envvar ENVIRONMENT | String
#
#===

set -eEa -o pipefail

#===
# Variables
#===
export PGPASSWORD=${POSTGRES_PASSWORD}
PRIORITY=0
last_checkpoint="/fieldsets-bin/bash-template.sh"

#===
# Functions
#===

source /fieldsets-lib/shell/utils.sh
source /fieldsets-lib/shell/db.sh

##
# init_server: setup container config
##
init() {
    local dbready
    local query
    local results

    # How to run a simple DB query.
    dbready=$(wait_for_db "$POSTGRES_HOST" 5432 60)
    if [[ "$dbready" = "true" ]]; then
        query="SELECT * from cron.job_run_details;"
        results=$(fetch_results "${query}")
        while read -r row; do
            echo "${row}" | jq '.'
        done <<<"${results}"
    fi
}

#===
# Main
#===
trap traperr ERR

init

((PRIORITY+=1))

