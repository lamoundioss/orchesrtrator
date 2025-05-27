-- Créer l'utilisateur s'il n'existe pas
DO
$$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_catalog.pg_roles WHERE rolname = 'admin'
   ) THEN
      CREATE ROLE admin LOGIN PASSWORD 'admin123';
   END IF;
END
$$;

-- Créer la base de données si elle n'existe pas
DO
$$
BEGIN
   IF NOT EXISTS (
      SELECT FROM pg_database WHERE datname = 'billing_db'
   ) THEN
      CREATE DATABASE billing_db OWNER admin;
   END IF;
END
$$;

-- Accorder tous les privilèges
GRANT ALL PRIVILEGES ON DATABASE billing_db TO admin;
