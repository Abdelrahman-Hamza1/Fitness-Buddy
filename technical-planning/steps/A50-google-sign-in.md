# A50 — Google sign-in on the phone

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A33 ✅ | S | Claude | ⬜ Not started |

_New step (owner, 2026-10-30; resolves backlog #200). Phase 1, wave 3 (TD-105). Tier: Risky (sign-in)._

**Goal.** Google sign-in works on the A55: the plugin behind A33's `GoogleIdTokenSource`, using the client IDs already registered.

**Spec:** AC-001 (Google part), AC-002 · **Decisions:** A33 D7, TD-006

## Scope
- Add `google_sign_in` (approved by the owner) behind `GoogleIdTokenSource`.
- Reuse the existing client IDs from 2026-10-18 (web/server + Android with the release certificate; the server identity is already configured). No Cloud Console work.
- Emulator tests use a fake token source (no debug client needed).

## Out of scope
- Sign in with Apple (R2, D-081).

## Exit criteria
- [ ] Sign-in with a fake source passes the sign-in journey; the plugin adapter has a unit test.
- [ ] Owner A55 check: Google sign-in against the laptop server (collected, non-blocking).

## Read first
A33 card (D7) · B04 card · backlog #200

## Owner involvement
One sign-in check on the A55.

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._
