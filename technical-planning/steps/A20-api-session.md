# A20 — API session: anonymous identity & auth interceptor

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | **B04** (contract) | S | Codex (TD-078) | ⬜ Not started |

_Old ID: S25 part (renumbered by TD-063, 2026-10-16). The sign-in screens and guest upgrade stay in A33._

**Goal.** The app holds a server session without the user doing anything: an anonymous identity fetched in the background, tokens kept safely and refreshed transparently. Buddy and online search need it (A22, A24).

**Spec:** AC-002 (guest works fully), AC-001 (token handling part) · **Decisions:** TD-024, TD-053

## Scope
- **Auth state** (Riverpod): none / anonymous / registered (the registered path is completed in A33). Tokens in secure storage, per account.
- **Background anonymous token:** when online, `POST /v1/auth/anonymous` after the first frame, **never on the startup path**; retried on reconnect.
- **dio auth interceptor:** attach the access token to the API origin only (backlog #41); on `401`, refresh once (single-flight). Refresh failure or reuse: an **anonymous** session gets a fresh anonymous token; a **registered** session becomes "session expired, sign in again" (A33's flow), keeping its database and data untouched, never silently replaced by a new anonymous user.

## Out of scope
- Sign-in screens, guest upgrade, sign out, per-account database switching (A33).

## Exit criteria
- [ ] Cold start makes no auth call before the first frame (test).
- [ ] An expired access token is refreshed transparently; concurrent `401`s cause one refresh (fake API tests).
- [ ] Refresh failure: anonymous → a new anonymous session; registered → "sign in again" with the local data intact (fake API tests).
- [ ] Against the laptop server (B03): the A55 gets an anonymous token in the background.

## Read first
`04-backend.md` §5 · `05-data-and-sync.md` §6 · B04 Outcome

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
