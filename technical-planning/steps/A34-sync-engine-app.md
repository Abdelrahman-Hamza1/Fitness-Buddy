# A34 — Sync engine (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A33, **B05**, **B17**, **B18**, **B19**, **B20**, **B21** | L | Claude (TD-085; was Codex, TD-078) | ✅ Closed, awaiting review/merge (with A35, one step) |

_Old ID: S27 (renumbered by TD-063, 2026-10-16)._

**Goal.** Everything a signed-in user does syncs to their account automatically, survives reinstall and phone changes, and never silently loses an edit.

**Spec:** AC-010, AC-011, AC-012, AC-013, AC-020 (sync part), UX-053, OF-03, AT-006 (restore part), SC-6, G3, G7 · **Decisions:** TD-006, TD-031

## Scope
- **Production `SyncEngine`:** read the outbox → push batches → handle per-change results (`stale` → pull, `invalid` → report + quarantine), pull pages → apply each document with LWW unless a newer local pending change exists → advance the cursor. Crash-safe at every step.
- **Dataset id (TD-066):** when the server's dataset id changes (laptop reset, move to production), reset the cursor and push every local row again; the phone is the source of truth.
- **Scheduling:** debounced after change sets, on app foreground, on reconnect, on pull-to-refresh. **Never on the startup critical path.**
- **First sync** on a new device (AC-011): paged pull from 0 with progress, the app usable meanwhile.
- **Document upgraders** in `fb_domain`: older `schemaVersion` → current on pull. First one: `weighIn` v1 → v2 (A14 D7, B19 D6); upload `weighIn` v2 only, after B19 is deployed.
- **What syncs:** every synced table from earlier steps (diary, foods, saved meals, slots, day marks, profile, goals, targets, weigh-ins, measurements, settings) and later ones as they're added (each step adds its entities to the registry). Images never sync.
- **Sync indicator** (AC-013, UX-053): small, calm, only when something hasn't synced. A detail sheet with the last sync time.
- **Earlier versions** (G7): item detail → "Earlier versions" (online) → restore one as a direct action with undo.
- **Tests:** the convergence simulation against the **real API in CI** (Docker), fault injection, version skew, the **OF-03** E2E.

## Out of scope
- Live multi-device push nudges (R2+). Account deletion (A35).

## Fixed by the plan
- The protocol in `05` §5. Pending proposals sync like any row (G3).

## Decide in the low-level plan
- Quarantine handling for `invalid` documents (keep locally and report to Sentry with no content).
- Backoff policy and battery considerations.

## Exit criteria
- [ ] **OF-03 passes:** the same entry edited offline on two devices → after sync the latest wins and the other version is visible in "Earlier versions".
- [ ] **Reinstall/new phone:** sign in on a fresh install → all data restored (AT-006 restore part), demonstrated against the laptop server (B03), and again on production in B14.
- [ ] The convergence simulation passes in CI against the real API (≥ 50 randomised runs per CI build, ≥ 1,000 nightly).
- [ ] Cold start time unchanged with sync enabled (measured on the A55).
- [ ] Indicator goldens (synced, pending, offline).

## Read first
`05-data-and-sync.md` §5–6 · B01 + B05 Outcomes

## Owner involvement
Test with the A55 + a second device or emulator.

---

## Low-level plan
_Combined A34 + A35 plan (one step, owner 2026-10-30: "one plan, one implementation, one Codex review"). Written by the implementing agent (Claude Opus), self-approved under TD-037: no spec change, no Accepted-TD change, no vendor, no security trade-off. **Tier: Risky** (sync and account deletion touch the user-data write path). **Size:** L+ (estimate 2.5–3.5 days of agent work including one Codex fix round)._

### 1. Shape

```
packages/fb_sync (new, pure Dart: fb_api_client + fb_domain)
  SyncEngine ── SyncStore port ── MemorySyncStore (tests, sync_sim)
             └─ SyncTransport port ── FakeSyncServer (tests) / ApiSyncTransport (sync_sim, app)
apps/mobile
  core/db/sync/   DriftSyncStore (outbox read, ack, park, defer, page apply, reset) + generic column codec
  core/sync/      transport adapter (Dio → typed failures), scheduler, providers, status
  features/sync/  indicator (Today), Me › Account row, detail sheet, Earlier versions sheet
  features/account/ delete-account screen + controller (A35)
fb_domain         weighIn v1→v2 upgrader, SyncDocumentUpgraders, RemoteChangesApplied event
tools/sync_sim    scenarios run the production engine (memory store) against the fake and the real API
```

