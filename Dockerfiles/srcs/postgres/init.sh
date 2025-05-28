#!/bin/bash
set -e

# Vérification des permissions
echo "Current user: $(id)"
echo "PGDATA: $PGDATA"
echo "Contents of data directory: $(ls -la $PGDATA/ 2>/dev/null || echo 'Directory empty or does not exist')"

# Initialisation si le répertoire est vide
if [ -z "$(ls -A $PGDATA 2>/dev/null)" ]; then
    echo "Initializing PostgreSQL database..."
    
    # Initialisation de la base
    initdb --auth-host=md5 --auth-local=peer
    
    # Démarrage temporaire pour la configuration
    pg_ctl -D $PGDATA -w start
    
    # Valeurs par défaut si non définies
    MAIN_USER="${POSTGRES_USER:-postgres}"
    MAIN_DB="${POSTGRES_DB:-$MAIN_USER}"
    
    # Configuration des utilisateurs et bases de données
    if [ -n "$POSTGRES_PASSWORD" ]; then
        psql -v ON_ERROR_STOP=1 <<-EOSQL
            -- Modification du mot de passe de l'utilisateur postgres
            ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';
            
            -- Création utilisateur principal s'il est différent de postgres
            $([ "$MAIN_USER" != "postgres" ] && echo "CREATE USER \"$MAIN_USER\" WITH PASSWORD '$POSTGRES_PASSWORD';")
            
            -- Création utilisateur en lecture seule si défini
            $([ -n "$READONLY_USER" ] && [ -n "$READONLY_PASSWORD" ] && echo "CREATE USER \"$READONLY_USER\" WITH PASSWORD '$READONLY_PASSWORD';")
            
            -- Création des bases de données
            $([ "$MAIN_DB" != "postgres" ] && echo "CREATE DATABASE \"$MAIN_DB\" WITH OWNER \"$MAIN_USER\";")
            $([ -n "$APP_DB_NAME" ] && [ "$APP_DB_NAME" != "$MAIN_DB" ] && echo "CREATE DATABASE \"$APP_DB_NAME\" WITH OWNER \"$MAIN_USER\";")
EOSQL

        # Attribution des permissions en lecture seule si nécessaire
        if [ -n "$READONLY_USER" ] && [ -n "$APP_DB_NAME" ]; then
            psql -v ON_ERROR_STOP=1 -d "$APP_DB_NAME" <<-EOSQL
                GRANT CONNECT ON DATABASE "$APP_DB_NAME" TO "$READONLY_USER";
                GRANT USAGE ON SCHEMA public TO "$READONLY_USER";
                GRANT SELECT ON ALL TABLES IN SCHEMA public TO "$READONLY_USER";
                ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "$READONLY_USER";
EOSQL
        fi
    fi
    
    # Arrêt propre
    pg_ctl -D $PGDATA -m fast -w stop
    
    echo "Database initialization completed."
else
    echo "Database already initialized."
fi

# Démarrage final
echo "Starting PostgreSQL..."
exec "$@"