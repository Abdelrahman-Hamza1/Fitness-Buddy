-- Local development only. Runs on every `make up`, before migrations, so a volume created before a role existed gets it
-- (initdb scripts run only on a fresh volume). Idempotent; keeps the data. B23: the console login fb_admin; B23b: the
-- worker login fb_worker (a member of fb_app that can't SET ROLE to it).
DO $$BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fb_admin') THEN
    CREATE ROLE fb_admin LOGIN PASSWORD 'local-admin-console-only' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'fb_worker') THEN
    CREATE ROLE fb_worker LOGIN PASSWORD 'local-worker-only' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS INHERIT;
  END IF;
END$$;
GRANT fb_app TO fb_worker WITH INHERIT TRUE, SET FALSE;
GRANT CONNECT ON DATABASE fitness_buddy TO fb_admin, fb_worker;
