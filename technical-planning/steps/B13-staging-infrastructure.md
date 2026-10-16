# B13 — Staging on Hetzner & deploy pipeline

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | S04 ✅ · code any time; provisioning (cost) starts when the app track reaches **A38** (TD-064) | L | Codex | ⬜ Not started |

_Old ID: S05 (renumbered by TD-063, 2026-10-16)._

**Goal.** A real, hardened staging server on Hetzner, created entirely from code, receiving zero-downtime deploys from CI on every merge, with TLS, private SSH, telemetry, error reporting and uptime alerts. It replaces the laptop test server (B03) for testing, near the end of R1 by the owner's choice (TD-064); B14 builds production on the same code.

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
- Production, db VM, backups and restore tests (B14). The load balancer (R3).

## Fixed by the plan
- Hetzner (Germany), OpenTofu + cloud-init, Kamal 2, GHCR, Tailscale, Cloudflare DNS, Grafana Cloud, Sentry (`08`).
- Migrations run **before** traffic switches, and must be backward-compatible.

## Decide in the low-level plan
- The OpenTofu state backend (Hetzner object storage S3 backend vs another provider's bucket) and how to bootstrap it.
- The image tagging scheme (git SHA + `staging` alias).
- The uptime monitor product (any free one on a different provider).
- The exact VM type (current Hetzner line-up and prices).

## Notes from earlier steps
- **From S06a (updated by TD-064):** the app side moved to A11 (Sentry for the app, the API URL from a CI variable). Here: set the staging build's CI variable to the staging URL (https) and check the app fetches `/v1/config` from staging. Sentry for the server: a project in the EU region with "Prevent storing IP addresses" and server-side scrubbing.

- **From S03:** `/v1/config` synthetic uptime and deploy probes must send `X-App-Version`, `X-Platform` and a fixed UUID `X-Device-Id` (otherwise 400). The chiseled image has no shell/HEALTHCHECK: kamal-proxy probes `/health/ready` at app port 8080. Verify proxy CIDRs/forwarded headers on the real network; local compose binds loopback only. Revisit OTLP exception-type display (`ScrubbedException`; original type in its message) when wiring Grafana. Sentry stays errors-only with local scrubbing.

- **From S04:** api/worker require `ConnectionStrings:Application` (fb_app); only migrate gets `ConnectionStrings:Migrator` (fb_migrator). Provision roles independently of local bootstrap passwords. Migration registry/history is schema-local, with an advisory lock. Carry Postgres privacy settings from compose into the accessory: no ordinary statement-error/parameter logs, FATAL/PANIC infrastructure messages only with terse verbosity. `/health/ready` checks DB availability; outbox/jobs handlers must remain database-only, with stable idempotency keys for future external effects.

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
Create the accounts in `steps/README.md` §3 (Hetzner, domain + Cloudflare, Grafana Cloud; Tailscale and Sentry exist by then) and add the tokens as GitHub secrets (the session lists exactly which).

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
