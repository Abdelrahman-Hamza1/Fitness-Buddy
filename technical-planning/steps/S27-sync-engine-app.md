# S27 — Sync engine (app)

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P3 Accounts, sync & prod | S25, S26 | L | ⬜ Not started |

**Goal.** Everything a signed-in user does syncs to their account automatically, survives reinstall and phone changes, and never silently loses an edit.

**Spec:** AC-010, AC-011, AC-012, AC-013, AC-020 (sync part), UX-053, OF-03, AT-006 (restore part), SC-6, G3, G7 · **Decisions:** TD-006, TD-031

## Scope
- **Production `SyncEngine`:** read the outbox → push batches → handle per-change results (`stale` → pull, `invalid` → report + quarantine), pull pages → apply each document with LWW unless a newer local pending change exists → advance the cursor. Crash-safe at every step.
- **Scheduling:** debounced after change sets, on app foreground, on reconnect, on pull-to-refresh. **Never on the startup critical path.**
- **First sync** on a new device (AC-011): paged pull from 0 with progress, the app usable meanwhile.
- **Document upgraders** in `fb_domain`: older `schemaVersion` → current on pull.
- **What syncs:** every synced table from earlier steps (diary, foods, saved meals, slots, day marks, profile, goals, targets, weigh-ins, measurements, settings) and later ones as they're added (each step adds its entities to the registry). Images never sync.
- **Sync indicator** (AC-013, UX-053): small, calm, only when something hasn't synced. A detail sheet with the last sync time.
- **Earlier versions** (G7): item detail → "Earlier versions" (online) → restore one as a direct action with undo.
- **Tests:** the convergence simulation against the **real API in CI** (Docker), fault injection, version skew, the **OF-03** E2E.

## Out of scope
- Live multi-device push nudges (R2+). Account deletion (S28).

## Fixed by the plan
- The protocol in `05` §5. Pending proposals sync like any row (G3).

## Decide in the low-level plan
- Quarantine handling for `invalid` documents (keep locally and report to Sentry with no content).
- Backoff policy and battery considerations.

## Exit criteria
- [ ] **OF-03 passes:** the same entry edited offline on two devices → after sync the latest wins and the other version is visible in "Earlier versions".
- [ ] **Reinstall/new phone:** sign in on a fresh install → all data restored (AT-006 restore part), demonstrated on staging.
- [ ] The convergence simulation passes in CI against the real API (≥ 50 randomised runs per CI build, ≥ 1,000 nightly).
- [ ] Cold start time unchanged with sync enabled (measured on the A55).
- [ ] Indicator goldens (synced, pending, offline).

## Read first
`05-data-and-sync.md` §5–6 · S12 + S26 Outcomes

## Owner involvement
Test with the A55 + a second device or emulator.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
