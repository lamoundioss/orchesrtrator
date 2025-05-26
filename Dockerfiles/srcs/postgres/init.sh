#!/bin/bash
set -e

# Vérifier si la base doit être initialisée
if [ -z "$(ls -A /var/lib/postgresql/data)" ]; then
    echo "Initializing PostgreSQL database..."
    
    # Initialisation de la base
    initdb -D /var/lib/postgresql/data
    
    # Configuration
    echo "host all all 0.0.0.0/0 md5" >> /var/lib/postgresql/data/pg_hba.conf
    echo "listen_addresses='*'" >> /var/lib/postgresql/data/postgresql.conf

    # Démarrage temporaire
    pg_ctl -D /var/lib/postgresql/data -o '-c listen_addresses=localhost' -w start

    # Configuration utilisateur et base
    psql -v ON_ERROR_STOP=1 --username postgres <<-EOSQL
        ALTER USER ${POSTGRES_USER:user} WITH PASSWORD '${POSTGRES_PASSWORD:-test}';
        CREATE DATABASE ${POSTGRES_DB:-db};
EOSQL

    # Arrêt propre
    pg_ctl -D /var/lib/postgresql/data -m fast -w stop
    
    echo "PostgreSQL initialization complete!"
fi

# Démarrer PostgreSQL
exec "$@"