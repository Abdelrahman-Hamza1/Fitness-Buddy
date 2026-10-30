# A34 — Sync engine (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A33, **B05**, **B17**, **B18**, **B19**, **B20**, **B21** | L | Claude (TD-085; was Codex, TD-078) | ⬜ Not started |

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
_Written in Phase B._

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
_Written in Phase E._
