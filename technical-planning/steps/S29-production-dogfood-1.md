# S29 — Production environment & Dogfood 1 release

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P3 Accounts, sync & prod | S27, S28 | L | ⬜ Not started |

**Goal.** A production environment the owner's real data can live in safely: a separate database VM, point-in-time backups to two providers, automated restore tests, alerts, runbooks, and the app on Google Play internal testing. Then the owner switches to Fitness Buddy daily. **Milestone: Dogfood 1.**

**Spec:** SC-6, AT-006, AC-011 · **Decisions:** TD-026, TD-027, TD-028, TD-029

## Scope
- **OpenTofu prod:** app VM, **db VM** with a data volume, private network, firewall rules (Postgres reachable only from the app VM).
- **Postgres 18 on the db VM** per the chosen option (`08` §4: Kamal accessory + WAL-G by default), tuned for the VM size, with roles `fb_app` / `fb_migrator` / backup / read-only.
- **Backups (TD-028):** continuous WAL archiving + daily base backups to object storage in **another data center**. A weekly copy to a **second provider**. 30-day retention.
- **Automated weekly restore test:** restore the latest backup into staging, verify row counts/checksums, report, and **alert on failure or on backup age > 26 h**.
- **Alerts** (`08` §7): 5xx rate, p90 latency, disk > 80%, backup age, restore test failure, certificate expiry, queue stuck. Delivered to the owner.
- **Prod deploys:** tag `api-v*` → approval → migrate → deploy → smoke test → rollback on failure. The minimum app version is configured.
- **App release:** Play Console app, signing keys (backed up safely), the `mobile-release` workflow → **internal testing track**. The owner installs from Play.
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
- **From S02 (TD-044):** with the first `app-v*` release that calls the API, set `info.version` to 1.0.0 and create the first contract tag `contracts-v1.0.0`; from then on the breaking gate blocks. Add the `contracts-v*` tag ruleset (backlog #19).

## Exit criteria
- [ ] The restore drill is done: recovery to a chosen point in time within the target (≤ 1 h). Timings are in the runbook.
- [ ] The automated restore test runs green on schedule, and a forced failure alerts the owner.
- [ ] AT-006: fresh install + sign-in on prod restores all data. Export complete.
- [ ] The app installs from Play internal testing on the A55. A prod deploy + rollback has been exercised.
- [ ] **Dogfood 1 started:** the owner uses the app daily as a manual tracker + weight log. Feedback is collected in issues.

## Read first
`08-infrastructure-and-operations.md` (all) · S05 Outcome

## Owner involvement
Play Console ($25), a second storage provider account, an alert contact. Then: use the app every day and report anything odd.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