The engine lives in a pure-Dart package so the **same engine code** runs on the phone (drift store), in the 1,000-seed fake convergence test and in CI's real-API run (`make sync-spike`, image job). The app's drift store is checked against the same store contract and an engine + drift + fake-server convergence test.

### 2. Decisions

| # | Decision | Why |
|---|---|---|
| D1 | New workspace package **`packages/fb_sync`** (engine, ports, models, `MemorySyncStore`, `FakeSyncServer` in `testing.dart`). The prototype engine in `tools/sync_sim` is deleted; sync_sim keeps the real HTTP transport, faults and the oracle | One engine, proven against the real API in CI (exit criterion) without a Flutter dependency |
| D2 | **Run order:** (a) discovery/reset pull when no dataset is bound or a reset is pending; (b) **push first**; (c) pull until an empty page. A `stale` result needs no extra step: (c) brings the winner. A `datasetMismatch` restarts at (a) once per run | Push-first sends every pending local version before a newer remote one can overwrite it, so the loser lands in `row_history` (OF-03, G7). Pull-first would overwrite an offline edit with no history |
| D3 | **Push:** the outbox coalesces per `(entity,row_id)`; the change sent is the row **as it is now** (its own `updated_hlc`, `device_id`, `deleted_at`) through the entity codec; ack deletes `hlc <= sent`. Batches ≤ 500 changes and ≤ 240 KiB of UTF-8 JSON (`jsonEncode` default, unescaped). A row alone over the budget, or a single-row `413`, is parked (`tooLarge`); a multi-row `413` splits the batch in halves | A01 D9 outbox (no payload copy); B18 D14 byte budget; #111 |
| D4 | **Per-change results:** `accepted`, `stale` → ack. `invalid/versionConflict` → ack (the server already holds that immutable `(entity,id,hlc)`; it happens when a pulled or upgraded version is re-sent, e.g. a v1 `weighIn` re-uploaded as v2 after a reset). `invalid/clockDrift` → keep pending, stop pushing this run, status `clockAhead`. `invalid/datasetMismatch` → D2. `unsupported`, `invalidPayload`, anything else → **quarantine** (D5) | Never retry a permanent rejection endlessly (#111); never drop a version the server lacks |
| D5 | **Quarantine:** new local table `sync_parked (entity,row_id,hlc,reason,parked_at)`; the outbox rows `<= hlc` of that row move there in one transaction. The local row is untouched and stays visible. A newer local edit makes a new outbox row and pushes normally; its ack clears parked rows `<= hlc`. Retried: "Try again" in the sync sheet, automatically once when the app version changes, and once a day. Reported to Sentry as a fixed kind with **entity + reason only** (no id, no HLC, no content) | The card's rule (keep locally, report without content); a server or app update can fix the cause |
| D6 | **Pull:** `limit` 100. A page is validated (strictly ascending `serverSeq`, `nextCursor` = last delivered or the input cursor) and applied in **one transaction** with the cursor, the dataset id and `hlc.last`. Per document: apply only if `remote.hlc > local.updated_hlc` (a newer local pending change always has the newer row HLC). Outbox capture is off inside the transaction. Applied rows get `version + 1` (1 when new), so an open undo or form on that row gets a `VersionConflict` instead of overwriting it. Local-only columns are never written from a payload (`chat_messages.request_json/answer_json`); a pulled chat tombstone nulls them (A23). A compacted fence tombstones an older local row (meta only, content kept) and is skipped when the row is absent | `05` §5.4/§5.5; B18/A23 handoffs; LWW ties go to the higher device id via HLC text order |
| D7 | **Deferral:** a pulled document the app can't apply (unknown entity, a `schemaVersion` newer than this app reads, a payload the codec can't decode) is stored raw in new local table `sync_deferred` and retried when the app version changes. The cursor advances; nothing is lost and sync is never blocked by one document. Reported as a fixed kind (entity + reason) | Version skew (`05` §5.3): an old app keeps working beside a newer one; LWW makes late application correct |
| D8 | **Dataset reset (TD-066):** on a changed dataset id, one transaction sets the cursor to 0, records `reset.active`, and re-enqueues **every local row** (`INSERT INTO sync_outbox SELECT …` per synced table). The reset pull from 0 applies server winners and deletion fences by LWW and, while `reset.active`, deletes outbox rows `<= pulled hlc` of each pulled row (the new dataset already has that version or a newer one). The empty page clears the flag; the push re-uploads what the new dataset lacks. Every step is resumable after a crash | TD-066's order: merge server winners and fences before re-uploading surviving local versions |
| D9 | **Clock:** the apply transaction feeds each pulled HLC to a `HybridLogicalClock` restored from `hlc.last` and stores the result; then the applier drops its in-memory clock (new `ChangeSetApplier.runExclusive`, inside its serial queue and write gate), so the next local write is after every pulled version. A pulled HLC more than 24 h ahead of the phone clock aborts the page (cursor unchanged), status `clockBehind` | `05` §5.4 "feed received HLCs to the local clock before further writes" |
| D10 | **Scheduling** (`core/sync/sync_scheduler.dart`): 3 s debounce after `ChangeSetApplied`; on foreground (`resumed`); when the API session becomes ready or a request succeeds after a failure (the reconnect signal, no connectivity plugin); "Sync now" and pull-to-refresh on the sync sheet. The first run is ≥ 3 s after the first frame (never on the startup path). Single flight; a trigger during a run queues one more run. Runs only for a registered, writable profile with a ready session and no account transition | Card scope; UX-001 |
| D11 | **Backoff and battery:** foreground only, no background jobs, no polling. After a failed run: 30 s × 2ⁿ, ±20 % jitter, capped at 15 min; `Retry-After` honoured; the backoff resets on success, foreground or a reconnect signal | Calm battery use; the phone is the source of truth so a delay never loses data |
| D12 | **Auth and gates:** `401` after the interceptor's refresh → stop (A33's session-expired banner exists); `403` → stop (not a registered account); `426` → the update gate; `5xx`, timeouts, connection errors → backoff | A20/A33 behaviour reused |
| D13 | **Status and UI:** `SyncStatus` = {state: idle/syncing/restoring/offline/needsSignIn/clockAhead/clockBehind/error, pending count, parked count, last success time, first-sync progress}. **Today:** one small calm row only when something hasn't synced (pending older than 2 min, or offline/error/parked) or during first restore. **Me › Account:** a "Sync" row with a one-line status, replacing the A33 placeholder. **Sync sheet:** status, last sync time, pending/parked counts, "Sync now" (and pull to refresh), "Try again" for parked changes | AC-013, UX-053 |
| D14 | **Earlier versions (G7):** a generic sheet over `GET /v1/sync/history/{entity}/{id}` (online), decoded through the codec and the upgraders; compacted versions are not listed. **Restore** is a direct action: a `RestoreVersionOp` (core handler) upserts the version's content columns through the `ChangeSetApplier`, with the usual undo snackbar. R1 entry point: the diary entry editor (OF-03's case); other item screens are backlog | G7; rule 8 (direct action with undo) |
| D15 | **Upgraders** in `fb_domain` (`SyncDocumentUpgraders`): `weighIn` v1→v2 per A14 D7 (`inputValue = kg`, `inputUnit = kg`, `preferredForDay = false`, `tzOffsetMin` = the offset nearest 0 whose local date is `localDate`, clamped −720…840). Upload is v2 only | A14 D7, B19 D6 |
| D16 | **Codecs:** a generic codec maps the table's content columns 1:1 to camelCase payload fields plus `createdAtMs`/`origin`/`editedByUser` (reads whole `num` as `int`, `int` as `double` for real columns, `bool` ↔ 0/1). `chatMessage` and `proposal` use their feature mappers (allowlists, `tooLarge`/`unscrubbedTombstone` → parked, A23 D15/D16), composed in `app/app_scope.dart` like the op handlers | Contract tests pin the 1:1 shape; core never imports features |
| D17 | Remote apply notifies drift's table streams and emits `RemoteChangesApplied(entities)` (not `ChangeSetApplied`, so it never schedules a push). Buddy re-runs its restore for the sessions when `chatMessage`/`proposal` changed (A23 D12) | A23 handoff |
| D18 | **No server change.** Deploy note: the laptop/phone server must run an image with B17–B21 (all 23 entities) before this app build syncs, else those rows are parked as `unsupported` (safe) until "Try again" or the daily retry | Server-first (TD-080) |
| D19 | **A35 flow:** Me › Account › "Delete account" (registered) or "Delete data on this phone" (guest) → explain screen (what goes, backups expire within 30 days, export first) → confirm dialog → registered: sync paused, `DELETE /v1/me`; `204` → wipe (the A33 transition "sign out, remove": `user.db` directory, credentials, per-profile caches), then a new empty guest profile. Failure kinds: **offline** (no connection, nothing sent) → "needs a connection", retry; **uncertain** (timeout or 5xx after sending) → "couldn't confirm", retry; a retry answering `401` after an uncertain attempt → B06: not proof of deletion, so the screen says the session ended, explains deletion probably completed, and offers "Remove data from this phone" (wipe) or sign in again to check. Guest: confirm → device wipe only | B06 handoff ("old-token 401 after a lost 204 alone is not proof"), AC-031 |
| D20 | **CI:** `make sync-spike` (image job) runs the production engine: faults, 50 randomised real-API runs per build, `SYNC_SIM_RUNS=1000` on nightly/manual. `make test-dart` runs 1,000 fake seeds in fb_sync. The OF-03 scenario runs against both the fake and the real API | Exit criteria; TD-086 budgets |

