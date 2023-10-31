
!/usr/bin/env bash



===

 bash-template.sh: A template for your bash scripts

 See shell coding standards for details of formatting.

 https://github.com/Fieldsets/fieldsets-pipeline/blob/main/docs/developer/coding-standards/shell.md



 @envvar VERSION | String 

 @envvar ENVIRONMENT | String



===



et -eEa -o pipefail



===

 Variables

===

xport PGPASSWORD=${POSTGRES_PASSWORD} 

RIORITY=0

ast_checkpoint="/fieldsets-bin/bash-template.sh"



===

 Functions

===



ource /fieldsets-lib/shell/utils.sh

ource /fieldsets-lib/shell/db.sh

ource /fieldsets-lib/shell/plugins.sh



#

 init_server: setup container config

#

nit() {

   build_plugins





===

 Main

===

rap traperr ERR



nit



(PRIORITY+=1))


