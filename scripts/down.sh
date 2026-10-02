#!/usr/bin/env sh
# Stops the platform of one environment. The volume is kept: it is the history of the system
# (Annex J J.5.4). Never add -v in qa or main.
# usage: ./scripts/down.sh [dev|qa|main]
set -eu
cd "$(dirname "$0")/.."
environment="${1:-dev}"
docker compose --env-file "env/${environment}.env" down