**Oracle change (D1):** with coalescing (A01 D9) an intermediate local version overwritten on the same device before any sync never leaves the phone. The convergence oracle therefore requires every version that was a row's **newest local version when its device started a sync**, plus every final winner, to be recoverable (live or `row_history`). The B01 oracle (every version) modelled a payload-copying outbox the app never had.

### 3. Schema (drift v11 → v12)

`sync_parked` (`entity`, `row_id`, `hlc`, `reason`, `parked_at`; PK `(entity,row_id,hlc)`) and `sync_deferred` (`entity`, `row_id`, `hlc`, `schema_version`, `document_json`, `reason`; PK `(entity,row_id,hlc)`). Local only, no triggers, never exported. New `sync_state` keys: `sync.cursor`, `sync.dataset`, `sync.reset`, `sync.lastSuccessMs`, `sync.parkedRetryMs`, `sync.appVersion`. Migration test + schema dump + `make gen-app`.

### 4. Work packages (one commit each)

1. **fb_domain:** upgraders (`weighIn` v1→v2), `RemoteChangesApplied`, tests (property test of the offset rule).
2. **fb_sync:** models, ports, engine, `MemorySyncStore`, `FakeSyncServer`, store contract checks; tests: results matrix, byte batching, 413 split, quarantine, deferral, reset, clock, crash points, OF-03, 1,000-seed convergence.
3. **sync_sim** on fb_sync; `sync-spike.sh`/CI env for 50/1,000 real runs.
4. **App store:** migration v12, generic codec, `DriftSyncStore`, `ChangeSetApplier.runExclusive`; tests: store contract on drift, crash points (rollback mid-page), local-only columns, `weighIn` v1 pull, fences, reset, engine + drift + fake convergence, every registered entity round-trips.
5. **App wiring + UI:** transport adapter, codec composition, scheduler, providers, Buddy listener, Today row, Me row, sync sheet, Earlier versions + restore op, ARB; tests: scheduler (debounce, single flight, backoff, gating), adapter error mapping, restore with undo, one happy-path widget test per new screen.
6. **A35:** deletion service + controller, explain screen, route, ARB; tests: success wipes, offline, uncertain → retry success, uncertain → 401 → wipe choice, guest wipe; one widget test.
7. **Close:** Outcomes, `05` §5 note, board, backlog (#223 fixed here), `make progress`.

### 5. Exit criteria → evidence

| Criterion | Evidence |
|---|---|
| OF-03 | fb_sync OF-03 test (fake) + sync_sim OF-03 against the real API in CI; Earlier versions sheet + restore test. The two-phone run is an optional owner check |
| Reinstall/new phone restore | fresh-store convergence in fb_sync + drift test (fresh database restores all rows); real-API fresh pull in sync_sim. Fresh install on the A55 against the laptop: optional owner check |
| Convergence in CI | `make sync-spike`: 50 runs per CI build, 1,000 nightly (D20) |
| Cold start unchanged | no sync before first frame + 3 s (scheduler test); A55 measurement: optional owner check |
| Indicator goldens | Waived by TD-104 (no goldens by default); widget tests for synced/pending/offline states instead |
| A35 E2E on the laptop | B06's server tests prove erasure and token revocation; the app side is a fake-API test. Laptop run: optional owner check |
| A35 retry after failure | controller tests (D19) |
| A35 goldens | Waived by TD-104; one widget test for explain + confirm |

### 6. Risks

Data loss on the write path (mitigated by transactions + crash-point tests); a page apply racing a local write (serialized through the applier's queue and SQLite); memory on first sync of large proposal rows (limit 100, ~39 MB worst case); real-API run only in CI (also run locally once through `heavy.sh` with the existing image).

### Handoffs from earlier steps

**B18 handoff (2026-10-28, B18 WP1 §8):** `chatMessage` and `proposal` rows upload only after the full B18 merge (the contract merge alone admits them, but A34 depends on all of B18).
- Send push bodies as unescaped UTF-8 (Dart `jsonEncode`'s default). The largest valid `proposal` row is about 197 KB that way and fits the 256 KiB push cap; `\u`-escaping non-ASCII would not (B18 D14).
- Read integers as `num` → `int`: the server admits whole-number `1.0` for integer fields (B18 D15).
- Rows the server rejects permanently (`invalidPayload`, e.g. an unpaired surrogate) must not be retried endlessly (backlog #111).
- Size push batches by encoded UTF-8 bytes (with margin under 256 KiB), not just by the 500-change cap; send a near-cap row in a push of its own.
- On 413, split the batch and retry the halves; a single row that still gets 413 is parked like a permanent rejection (#111) so it never blocks the queue.
- Pull until a page comes back **empty**; never stop because `changes` < `limit`.
- Pulled rows can be about 2× larger on the wire than pushed ones: the server `\u`-escapes non-ASCII, so the largest `proposal` row is about 393 KB in a pull page. Use small pull pages (`limit`) when rows are large; 500 such rows would be ~200 MB.
- Tombstones carry a scrubbed valid payload (`chatMessage`: `text: ""`, `budgetJson: null`; `proposal`: keep `codecVersion`, `draftJson: "{}"`, `interpretationJson: null`), as A23's clear history writes them (B18 handoff).

**B19 handoff (2026-10-29, B19 WP1 §8):** `profile`, `goalPhase`, `targetSettings` and `weighIn` upload only after the B19 merge (server-first, TD-080).
- `weighIn`: pull reads v1 through the v1→v2 upgrader (A14 D7: `inputValue` = `kg`, `inputUnit` `kg`, `preferredForDay` false, `tzOffsetMin` the offset implied by `localDate` and `measuredAtUtc`, clamped to −720…840); upload v2 only.
- Read whole `num` as `int` for integer fields (`birthYear`, `revision`, `tzOffsetMin`, `createdAtMs`): the server admits `1990.0`, raw `TargetRules.wire` rejects it (`contracts/README.md` A34 decoding note).
- Tombstones carry the full payload under the live rules. A scrubbed targets tombstone must stay wire-valid (no zeroed `heightCm`/`baseKcal`/`basisWeightKg`, expression fields intact); a scrubbed `weighIn` v2 tombstone sends `kg` 0, `inputValue` 0, `note` null and keeps the rest (B19 D11, backlog #136).
- The corpus lists `serverRejectsAppTolerates` and `serverAcceptsAppSkips` (in `contracts/testdata/sync/body-targets-validation-vectors.json`) name the rows the server rejects permanently or the app skips on read: never retry them endlessly (#111).


**B20 handoff (2026-10-30, B20 WP3 §9):** upload `measurementType` and `measurement` v1 only after B20 is deployed (server-first, TD-080).
- A scrubbed `measurement` tombstone may zero `value` and `inputValue` but must keep `kind`, `customTypeId` and `inputUnit` paired (M1, M2); a scrubbed `measurementType` tombstone may send `name` `""` (B20 D8, backlog #136).
- The corpus's `serverRejectsAppTolerates` rows (in `contracts/testdata/sync/measurement-validation-vectors.json`: a 121-unit type name, a body fat of `100.0000000000000001`, metadata out of bounds) are rejected permanently: never retry them endlessly (#111). `serverAcceptsAppSkips` lists the rows the app skips on read (value 0, `measuredAtUtc` past year 9999, an empty or blank type name).
- Read whole `num` as `int` for `measuredAtUtc`, `tzOffsetMin` and `createdAtMs` (the server admits `180.0`).
- A pulled measurement whose type is missing or tombstoned stays stored and hidden (A15b D25); the server never cascades a type tombstone.

**B21 handoff (2026-10-30, B21 WP4 §9):** upload the seven workout entities v1 (`customExercise`, `workoutSession`, `sessionExercise`, `workoutSet`, `workoutTemplate`, `workoutTemplateItem`, `weeklyPlanDay`) only after B21 is deployed (server-first, TD-080).
- Each payload is the table's content columns as they are; the muscle list is `secondaryMusclesJson` (the column's JSON string), not an array member.
- Plan days keep their natural IDs (`planDayId`, W5); a plan-day row with another ID is rejected permanently.
- A revived session exercise or set (A37a D25) is pushed as the row's current content at its current HLC; never re-stamp a revival older than the tombstone (TD-049).
- Scrubbed tombstones (#136) must keep W1–W5: a scrubbed `workoutSet` may zero its numbers but keeps its null pattern; a scrubbed `customExercise` may send `name` `""` with empty lists and no primary muscle.
- The corpus's `serverRejectsAppTolerates` rows (`contracts/testdata/sync/workout-validation-vectors.json`: legacy or unknown muscle codes, non-string aliases, set shapes the app reads tolerantly, a plan day under another weekday's ID) are rejected permanently: never retry them endlessly (#111). `serverAcceptsAppSkips` lists the rows the app hides on read (orphans, names past 80 code points, app write bounds).
- Read whole `num` as `int` for integer fields (`weekday`, `reps`, `position`, `createdAtMs`; the server admits `3.0`).

**A23 handoff (2026-10-30, A23 plan review, TD-102):**
- Remote apply preserves the local-only `chat_messages` columns `request_json` and `answer_json`: never overwrite or null them from a pulled row; a pulled tombstone (and clear history) nulls them.
- After a remote apply touches `chatMessage`/`proposal` rows, re-run the Buddy thread's `ensureRestored` for those sessions (A23 D12).
- Park `proposal` rows whose mapper returns `tooLarge` (A23 D15; never push, never ack) and refuse unscrubbed tombstones (`unscrubbedTombstone`, A23 D16).

## Outcome
_A34 + A35 built as one step (owner, 2026-10-30), Claude Opus, lane 3. Status: closed, awaiting the Codex review (Risky: code + security tasks) and merge. Commits stay local until `merge-step.sh`._

**Built.**
- **`packages/fb_sync`** (new, pure Dart): `SyncEngine` over the `SyncStore` and `SyncTransport` ports, `ApiSyncTransport` (Dio errors → fixed `SyncFailure` kinds), byte-budget batching, and `testing.dart` (in-memory store, an independent fake of the B05 rules, the shared store contract checks, the convergence/OF-03/fault scenarios). The B01 prototype engine in `tools/sync_sim` is gone; sync_sim now runs this engine against the real API.
- **App store** (`core/db/sync/`): `DriftSyncStore` (coalesced outbox reads, settle, park, LWW page apply in the applier's serial queue with capture off and `hlc.last` fed, fences, deferral, dataset reset) and the codecs (generic 1:1 column codec; `chatMessage`/`proposal` over the A23 mappers, local-only chat JSON preserved and cleared on a pulled tombstone). `ChangeSetApplier.runExclusive` (D9). Drift v12: `sync_parked`, `sync_deferred`.
- **Wiring** (`core/sync/`): `SyncController` + `SyncScheduler` (D10/D11), the post-auth `SyncGuardInterceptor` (a stale run never sends with the next profile's credentials), fixed-code Sentry reports, `RestoreVersionOp` (G7), Buddy restore after remote chat/proposal changes.
- **UI** (`features/sync/`): Today's calm sync line (only when something waits > 2 min, a problem, parked changes or a first restore), Me › Account "Sync" row + sheet (status, last sync, Sync now, pull to refresh, Try again), Earlier versions on the diary entry with Restore + Undo.
- **fb_domain:** `SyncDocumentUpgraders` (`weighIn` v1→v2, A14 D7), `RemoteChangesApplied`.
- **A35:** see its card.

**Crash points and recovery** (every store call is one SQLite transaction; pushes are idempotent per immutable version):
- Crash before or during a push, or a lost response: nothing is acknowledged; the next run re-sends the same versions (`accepted` as duplicates). Tested: fake and real API.
- Crash after the server accepted, before `settle` commits: the same. A local edit made while a push is in flight has a newer HLC and stays pending (`hlc <= sent` acknowledgement).
- Crash mid-page: the page, its cursor, dataset and clock roll back together; the page is pulled again. Tested on the memory and drift stores (temp-trigger abort).
- Crash during a dataset reset: `beginReset` is one transaction (cursor 0, reset flag, every row re-enqueued); the reset pull resumes from its committed cursor and keeps pruning; the re-upload stays in the outbox until acknowledged.
- Profile switch during a run: the remote apply is refused by the applier's write gate (stale generation); requests are refused by the guard after the bearer is attached.

**Exit criteria.**
- OF-03: passes in both sync orders against the fake (`fb_sync/test/convergence_test.dart`) and the **real API** (`make sync-spike`, ran locally with the smoke image: passed); Earlier versions + restore tested (`test/core/sync/sync_wiring_test.dart`). Two-phone run: optional owner check (backlog #237).
- Reinstall/new phone: a fresh store restores every row (fb_sync), every registered entity round-trips through push and a fresh drift database (`drift_sync_engine_test.dart`), 10,000 rows restored from cursor 0 against the real API (0.6 s on loopback). Fresh install on the A55: optional owner check (#237).
- Convergence in CI: `make sync-spike` (image job) runs the production engine: 50 randomized real-API runs per build, `SYNC_SIM_RUNS=1000` nightly/manual (job timeout 30 min there); local run: 50 runs in 19 s. `make test-dart`: 1,000 fake seeds (3 s).
- Cold start: the scheduler's first attempt is after the first frame and the session start (bootstrap + scheduler tests); the A55 measurement is an optional owner check (#237).
- Indicator goldens: waived by TD-104 (no new goldens); widget tests cover synced / pending / offline. The Me › Account goldens were regenerated (rows changed).

**Deviations.**
- One combined step with A35 (owner); one plan, no separate plan review (owner).
- The convergence oracle now requires every version that was a row's newest local version when its device started a run (plus winners) to be recoverable: the app's outbox coalesces (A01 D9), so an intermediate version overwritten on the same phone before any sync never leaves it. B01's "every version" oracle modelled a payload-copying outbox the app never had.
- No startup delay timer: the first attempt runs right after the session start and is skipped until a session is ready (a pending timer broke whole-app widget tests); later runs follow the session becoming ready.
- Earlier versions is wired on diary entries only (OF-03's case); other item screens are backlog #236.
- `versionConflict` is acknowledged (D4); the plan's reasoning is that the server already holds that immutable version.

**Server / deploy.** No server or contract change. The laptop/phone server must run an image with B17–B21 (all 23 entities) before an app build with this step syncs; with an older image those rows are parked as `unsupported` (kept, retried daily and after "Try again"). The running phone server was not touched.

**Tests added.** fb_domain: upgraders + property test (7). fb_sync: engine (19), store contract on the memory store (12), convergence/OF-03/faults (3), API transport (3), dependencies (3). App: store contract on drift (12), drift integration (7: all-entity round trip, weighIn v1 upgrade, chat local-only, unscrubbed tombstone parked, clock fed, undo conflict, 25-seed two-phone convergence), scheduler (6), guard + earlier versions + restore (3), deletion service + controller (7), widget tests (sync line/sheet/earlier versions, delete screen).

**Measurements.** 7 commits (plan + 6 WPs/chore), ~8.2k lines excluding generated code. Local runs (focused files only, via `heavy.sh`): all green; `make check-dart`, `make check-contract`, `make gen-app` (no diff), `dart analyze --fatal-infos apps packages tools` clean; `make sync-spike` with the existing smoke image: green.


**Fix round 1 (Codex review: CHANGES-REQUIRED, 2 blockers, 2 majors, 4 minors; all fixed).**

| # | Finding | Fix | Commit | Tests |
|---|---|---|---|---|
| 1 | Blocker: a pull (or a deferred retry, a fence, a reset page) could overwrite a pending or parked local edit whose outbox entry has no payload | Before a pulled version replaces a row whose current version is pending or parked, the store keeps it whole in `sync_displaced` (drift v12, unshipped, regenerated) in the same transaction; it is pushed later (the server archives it as a loser) and only its own acknowledgement removes it; parked ones keep their payload for Try again | `4373512` | 3 new store-contract checks on both stores; edit-during-pull (older and newer), deferred retry, fence; a drift edit-during-pull test; scenarios and the fault set now inject edits during pulls and pushes (1,000 seeds; real API) |
| 2 | Blocker: the device wipe hit whichever profile was active later | `AccountService.deleteAccount(profileKey)`: a `PendingDeletion` record bound to the confirmed profile, transitions refused while DELETE is in flight, the post-auth guard bound to it, and one write journaling the confirmed deletion with the remove transition for that exact key (recovery finishes it); independent of the screen; back blocked while busy | `0cc8ea3` | in-flight refusal, non-active profile, open journal, crash after 204 + recovery, restart between attempts, disposed screen |
| 3 | Major: the lost-204 recovery was unreachable through the real auth stack | The typed `SessionFailure(sessionExpired)` the interceptor produces after a failed refresh counts like a 401: `sessionEnded` after an earlier unconfirmed (persisted) attempt, else `needsSignIn` | `0cc8ea3` | real `AuthInterceptor` + `SessionService`: lost 204 → revoked session → Remove data |
| 4 | Major: a batch where every row was codec-refused stopped the drain | `_pushAll` keeps reading after a read that only parked rows | `4373512` | 520 refused rows then a valid one uploads in the same run |
| 5 | Restore ignored the version shown | `EarlierVersion.localVersion` → `expectedVersion` | `038ae46` | an edit meanwhile refuses the restore, nothing written |
| 6 | Queued runs and further pages after backgrounding | queued runs start only in the foreground; the request guard includes the foreground | `b66e8f4` | scheduler test; guarded engine stops after one page |
| 7 | Local edits undercut Retry-After and backoff | a retry deadline the debounce never undercuts; Retry-After also holds against foreground/reconnect | `b66e8f4` | edits during a rate-limit wait |
| 8 | The scrubber removed the sync issue codes | closed lists (`SyncIssueCodes`, entities pinned to the registry); the scrubber keeps only a matching `SyncIssue` value | `038ae46` | final scrubbed event: kept when allowlisted, scrubbed otherwise |

Backlog #239 is closed by fix 1 (it was not a millisecond window: it spanned every network wait of a pull).

**Fix round 2 (Codex fix-check: all round-1 findings verified, one new major).** `removeProfile` now releases the in-flight deletion marker on every outcome, so a cleanup that fails after the switch no longer blocks sign-in, sign-out and sync until restart; the unfinished cleanup stays journaled and holds the session for recovery. Test: cleanup failure → recovery → sign-in on the same `AccountTransitions` instance. Schema note: drift v12 (`sync_parked`, `sync_deferred`, `sync_displaced`) has never shipped (not on `main`, no build installed it), so editing it in round 1 needs no migration or recreation anywhere.

Re-run after the fixes: `make sync-spike` with the smoke image is green (faults incl. the edit-during-pull fault, OF-03 both orders, 50 randomized runs with pull/push-time edits in 20 s, 10,000 rows restored in 0.6 s); `make check-dart`, `dart analyze --fatal-infos apps packages tools`, format and `make gen-app` (no diff) clean; fb_sync 47 tests, the touched app test folders 216 tests green.

**Backlog.** Done: #54 (clockDrift stays pending, the status says the clock is ahead; no re-stamping), #98 (remote apply bumps `version`), #223. Partly: #56 (real SQLite + production engine + real API in CI; device process death and Wi-Fi timing remain an owner check), #111 (permanent rejections parked; the `validateWire` UTF-16 check remains). New: #236–#242 (#239 closed by fix round 1).

## Progress log
- 2026-10-30 — Combined A34 + A35 plan written and self-approved (Risky; lane 3, branch `step/A34-A35-sync-deletion`). Status: in progress.
- 2026-10-31 — Codex fix round 2: in-flight deletion marker released on every outcome (+ same-instance test); v12 confirmed unshipped. Awaiting merge.
- 2026-10-31 — Codex review round 1 (CHANGES-REQUIRED): all 8 findings fixed in 5 commits (see Outcome); cross-checks and the real-API run re-run. Status: closed, awaiting the Codex fix-check and merge.
- 2026-10-30 — WP1–WP6 committed locally (fb_domain upgraders; fb_sync engine; sync_sim on the production engine, real-API run green locally; drift store + codecs + migration v12; scheduling + UI + earlier versions; A35 deletion). Cross-checks green. Outcome written. Status: closed, awaiting the Codex review (code + security) and merge.
