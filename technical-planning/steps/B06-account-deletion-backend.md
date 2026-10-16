# B06 — Account deletion (backend)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B04, B05 | M | Codex | ⬜ Not started |

_Old ID: S28 server part (renumbered by TD-063, 2026-10-16). The app side is A35._

**Goal.** A real account deletion that removes everything the server holds for a user, idempotently, with tokens revoked at once.

**Spec:** AC-031, AC-040, PR-11, C-4 (server side) · **Decisions:** TD-022, TD-025

## Scope
- **Contract first:** `DELETE /v1/me` (+ a status read if completion is asynchronous). Commit it and note it in the Progress log so A35 can build against it.
- **Account module:** create a deletion request → **integration events** (outbox) to each module (Identity: identities, tokens, keys; UserData: documents + history; Usage: counters; Buddy: idempotency records) → each module deletes its data for the user idempotently → mark complete. Tokens revoked immediately. Audited (no content).
- A test that **no rows remain for the user in any schema** after deletion. Modules added later register their deletion handler (an architecture test fails if a module with user data has none).

## Out of scope
- The app flow (A35). Backups age out within 30 days (`08` §5); nothing is deleted from backups.

## Decide in the low-level plan
- Whether deletion completes synchronously in the request or in the worker (with the app polling).

## Exit criteria
- [ ] Integration test: after deletion, a query across all schemas finds zero rows for the user. Old refresh tokens fail.
- [ ] Deletion is idempotent (a retry after a partial failure completes).
- [ ] Contract conformance green; the Dart client regenerated.

## Read first
`04-backend.md` §3, §6 · `05-data-and-sync.md` §6–7 · `spec/20-accounts-and-data.md` §4

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
