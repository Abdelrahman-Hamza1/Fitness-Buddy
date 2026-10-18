# B05 — Sync backend

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B01, B04 | L | Codex | 🟦 Planning |

_Old ID: S26 (renumbered by TD-063, 2026-10-16)._

**Goal.** The production UserData module: validated document storage, push/pull with last-write-wins and history, and the cleanup jobs, secured per user.

**Spec:** AC-010, AC-011, AC-012 (server side), G6, G7 · **Decisions:** TD-006, TD-031, TD-025

## Scope
- **Schema `userdata`** (from the B01 prototype, hardened): `documents` (PK user+entity+id, `server_seq` from a sequence, index `(user_id, server_seq)`), `row_history` (30-day retention), **RLS** on both.
- **Entity registry:** the list of synced entities and their JSON schemas per `schemaVersion`, sourced from the contract (`contracts/openapi/` sync components). Unknown entities or invalid payloads → per-change `invalid` results.
- **`POST /v1/sync/push`:** ≤ 500 changes, per-change result (`accepted` / `stale` / `invalid`), HLC comparison, a **future-clock admission bound (reject; never rewrite an immutable HLC)**, a history copy when a version from another device is replaced (and on delete), idempotent replays, the returned max `server_seq`.
- **Sync dataset id (TD-066):** push and pull responses carry a dataset id. Requests bind to that dataset before uploading; on mismatch the client pulls from zero, merges by HLC (including deletion fences), then replays its immutable outbox. See D5 for reset/restore handling; blind re-upload is unsafe.
- **`GET /v1/sync/pull`:** cursor paging (≤ 500), stable under concurrent pushes, returning tombstones.
- **`GET /v1/sync/history/{entity}/{id}`:** earlier versions within 30 days (G7).
- **Policies:** registered users only (anonymous → `403`), per-user rate limits, payload size limits.
- **Jobs:** purge `row_history` > 30 days, compact tombstone payloads > 30 days while retaining minimal deletion fences (scheduled in the worker).
- **Metrics:** pushes/pulls, changes per request, stale/invalid counts, latency.

## Out of scope
- The app's engine and UI (A34). Account deletion (B06).

## Fixed by the plan
- Document storage, not mirrored tables (TD-031, as confirmed by B01). Server-assigned `server_seq` ordering for pulls.

## Decide in the low-level plan
- How entity JSON schemas flow from the contract into the backend at build time.
- Partition readiness (keep the schema partition-friendly by `user_id`, no partitioning yet).

## Notes from earlier steps
- B01 uses five-minute admission rejection, not HLC rewriting. TD-049's 24-hour library receive default remains unchanged. Compare HLCs with `COLLATE "C"`.
- B01 backlog #54–57 covers clock recovery, retention/reset safety, real authenticated simulation and JSONB validation. B04 supplies live-session authentication; A01/A06 supply seven current entity names.
- Planned jointly with B06 under PROCESS A3; implement, code/security review and merge B05 independently before starting B06.

## Exit criteria
- [ ] Integration tests: LWW for concurrent edits from two devices, history captured, a tombstone beats an older update, a future-dated HLC is rejected without altering or acknowledging it, invalid payloads are rejected per change, pagination is complete under concurrent pushes, anonymous → `403`, **user A can't read B's documents even with a crafted request**.
- [ ] The convergence simulation from B01 passes against the production module.
- [ ] Purge and compaction jobs tested with a fake clock.
- [ ] Load test: 10,000-change push + pull on the laptop server, timings recorded (repeated on production in B14).

## Read first
`05-data-and-sync.md` §4–5 · `04-backend.md` §6–7 · B01 Outcome

## Owner involvement
None.

---

## Low-level plan
**Tier: Risky. Expected size: L, six WPs (WP1–WP6), plus shared planning WP0.** The original M estimate omitted production schema validation, dataset recovery and retention fences. No product scope is removed. Planning wave with B06; B06 implementation remains dependency-blocked until B05 is merged. One fresh independent planning review covers both cards; each implementation gets its own whole-diff review and separate security review.

### Design and decisions

