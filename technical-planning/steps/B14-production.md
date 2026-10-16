# B14 — Production, backups & go-live

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B13 | L | Codex | ⬜ Not started |

_Old ID: S29 server part (renumbered by TD-063, 2026-10-16)._

**Goal.** A production environment the owner's real data can live in safely: a separate database VM, point-in-time backups to two providers, automated restore tests, alerts and runbooks. The laptop test server's data moves in, and the owner's app switches over to it. **Milestone M7 (production)** together with A43.

**Spec:** SC-6, AT-006, AC-011 · **Decisions:** TD-026, TD-027, TD-028, TD-029

## Scope
- **OpenTofu prod:** app VM, **db VM** with a data volume, private network, firewall rules (Postgres reachable only from the app VM).
- **Postgres 18 on the db VM** per the chosen option (`08` §4: Kamal accessory + WAL-G by default), tuned for the VM size, with roles `fb_app` / `fb_migrator` / backup / read-only.
- **Backups (TD-028):** continuous WAL archiving + daily base backups to object storage in **another data center**. A weekly copy to a **second provider**. 30-day retention.
- **Automated weekly restore test:** restore the latest backup into staging, verify row counts/checksums, report, and **alert on failure or on backup age > 26 h**.
- **Alerts** (`08` §7): 5xx rate, p90 latency, disk > 80%, backup age, restore test failure, certificate expiry, queue stuck. Delivered to the owner.
- **Prod deploys:** tag `api-v*` → approval → migrate → deploy → smoke test → rollback on failure. The minimum app version is configured.
- **Real email sign-in codes:** choose the vendor (Postmark, Amazon SES, Resend…: EU data handling, deliverability, free tier), the `IEmailSender` vendor adapter + its contract tests, the sending domain's DNS records (SPF/DKIM) (moved from B04, TD-064).
- **Move in from the laptop (TD-064), as a written procedure with a staging dry run:** (1) stop the laptop API for good before the dump (anything synced after it would be acked and never re-pushed); (2) a full `pg_dump` (sequences, schema-local migration history, RLS) with `--no-owner`, roles provisioned separately (S04 note); check production `server_seq` ≥ the laptop maximum; (3) move the signing-key encryption secret, then **rotate the JWT signing keys** right after; (4) the phone runs offline until the production-URL build is installed; the sync dataset id (TD-066) makes the app re-push anything the server lacks.
- **Runbooks** (`08` §8): restore to a point in time, rebuild a VM, roll back, rotate secrets/keys, handle a missing-data report, delete an account manually, Postgres upgrades, disk full.
- **A manual restore drill** once: restore prod into a scratch VM, time it, and document it.

## Out of scope
- Stage 2 infrastructure (R3). iOS distribution (R2, D-081).

## Fixed by the plan
- `08` in full: separate db VM from the first real data, backups to two providers, restore tests.

## Decide in the low-level plan
- **The Postgres hosting option** (`08` §4: Kamal accessory + WAL-G vs native + pgBackRest via Ansible).
- The second backup provider. VM sizes. The alert delivery channel.

## Notes from earlier steps
- **From S02 (TD-044):** the first contract tag comes with the first `app-v*` release, in A43 (with Codex for the server gates).

## Exit criteria
- [ ] The restore drill is done: recovery to a chosen point in time within the target (≤ 1 h). Timings are in the runbook.
- [ ] The automated restore test runs green on schedule, and a forced failure alerts the owner.
- [ ] AT-006: fresh install + sign-in on prod restores all data. Export complete.
- [ ] The laptop data is in production (row counts match), the owner's app syncs with production, and nothing was lost (A34's convergence checks green). A prod deploy + rollback has been exercised.
- [ ] A real email sign-in code arrives and works.

## Read first
`08-infrastructure-and-operations.md` (all) · B13 Outcome

## Owner involvement
A second storage provider account (e.g. Backblaze B2), an alert contact, and an email-provider account with access to the domain's DNS. Keep the laptop server on during the move-in.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
