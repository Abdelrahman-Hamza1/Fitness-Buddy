# A35 — Account deletion (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A34, **B06** | S | Claude | ✅ Closed, awaiting review/merge (built with A34, one step) |

_Old ID: S28 deletion part (renumbered by TD-063, 2026-10-16). The export part moved to A11, the server part to B06._

**Goal.** A real account deletion from the phone: one clear flow that removes everything on the server (B06) and on the device.

**Spec:** AC-031, AC-040, PR-11, C-4 (in-app deletion) · **Decisions:** TD-022

## Scope
- **Account deletion** (AC-031): Me → Account → an explain screen (what will be deleted, backups expire within 30 days, export first) → confirmation → `DELETE /v1/me` (B06's contract).
- **Device:** wipe the account's `user.db`, secure storage and caches after a successful response. Offline: explain that deletion needs a connection. A guest has no server account: "delete" wipes the device data only.
- Handle completion the way B06's contract defines it (e.g. polling a status), and a retry after a failure.

## Out of scope
- Export (A11). The server-side deletion (B06). Chat history clear (A23).

## Fixed by the plan
- Deletion is immediate on the server, and backups age out within 30 days (`08` §5).

## Exit criteria
- [ ] E2E against the laptop server (B03): delete → the device is clean, the old refresh token fails, and B06's all-schemas query finds zero rows for the user.
- [ ] A retry after a simulated failure completes (fake API test).
- [ ] Goldens for the explain and confirm screens.

## Read first
`05-data-and-sync.md` §6–7 · `spec/20-accounts-and-data.md` §4 · B06 Outcome

## Owner involvement
None.

---

## Low-level plan
Built together with A34 as one step (owner, 2026-10-30): see the combined plan in [A34](A34-sync-engine-app.md#low-level-plan), decision **D19** (flow and failure kinds) and WP6.

## Outcome
_Built with A34 as one step (owner, 2026-10-30); the shared plan, measurements and review are on [A34](A34-sync-engine-app.md#outcome)._

**Built.** Me › Account › "Delete account" (signed in) or "Delete data on this phone" (guest) opens an explain screen (what goes, server backups deleted within 30 days, "Export my data" first), then a confirmation sheet. Signed in: sync is paused, `DELETE /v1/me` (`AccountService.deleteServerAccount`), and on `204` the phone is wiped through the A33 "sign out, remove" transition (`AccountService.wipeDevice`: credentials forgotten, the profile's `user.db` directory and its caches deleted last, a new empty guest profile opens and the app rebuilds). A guest only wipes the phone (no server call).

**Outcomes (D19, B06's contract).** No connection (nothing sent) → "needs a connection", retry; a timeout, dropped connection or server failure → "couldn't confirm", retry; a retry that answers `401` after such an attempt → "your session ended, so we can't confirm; it has probably finished", with **Remove data from this phone** or **Sign in again** (B06: a 401 after a lost 204 is not proof); a first-attempt `401` → sign in again; a wipe that fails → retry. No "done" snackbar: the profile switch rebuilds the app into a fresh Today (backlog #241).

**Exit criteria.**
- Laptop E2E (device clean, old refresh token fails, B06's zero-rows query): B06's server tests prove erasure and revocation; the app side is covered by fake-API tests (`test/core/account/account_deletion_test.dart`). The laptop run is an optional owner check (backlog #238).
- Retry after a simulated failure completes: controller tests (offline → retry, uncertain → retry succeeds, uncertain → 401 → remove locally).
- Goldens for explain/confirm: waived by TD-104; one widget test (explain → confirm → delete).

**Fix round 1 (Codex, findings 2 and 3).** Deletion is now a service operation bound to the confirmed profile (`AccountService.deleteAccount(profileKey)`): a `PendingDeletion` record in the profile registry is written before `DELETE /v1/me`, sign-in/sign-out/switches are refused while it is in flight, the request is checked after it has its credentials, and on `204` one write journals the confirmed deletion with the A33 remove transition for exactly that profile, which recovery finishes after a crash. The record survives restarts, so a later `401` or the expired session the auth interceptor reports after a failed refresh leads to the explicit "Remove data from this phone" choice (B06: not proof of deletion). "Sign in again" first keeps the account (drops the record). Back is blocked while deleting; the work no longer depends on the screen.

**Deviations.** The guest's server anonymous account is not deleted (the card: guest = device wipe only).

## Progress log
- 2026-10-30 — Built with A34 as one step (lane 3, branch `step/A34-A35-sync-deletion`); deletion service, controller, screen and tests committed (A34 WP6). Status: closed, awaiting the Codex review and merge.
- 2026-10-31 — Codex fix round 1: profile-bound journaled deletion and typed session failures (A34 Outcome table, findings 2–3). Status: awaiting the fix-check and merge.
