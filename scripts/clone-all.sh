#!/usr/bin/env sh
# Clones every repository of the platform as siblings of this one, with the names compose.yml
# includes (barber-saas-<repo>), on the given branch: what a new host needs (ADR-019).
# usage: ./scripts/clone-all.sh [branch=main]
set -eu
cd "$(dirname "$0")/../.."
branch="${1:-main}"
for repo in infra-mongo api-gateway workflow worker \
            identity-auth-db identity-auth-api barbershop-db barbershop-api schedule-db schedule-api \
            appointment-db appointment-api loyalty-db loyalty-api finance-inventory-db finance-inventory-api \
            notifications-db notifications-api platform-admin-db platform-admin-api; do
  dir="barber-saas-$repo"
  if [ -d "$dir/.git" ]; then
    git -C "$dir" fetch --quiet origin && git -C "$dir" checkout --quiet "$branch" && git -C "$dir" pull --quiet --ff-only
  else
    git clone --quiet --branch "$branch" "https://github.com/code-corhuila/$dir.git" "$dir"
  fi
  echo "$dir $(git -C "$dir" log -1 --format=%h)"
done
