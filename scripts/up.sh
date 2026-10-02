#!/usr/bin/env sh
# Brings the platform up for one environment (default: dev), then migrates every -db.
# usage: ./scripts/up.sh [dev|qa|main]
set -eu
cd "$(dirname "$0")/.."
environment="${1:-dev}"
env_file="env/${environment}.env"

[ -f "$env_file" ] || { echo "missing $env_file: cp env/${environment}.env.example $env_file and fill it in"; exit 1; }
grep -q '^PG_ADMIN_PASSWORD=.' "$env_file" || { echo "PG_ADMIN_PASSWORD is empty in $env_file"; exit 1; }
grep -q '^JWT_PUBLIC_KEY=.' "$env_file" || { echo "JWT_PUBLIC_KEY is empty: run ./scripts/dev-keys.sh (dev only)"; exit 1; }

docker network inspect platform >/dev/null 2>&1 || docker network create platform
docker compose --env-file "$env_file" up -d --wait postgres
./scripts/migrate.sh "$environment"
docker compose --env-file "$env_file" up -d --build --wait
docker compose --env-file "$env_file" ps
