# barber-saas-infra-postgres

> Compose/IaC, observability, environments and secrets

Part of the **Barber Saas** distributed system — team `barber-saas`, Grupo 2.
Governance and documentation live in [`barber-saas-docs`](https://github.com/code-corhuila/barber-saas-docs).

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

Full policy: `00-governance/branching-policy.md` in `barber-saas-docs`.

---

## BarberSaaS — what this repository is

The single PostgreSQL instance of the platform and the root composition (ADR-011, course norm
Annex J). It defines the instance, its volume, the extensions and one `<domain>_app` user per
domain; every `barber-saas-<domain>-db` migrates its own schema into it, and every service
connects with its own user. The MongoDB instance is `barber-saas-infra-mongo`, which this root
composition includes: `up.sh` starts both engines and `migrate.sh` prepares both.

### How to start it

**You need:** Git, Docker Desktop (or Docker Engine) with Compose v2.20 or newer, `openssl`, and a
POSIX shell (on Windows, Git Bash). About 6 GB of free RAM for Docker: every service builds its own
image the first time, which takes several minutes.

```bash
mkdir barbersaas && cd barbersaas
git clone https://github.com/code-corhuila/barber-saas-infra-postgres.git
cd barber-saas-infra-postgres
./scripts/clone-all.sh develop          # every other repository as a sibling, named barber-saas-<repo>
cp env/dev.env.example env/dev.env      # set PG_ADMIN_PASSWORD, every *_APP_PASSWORD and the Mongo passwords
./scripts/dev-keys.sh                   # development RS256 keys and the service tokens (aud, scope; 1 day)
./scripts/up.sh dev                     # network, PostgreSQL and MongoDB, migrations of every -db, services
```

The folder names matter: `compose.yml` includes `../barber-saas-<repo>/…`, and a missing sibling makes
`up.sh` fail with the path it could not find. Any value of `env/dev.env` left empty that a service
needs is reported by name before anything starts.

**Check that it runs:** `curl http://localhost:8000/api/v1/barbershops` answers `200` with a JSON
page (the public catalog, through the gateway), and `docker compose --env-file env/dev.env ps` shows
every container `healthy`. The mobile app and the web portals are in `barber-saas-front` and point
to `http://<this machine>:8000`.

`./scripts/dev-super-admin.sh` (development only) creates the `SUPER_ADMIN` of `DEV_SUPER_ADMIN_EMAIL` /
`DEV_SUPER_ADMIN_PASSWORD`, who signs in to *Plataforma*; running it again changes nothing.

`./scripts/migrate.sh dev` applies pending migrations again (a second run applies nothing). It
first re-runs `postgres/init/01-instance.sh`, so after a `git pull` that adds an extension or a
`<domain>_app` user, the next `up.sh` or `migrate.sh` creates it in your existing volume.
`./scripts/down.sh dev` stops everything and keeps the volume. Never use `down -v` in qa or main.

### Personal credentials — never versioned

`env/<environment>.env` holds the real values and is ignored; the `*.env.example` files only name the
variables, empty. `FCM_SERVICE_ACCOUNT_JSON` (push through Firebase) is a personal secret of whoever owns
the Firebase project: leave it empty unless you use your own project, prefer exporting it in your shell
from a file outside the repository over writing it in `env/dev.env`, and never commit, push or share
it. The `Secrets` workflow fails any pull request that carries an env file, a Firebase file, a private
key or an example with a value.

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

### What it runs

Everything the platform needs: PostgreSQL and MongoDB; identity-auth, barbershop, schedule,
appointment, loyalty, finance-inventory, platform-admin (each `-db` and `-api`) and notifications
(on MongoDB); the api-gateway, the workflow (ADR-009) and the worker (ADR-016). Observability
(OpenTelemetry collector, Prometheus, Grafana) starts with `--profile observability`. The public
host adds Caddy with HTTPS on top (`compose.public.yml`, `deploy/azure/README.md`). The front is
built and run from `barber-saas-front`.