- **D1 · Auth and lifecycle seam.** Replace `SpikeAccess`/test-key access with B04 `registered-user` authorization and `ICurrentUser`; unauthenticated 401, guest 403. Never bind a user id from HTTP. Retain forced RLS, transaction-local `app.user_id`, parameterized SQL and the per-user advisory lock acquired before sequence allocation. Add Identity's small public transaction-bound active-user check through `Identity.Contracts`; it reads/locks its own user row with a narrow TD-077-style function, checking status and the validated session. B05 sync reads/mutations and B06 deletion acquire the same advisory lock first, then Identity's user/session check, then module rows. Document and test auth-function lock order as well: no session→user inversion. Generic authenticated idempotency handling must take this user lock and re-check live state **before both cached response replay and new execution**, not only inside the endpoint; B06 implements that shared-middleware change with its replay/deletion race test. No API migrator credentials or general bypass.
- **D2 · Contract first and compatibility.** Keep existing push/pull operation IDs, immutable versions, string cursors, accepted/stale/invalid results and ordered acknowledgements. Remove experimental access requirements only through the contract commit; retain the existing global history operation for the oracle and add item-scoped `GET /v1/sync/history/{entity}/{id}` with its own bounded cursor. Add bearer security, 403 and safe schema/clock/dataset reasons. Add response `datasetId` and `serverTime`; introduce optional request dataset binding with a fail-closed discovery mode: unbound push performs **no writes** and returns the dataset, requiring a bound retry. An unbound pull accepts only cursor 0. A mismatched dataset performs no changes and never acknowledges an outbox version. Do not add a push maximum sequence as a client cursor. Check the published-contract baseline before the contract commit; if the gate detects a breaking published change, stop for the owner/versioning rather than bypass it. Keep changes in `modules/userdata.yaml` (the existing owner), not the empty `sync.yaml` placeholder.
- **D3 · Schema registry.** Contract components plus a closed `(entity,schemaVersion) → component` manifest are the sole payload authority. Version 1 covers current A01/A06 `setting`, `mealSlot`, `dishGroup`, `diaryEntry`, `dayMark`, `savedMeal`, `savedMealItem`, with camelCase fields mapped explicitly from their existing content columns; include all necessary sync metadata outside payload without duplicating local `version`. Retain a documented `weighIn` v1 fixture shape for B01 compatibility, aligned with `05` fields. Publish representative valid/invalid fixtures and nullability, timestamp/unit/number rules. Later app entities get additive schemas before A34 accepts their outbox; unknown entities/versions are per-change `invalid/unsupported`, never an arbitrary-object escape hatch. A build-time exporter embeds resolved JSON schemas/manifest in UserData (no runtime file or remote `$ref` fetch). Prefer a bounded validator for the explicitly documented schema vocabulary with build-time rejection of unsupported keywords; do not silently ignore schema constraints or invent a general JSON Schema engine. If that cannot stay small, evaluate one maintained validator before implementation and record its licence/size rationale. Read app definitions only; no app/package edits except generated client.
- **D4 · Validation and clock recovery.** Validate the envelope before opening a DB transaction (null entries/unreadable JSON → fixed 400); each representable change gets a result. Enforce 500 changes and host 256 KiB, bounded depth/string/collection sizes, finite numbers and Postgres JSONB representability (including nested escaped U+0000 and numeric bounds) before SQL. Never echo payload or validator values in problems/logs. A submitted HLC/device suffix must agree, but historical outbox device IDs need not equal the current installation header. Future wall time > server+5min → `invalid/clockDrift`; return server time, retain the exact pending version, and never silently re-stamp it. A34 waits for clock correction/admission or explicitly creates a new local version through the single writer; B05's simulator proves eventual retry, retaining newer concurrent edits. No change to Accepted TD-049 or automatic loss of confirmed edits.
- **D5 · Dataset and rollback recovery.** Refine Proposed TD-066 during implementation: an opaque dataset UUID is persisted in UserData metadata, survives ordinary process restart and faithful migration/dump transfer, and changes on a genuinely new database or rollback restore. The operator restore/reset procedure explicitly rotates the epoch before serving traffic (including restoring an older snapshot); a dump alone cannot prove currentness. Reject an impossible ahead-of-dataset cursor rather than treating an empty page as success. New client: discover, pull from 0, persist merge+cursor+dataset atomically, then upload pending immutable versions and any locally newer rows missing remotely. Server winners/deletion fences are merged before upload, without manufacturing newer HLCs. A reset with no surviving server copy can only recover data retained on a phone/backup; deleted data absent from all surviving copies cannot be inferred. Test both faithful laptop→production transfer and rollback/new-database reset. B14 gets the epoch runbook; no live owner reset or real-data migration in B05 tests.
- **D6 · LWW, history and safe compaction.** Preserve B01's per-user commit ordering (`CACHE 1`), displaced **and stale incoming** versions, and binary HLC comparison. History expires 30 days after first archival; replay must not renew retention. Keep a compact per-version receipt `(user,entity,id,hlc,fingerprint)` for immutable retry identity after history payload expiry; canonical fingerprints cover schemaVersion, deviceId, deletedAt and JSON content (object-key ordering/numeric equivalence explicitly tested). No plaintext user content in receipts. Compact a tombstone's payload after **server acceptance time**, not client `deletedAt`, reaches 30 days. Retain its minimal row/HLC/deletion fence, fingerprint and pull sequence until account deletion, so an offline old update cannot resurrect it and a fresh pull can remove a stale local row. A strictly newer HLC can intentionally restore the row. Pull documents expose an explicit compacted-tombstone shape; validate this separately from a live entity payload. All user-owned receipts/fences use forced RLS and are deleted by B06. Metadata growth is measured/documented; do not expire fences or receipts without a separately proven protocol.
- **D7 · Worker and observability.** Use S04 database-only scheduled handlers and supplied transactions. Use bounded per-user cleanup work with authenticated-user context from durable jobs; obtain candidates through a narrow module-owned enumeration capability, not API-wide RLS bypass or a cross-schema scan. Acquire the same user lock as push before cleanup. Persist/renew schedule progress so idle users are cleaned too; test recovery from worker failure. Register supported metrics with only bounded operation/result/entity labels (known registry entities plus `unknown`); no user, device, row, HLC, cursor, schema error text, payload or dataset labels. Privacy tests inspect logs, Activities, Meter tags, serialized Sentry and Postgres error logs with synthetic canaries.

