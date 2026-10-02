# barber-saas-infra

> Compose/IaC, observability, environments and secrets

Part of the **LMS Library** distributed system — team `lms-library`, Grupo 2.
Governance and documentation live in [`library-docs`](https://github.com/code-corhuila/library-docs).

## Branching

Three permanent branches. **None of them accepts a direct commit** — you enter through a child
branch and leave through a Pull Request.

```
develop  <--PR--  feat/... fix/... chore/...
qa       <--PR--  qa/...
main     <--PR--  release/...  hotfix/...
```

Promotion happens **by re-application** (`git cherry-pick -x`), never by merging one permanent
branch into another: `merge develop -> qa` and `merge qa -> main` do not exist in this model.

`main` requires **1 approval from `ariel5253`**. On `develop` and `qa` the team sets its own review
rule.

Full policy: `00-governance/branching-policy.md` in `library-docs`.

---

## BarberSaaS — what this repository is

The single PostgreSQL instance of the platform and the root composition (ADR-011, course norm
Annex J). It defines the instance, its volume, the extensions and one `<domain>_app` user per
domain; every `barber-saas-<domain>-db` migrates its own schema into it, and every service
connects with its own user. It is not the MongoDB instance (that is `barber-saas-infra-mongo`).

### How to start it

Clone the repositories as siblings with their full names (`barber-saas-infra`,
`barber-saas-identity-auth-db`, `barber-saas-identity-auth-api`, …), then:

```bash
cd barber-saas-infra
cp env/dev.env.example env/dev.env      # set PG_ADMIN_PASSWORD and every *_APP_PASSWORD
./scripts/dev-keys.sh                   # development RS256 keys and service token
./scripts/up.sh dev                     # network, PostgreSQL, migrations of every -db, services
```

`./scripts/migrate.sh dev` applies pending migrations again (a second run applies nothing).
`./scripts/down.sh dev` stops everything and keeps the volume. Never use `down -v` in qa or main.

### Where the data is

| | Value |
|---|---|
| Database | `barbersaas` (`PG_DATABASE`) in the `postgres` container, port 5432 inside the `platform` network |
| Administrator | `PG_ADMIN_USER` / `PG_ADMIN_PASSWORD` from `env/<environment>.env` (infrastructure and migrations only) |
| Schemas | one per domain: `identity_auth`, `barbershop`, `schedule`, `appointment`, … |
| Look at it | `docker compose --env-file env/dev.env exec postgres psql -U barbersaas_admin -d barbersaas` |

### How it is tested

`./scripts/up.sh dev` waits for every container to be healthy. Annex J's query (J.10) shows that
each `<domain>_app` writes only to its own schema.

### What is missing

Only identity-auth is composed so far; the other domains, the gateway and the front are added to
`include` as they are built. Observability starts with `--profile observability`.
