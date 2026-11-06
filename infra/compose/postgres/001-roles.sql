-- Local development only. Production credentials are provisioned by S05, never copied from this file.
CREATE ROLE fb_migrator LOGIN PASSWORD 'local-migrator-only' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE ROLE fb_app LOGIN PASSWORD 'local-app-only' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
-- B23 console login: only its own admin schema (+ later content-free admin_* functions); member of no role.
CREATE ROLE fb_admin LOGIN PASSWORD 'local-admin-console-only' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT;
-- B23b worker login: every fb_app privilege by membership (same RLS policies), plus the worker-only grants (heartbeats, the
-- console counters' cleanup). It can't SET ROLE fb_app, and fb_app is never a member of it.
CREATE ROLE fb_worker LOGIN PASSWORD 'local-worker-only' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS INHERIT;
GRANT fb_app TO fb_worker WITH INHERIT TRUE, SET FALSE;
ALTER DATABASE fitness_buddy OWNER TO fb_migrator;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE fitness_buddy FROM PUBLIC;
GRANT CONNECT ON DATABASE fitness_buddy TO fb_app, fb_admin, fb_worker;
