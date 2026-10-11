# 08 — Infrastructure & Operations

_Where the backend runs, how it's deployed, kept safe and observed. Decisions: TD-026 to TD-029. The backend itself: `04`._

## 1. Principles

1. **Servers are cattle, not pets.** Every VM is created by code (OpenTofu + cloud-init) and can be rebuilt in minutes. Nothing is configured by hand over SSH except during an incident, and an incident fix is turned into code afterwards.
2. **One stateful component: Postgres.** Everything else is a stateless container. Backups protect the one thing that matters.
3. **Same image everywhere.** dev (Docker Compose), staging and prod run the same container image, with different configuration.
4. **Boring and documented.** Every operation that matters has a runbook in `docs/runbooks/`.

## 2. Provider & environments

**Hetzner Cloud, Germany** (Nuremberg/Falkenstein), close to the West Bank. VMs, private networks, cloud firewalls, load balancers, volumes and S3-compatible object storage, all from one provider. There is **no managed Postgres**, so we run it ourselves (§5). If that becomes a burden, the fallback is managed Postgres (DigitalOcean, or Ubicloud on Hetzner). The backend only needs a connection string (`02` Appendix A).

| Env | Where | Database | Deploys | Purpose |
|---|---|---|---|---|
| **dev** | Your machine, `docker compose up` | Postgres container | — | Development, tests (Testcontainers) |
| **staging** | 1 small VM (≈ 2 vCPU / 4 GB) | Postgres container on the same VM | Every merge to `main` | Integration, eval runs, release candidates, restore tests |
| **prod** | app VM + **separate** db VM (§3) | Postgres 18 on the db VM, with point-in-time backups | Git tag `api-v*` | The owner (R1), friends (R2), public (R3) |

Supporting services: **GitHub** (code, CI, container registry GHCR) · **Cloudflare** (DNS only) · **Tailscale** (private SSH access) · **Sentry** (errors) · **Grafana Cloud** free tier (metrics, logs, traces) · an **external uptime monitor** · an **email provider** for sign-in codes (chosen in S24).

## 3. Topology

### 3.1 Stage 1: R1 and R2

```
                         Internet (HTTPS only)
                                │  DNS: api.<domain> (Cloudflare, DNS only)
                     ┌──────────▼───────────┐   Hetzner cloud firewall:
                     │ app VM (4 vCPU/8 GB) │   80/443 public · SSH closed publicly
                     │  kamal-proxy (TLS)   │   (SSH via Tailscale only)
                     │  api ×2 · worker ×1  │
                     └──────────┬───────────┘
                    private network (Postgres never public)
                     ┌──────────▼───────────┐       ┌──────────────────────────────┐
                     │ db VM (2–4 vCPU)     │──WAL─►│ object storage, other DC     │
                     │ PostgreSQL 18        │ base  │ + weekly copy, 2nd provider  │
                     │ data on a volume     │backup └──────────────────────────────┘
                     └──────────────────────┘
```

The database has its own VM **from the first real data (Dogfood 1, S29)**, so scaling the API later is just adding app VMs.

### 3.2 Stage 2: R3 (public)

```
          Hetzner Load Balancer (TLS)
            │            │            │
       app VM 1     app VM 2  …  app VM n      stateless api: add/remove freely
       worker VM(s)                            jobs, outbox
       PgBouncer → Postgres primary ──streaming──► replica (failover + catalog reads)
       Valkey/Redis only if measured (shared rate limits, hot caches)
       CDN in front of object storage (catalog packs)
```

### 3.3 Stage 3: if it really takes off

Kubernetes (k3s on VMs, or a managed cluster) with the **same images and the same contract**. Partitioned sync storage, possibly a second region. Nothing from stages 1–2 is thrown away.

### 3.4 Capacity reality check

| Daily active users | Load (≈ 40 API calls per user per day, 10× peak at mealtimes) | Needs |
|---|---|---|
| 1–50 (R1/R2) | negligible | Stage 1, mostly idle |
| 10,000 | ≈ 5 req/s average, ≈ 50 at peak. ≈ 20 AI calls in flight at peak | Stage 1, still one app VM. AI cost and provider rate limits matter more than servers |
| 100,000 | ≈ 50 req/s average, ≈ 500 at peak. Millions of synced rows per day | Stage 2: 3–4 app VMs, a bigger db VM + replica, PgBouncer, partitioning |

**Where growth really hurts:** AI cost and provider limits (handled by routing, caching and allowances), and Postgres write volume from sync (handled by indexes, pooling, then partitioning). The VM count is the easy part.

## 4. Provisioning & deployment

