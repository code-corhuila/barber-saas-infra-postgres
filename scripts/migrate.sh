#!/usr/bin/env sh
# Applies the pending migrations of every -db repository to the single instance (Annex J J.5.3).
# Running it again applies nothing. In qa and main, back the database up first (J.5.4).
# usage: ./scripts/migrate.sh [dev|qa|main]
set -eu
cd "$(dirname "$0")/.."
environment="${1:-dev}"
env_file="env/${environment}.env"

# PostgreSQL runs the init script only on an empty volume. Run it again first, so an existing
# volume also gets every extension and <domain>_app user added since it was created; a migration
# that needs a new extension (btree_gist for appointment) would fail otherwise. It is idempotent.
docker compose --env-file "$env_file" exec -T postgres sh /docker-entrypoint-initdb.d/01-instance.sh
# The same for MongoDB: mongo-init (barber-saas-infra-mongo) creates the missing <domain>_app users.
docker compose --env-file "$env_file" --profile tooling run --rm mongo-init

runners=$(docker compose --env-file "$env_file" --profile tooling config --services | grep -- '-db-migrate$' || true)
[ -n "$runners" ] || { echo "no -db-migrate runner in the composition"; exit 0; }
for runner in $runners; do
  echo "== $runner"
  docker compose --env-file "$env_file" run --rm "$runner"
done
