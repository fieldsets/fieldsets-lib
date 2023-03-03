#===
# DB Includes
# See shell coding standards for details of formatting. 
# https://github.com/Fieldsets/fieldsets-pipeline/blob/main/docs/developer/coding-standards/shell.md
#===

#===
# Functions
#===

##
# fetch_results: Execute a query and return results in a json array that can be parsed with jq.
# @param STRING: query
# @return JSON
# @requires PROGRAM: psql
# @envvar POSTGRES_HOST
# @envvar POSTGRES_PORT
# @envvar POSTGRES_USER
# @envvar POSTGRES_PASSWORD
# @envvar POSTGRES_DB
##
fetch_results() {
    local query="$1"
    local results
    local prev_ifs
    prev_ifs=${IFS}
    export PGPASSWORD=${POSTGRES_PASSWORD}

    results=$(psql -v ON_ERROR_STOP=1 --host "$POSTGRES_HOST" --port "$POSTGRES_PORT" --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" -F $'\",\t\"' -R $'\n' -t -A -c "${query}")

    IFS=$'\n';
    declare -a results_list
    while read -r row; do
        results_list+=("[\"${row}\"]")
    done <<<"${results}"
    echo "${results_list[*]}"
    IFS=${prev_ifs}
}

##
# wait_for_db: check to see if a PostgreSQL db is accepting connections
# @param STRING: dbhost - Postgres DB host address
# @param INT: dbport - DB port number (default 5432)
# @param INT: timeout - Timeout in seconds
# @return STRING/BOOLEAN: String representation of boolean values (true|false)
wait_for_db() {
    local dbhost="${1}"
    local dbport="${2:-5432}"
    local timeout="${3:-60}s"
    
    timeout -s SIGTERM --preserve-status --foreground "${timeout}" bash -c "until pg_isready -h ${dbhost} -p ${dbport}; do printf '.'; sleep 5; done; printf '\n'" > /dev/null 2>&1 || echo "false"
    
    echo "true"
}
