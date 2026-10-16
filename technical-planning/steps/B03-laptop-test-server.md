# B03 — Laptop test server for the phone

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | S04 ✅ | S | Codex | ⬜ Not started |

_Old ID: new (TD-064, 2026-10-16)._

**Goal.** The owner's laptop serves as the test server until production exists (B13–B14 run last, TD-064). The phone reaches a dedicated test-server stack on the laptop over HTTPS from anywhere, privately, so every online feature (Buddy, search, sign-in, sync) can be built and used on the A55 without Hetzner.

**Spec:** — (enables online features before production) · **Decisions:** TD-064, TD-029 (Tailscale), TD-058

## Scope
- **Tailscale** on the laptop (pinned, scripted install per the machine-setup rules) and the Tailscale app on the A55, on the owner's tailnet.
- **A separate test-server stack, not the dev stack:** its own compose project and named volume, running only images built from `main`, in a production-like environment (not Development; B02's dev parse endpoint off; the dev email sender writes codes to a local file only). Codex keeps resetting and testing the dev stack freely; the test server holds the owner's real data.
- **`tailscale serve`** in front of the test-server API: `https://<laptop>.<tailnet>.ts.net` with a valid certificate, so the hardened staging/prod builds (HTTPS only, system CAs, S06 A8) work unchanged. **Tailnet only: never Funnel**, nothing exposed to the internet.
- **A Tailscale ACL** that lets only the owner's A55 reach the laptop on 443.
- **A nightly `pg_dump`** of the test server to a local folder, kept 7 days, plus a disk-encryption check in the runbook.
- **`make serve-phone` / `make serve-phone-stop`** (or similar): start the test-server stack + the serve mapping, print the URL, and a status check (`/health/ready` through the tailnet URL). The stack keeps its data across restarts (named volume).
- Forwarded headers / proxy settings for the serve hop (S03 note: verify proxy CIDRs and forwarded headers on the real network).
- **Runbook** `docs/runbooks/laptop-test-server.md`: start, stop, check from the phone, what works while the laptop is off (everything except online features, by design), where the data lives, and how B14 moves it to production.
- The tailnet hostname stays out of the repo (A11 puts it in a GitHub Actions variable). That is hygiene only: `*.ts.net` names are public through Certificate Transparency logs. The tailnet and the ACL are the control.

## Out of scope
- The app's API URL wiring (A11). Hetzner staging and production (B13, B14). `adb reverse` + `make run-dev` stay as they are for development.

## Fixed by the plan
- The same container images as `make up` (a separate compose project and volume). Postgres remains the only stateful dependency.

## Decide in the low-level plan
- How the stack and the serve mapping survive a laptop reboot (manual `make` target vs a user service).
- Whether the worker runs too (needed once outbox/jobs matter).

## Exit criteria
- [ ] From the A55 on mobile data (Wi-Fi off), `https://<laptop>.<tailnet>.ts.net/v1/config` returns a contract-conformant response with a valid certificate.
- [ ] The URL is unreachable from a device outside the tailnet, and from tailnet devices other than the A55 (checked).
- [ ] Resetting the dev stack (`make down`/`up`, tests) leaves the test server's data untouched (checked). The nightly dump restores into a scratch database.
- [ ] The runbook works end to end from a stopped laptop.

## Read first
`08-infrastructure-and-operations.md` §2, §6 · `09-cross-cutting.md` §7 · `docs/runbooks/` · S03, S04 Outcomes

## Owner involvement
Create a free Tailscale account, install Tailscale on the A55 and sign in (≈ 5 min, the session gives the steps).

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
