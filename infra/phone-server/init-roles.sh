#!/usr/bin/env bash
set -euo pipefail
# Variables are psql quoted literals, never shell-expanded SQL. No passwords in output.
psql --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" --set ON_ERROR_STOP=1 \
  --set app_password="$FB_PHONE_APP_PASSWORD" \
  --set migrator_password="$FB_PHONE_MIGRATOR_PASSWORD" \
  --set backup_password="$FB_PHONE_BACKUP_PASSWORD" <<'SQL'
CREATE ROLE fb_migrator LOGIN PASSWORD :'migrator_password' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
CREATE ROLE fb_app LOGIN PASSWORD :'app_password' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS;
-- B23 console role. NOLOGIN until the controller's ensure-admin-role step gives it its own private password.
CREATE ROLE fb_admin NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS NOINHERIT;
-- B23b worker role: fb_app's privileges by membership (no SET ROLE). NOLOGIN until ensure-worker-role gives it its password.
CREATE ROLE fb_worker NOLOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION NOBYPASSRLS INHERIT;
GRANT fb_app TO fb_worker WITH INHERIT TRUE, SET FALSE;
-- Complete dumps must read FORCE RLS tables. This role has no writes or administrative rights.
CREATE ROLE fb_backup LOGIN PASSWORD :'backup_password' NOSUPERUSER NOCREATEDB NOCREATEROLE NOREPLICATION BYPASSRLS;
GRANT pg_read_all_data TO fb_backup;
ALTER DATABASE fitness_buddy OWNER TO fb_migrator;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
REVOKE ALL ON DATABASE fitness_buddy FROM PUBLIC;
GRANT CONNECT ON DATABASE fitness_buddy TO fb_app, fb_backup, fb_admin, fb_worker;
SQL
