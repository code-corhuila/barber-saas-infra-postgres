#!/usr/bin/env sh
# Applies the pending migrations of every -db repository to the single instance (Annex J J.5.3).
# Running it again applies nothing. In qa and main, back the database up first (J.5.4).
# usage: ./scripts/migrate.sh [dev|qa|main]
set -eu
cd "$(dirname "$0")/.."
environment="${1:-dev}"
env_file="env/${environment}.env"

runners=$(docker compose --env-file "$env_file" --profile tooling config --services | grep -- '-db-migrate$' || true)
[ -n "$runners" ] || { echo "no -db-migrate runner in the composition"; exit 0; }
for runner in $runners; do
  echo "== $runner"
  docker compose --env-file "$env_file" run --rm "$runner"
done
