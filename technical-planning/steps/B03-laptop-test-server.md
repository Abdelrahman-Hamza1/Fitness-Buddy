# B03 — Laptop test server for the phone

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | S04 ✅ | S (expected 3 WPs) | Codex | ✅ (reboot follow-up#76) |

_Old ID: new (TD-064, 2026-10-16)._

**Goal.** The owner's laptop serves as the test server until production exists (B13–B14 run last, TD-064). The phone reaches a dedicated test-server stack on the laptop over HTTPS from anywhere, privately, so every online feature (Buddy, search, sign-in, sync) can be built and used on the A55 without Hetzner.

**Spec:** — (enables online features before production) · **Decisions:** TD-064, TD-029 (Tailscale), TD-058

## Scope
- **Tailscale** on the laptop (pinned, scripted install per the machine-setup rules) and the Tailscale app on the A55, on the owner's tailnet.
- **A separate test-server stack, not the dev stack:** its own compose project and named volume, running only images built from `main`, in a production-like environment (not Development; B01 sync spike disabled and B02 CLI absent from the runtime image; B04 will supply the local-file email sender). Codex keeps resetting and testing the dev stack freely; the test server holds the owner's real data.
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
- [x] From the A55 on mobile data (Wi-Fi off), `https://<laptop>.<tailnet>.ts.net/v1/config` returns a contract-conformant response with a valid certificate.
- [x] The URL is unreachable from a device outside the tailnet, and from tailnet devices other than the A55 (checked).
- [x] Resetting the dev stack (`make down`/`up`, tests) leaves the test server's data untouched (checked). The nightly dump restores into a scratch database.
- [ ] The runbook works end to end from a stopped laptop. **Stopped-stack runbook verified; full machine reboot is collected owner follow-up#76 (PROCESS.md A6), nonblocking.**

## Read first
`08-infrastructure-and-operations.md` §2, §6 · `09-cross-cutting.md` §4, §9 · `docs/runbooks/` · S03, S04 Outcomes

## Owner involvement
Create a free Tailscale account, install Tailscale on the A55 and sign in (≈ 5 min, the session gives the steps).

---

## Low-level plan
**Tier: Risky** (infrastructure, backups and eventual real data). Expected size **S / 3 WPs**, with owner-only activation checks collected separately. GPT-6.1 Sol for plan review, implementation, independent code review and a separate fresh security review (PROCESS.md C).

### Design
- **D1 — Dedicated stack:** standalone `infra/phone-server/compose.yml`, fixed project `fitness-buddy-phone`, separate database volume and bridge; only API publishes `127.0.0.1:5199`. Production environment, non-root/read-only/no capabilities application containers, worker included. No provider keys, spike identity, dev exporter or outbound telemetry configuration.
- **D2 — Main image provenance:** prepare exports only `backend/` from freshly fetched `origin/main` into a temporary build context. Record full revision and immutable Docker image ID in external private state. Startup uses that ID, never the mutable dev tag. Runtime compose/bootstrap/controller snapshots live outside the repo so Claude may change branches safely. Database upgrades are deliberately manual, migrate first; never delete the persistent volume.
- **D3 — Secrets:** independent random hex admin/migrator/app/backup credentials, generated once into a private owner-only directory outside git; mount the bootstrap with passwords supplied via the container environment. API/worker get only fb_app, migrate only fb_migrator. Backup uses a dedicated non-superuser fb_backup (pg_read_all_data + BYPASSRLS, no writes/admin); only scratch create/drop/restore uses admin. Test protected-row dump completeness. No real secrets, hostnames, IPs or node identities in committed evidence.
- **D4 — Tailscale:** existing pinned 1.104.1 install, record reproducible Ubuntu installer. Operator setup needs owner sudo. Tailnet policy generated privately from selected laptop/phone addresses, default deny with only A55 → laptop TCP443 and explicit policy tests. Never install an allow-all policy or Funnel. Bind the private policy receipt to selected device addresses/IDs and policy hash; re-check database-volume and backup-path encryption each start (no synthetic bypass in activation). Start Serve only after owner confirms the policy was applied; HTTPS capability is enabled in Tailscale admin by owner. Do not change unrelated tailnet settings.
- **D5 — Proxy:** determine dedicated bridge gateway dynamically and trust only that single `/32` hop; Serve header overwriting is verified with spoofed incoming forwarding headers. Prove Production HSTS with an HTTPS forwarded request and absence with direct HTTP. Confirm actual network hop through Serve once enabled; existing Host tests prove untrusted forwarding cannot influence rate limits/scheme.
- **D6 — Backups:** private custom-format `pg_dump` written atomically, retained seven days only after success. Nightly user systemd timer with Persistent=true; manual restart after reboot is intentional (no unattended exposure). Restore drill always creates a separate randomly named scratch database, restores dump without owner/ACL, records restored table counts (synthetic tests compare known stable protected rows), and drops only its own scratch database. Never restore over the live database. Root-disk encryption is checked before real-data activation; observed unencrypted storage needs owner resolution, not silent acceptance.
- **D7 — Activation and handoff:** prepare/test synthetic infrastructure while owner away; no claim of phone mobile-data/other-device verification without evidence. Owner supplies HTTPS/admin ACL activation and sudo operator action; encrypted storage prerequisite or explicit owner security decision remains a gate. Offline features need neither phone Tailscale nor server; online features need both. USB/chat app may disconnect at any time.

### Files and tests
- Create `infra/phone-server/{compose.yml,init-roles.sh}`, `tools/scripts/{phone-server.py,test_phone_server.py,phone-server-smoke.sh,setup-tailscale.sh}`, `docs/runbooks/laptop-test-server.md`; focused Makefile and server image CI additions, backend README and B03 evidence/board updates.
- Python offline tests (Rule `08.2-laptop-test-server`, `09.4-privacy`): reject unsafe state permissions/paths, preserve credentials, main-only provenance command, secret-free child errors, fail closed on missing ACL/encryption prerequisites, no destructive lifecycle operation, bounded backup failure and safe scratch restore.
- Actual Docker smoke (Rule `08.2-laptop-test-server`, `08.5-backups`): immutable image, migration repeat, worker schedule, Production headers/dark routes, dev/test stack isolation, backup/restore row counts and retention. CI uses synthetic data only, no Tailscale credentials/API calls.
- Existing .NET proxy/security tests and `make check test`, contract checks remain regression gates; no product API changes, Dart client or paid model calls.

### Work packages
**PA1 (plan review):** dedicated read-only backup role and protected-row completeness test added; activation tied to policy/device identity and both storage paths, spoofed forwarding-header verification required, physical device checks explicitly pending until performed. Fresh GPT-6.1 Sol plan review: 0 blockers, 1 major addressed, 3 minors incorporated.

1. **WP1:** isolated compose, secrets/provenance/lifecycle controller, reproducible Tailscale installer, offline safety tests.
2. **WP2:** backup/timer/restore, synthetic image smoke and CI integration; runbook and focused backend docs.
3. **WP3:** independent whole-diff and separate security reviews, fix/recheck majors; evidence and safe owner handoff. Merge only through merge-step.sh once all non-owner gates pass; never bypass a security decision.

### Risks / owner actions
- Current laptop root is plain ext4 (no visible encrypted block ancestor). Owner explicitly approved unencrypted storage for this private laptop on2026-10-18; a private machine/device/policy/storage-bound receipt records the exception. No production approval.
- Tailscale has no local operator configured and HTTPS is disabled; no authenticated browser available to this session. Prepare exact owner commands/admin policy instead of blocking implementation.
- Only two tailnet devices exist. Third-device negative test remains owner/next test-device work; policy test assertions provide automated coverage, not a claimed physical-device measurement.
- `pg_dump` is a local daily backup, not B14 production PITR or an off-device disaster backup.

## Progress log
- **2026-10-18 · Orient → Plan:** owner connected A55 and laptop and released checkout after Claude. Started from clean current main `3cca0a8`; branch `step/B03-laptop-test-server`. Both Tailscale devices online, 1.104.1; no local operator or HTTPS certificate domains. Read PROCESS.md and B03 dependencies; corrected stale B02 endpoint and cross-cutting section references. Root disk appears unencrypted; production data activation is gated. Owner away; keep repo work autonomous, collect final phone checks.


- **2026-10-18 · Plan → Implement / WP1:** fresh GPT-6.1 Sol plan review approved after dedicated backup role amendment (1 major fixed, 3 minors incorporated; no open blockers/majors). Implemented separate Production compose, main-archive immutable image preparation, private persistent credentials/snapshots, device-bound dual-stack policy generation and fail-closed ACL/HTTPS/encryption activation, scoped Serve ownership and reproducible Tailscale installer. Fifteen offline safety tests and shell syntax pass; existing 244 .NET tests pass with zero warnings/errors/skips. Baseline `make check test` stopped at root Dart analyzer crash under exhausted 7 GB RAM/4 GB swap; no Dart files changed, full gate remains CI responsibility. No deployment or tailnet policy change yet. WP2 adds actual synthetic Docker proof and runbook.

- **2026-10-18 · WP2 / implementation → review:** added atomic seven-day dump retention with dedicated backup login, isolated scratch restore, nightly private user timer, complete runbook and CI image smoke. Synthetic Docker checks pass (Production UID1654/read-only/loopback, exact gateway + HSTS, dark routes, backup read-only privileges, two RLS users restored 2 rows/sum33, dev-volume isolation and restart/worker). Fixed bootstrap readability for container Postgres UID; synthetic HSTS uses a non-loopback Host like Serve. Seventeen offline tests pass. Main image prepared from `3cca0a89e551` and private dual-stack policy generated outside git; no policy attestation, Serve mapping or real-data volume created. Contract checks/conformance pass; .NET244 pass, full Dart tests running. Root analyzer memory crash remains explicitly unclaimed, CI will decide full checks. Fresh code and separate security reviews next; owner actions remain HTTPS/ACL, local operator and disk protection.

- **2026-10-18 · WP3 / review round1 → fixes:** independent whole-diff code reviewer and separate fresh security reviewer each found the same major: copied controller inferred the wrong repo root, breaking nightly backup. Fixed runtime checkout discovery while retaining checkout-path exclusion; added actual copied-controller subprocess tests and Docker backup/restore through relocated snapshot. Nineteen offline tests, actual dev-compose isolation smoke and all10 Dart test packages pass; .NET244 and contract gates remain green. Evidence in `evidence/B03-verification.md`; operational owner prerequisites explicitly pending. No open new scope or paid testing. Scoped fresh-review rechecks follow this commit.

- **2026-10-18 · Review → owner activation handoff:** scoped independent code and separate security rechecks at3836b10 both approved, no open blockers/majors/minors. Automated evidence complete locally except root analyzer (CI gate pending). B03 operational acceptance stays open: encrypted storage, operator privileges, HTTPS and policy application, actual Serve/phone checks. No merge or security bypass. While waiting for CI/owner, prepare a separate planning-only wave for B04–B06; no implementation starts without prerequisites.

- **2026-10-18 · Handoff / activation blocked:** code+security rechecks approved; refreshed private runtime snapshot from main3cca0a8 and successfully ran its installed status command (not running,0 backups, no secret output). Separate reviewed B04 draft pushed on `plan/B04-identity` (2cc1c14), with Proposed TD-077 owner gate; no identity implementation. B03 CI run39119188932 has dotnet/image/contract/catalog success and full Dart format/analyze/tests success; generated-code final job completion still pending at this log revision. Private `OWNER-ACTIONS.md` prepared outside git. No real-data volume/Serve/timer activation. Return checkout to main after final push; phone USB/chat app can disconnect, Tailscale needed only for later online checks.

- **2026-10-18 · Resume / owner storage decision → activation:** owner returned and corrected their initial selection to explicitly approve **unencrypted storage on this private laptop**, after the at-rest risk was explained under PROCESS.md A6. Added narrowly scoped approval receipt bound to project, machine, selected-device policy, state/Docker/backup paths and backing mounts; changed locations/devices invalidate it. No production exception. Owner configured local operator and HTTPS certificates (verified); A55-only policy application pending.22 offline tests pass including absent/stale/wrong-project approval. Previous CI failed because emulator job hit45min timeout after first attempt reported3/3 tests passing; retry hung. Backend/image/contract/catalog/Dart/build jobs passed. Investigate CI runner before merge; do not alter app files or ignore red ci.

- **2026-10-18 · Activation / policy fix and live stack:** owner saved corrected policy after Tailscale exposed invalid IPv4→IPv6 test combinations. Generator now keeps each assertion within the source address family; grants unchanged,22 tests pass with family regression assertion. Both scoped code and security reviews approved the explicit storage-exception delta864292a (0 open blockers/majors; minor stale docs corrected). Owner confirmed exact saved policy; recorded policy/storage receipts, started immutable main3cca0a8 stack, Production loopback readiness passed. Real backup and scratch restore succeeded (9 module tables); installed nightly user timer and its actual service invocation exited0. Temporary diagnostic HTTPS page enables phone config/proxy tests with synthetic headers only; remove after owner results. Local laptop HTTPS is correctly denied by A55-only policy. No real user content/paid calls.

- **2026-10-18 · Live verification → closing gates:** owner confirmed all5 mobile-data HTTPS/config/proxy/trace checks PASS, then confirmed inaccessible with Tailscale off and reconnected. Non-A55 laptop client denied. Actual dev `make down/up` preserved private database aggregates/readiness; actual backup/restore and nightly service exit0. Removed temporary diagnostic proxy/process/file; final Serve has1 HTTPS443 handler, Funnel off. Actual private stop/start preserved data/readiness; Docker/Tailscale/timer enabled. Full machine reboot collected as owner follow-up#76 per PROCESS.md A6. Code recheck947777b approved address-family fix. Evidence rewritten around actual results; final CI still mandatory (previous emulator runner issue tracked#77). No further owner action needed for this session.

- **2026-10-18 · Verify → Close:** required branch CI succeeded at947777b (run39129316527), including Android/emulator, full Dart/generation and all server/image/contract/catalog jobs. No app source or runner edit/rerun bypass. Live evidence and deferred owner reboot check approved by independent reviewer. Board/working agreement/outcome/evidence updated; preparing merge exclusively through `merge-step.sh B03`, which may move main only after the actual squash ci is green. Server stays running; no more owner action required now.

## Outcome

**Built and activated.** A dedicated Production api/worker/migrate/Postgres stack behind A55-only
Tailscale HTTPS, immutable main image, independent persistent volume/credentials and external
runtime snapshots. Only loopback API5199 is published; no public database, dev exporters, provider
keys or Funnel. Exact bridge gateway trust passes actual phone spoofed-protocol/HSTS checks.

**Data safety.** Dedicated non-superuser read-only backup role includes FORCE RLS rows. Atomic
seven-day local dump retention, isolated scratch restores and nightly user timer. Actual backup,
restore, timer invocation, dev reset isolation and private stop/start persistence pass. The owner
explicitly accepted unencrypted storage **for this private laptop only**; machine/device/policy/
storage-bound receipt enforces the exception. No production exception or disk operation.

**Evidence and reviews.** [Verification](evidence/B03-verification.md): owner mobile-data5checks PASS,
off-tailnet blocked, non-A55 laptop blocked;22 Python tests,244 .NET tests,10 Dart packages,
contract and synthetic image/RLS restore checks pass. Independent whole-diff code and separate
security reviews fixed1 shared major (relocated timer controller), both rechecks approved. Owner
storage delta independently code/security approved; policy-family fix independently approved.
No open implementation blocker/major. Full branch CI is green at947777b (run39129316527); squash merge remains gated on the exact squash SHA.

**Deviations / follow-ups.** Manual start after reboot; worker included. Full machine reboot check
collected under PROCESS.md A6 as backlog#76; stopped-stack runbook works. First policy-editor test
revealed invalid cross-family assertions, fixed without changing grants. Prior emulator CI run
had3/3 tests pass but Gradle failure and a hung retry; tracked#77, no app edits or CI bypass. Local
analyzer memory crash is documented; CI full Dart checks/generation passed. A11 wires the private
URL (kept outside repo); B04 supplies identity; B14 supplies off-device/PITR backup and production.

**Metrics.** ExpectedS/3WPs, actualM/3WPs plus owner activation package.22 Python cases; synthetic
restore2protected rows/sum33; live restore9module tables; real backup service exit0. No paid API
calls, new provider, spec change or Accepted-TD change. Owner-approved private storage risk is
recorded above. Final main SHA/CI are reported by the merge script and close message.
