# S05 — Staging infrastructure & deploy pipeline

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S04 | L | ⬜ Not started |

**Goal.** A real, hardened staging server on Hetzner, created entirely from code, receiving zero-downtime deploys from CI on every merge, with TLS, private SSH, telemetry, error reporting and uptime alerts. This retires the "running our own servers" risk (TR-10) early, while it's cheap.

**Spec:** — (enables every online feature) · **Decisions:** TD-026, TD-027, TD-029

## Scope
- **OpenTofu** (`infra/tofu/`): Hetzner project resources for staging: private network, cloud firewall (80/443 public, nothing else), one VM (≈ 2 vCPU / 4 GB), and an object-storage bucket. Remote state in a private bucket.
- **cloud-init** (`infra/cloud-init/`): Ubuntu LTS, a deploy user with SSH keys only, root login off, Docker, **Tailscale** (SSH only over the tailnet), `unattended-upgrades`, fail2ban, swap, time sync, log rotation.
- **DNS:** `api-staging.<domain>` on Cloudflare (DNS only, no proxy).
- **Kamal 2** (`infra/kamal/`): `api` (2 containers) + `worker` + a **Postgres 18 accessory** on the same VM (staging only), kamal-proxy with Let's Encrypt TLS, health check `/health/ready`, image in GHCR.
- **Pipeline (`api-deploy`):** on merge to `main`, build the image → push to GHCR → run `migrate` with the new image → `kamal deploy` → smoke test (`/health/ready`, `/v1/config`) → automatic `kamal rollback` if the smoke test fails. The workflow reaches the VM through Tailscale (an ephemeral auth key in GitHub secrets).
- **Secrets:** GitHub environment secrets → Kamal secrets. Nothing in the repo or image.
- **Telemetry:** the OTLP exporter → Grafana Cloud (free tier). Sentry DSN for staging. An external uptime monitor on `/health/ready` alerting the owner.
- **Runbooks:** `docs/runbooks/rebuild-staging.md`, `rollback.md`.
- `infra` CI workflow: `tofu fmt`, `validate`, and `plan` as a PR comment (apply is manual).

## Out of scope
- Production, db VM, backups and restore tests (S29). The load balancer (R3).

## Fixed by the plan
- Hetzner (Germany), OpenTofu + cloud-init, Kamal 2, GHCR, Tailscale, Cloudflare DNS, Grafana Cloud, Sentry (`08`).
- Migrations run **before** traffic switches, and must be backward-compatible.

## Decide in the low-level plan
- The OpenTofu state backend (Hetzner object storage S3 backend vs another provider's bucket) and how to bootstrap it.
- The image tagging scheme (git SHA + `staging` alias).
- The uptime monitor product (any free one on a different provider).
- The exact VM type (current Hetzner line-up and prices).

## Notes from earlier steps
- **From S06a:** the app's `staging` flavor points at a `.invalid` placeholder URL with an empty Sentry DSN; set the real URL (https only outside `dev`) and check the app fetches `/v1/config` from staging. Before setting any DSN: native (Java/NDK) Sentry scrubbing or `enableNativeCrashHandling=false` (A5), a native `beforeSendLog`/`beforeSendMetric` that drops everything (sentry_flutter 10 forces native logs/metrics on), and a Sentry project in the EU region with "Prevent storing IP addresses" and server-side scrubbing (backlog #34, #40). Sentry navigation breadcrumbs were deferred to here.

## Exit criteria
- [ ] `tofu apply` from a clean state creates staging. Destroying and re-creating it, then redeploying, works by following the runbook.
- [ ] `https://api-staging.<domain>/v1/config` serves valid TLS and a contract-conformant response.
- [ ] **Zero downtime verified:** a loop of requests during a deploy shows no errors.
- [ ] `kamal rollback` tested. A deliberately broken image is auto-rolled back by the pipeline.
- [ ] Port 22 is closed from the internet (verified from outside). SSH works over Tailscale.
- [ ] A trace from a staging request is visible in Grafana Cloud, a test exception appears in Sentry, and the uptime monitor alerts the owner when the API is stopped.
- [ ] Measured monthly cost recorded in the Outcome.

## Read first
`08-infrastructure-and-operations.md` (all) · `04-backend.md` §3.4

## Owner involvement
Create the accounts in `steps/README.md` §3 (Hetzner, domain + Cloudflare, Tailscale, Grafana Cloud, Sentry) and add the tokens as GitHub secrets (the session lists exactly which).

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
