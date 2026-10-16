# A35 — Account deletion (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A34, **B06** | S | Claude | ⬜ Not started |

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
_Written in Phase B._

## Outcome
_Written in Phase E._
