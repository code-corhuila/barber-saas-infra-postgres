#!/bin/sh
# Prepares the single PostgreSQL instance (Annex J J.4, J.5.5, J.7). Safe to run again:
# extensions and users are created only when missing. Each -db creates its own schema,
# roles and grants; this script only creates what belongs to the whole instance.
# PostgreSQL runs it once, when the volume is empty; scripts/migrate.sh (and so up.sh) runs it
# again before every migration, so an existing volume gets new extensions and users too.
# By hand:
#   docker compose --env-file env/dev.env exec postgres sh /docker-entrypoint-initdb.d/01-instance.sh
set -eu

create_user() {
  domain="$1"
  password="$2"
  if [ -z "$password" ]; then
    echo "skip ${domain}_app: no password set"
    return 0
  fi
  psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<SQL
SELECT format('CREATE ROLE %I LOGIN PASSWORD %L', '${domain}_app', '${password}')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = '${domain}_app')\gexec
ALTER ROLE ${domain}_app SET search_path = ${domain};
SQL
}

psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<SQL
CREATE EXTENSION IF NOT EXISTS pgcrypto;
-- btree_gist: EXCLUDE constraints that mix = on uuid with && on ranges (appointment double booking)
CREATE EXTENSION IF NOT EXISTS btree_gist;
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
SQL

create_user identity_auth     "${IDENTITY_AUTH_APP_PASSWORD:-}"
create_user barbershop        "${BARBERSHOP_APP_PASSWORD:-}"
create_user schedule          "${SCHEDULE_APP_PASSWORD:-}"
create_user appointment       "${APPOINTMENT_APP_PASSWORD:-}"
create_user loyalty           "${LOYALTY_APP_PASSWORD:-}"
create_user finance_inventory "${FINANCE_INVENTORY_APP_PASSWORD:-}"
create_user platform_admin    "${PLATFORM_ADMIN_APP_PASSWORD:-}"
create_user workflow          "${WORKFLOW_APP_PASSWORD:-}"
