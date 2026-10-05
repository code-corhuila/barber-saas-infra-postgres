#!/usr/bin/env sh
# DEVELOPMENT ONLY. Generates an RS256 key pair in keys/ (git-ignored) and writes into
# env/dev.env the private key identity-auth-api signs with, the public key every service
# validates with, and one service token per calling service, with the service name as `sub`
# (07-api/authentication.md): the workflow's and the worker's. qa and main use
# keys issued by identity-auth and injected as secrets — never these (norm 5.9.2).
set -eu
cd "$(dirname "$0")/.."
env_file="env/dev.env"
[ -f "$env_file" ] || { echo "missing $env_file: cp env/dev.env.example $env_file"; exit 1; }

mkdir -p keys
[ -f keys/jwt-private.pem ] || openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -out keys/jwt-private.pem 2>/dev/null
openssl pkey -in keys/jwt-private.pem -pubout -out keys/jwt-public.pem

# One line with literal \n escapes: that is how an env file holds a PEM.
private_key=$(awk '{ printf "%s\\n", $0 }' keys/jwt-private.pem)
public_key=$(awk '{ printf "%s\\n", $0 }' keys/jwt-public.pem)
workflow_token=$(./scripts/dev-token.sh barber-saas-workflow SERVICE 1440)
worker_token=$(./scripts/dev-token.sh barber-saas-worker SERVICE 1440)

grep -v -e '^JWT_PRIVATE_KEY=' -e '^JWT_PUBLIC_KEY=' -e '^SERVICE_TOKEN=' -e '^WORKFLOW_SERVICE_TOKEN=' -e '^WORKER_SERVICE_TOKEN=' "$env_file" > "$env_file.tmp" || true
printf 'JWT_PRIVATE_KEY="%s"\n' "$private_key" >> "$env_file.tmp"
printf 'JWT_PUBLIC_KEY="%s"\n' "$public_key" >> "$env_file.tmp"
printf 'WORKFLOW_SERVICE_TOKEN=%s\n' "$workflow_token" >> "$env_file.tmp"
printf 'WORKER_SERVICE_TOKEN=%s\n' "$worker_token" >> "$env_file.tmp"
mv "$env_file.tmp" "$env_file"
echo "keys/ and $env_file updated. A user token: ./scripts/dev-token.sh <subject> [role] [minutes]"
