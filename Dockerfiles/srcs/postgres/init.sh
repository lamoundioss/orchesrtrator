#!/bin/bash
set -e

# Création de l'utilisateur postgres s'il n'existe pas
if ! getent passwd postgres > /dev/null 2>&1; then
    echo "Creating postgres user..."
    addgroup -g 999 postgres 2>/dev/null || true
    adduser -D -u 999 -G postgres -h /var/lib/postgresql -s /bin/bash postgres 2>/dev/null || true
fi

# Vérification des permissions et de l'utilisateur
echo "Current user: $(id)"
echo "User info: $(getent passwd postgres)"
echo "PGDATA: $PGDATA"
echo "Working directory: $(pwd)"
echo "Contents of data directory: $(ls -la $PGDATA/ 2>/dev/null || echo 'Directory empty or does not exist')"

# S'assurer des bonnes permissions
chown -R postgres:postgres /var/lib/postgresql 2>/dev/null || true

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