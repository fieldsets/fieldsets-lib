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

source /fieldsets-lib/bash/utils.sh
source /fieldsets-lib/bash/db.sh
source /fieldsets-lib/shell/plugins.sh

##
# init_server: setup container config
##
init() {
    build_plugins
}

#===
# Main
#===
trap traperr ERR

init

((PRIORITY+=1))

