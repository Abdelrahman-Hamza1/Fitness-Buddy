# A33 — Sign-in & guest upgrade

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A20, **B04** | M | Claude | ⬜ Not started |

_Old ID: S25 (renumbered by TD-063, 2026-10-16)._

**Goal.** The app works fully as a guest, signs in with Google or an email code, upgrades a guest without losing anything, and signs out safely.

**Spec:** AC-001, AC-002, AC-003, AC-004 · **Decisions:** TD-024, TD-016→TD-024, TD-034

## Scope
- **Builds on A20's session** (auth state, interceptor, background anonymous token): adds the registered state and the "session expired, sign in again" flow.
- **Sign-in screens:** Google (native), email → code entry. (Apple comes with iOS in R2, D-081.)
- **Guest prompt** (AC-002): gentle, dismissible, after the first week and before account-only actions, at most once a week.
- **Upgrade from guest** (AC-003): link the identity → the same user ID → mark the local database as owned → enable sync (A34 does the push). On a `409` (the identity has an existing account): ask **merge** this device's data into it, or **discard** it.
- **Per-account database files** (`05` §3): switching accounts opens the right `user.db`.
- **Sign out** (AC-004): ask "keep a copy on this phone (read-only)" or "remove". Wiping deletes the DB file and secure storage.
- **Me → Account:** shows the signed-in identity, sign-in/out, and placeholders for sync status (A34), export (A11) and delete (A35).

## Out of scope
- Sync itself (A34). Export (A11) and deletion (A35).

## Fixed by the plan
- Guest data never leaves the device. Sync refuses anonymous users (`04` §5).

## Decide in the low-level plan
- How "read-only kept copy" is represented (a flag on the DB file vs a separate state).
- The merge implementation detail (re-own rows + enqueue all).

## Exit criteria
- [ ] **patrol E2E** against the laptop server: guest logs food → signs up with email code → the same data is present and the user ID is unchanged.
- [ ] E2E: sign out with "keep" → data visible, editing disabled until sign-in. Sign out with "remove" → a clean app.
- [ ] Session expiry for a registered user → "sign in again" → the same account and database, nothing lost (test with a fake API).
- [ ] The guest prompt cadence is unit-tested.
- [ ] Real Google sign-in works on the A55 against the laptop server (B03).

## Read first
`05-data-and-sync.md` §6 · `04-backend.md` §5 · `spec/20-accounts-and-data.md` §1

## Owner involvement
Sign in on the A55 with your Google account.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
