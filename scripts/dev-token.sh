#!/usr/bin/env sh
# DEVELOPMENT ONLY. Prints an RS256 token signed with keys/jwt-private.pem, with the claims
# of 07-api/authentication.md. For a barbershop role, pass the tenant as the fourth argument.
# A user token always carries "aud":"barber-saas-app" (docs#164). A SERVICE token carries the
# called service as `aud` and its space-separated `scope` when given (docs#158, docs#159).
# usage: ./scripts/dev-token.sh [subject] [role] [minutes] [barbershopId] [audience] [scope]
set -eu
cd "$(dirname "$0")/.."
subject="${1:-dev-user}"
role="${2:-CLIENT}"
minutes="${3:-60}"
barbershop="${4:-}"
audience="${5:-}"
scope="${6:-}"
[ -z "$audience" ] && [ "$role" != "SERVICE" ] && audience="barber-saas-app"
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
now=$(date +%s)
tenant=""
[ -n "$barbershop" ] && tenant=$(printf ',"barbershopId":"%s"' "$barbershop")
aud=""
[ -n "$audience" ] && aud=$(printf ',"aud":"%s"' "$audience")
scopes=""
[ -n "$scope" ] && scopes=$(printf ',"scope":"%s"' "$scope")
header=$(printf '{"alg":"RS256","typ":"JWT","kid":"dev-1"}' | b64url)
payload=$(printf '{"iss":"barber-saas-identity-auth-api"%s,"sub":"%s","role":"%s","iat":%s,"exp":%s%s%s}' \
  "$aud" "$subject" "$role" "$now" "$((now + minutes * 60))" "$tenant" "$scopes" | b64url)
signature=$(printf '%s.%s' "$header" "$payload" | openssl dgst -sha256 -binary -sign keys/jwt-private.pem | b64url)
printf '%s.%s.%s\n' "$header" "$payload" "$signature"
