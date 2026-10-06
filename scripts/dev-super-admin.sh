#!/usr/bin/env sh
# Development only: creates the SUPER_ADMIN that signs in to /platform (platform-admin, FR-025).
# No password is versioned: it comes from DEV_SUPER_ADMIN_PASSWORD in env/dev.env, and pgcrypto
# hashes it with BCrypt, which identity-auth-api verifies. Safe to run again: an existing user is
# left as it is. qa and main never get this user; their SUPER_ADMIN is created by hand.
# usage: ./scripts/dev-super-admin.sh
set -eu
cd "$(dirname "$0")/.."
env_file="env/dev.env"
[ -f "$env_file" ] || { echo "missing $env_file"; exit 1; }

email=$(grep '^DEV_SUPER_ADMIN_EMAIL=' "$env_file" | cut -d= -f2-)
password=$(grep '^DEV_SUPER_ADMIN_PASSWORD=' "$env_file" | cut -d= -f2-)
[ -n "$email" ] || email="admin@barbersaas.dev"
[ -n "$password" ] || { echo "DEV_SUPER_ADMIN_PASSWORD is empty in $env_file"; exit 1; }

docker compose --env-file "$env_file" exec -T postgres sh -c 'psql -v ON_ERROR_STOP=1 -q -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
  -v email="$1" -v password="$2"' sh "$email" "$password" <<'SQL'
INSERT INTO identity_auth.app_user (id, barbershop_id, full_name, email, password_hash, role, is_active)
SELECT gen_random_uuid(), NULL, 'Super Admin', :'email', crypt(:'password', gen_salt('bf', 10)), 'SUPER_ADMIN', true
WHERE NOT EXISTS (SELECT 1 FROM identity_auth.app_user WHERE lower(email) = lower(:'email'));
SELECT CASE WHEN count(*) = 1 THEN 'SUPER_ADMIN ready: ' || :'email' ELSE 'not created' END
FROM identity_auth.app_user WHERE lower(email) = lower(:'email') AND role = 'SUPER_ADMIN';
SQL