| Concern | Choice |
|---|---|
| Infrastructure as code | **OpenTofu** (open-source Terraform) with the `hcloud` provider: VMs, private network, firewall rules, volumes, load balancer (stage 2), object storage buckets. State stored in a private object-storage bucket. Code in `infra/tofu/` |
| Base OS setup | **cloud-init** (`infra/cloud-init/`): Ubuntu LTS, a non-root deploy user, SSH keys only, Docker, Tailscale, `unattended-upgrades`, fail2ban, time sync, a swap file, log rotation |
| Database host setup | Decided in S29 between (a) Postgres in a container managed as a Kamal *accessory* with WAL-G, and (b) native Postgres from the PGDG apt repository with pgBackRest, configured by a small Ansible playbook. Default: **(a)**, so Kamal remains the one deploy tool |
| Deploys | **Kamal 2**: builds the image (or pulls it from GHCR), starts new containers over SSH, waits for `/health/ready`, switches traffic in kamal-proxy, then stops the old ones. Zero downtime. Automatic Let's Encrypt TLS. `kamal rollback` returns to the previous image in one command |
| Migrations in deploys | The pipeline runs the new image's **`migrate`** command against the database **before** `kamal deploy`. Migrations are always backward-compatible with the running version (expand → migrate → contract, `04` §6) |
| Pipeline | GitHub Actions: build → test → image to GHCR → staging deploy on merge to `main` → prod deploy on tag `api-v*` (manual approval) → smoke test (`/health/ready`, `/v1/config`) → automatic rollback if the smoke test fails |
| Secrets | Never in the repo or the image. GitHub encrypted secrets → Kamal `.kamal/secrets` at deploy time. Separate secrets per environment. Rotation runbook |

## 5. Data safety: backups & restore (SC-6, TD-028)

| Measure | Detail |
|---|---|
| Continuous archiving | **WAL-G** (or pgBackRest) ships WAL segments continuously, plus a **daily base backup**, to object storage in a **different data center** from the db VM |
| Second copy | A weekly job copies the latest base backup + WAL to a **second provider** (e.g. Backblaze B2 or Cloudflare R2). It protects against losing the whole Hetzner account or region |
| Recovery point | **≤ about 1 minute** of data loss (point-in-time recovery). Phones also keep their local copy, so in practice nothing is lost |
| Retention | 30 days (matches the AC-031 promise that deleted accounts disappear from backups within 30 days) |
| **Restore test** | **Automated weekly**: restore the latest backup into staging, run row-count and checksum checks, alert on failure. An untested backup doesn't count |
| VM snapshots | A convenience before risky changes. **Not** a backup |
| Recovery objectives | Recovery point ≤ 1 min. Recovery time ≤ 1 h (rebuild the db VM from code + restore) |

## 6. Security of the servers

- SSH only over **Tailscale**. Public SSH closed at the cloud firewall. Keys only, no root login, no passwords.
- Public ports: 80/443 on the app VM (stage 1) or the load balancer (stage 2). Postgres listens on the private network only.
- `unattended-upgrades` for security patches. A monthly patch window for reboots (Kamal makes rolling restarts safe).
- Containers run as non-root, with read-only filesystems where possible. Images built from minimal bases (`aspnet` chiseled/distroless).
- Dependency and image scanning in CI (GitHub Dependabot, `dotnet list package --vulnerable`, Trivy on images).
- Least privilege in Postgres: an app role (RLS on), a migration role, a backup role, a read-only role for debugging.
- Application-level security is in `04` §5–6 and `09` §4.

## 7. Observability

| Signal | Tool | What |
|---|---|---|
| Traces, metrics, logs | **OpenTelemetry** SDK → OTLP → **Grafana Cloud** (free tier) | Request traces (app → API → Postgres/LLM), RED metrics per endpoint, LLM latency/tokens/cost per task and model, sync volumes, job queue depth. Structured JSON logs **with no user content** (`09` §4) |
| Errors | **Sentry** (app + backend) | Exceptions, release health, scrubbed of personal data |
| Uptime | External monitor (different provider) | `/health/ready` and a synthetic `/v1/config` call every minute |
| Alerts | Grafana alerting → email/phone push | 5xx rate, Buddy p90 > 5 s, AI cost per day over budget, disk > 80%, **backup age > 26 h**, **failed restore test**, certificate expiry, job queue stuck |

If the free tiers run out (R3), the same OpenTelemetry signals can go to a self-hosted Grafana stack on a small ops VM. Nothing in the app changes.

## 8. Runbooks (`docs/runbooks/`, written in S29, kept current)

Restore the database to a point in time · rebuild a VM from code · roll back a deploy · rotate a secret or signing key · handle a "my data is missing" report · delete an account manually · Postgres minor and major upgrades · disk full on the db VM.

## 9. Running cost (estimate, verify at S05/S29)

| Item | Stage 1 |
|---|---|
| app VM (4 vCPU / 8 GB) | ≈ €10–20 /mo |
| db VM + volume | ≈ €10–20 /mo |
| staging VM | ≈ €5 /mo |
| Object storage + second backup copy | ≈ €7–10 /mo |
| Domain | ≈ €1–2 /mo |
| Email, Sentry, Grafana Cloud, Tailscale, uptime monitor | free tiers at this size |
| AI | cents per month for the owner (`06` §10) |
| Google Play (once) / Apple Developer (yearly, when iOS ships) | $25 once / $99 per year |
| **Total** | **≈ €35–55 /mo** + store fees |

**Your time:** about 1–2 hours a month once set up (review alerts and the restore report, apply Postgres minor upgrades). Major Postgres upgrades about once a year (half a day).
