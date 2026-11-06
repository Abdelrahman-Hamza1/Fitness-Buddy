-- Local development only. Runs on every `make up`, before migrations, so a volume created before a role existed gets it
-- (initdb scripts run only on a fresh volume). Idempotent; keeps the data. B23: the console login fb_admin.
DO $$BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fb_admin') THEN
    CREATE ROLE fb_admin LOGIN PASSWORD 'local-admin-console-only' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT;
  END IF;
END$$;
GRANT CONNECT ON DATABASE fitness_buddy TO fb_admin;
