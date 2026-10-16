# B04 — Identity backend

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | S04 ✅ | L | Codex | ⬜ Not started |

_Old ID: S24 (real email sender → B14) (renumbered by TD-063, 2026-10-16)._

**Goal.** Our own, secure Identity module: sign-in with Google and email one-time codes, anonymous guests, identity linking that keeps the user ID, and our own tokens, used by every other module.

**Spec:** AC-001, AC-002, AC-003 (server side), AC-041 (no identity leaks) · **Decisions:** TD-024, TD-034

## Scope
- **Schema `identity`:** users (id, created, anonymous flag, status), identities (provider, subject, email, verified), devices, refresh-token families + tokens (hashed), signing keys (`kid`, ES256 private key encrypted at rest, status), email codes (hashed, expiry, attempts), and an audit log (events only, no content).
- **Endpoints** (contract first, `04` §4.3): `auth/anonymous`, `auth/google`, `auth/email/start`, `auth/email/verify`, `auth/refresh`, `auth/logout`, `auth/link/{provider}`, `/.well-known/jwks.json`, `GET /v1/me`.
- **Google:** verify the ID token signature against Google's JWKS (cached), `aud` = our client IDs, `iss`, `exp`, `email_verified`.
- **Email codes:** 6 digits, 10 min, ≤ 5 attempts, throttled per address + IP, constant-time compare. `IEmailSender` port + a dev adapter (codes visible only on the laptop) now. The real vendor adapter, its contract tests and the DNS records (SPF/DKIM) come with production in B14 (TD-064). Plain, bilingual-ready template.
- **Tokens:** access JWT ≈ 15 min (ES256, `sub`, `anon`, `sid`, `kid`). Refresh tokens are opaque, rotated on use, with **reuse detection revoking the family**. Logout revokes the family. Key rotation with overlap.
- **Linking** (AC-003): link to the current anonymous user (same ID). If the identity already belongs to another user → `409` with a typed problem, so the app can offer merge/discard (`05` §6).
- **JwtBearer** for all modules. An authorization policy "registered user" (sync and other account features) vs "any user incl. anonymous" (Buddy, search).
- **Rate limits** on auth endpoints. Audit events (sign-in, link, refresh reuse, logout).
- Contract-test suite for `IEmailSender` adapters. Integration tests for every flow and its abuse cases.

## Out of scope
- The app side (A20, A33). Account deletion (B06). **Sign in with Apple (R2 with iOS, D-081):** the provider port makes it a new adapter + endpoint. Device attestation (R3).

## Fixed by the plan
- No passwords. No auth vendor. Identity never forwarded to the AI provider (`04` §5).

## Decide in the low-level plan
- Key storage for signing keys (database encrypted with a key from secrets vs a file secret).
- Exact token lifetimes.

## Notes from earlier steps
- **From S02:** JwtBearer 401/403 challenges must emit `application/problem+json` (the Spectral rule and the runtime must agree). Decide per auth POST whether it is `x-fb-idempotency: exempt` (with `x-fb-idempotency-reason`): token responses must not be stored and replayed. Move `GET /v1/config` into the Account module if it exists by then (backlog #20).

## Exit criteria
- [ ] Integration tests: each sign-in flow, refresh rotation, **refresh reuse → family revoked**, expired/invalid Google tokens rejected (wrong `aud`, wrong `iss`, expired), email code expiry/attempt limits/throttling, link keeps the user ID, link conflict → `409`, anonymous users rejected by the "registered user" policy.
- [ ] A JWKS rotation test: tokens signed with the old key stay valid until expiry, and new tokens use the new key.
- [ ] Logs and audit contain no codes, tokens or emails in plain text (scrubber tests).
- [ ] Running on the laptop server (B03). A real Google sign-in from a test client works against it.

## Read first
`04-backend.md` §5–6 · `05-data-and-sync.md` §6 · `09-cross-cutting.md` §4

## Owner involvement
Create a Google Cloud project with OAuth client IDs (Android + web/server). The session gives exact instructions. (The email provider and its DNS records move to B14.)

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
