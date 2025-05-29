#!/bin/bash
set -e

# Correction des permissions (nécessaire car Kubernetes monte avec runAsUser: 0)
mkdir -p /run/postgresql
chown -R postgres:postgres /var/lib/postgresql/data
chown -R postgres:postgres /run/postgresql
chmod 700 /var/lib/postgresql/data

# Variables d'environnement avec valeurs par défaut basées sur votre ConfigMap/Secret
export POSTGRES_DB="${BILLING_DB_NAME:-billing_db}"
export POSTGRES_USER="${BILLING_DB_USER:-admin}"

# Décoder le mot de passe de base64 en string
if [ -n "$BILLING_DB_PASSWORD" ]; then
    export POSTGRES_PASSWORD=$(echo "$BILLING_DB_PASSWORD" | base64 -d)
    echo "Mot de passe décodé depuis base64"
else
    export POSTGRES_PASSWORD="passer"
    echo "Utilisation du mot de passe par défaut"
fi

# Initialiser la base si elle n'existe pas
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initialisation de PostgreSQL..."
    
    # Initialiser avec l'utilisateur postgres
    su-exec postgres initdb -D "$PGDATA" --auth-host=md5 --auth-local=trust
    
    # Configurer PostgreSQL pour accepter les connexions externes
    echo "host all all all md5" >> "$PGDATA/pg_hba.conf"
    echo "listen_addresses='*'" >> "$PGDATA/postgresql.conf"
    echo "port = 5432" >> "$PGDATA/postgresql.conf"
    
    # Marquer que l'initialisation est nécessaire
    NEED_INIT=true
else
    echo "PostgreSQL déjà initialisé, vérification des utilisateurs..."
    NEED_INIT=false
fi

# Démarrer PostgreSQL temporairement pour créer/vérifier la base et l'utilisateur
echo "Démarrage temporaire de PostgreSQL pour configuration..."
su-exec postgres pg_ctl -D "$PGDATA" start -w -o "-F"

# Attendre que PostgreSQL soit prêt
sleep 3

# Créer la base de données et l'utilisateur si nécessaire
if [ "$NEED_INIT" = true ]; then
    echo "Création de la base de données et de l'utilisateur..."
    su-exec postgres psql -v ON_ERROR_STOP=1 <<-EOSQL
        CREATE DATABASE ${POSTGRES_DB};
        CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
        ALTER USER ${POSTGRES_USER} CREATEDB;
EOSQL
    
    # Se connecter à la base créée pour donner les permissions sur le schéma public
    su-exec postgres psql -d ${POSTGRES_DB} -v ON_ERROR_STOP=1 <<-EOSQL
        GRANT ALL ON SCHEMA public TO ${POSTGRES_USER};
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${POSTGRES_USER};
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${POSTGRES_USER};
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${POSTGRES_USER};
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${POSTGRES_USER};
EOSQL
else
    # Vérifier si l'utilisateur existe, sinon le créer
    echo "Vérification de l'existence de l'utilisateur ${POSTGRES_USER}..."
    USER_EXISTS=$(su-exec postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${POSTGRES_USER}';" || echo "")
    
    if [ -z "$USER_EXISTS" ]; then
        echo "Création de l'utilisateur ${POSTGRES_USER}..."
        su-exec postgres psql -v ON_ERROR_STOP=1 <<-EOSQL
            CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
            ALTER USER ${POSTGRES_USER} CREATEDB;
EOSQL
    fi
    
    # Vérifier si la base existe, sinon la créer
    echo "Vérification de l'existence de la base ${POSTGRES_DB}..."
    DB_EXISTS=$(su-exec postgres psql -tAc "SELECT 1 FROM pg_database WHERE datname='${POSTGRES_DB}';" || echo "")
    
    if [ -z "$DB_EXISTS" ]; then
        echo "Création de la base de données ${POSTGRES_DB}..."
        su-exec postgres psql -v ON_ERROR_STOP=1 <<-EOSQL
            CREATE DATABASE ${POSTGRES_DB};
EOSQL
    fi
    
    # S'assurer que l'utilisateur a les permissions sur la base ET le schéma public
    su-exec postgres psql -v ON_ERROR_STOP=1 <<-EOSQL
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
EOSQL
    
    su-exec postgres psql -d ${POSTGRES_DB} -v ON_ERROR_STOP=1 <<-EOSQL
        GRANT ALL ON SCHEMA public TO ${POSTGRES_USER};
        GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ${POSTGRES_USER};
        GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ${POSTGRES_USER};
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO ${POSTGRES_USER};
        ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO ${POSTGRES_USER};
EOSQL
fi

echo "Configuration terminée. Base: ${POSTGRES_DB}, Utilisateur: ${POSTGRES_USER}"

# Arrêter PostgreSQL
su-exec postgres pg_ctl -D "$PGDATA" stop -w

# Démarrer PostgreSQL de façon permanente
echo "Démarrage de PostgreSQL..."
exec su-exec postgres postgres -D "$PGDATA"