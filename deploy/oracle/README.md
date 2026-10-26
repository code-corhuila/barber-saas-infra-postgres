# Deploying `main` on Oracle Cloud Always Free (ADR-019)

The whole platform runs on one Always Free Ampere A1 (ARM) VM with the same compose files as a laptop,
plus `compose.public.yml` for HTTPS. Zero cost: the account must stay on the free tier, **never**
upgraded to "Pay As You Go".

## 1. Account and VM (once)

1. Create an Oracle Cloud Free Tier account (https://www.oracle.com/cloud/free/). A card is asked only to
   verify identity. Choose the home region carefully: Always Free resources exist only there.
2. *Compute → Instances → Create instance*:
   - Image: **Canonical Ubuntu 24.04**. Shape: **Ampere → VM.Standard.A1.Flex**, 4 OCPU and 24 GB
     (the Always Free limit). If it answers "Out of host capacity", try another availability domain or
     try again later.
   - Add your SSH public key.
   - *Show advanced options → Management → Initialization script*: paste
     [`cloud-init.yml`](cloud-init.yml).
3. *Networking → the instance's VCN → Security List*: add ingress rules for TCP **80** and **443** from
   `0.0.0.0/0`. Keep **22** only for your own IP. Do **not** open 8000: the gateway is reached through
   Caddy.
4. A free name for the public IP, for example DuckDNS (https://www.duckdns.org): `barbersaas.duckdns.org`
   pointing to the VM's public IP.

## 2. Secrets and keys (on the VM, never copied from a laptop)

```bash
ssh ubuntu@<public-ip>
cd /opt/barbersaas/barber-saas-infra-postgres
cp env/main.env.example env/main.env
nano env/main.env      # passwords (openssl rand -base64 24), SMTP, PUBLIC_HOST, Wompi sandbox keys, FCM
./scripts/dev-keys.sh main 525600   # this host's own RSA pair and service tokens, valid one year
```

`env/main.env` and `keys/` stay on the VM only (norm 5.9.2). Keep a copy of `env/main.env` in the team's
password manager, never in git or in a chat.

## 3. Start, migrate, publish

```bash
docker compose -f compose.yml --env-file env/main.env up -d --wait postgres mongo
./scripts/migrate.sh main
docker compose -f compose.yml -f compose.public.yml --env-file env/main.env up -d --build --wait
curl https://<PUBLIC_HOST>/health
```

Then create the platform's SUPER_ADMIN by hand (qa and main never run `dev-super-admin.sh`), register
`https://<PUBLIC_HOST>/api/v1/payments/wompi/events` as the events URL in Wompi's sandbox dashboard, and
package the app against the host (barber-saas-front):
`npm run android:package -- --gateway https://<PUBLIC_HOST>`.

## 4. Updating to a new release

```bash
cd /opt/barbersaas/barber-saas-infra-postgres
./scripts/backup.sh main                 # always before migrating (Annex J J.5.4)
./scripts/clone-all.sh main && git pull --ff-only
./scripts/migrate.sh main
docker compose -f compose.yml -f compose.public.yml --env-file env/main.env up -d --build --wait
```

Rollback: check out the previous tag in the repository that broke (`git -C ../barber-saas-<repo> checkout
v<previous>`) and run the last command again. A database change is undone only with its `05_rollbacks`
changeset or the backup.

## 5. Keeping it healthy

- `cron` runs `./scripts/backup.sh main` every day at 03:00 (cloud-init). Copy `backups/` off the VM
  once a week (`scp -r ubuntu@<ip>:/opt/barbersaas/barber-saas-infra-postgres/backups .`).
- Never `docker compose down -v`: the volumes are the data.
- Service tokens last one year: run `./scripts/dev-keys.sh main 525600` again before they expire, then
  `up -d` again. The RSA pair is kept, so users stay signed in.
