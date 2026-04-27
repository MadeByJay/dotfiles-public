# Database shell functions
# Credentials sourced from secrets.zsh: PGHOST_DEV, PGPORT_DEV, PGDATABASE_DEV, PGUSER_DEV, PGPASSWORD_DEV

_psql_check_creds() {
    if [[ -z "$PGHOST_DEV" || -z "$PGUSER_DEV" || -z "$PGPASSWORD_DEV" ]]; then
        echo "error: PGHOST_DEV, PGUSER_DEV, PGPASSWORD_DEV not set — source secrets.zsh" >&2
        return 1
    fi
}

# psql-dev [extra args]
# Connect to dev postgres. Requires VPN.
psql-dev() {
    _psql_check_creds || return 1
    PGPASSWORD="$PGPASSWORD_DEV" psql \
        -h "$PGHOST_DEV" \
        -p "${PGPORT_DEV:-5432}" \
        -U "$PGUSER_DEV" \
        -d "${PGDATABASE_DEV:-adfilter}" \
        "$@"
}

# psql-dev-query "SELECT * FROM ..."
# Run a single query and exit
psql-dev-query() {
    _psql_check_creds || return 1
    local query="${1:?usage: psql-dev-query \"SELECT ...\"}"
    PGPASSWORD="$PGPASSWORD_DEV" psql \
        -h "$PGHOST_DEV" \
        -p "${PGPORT_DEV:-5432}" \
        -U "$PGUSER_DEV" \
        -d "${PGDATABASE_DEV:-adfilter}" \
        -c "$query"
}
