#!/usr/bin/env sh
# A dump of both database instances (ADR-019, Annex J J.5.4): PostgreSQL with pg_dumpall and MongoDB
# with mongodump, into backups/<date>/, keeping the last 7. Run it daily from cron on the host and
# copy backups/ off the machine once a week; a backup that stays on the same disk is not a backup.
# usage: ./scripts/backup.sh [environment=main]
set -eu
cd "$(dirname "$0")/.."
environment="${1:-main}"
env_file="env/${environment}.env"
[ -f "$env_file" ] || { echo "missing $env_file"; exit 1; }
day=$(date +%Y-%m-%d)
target="backups/$day"
mkdir -p "$target"

docker compose --env-file "$env_file" exec -T postgres sh -c 'pg_dumpall -U "$POSTGRES_USER"' \
  | gzip > "$target/postgres.sql.gz"
docker compose --env-file "$env_file" exec -T mongo sh -c \
  'mongodump --quiet --archive --gzip -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin' \
  > "$target/mongo.archive.gz"

ls -1d backups/*/ | sort | head -n -7 | xargs -r rm -rf
echo "backup written to $target ($(du -sh "$target" | cut -f1))"
