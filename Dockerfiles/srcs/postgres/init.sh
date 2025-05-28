#!/bin/bash
set -e

if [ -z "$(ls -A $PGDATA)" ]; then
    su-exec postgres initdb
    
    su-exec postgres pg_ctl -D $PGDATA -w start
    
    # Valeurs par défaut si non définies
    local MAIN_USER="${POSTGRES_USER:-postgres}"
    local MAIN_DB="${POSTGRES_DB:-$MAIN_USER}"
    
    su-exec postgres psql <<-EOSQL
        -- Création utilisateur principal (doit exister dans les Secrets)
        CREATE USER "${MAIN_USER}" WITH PASSWORD '${POSTGRES_PASSWORD}';
        
        -- Création utilisateurs/bases supplémentaires (ConfigMap)
        CREATE USER "${READONLY_USER}" WITH PASSWORD '${READONLY_PASSWORD}';
        CREATE DATABASE "${MAIN_DB}" WITH OWNER "${MAIN_USER}";
        CREATE DATABASE "${APP_DB_NAME}" WITH OWNER "${MAIN_USER}";
        
        -- Permissions
        GRANT CONNECT ON DATABASE "${APP_DB_NAME}" TO "${READONLY_USER}";
        \c "${APP_DB_NAME}"
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO "${READONLY_USER}";
EOSQL

    su-exec postgres pg_ctl -D $PGDATA -m fast -w stop
fi

exec su-exec postgres "$@"