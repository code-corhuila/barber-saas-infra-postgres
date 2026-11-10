# Deploying on an Azure for Students VM (ADR-020)

The whole platform runs on one VM with the same compose files as a laptop, plus `compose.public.yml` for
HTTPS. It is paid from the subscription's credit: **never** upgrade to pay-as-you-go.

## 1. VM (once)

1. Activate https://azure.microsoft.com/free/students/ with the institutional e-mail. No card is asked.
2. Find what the subscription allows, in Cloud Shell. The region policy and the VM sizes are separate limits,
   and a size can be listed in a region the policy refuses:

   ```bash
   az policy assignment list --query "[].parameters.listOfAllowedLocations.value[]" -o tsv
   ```

3. *Virtual machines → Create → Azure virtual machine*:
   - Region: **Chile Central**. Availability: no infrastructure redundancy. Azure Spot: **off**.
   - Image: **Ubuntu Server 24.04 LTS, x64**. Size: **`Standard_B2as_v2`** (2 vCPU, 8 GB).
   - Username: **`ubuntu`**, which the script below uses. SSH public key: your own.
   - Inbound ports: 22, 80, 443.
   - *Disks*: 64 GiB, standard SSD, locally redundant.
   - *Advanced → Custom data*: paste [`cloud-init.yml`](cloud-init.yml).
4. On the VM's *Public IP address → Configuration*: static assignment and the DNS label `barbersaas`, which gives
   `barbersaas.chilecentral.cloudapp.azure.com`.
5. On the VM's *Network settings*: restrict the SSH rule to your own address. Do **not** open 8000: the gateway
   is reached through Caddy.
6. *Budgets*: a monthly budget of USD 30 with your e-mail, to know before the credit runs out.

## 2. Secrets and keys (on the VM, never copied from a laptop)

```bash
ssh ubuntu@<public-ip>
cloud-init status --wait
cd /opt/barbersaas/barber-saas-infra-postgres
cp env/main.env.example env/main.env
nano env/main.env      # passwords (openssl rand -hex 24), SMTP, PUBLIC_HOST, FCM, Wompi sandbox keys if any
./scripts/dev-keys.sh main 10080    # this host's own RSA pair and service tokens, valid 7 days
```

`env/main.env` and `keys/` stay on the VM only (norm 5.9.2). Keep a copy of `env/main.env` in the team's
password manager, never in git or in a chat.

## 3. Start, migrate, publish

```bash
docker network inspect platform >/dev/null 2>&1 || docker network create platform
docker compose -f compose.yml --env-file env/main.env up -d --wait postgres mongo
./scripts/migrate.sh main
COMPOSE_PARALLEL_LIMIT=2 docker compose -f compose.yml -f compose.public.yml --env-file env/main.env up -d --build --wait
curl https://<PUBLIC_HOST>/health
```

The network is declared external in `compose.yml`, so nothing creates it on a new host. Then create the platform's
SUPER_ADMIN by hand (qa and main never run `dev-super-admin.sh`), register
`https://<PUBLIC_HOST>/api/v1/payments/wompi/events` as the events URL in Wompi's sandbox dashboard, and package the
app against the host (barber-saas-front): `npm run android:package -- --gateway https://<PUBLIC_HOST>`.

`COMPOSE_PARALLEL_LIMIT=2` builds two images at a time. The first build took about 6 minutes on 2026-11-06, and the
platform at rest uses about 2.3 GB of the 8.

## 4. Stopping and starting the VM

- **Stop:** *Virtual machines → barbersaas → Stop*, from the portal, until it says **Stopped (deallocated)**. Only
  then does the VM stop using credit; the disk and the IP still do. Shutting it down from inside keeps it billed.
- **Start:** *Start*. cloud-init installs [`barbersaas.service`](barbersaas.service), which brings the platform up
  at boot, because most containers have no restart policy. A reboot answered `/health` after 45 s on 2026-11-06.
- The IP and the name do not change, so the installed app keeps working. While it is stopped, the app does not
  answer, and reminders and the daily backup do not run.

## 5. Updating to a new release

```bash
cd /opt/barbersaas/barber-saas-infra-postgres
./scripts/backup.sh main                 # always before migrating (Annex J J.5.4)
./scripts/clone-all.sh main && git pull --ff-only
./scripts/migrate.sh main
COMPOSE_PARALLEL_LIMIT=2 docker compose -f compose.yml -f compose.public.yml --env-file env/main.env up -d --build --wait
```

Rollback: check out the previous tag in the repository that broke (`git -C ../barber-saas-<repo> checkout
v<previous>`) and run the last command again. A database change is undone only with its `05_rollbacks`
changeset or the backup.

## 6. Keeping it healthy

- Check the balance in *Education* in the portal. Left on, the VM uses about USD 2.90 of credit a day.
- `cron` runs `./scripts/backup.sh main` every day at 03:00 (cloud-init). Copy `backups/` off the VM
  once a week (`scp -r ubuntu@<ip>:/opt/barbersaas/barber-saas-infra-postgres/backups .`).
- Never `docker compose down -v`: the volumes are the data.
- Service tokens last 7 days (docs#158): `cron` runs `./scripts/dev-keys.sh main 10080` and
  `./scripts/up.sh main` every Sunday at 03:30 (`cloud-init.yml`). The RSA pair is kept, so users stay
  signed in. On a VM created before this change, add that line to `/etc/cron.d/` by hand.