### Work packages and files

1. **WP0 — Wave plan.** B05/B06 cards, own board rows; one independent plan review, then commit/push the plans. No server/Flutter changes in the planning branch. Plan merge uses the docs variant of `merge-step.sh`.
2. **WP1 — Contract handoff.** `contracts/openapi/modules/userdata.yaml`, root references if needed, `contracts/testdata/sync/` schemas/fixtures, contract tooling for the registry, generated bundle/client using `make gen`. Note the exact wire handoff in Progress; its own commit before server code. Do not add a new shared problem type without an app-owner handoff (B04's four-file exception does not carry forward).
3. **WP2 — Persistence and lifecycle.** Additive UserData migration/context for metadata, acceptance timestamps, compacted flags and receipts, updated snapshots; extend Identity public active-user transaction contract and its narrow SQL capability/migration; `PostgresSyncStore`, application ports/domain rules. Never edit an applied migration. Tests cover migration from B01+B04 data and unchanged owners/payloads, exact grants/RLS and lock ordering.
4. **WP3 — Validation/API.** Embedded contract registry/export target, bounded validation, production endpoint authorization, dataset protocol, item history, safe errors and cursor limits. Host OpenAPI transformer/contract tests as necessary. Separate envelope/per-change tests and all current entity fixtures, including UUIDv5 natural keys as well as UUIDv7.
5. **WP4 — Retention/privacy.** UserData cleanup handlers/schedules, minimal fences/receipts, fixed-clock retention tests, bounded telemetry and end-to-end privacy canaries. Update `backend/README.md`, `05` §4–5 and sync runbook with admission/recovery/epoch procedures; refine Proposed TD-066 without changing Accepted TDs.
6. **WP5 — Real simulator and measurements.** `tools/sync_sim`, `tools/scripts/sync-spike.sh` (or production-named successor), Makefile and server image CI section only. Remove production dependence on test bypass: use isolated real Identity authentication with synthetic local email/Google fixtures, never a production proof bypass. Keep independent fake/oracle, ≥1,000 fake seeds and ≥50 real authenticated seeds; include reset/retention/races and replay/drop/crash cases. Keep a harness-only way to enumerate bounded history using the authenticated existing history API. Push 10,000 small synthetic changes in byte- and row-bounded batches, fresh pull, record timings/environment, operation counts and API p95 separately. Reuse existing loopback port isolation; never load-test the owner's account or tailnet.
7. **WP6 — Review/close.** Full `make check test`, `make gen-check`, `make contract-conformance`, baseline/enabled production-image smoke and real simulation, one heavy build at a time. Fresh independent whole-diff reviewer plus a separate fresh security reviewer, fix/recheck majors, `evidence/B05-verification.md`, Outcome and B01 follow-ups, own board row, commit/push and CI-gated B05 squash. App SQLite/process-death/Wi-Fi acceptance remains A34 (#56), explicitly unclaimed here. Only then create B06's implementation branch from latest main.

### Test and exit-criterion map

| Requirement/rule | Named evidence planned |
|---|---|
| AC-010/011 | `RegisteredSync_RestoresEveryRegisteredEntity`; schema fixtures for all current synced tables; fresh-device authenticated pull; version-skew rejection without ack |
| AC-012 | `ConcurrentPushes_ConvergeAndPreserveLosers`; `Replay_AfterHistoryExpiry_RejectsChangedVersion`; `CompactedDelete_RejectsOldOfflineUpdate`; `NewerVersion_CanRestore`; ≥1,000 fake/≥50 real runs |
| `05.5-clock` / TD-049 | Five-minute boundary, exact immutable ack, retained invalid outbox, server-time recovery without losing a concurrent edit; shared HLC vectors |
| `05.5-cursors` / TD-066 | Held commit ordering, mutable paging, separate history cursor, push acknowledgements never advance pull, dataset mismatch no-write/no-ack, ahead cursor, new DB, faithful transfer and rollback epoch tests |
| `04.6-rls` | Missing token401/guest403; A cannot read/write B documents/history/receipts via crafted IDs or app-role SQL; pooled-connection leakage and stale-session→deletion race |
| `05.7-retention` | Fake-clock exact30days, stale/client-forged deletion timestamp, replay doesn't renew history, idle-user cleanup, bounded retries/transaction rollback and forced RLS |
| `09.4-no-user-content` | Malformed/U+0000/extreme numeric/unknown schema batches produce safe per-change errors; telemetry/error/audit canaries contain no content |
| `09.6-performance` | Isolated10,000-row batched push/fresh pull timings, per-request p95 and receipt/fence footprint; repeat on production in B14 |

### Risks and handoff

B05 is L because cleanup/reset/version identity are protocol work, not CRUD. The independent reviewer must challenge false confidence from a matching fake, schema drift from actual A01/A06 rows, restore epochs and deletion lock ordering. If the schema validator or identity capability needs a new security trade-off/Accepted TD change, prepare the concrete proposal and stop that dependent part for the owner; otherwise self-approve under PROCESS A6. No new paid service or AI call. A34 implements the client decisions; B05 does not edit its Flutter engine. B06 erases **all** UserData structures, including receipts/fences, under the same user lock.


## Progress log

- 2026-10-18 · Orient → wave plan: clean up-to-date main at6ab152d; read PROCESS, board/dependencies, B01/B04 outcomes, data/auth/retention requirements and actual UserData/Identity/queue/app schema code. Owner requested joint B05+B06 planning only, separate implementations/reviews/merges. Corrected stale “clamp” wording, refined proposed reset handling, and raised size M→L for explicit production validation/cleanup/recovery. Independent wave review pending; no implementation started.
- 2026-10-18 · Plan review R1 → shared amendment PA3: added transaction-bound lifecycle checking for sync reads as well as mutations and explicitly required B06's generic cached-response replay path to obtain the same user lock/check. B06 resolves the review's recovery/queue/email findings; scoped wave re-review pending.
- 2026-10-18 · Plan review R2 → approved: independent GPT-6.1 Sol reviewer approved the corrected wave with no remaining blockers/majors. Separate step/code/security gates unchanged. Pending local checks and docs-only CI merge; no implementation started.

- 2026-10-18 · Plan publication: `make check test` passed (all ten Dart workspace packages; existing app skip unchanged;290 .NET tests passed, zero failed/skipped), `git diff --check` clean. Docs-only wave ready for CI-gated merge; plans approved, implementation and each step's own code/security reviews remain future work.

## Outcome
_Written in Phase E._
