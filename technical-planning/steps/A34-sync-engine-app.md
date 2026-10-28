# A34 — Sync engine (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A33, **B05**, **B17**, **B18** | L | Claude (TD-085; was Codex, TD-078) | ⬜ Not started |

_Old ID: S27 (renumbered by TD-063, 2026-10-16)._

**Goal.** Everything a signed-in user does syncs to their account automatically, survives reinstall and phone changes, and never silently loses an edit.

**Spec:** AC-010, AC-011, AC-012, AC-013, AC-020 (sync part), UX-053, OF-03, AT-006 (restore part), SC-6, G3, G7 · **Decisions:** TD-006, TD-031

## Scope
- **Production `SyncEngine`:** read the outbox → push batches → handle per-change results (`stale` → pull, `invalid` → report + quarantine), pull pages → apply each document with LWW unless a newer local pending change exists → advance the cursor. Crash-safe at every step.
- **Dataset id (TD-066):** when the server's dataset id changes (laptop reset, move to production), reset the cursor and push every local row again; the phone is the source of truth.
- **Scheduling:** debounced after change sets, on app foreground, on reconnect, on pull-to-refresh. **Never on the startup critical path.**
- **First sync** on a new device (AC-011): paged pull from 0 with progress, the app usable meanwhile.
- **Document upgraders** in `fb_domain`: older `schemaVersion` → current on pull.
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

## Outcome
_Written in Phase E._
