#===
# Event Includes
# See shell coding standards for details of formatting. 
# https://github.com/Fieldsets/fieldsets-pipeline/blob/main/docs/developer/coding-standards/shell.md
#===

#===
# Functions
#===

##
# event_emitter: Print JSON to our event listener
# @param STRING: event_name
# @param STRING: pipeline_name
# @param JSON: metadata
#
# @requires PROGRAM: fluent-bit
# @requires PROGRAM: jq
##
event_emitter() {
    local event_name="$1"
    local pipeline_name="${2:-all}"
    local status="${3:-pending}"
    local metadata="${4:-\{\}}"
    local db_schema="${PGOPTIONS}"
    local metadata_json

    export PGOPTIONS='-c search_path=pipeline'

    metadata_json=$(printf '%s' "${metadata}" | jq 'if has("meta_data") then .meta_data else . end')

    printf '{"fieldsets_event": "%s", "pipeline": "%s", "event_status": "%s", "meta_data": %s}' "${event_name}" "${pipeline_name}" "${status}" "${metadata_json}" | jq '.' | fluent-bit -i stdin -t "event_log" -o forward -p "Host=${EVENT_LOGGER_HOST:-0.0.0.0}" -p "Port=${EVENT_LOGGER_PORT:-24224}"

    # Set PGOPTIONS back in case this shared functiion is called with this value set.
    export PGOPTIONS="${db_schema}"
}

##
# update_event: Update an existing event entry
# @param JSON: event_json
##
update_event() {
    export PGPASSWORD=${POSTGRES_PASSWORD}
    local event_json=$1
    local sql_stmt

    sql_stmt=$(printf "CALL pipeline.fieldsets_emit_event('%s'::JSON);" "${event_json}")
    psql -v ON_ERROR_STOP=1 --host "$POSTGRES_HOST" --port "$POSTGRES_PORT" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -c "${sql_stmt}"
}

##
# trap_failed_event: Log error into events
##
trap_failed_event() {
    local error_code=$1
    local event_json=$2
     
    event_json=$(printf '%s' "${event_json}" | jq '.event_status |= "error"')
    event_json=$(printf '%s' "${event_json}" | jq --arg code "${error_code}" --arg cmd "${BASH_COMMAND[*]}" --arg src "${BASH_SOURCE[1]}" --arg linenum "${BASH_LINENO[0]}" '.meta_data.error.error_code |= $code | .meta_data.error.command |= $cmd | .meta_data.error.source |= $src | .meta_data.error.lineno |= $linenum')
    update_event "${event_json}"
}