# S28 — Export & account deletion

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P3 Accounts, sync & prod | S27 | M | ⬜ Not started |

**Goal.** The user owns their data: a complete export from the phone, and a real account deletion that removes everything on the server and the device.

**Spec:** AC-030, AC-031, AC-040, PR-11, C-4 (in-app deletion), AT-006 (export part) · **Decisions:** TD-020, TD-022

## Scope
- **Export** (AC-030): generated **on the device** from `user.db`: one CSV per type (diary, foods, saved meals, weigh-ins, measurements, workouts later, targets history, memory later) + one JSON with everything. Shared through the OS share sheet. Works offline and for guests. A versioned export format documented in the repo.
- **Account deletion** (AC-031): an explain screen (what will be deleted, backups expire within 30 days) → confirmation → `DELETE /v1/me`.
- **Backend Account module:** create a deletion request → **integration events** to each module (Identity: identities, tokens, keys; UserData: documents + history; Usage: counters; Buddy: idempotency records) → each module deletes its data for the user idempotently → mark complete. Tokens revoked immediately. Audited (no content).
- **Device:** wipe the account's `user.db`, secure storage and caches after a successful response. Offline: explain that deletion needs a connection.
- Test that **no rows remain for the user in any schema** after deletion.

## Out of scope
- Progress photo export (R2, WB-052). Chat history clear (S34).

## Fixed by the plan
- Export runs on the device (TD-020). Deletion is immediate on the server, and backups age out within 30 days (`08` §5).

## Decide in the low-level plan
- The CSV column sets (stable and documented) and the JSON shape.
- Whether deletion completes synchronously in the request or in the worker (with the app polling).

## Exit criteria
- [ ] The export contains every synced entity (a test compares export counts with DB counts) and opens cleanly in a spreadsheet app.
- [ ] Deletion E2E on staging: after deletion, a query across all schemas finds zero rows for the user. Old refresh tokens fail. The device is clean.
- [ ] Deletion is idempotent (a retry after a partial failure completes).

## Read first
`05-data-and-sync.md` §6–7 · `04-backend.md` §3 · `spec/20-accounts-and-data.md` §4

## Owner involvement
Try an export and open it.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
