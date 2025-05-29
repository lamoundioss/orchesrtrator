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
export POSTGRES_PASSWORD="${BILLING_DB_PASSWORD:-passer}"

# Initialiser la base si elle n'existe pas
if [ ! -s "$PGDATA/PG_VERSION" ]; then
    echo "Initialisation de PostgreSQL..."
    
    # Initialiser avec l'utilisateur postgres
    su-exec postgres initdb -D "$PGDATA" --auth-host=md5 --auth-local=trust
    
    # Configurer PostgreSQL pour accepter les connexions externes
    echo "host all all all md5" >> "$PGDATA/pg_hba.conf"
    echo "listen_addresses='*'" >> "$PGDATA/postgresql.conf"
    echo "port = 5432" >> "$PGDATA/postgresql.conf"
    
    # Démarrer PostgreSQL temporairement pour créer la base et l'utilisateur
    su-exec postgres pg_ctl -D "$PGDATA" start -w -o "-F"
    
    # Attendre que PostgreSQL soit prêt
    sleep 2
    
    # Créer la base de données et l'utilisateur
    su-exec postgres psql -v ON_ERROR_STOP=1 <<-EOSQL
        CREATE DATABASE ${POSTGRES_DB};
        CREATE USER ${POSTGRES_USER} WITH PASSWORD '${POSTGRES_PASSWORD}';
        GRANT ALL PRIVILEGES ON DATABASE ${POSTGRES_DB} TO ${POSTGRES_USER};
        ALTER USER ${POSTGRES_USER} CREATEDB;
EOSQL
    
    echo "Base de données ${POSTGRES_DB} créée avec utilisateur ${POSTGRES_USER}"
    
    # Arrêter PostgreSQL
    su-exec postgres pg_ctl -D "$PGDATA" stop -w
fi

# Démarrer PostgreSQL de façon permanente
echo "Démarrage de PostgreSQL..."
exec su-exec postgres postgres -D "$PGDATA"