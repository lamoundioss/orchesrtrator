#!/bin/bash
set -e

# Fonction pour ajuster l'utilisateur postgres
adjust_postgres_user() {
    local current_uid=$(id -u postgres 2>/dev/null || echo "0")
    local current_gid_postgres=$(getent group postgres | cut -d: -f3 2>/dev/null || echo "0")
    
    echo "Current postgres UID: $current_uid, postgres group GID: $current_gid_postgres"
    
    if [ "$current_uid" != "999" ] || [ "$current_gid_postgres" != "999" ]; then
        echo "Adjusting postgres user to UID/GID 999..."
        
        # Installer shadow package pour usermod/groupmod si nécessaire
        apk add --no-cache shadow 2>/dev/null || true
        
        # Modifier le GID du groupe postgres
        if [ "$current_gid_postgres" != "999" ]; then
            groupmod -g 999 postgres
        fi
        
        # Modifier l'UID de l'utilisateur postgres
        if [ "$current_uid" != "999" ]; then
            usermod -u 999 postgres
        fi
        
        echo "Postgres user adjusted successfully"
    else
        echo "Postgres user already has correct UID/GID"
    fi
    
    # Réajuster les permissions
    chown -R postgres:postgres /var/lib/postgresql
}

# Vérification de l'environnement
echo "Current user: $(id)"
echo "PGDATA: $PGDATA"

# Ajuster l'utilisateur postgres si nécessaire
adjust_postgres_user

# Vérifier les permissions sur le répertoire de données
if [ ! -w "$PGDATA" ]; then
    echo "Fixing permissions on $PGDATA"
    chown -R postgres:postgres /var/lib/postgresql
    chmod 700 "$PGDATA"
fi

echo "Final postgres user info: $(getent passwd postgres)"
echo "Contents of data directory: $(ls -la $PGDATA/ 2>/dev/null || echo 'Directory empty or does not exist')"

# Passer à l'utilisateur postgres pour les opérations PostgreSQL
echo "Switching to postgres user for database operations..."

# Initialisation si le répertoire est vide
if [ -z "$(su postgres -c "ls -A $PGDATA" 2>/dev/null)" ]; then
    echo "Initializing PostgreSQL database..."
    
    # Initialisation de la base
    su postgres -c "initdb --auth-host=md5 --auth-local=peer"
    
    # Démarrage temporaire pour la configuration
    su postgres -c "pg_ctl -D $PGDATA -w start"
    
    # Valeurs par défaut si non définies
    MAIN_USER="${POSTGRES_USER:-postgres}"
    MAIN_DB="${POSTGRES_DB:-$MAIN_USER}"
    
    # Configuration des utilisateurs et bases de données
    if [ -n "$POSTGRES_PASSWORD" ]; then
        su postgres -c "psql -v ON_ERROR_STOP=1" <<-EOSQL
            -- Modification du mot de passe de l'utilisateur postgres
            ALTER USER postgres PASSWORD '$POSTGRES_PASSWORD';
EOSQL

        # Création utilisateur principal s'il est différent de postgres
        if [ "$MAIN_USER" != "postgres" ]; then
            su postgres -c "psql -v ON_ERROR_STOP=1" <<-EOSQL
                CREATE USER "$MAIN_USER" WITH PASSWORD '$POSTGRES_PASSWORD';
EOSQL
        fi
        
        # Création utilisateur en lecture seule si défini
        if [ -n "$READONLY_USER" ] && [ -n "$READONLY_PASSWORD" ]; then
            su postgres -c "psql -v ON_ERROR_STOP=1" <<-EOSQL
                CREATE USER "$READONLY_USER" WITH PASSWORD '$READONLY_PASSWORD';
EOSQL
        fi
        
        # Création des bases de données
        if [ "$MAIN_DB" != "postgres" ]; then
            su postgres -c "psql -v ON_ERROR_STOP=1" <<-EOSQL
                CREATE DATABASE "$MAIN_DB" WITH OWNER "$MAIN_USER";
EOSQL
        fi
        
        if [ -n "$APP_DB_NAME" ] && [ "$APP_DB_NAME" != "$MAIN_DB" ]; then
            su postgres -c "psql -v ON_ERROR_STOP=1" <<-EOSQL
                CREATE DATABASE "$APP_DB_NAME" WITH OWNER "$MAIN_USER";
EOSQL
        fi

        # Attribution des permissions en lecture seule si nécessaire
        if [ -n "$READONLY_USER" ] && [ -n "$APP_DB_NAME" ]; then
            su postgres -c "psql -v ON_ERROR_STOP=1 -d $APP_DB_NAME" <<-EOSQL
                GRANT CONNECT ON DATABASE "$APP_DB_NAME" TO "$READONLY_USER";
                GRANT USAGE ON SCHEMA public TO "$READONLY_USER";
                GRANT SELECT ON ALL TABLES IN SCHEMA public TO "$READONLY_USER";
                ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO "$READONLY_USER";
EOSQL
        fi
    fi
    
    # Arrêt propre
    su postgres -c "pg_ctl -D $PGDATA -m fast -w stop"
    
    echo "Database initialization completed."
else
    echo "Database already initialized."
fi

# Démarrage final avec l'utilisateur postgres
echo "Starting PostgreSQL..."
exec su postgres -c "$*"