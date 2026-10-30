# A33 — Sign-in & guest upgrade

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A20, **B04** | M | Claude | ✅ Done |

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
_Written in Phase B (2026-10-29), Claude, on `step/A33-sign-in`. **Tier: Risky** (identity, secrets, account/DB switching). Time-boxed session (owner, 2026-10-29): plan + code now; architecture review, code review and security review come **later**, before any merge. No spec or Accepted-TD change. Builds on A20's `SessionService` (no change to its refresh/fencing design) and B04's generated `IdentityClient`; no hand-written API types._

### 1. Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **Profiles registry** (non-secret, `shared_preferences`, key `fb.profiles.v1`): list of local profiles `{profileKey, kind: guest\|registered, ownerRef?, readOnly}` + the active `profileKey`. The first/guest profile stays `local` (no file move for existing installs). A registered account's profile key is `acct-<first 16 hex of sha256(flavor+origin+userId)>`: a directory name with no raw user id. | `05` §3 one DB per account; keeps A01's `DatabaseLocation` regex; no PII in paths. |
| D2 | **"Read-only kept copy" = a `readOnly` flag on the profile entry** (not on the DB file). `ChangeSetApplier` refuses writes for a read-only profile with a typed failure; UI shows "Sign in to edit". Signing in to the same account clears the flag. | The card asks to decide; a registry flag is atomic, survives restarts, and needs no drift schema change. |
| D3 | **Active profile is resolved before `runApp`** with one local `shared_preferences` read (no network, no secure storage); `profileKeyProvider` becomes an overridable Notifier. Switching sets the key → `appDatabase` is disposed/re-opened (A01 already closes on dispose). | Local-first startup (UX-001 allows local reads; the prefs read is the same class as device id). |
| D4 | **Upgrade from guest (AC-003)**: Google → `linkIdentity(provider: google, idToken)`; email → `startEmailSignIn(purpose: link)` then `linkIdentity(provider: email, challengeId, code)`, both on the normal API Dio (needs the live guest bearer). Success returns the **same user id** → `SessionService.acceptAuthenticatedSession` → registry marks `local` as `registered` (owner ref) → sync allowed (A34 enqueues/pushes). | B04 handoff: linking requires guest bearer + purpose-bound proof. |
| D5 | **409 identity-conflict** → ask **Merge** or **Discard**. Then sign in with the plain flow (`signInGoogle` / `startEmailSignIn(purpose: signIn)` + `verifyEmailSignIn`). Merge = the guest profile is re-owned by the account (rows carry no user id in a per-account DB, so re-own = registry change) and A34 later enqueues every row; if a kept copy of that account already exists on the device, merge keeps the guest file and the old kept copy is removed only after A34 pulls (deferred: until A34 the kept copy wins and merge is offered as "discard" only — flagged in §4). Discard = delete guest DB file and open/create the account profile. | `05` §6; UUIDs avoid collisions. |
| D6 | **Sign out (AC-004)**: `logoutSession` best-effort (offline is fine), then **Keep** → profile `readOnly=true`, session credentials removed, app falls back to a guest profile only when the user chooses "continue as guest"; **Remove** → close DB, delete the profile directory (user.db + sidecars), remove that account's secure-storage envelope, start a fresh guest `local` profile. | AC-004; wipe deletes DB file and secure storage. |
| D7 | **Google sign-in behind `GoogleIdTokenSource`** (interface). R1 adapter needs the `google_sign_in` plugin (Android + iOS, BSD-3, Google-maintained) **and an OAuth web/server client ID** → ⚠️ OWNER. Until approved/configured the app ships `UnconfiguredGoogleIdTokenSource` (button hidden), tests use a fake. | Can't finish without owner credentials; dependency needs approval per brief. |
| D8 | **Guest prompt cadence (AC-002)** is a pure rule in `fb_domain` (`GuestPromptPolicy`): eligible when guest, first use ≥ 7 days ago, last shown ≥ 7 days ago (or never); account-only actions bypass the 7-day first-use wait but still respect once/week. Stored in prefs `fb.guest_prompt.v1` (display state, never synced). | Spec AC-002; injected clock; property-tested. |
| D9 | **Session expired** (A20 `sessionExpired`) → a non-blocking banner on Today/Me "Session expired — sign in again" → sign-in screen pre-bound to the same account; success with the same user id keeps the same profile/DB. A different account id → treated as switching accounts (D5/D6). | Exit criterion 3. |
| D10 | **Privacy**: no email, user id, code or token in logs/telemetry/`toString`; failures are fixed enums; the email field is kept only in the sign-in view model memory. | `09` §4, rule 6. |

### 2. Files
- `packages/fb_domain/lib/src/account/guest_prompt_policy.dart` (+ export, tests).
- `apps/mobile/lib/core/account/`: `profile_registry.dart` (prefs-backed), `account_service.dart` (flows above over generated `IdentityClient` + `SessionService`), `google_id_token_source.dart`, `account_failure.dart`, `account_providers.dart`.
- `apps/mobile/lib/core/db/db_providers.dart` (profile key notifier), `main.dart`/bootstrap (pre-runApp key read), `ChangeSetApplier` read-only guard.
- `apps/mobile/lib/features/account/`: barrel, `sign_in_screen.dart`, `email_code_screen.dart`, `account_section.dart` (Me → Account: identity, sign in/out, placeholders sync A34 / export A11 / delete A35), `sign_out_sheet.dart`, `merge_or_discard_sheet.dart`, `guest_prompt_card.dart`, view models; routes; ARB strings.

### 3. Work packages (one commit each)
1. **WP1** `GuestPromptPolicy` (domain) + tests.
2. **WP2** Profile registry + account service (link/sign-in/409/sign-out/expired) + Google seam + unit tests with fakes.
3. **WP3** Profile switching (pre-runApp key, DB reopen, read-only guard in applier) + data tests.
4. **WP4** UI: sign-in, email code, Me → Account, sign-out and merge/discard sheets, guest prompt, session-expired banner; ARB; widget tests (light/dark, text scale 2.0).
5. **WP5** patrol E2E (guest logs → email upgrade → same data + id; sign out keep/remove) against the laptop server.

### 4. Tests (spec IDs)
| Test | Proves |
|---|---|
| `AC-002 guest prompt not before 7 days`, `AC-002 at most once a week`, `AC-002 account-only action bypasses first-week wait`, property: never two shows < 7 days apart | AC-002 cadence |
| `AC-003 link keeps the same user id and re-owns local profile`, `AC-003 409 offers merge or discard`, `AC-003 merge keeps guest rows`, `AC-003 discard deletes guest db` | AC-003 |
| `AC-001 email code sign-in opens the account profile`, `AC-001 google sign-in via token source` (fake) | AC-001 |
| `AC-004 sign out keep marks profile read-only and applier refuses writes`, `AC-004 sign out remove deletes db and envelope` | AC-004 |
| `AC-001 session expired sign-in again keeps same profile and db` (fake API) | exit 3 |
| `Rule:09.4-no-content-logging account failures carry no email/token` | privacy |
| patrol `AC-003 guest to email account keeps data and id` | exit 1–2 |

### 5. Owner items
- ⚠️ OWNER: create the Google OAuth **web/server client ID** (+ Android client with the release SHA-1) and approve adding `google_sign_in`; then the A55 Google sign-in check (#78).
- ⚠️ OWNER: decide later if D5's "kept copy + guest data" edge case may wait for A34 (recommended).
- Reviews (architecture, code, security) still owed before merge.


### 6. Account transition lifecycle (review PR1, 2026-10-29)
_Added after the Codex code + architecture + security review ("changes required"): profile ownership, write permission and credentials change in **one coordinated transition**, not three independent steps. Supersedes D4–D6 where they disagree._

**Journal.** One `AccountTransition` record lives **in the same preference value as the profile registry** (`fb.profiles.v1`), so every phase change and its registry change are one atomic write. It holds no secret or PII: `kind` (`signIn` | `signOut`), `phase`, `fromKey`, `toKey`, `credentialRef` (A20's hashed account key), `signOutMode`, plus the registry's `reserved` list (directories awaiting deletion, never reused as a profile key).

**Phases.**

| Sign-in (upgrade, re-sign-in, switch, merge/discard) | Sign-out (keep / remove) |
|---|---|
| 0. Network proof → `AuthTokens` held in memory only (no local change yet) | 0. Server logout, best effort (no local change) |
| 1. `preparing`: journal written; writes + session acquisition suspended | 1. `preparing`: journal written; writes + acquisition suspended |
| 2. `credentialsCommitted`: `acceptAuthenticatedSession` durably stored the tokens (A20 barrier), then the phase is written | 2. `profileSwitched`: keep → profile `readOnly`; remove → profile **reserved** + a **new, distinct empty guest** profile allocated and made active (one atomic write); old database closed |
| 3. `profileSwitched`: ownership/active profile written; old database closed (one shared close future) | 3. `credentialsCleared`: `endSession` (fail closed on storage errors) |
| 4. `cleanupPending`: discarded guest directory reserved, then deleted | 4. `cleanupPending`: reserved directory deleted |
| 5. `done`: journal removed, writes resume | 5. `done`: journal removed, writes resume |

**Rules.**
- While a journal exists (in memory or on disk) the `ChangeSetApplier` rejects apply **and** revert inside its serialized transaction entry, bound to the profile its database belongs to; a read-only profile and a profile that is no longer the active one are rejected the same way. `SessionService` rejects lease acquisition while suspended or signing out.
- No guest data is deleted and no profile is switched before the token is durably persisted. Destructive cleanup runs only after the transition is durably complete (`cleanupPending`); a reserved directory leaves `reserved` only after its deletion succeeded.
- **Crash recovery** runs inside lazy active-profile resolution, i.e. when the database first opens (after the first frame; no pre-frame storage read): sign-in `preparing` rolls **forward** if the session's active credential ref equals the journal's (the token was committed before the phase write), otherwise **back** (journal cleared, guest untouched); `credentialsCommitted` and later roll forward; sign-out `preparing` rolls back; sign-out `profileSwitched` and later roll forward (clear credentials, then cleanup). A failing step leaves the journal in place and is retried at the next launch.
- Conflict consent and a pending Google token belong to one disposable `SignInFlow` bound to one identity; cancel, sign-out or a new flow discards it.
- Merge when a kept copy of that account is already on the phone is **blocked** with an explanation; both copies stay (real merge waits for A34, owner rec).
- Guest email upgrade uses a new **authenticated** `POST /v1/auth/link/email/start` (bearer required, guests only); the public `POST /v1/auth/email/start` stays for plain sign-in. Contract first, then server, then the generated client.

### 7. Security fix check (review PR2, 2026-10-29)
_Codex security re-check: 1, 2, 3, 5, 7, 8 verified; 4 and 6 partial; seven new findings. Fixed one commit each, with a test per crash point:_

| # | Finding | Fix |
|---|---|---|
| S1 | Interrupted removal keeps secrets | The exact hashed credential keys are journaled before sign-out clears anything; `forgetKeys` deletes them with or without a pointer, so recovery finishes the wipe. |
| S2 | A failed transition reopens acquisition | The session hold is kept until the journal is durably clear (failed step, failed journal write, unreadable registry all keep it). The post-frame bootstrap runs journal recovery **before** the API session starts. |
| S3 | A cancelled completion can sign back in | The sign-in plan (target, discard, merge eligibility) is computed inside the transition lock, and the flow's validity is checked there before any commit. |
| S4 | Guest envelope mistaken for a new commit | A unique per-transition tag (UUIDv7) is stored in the journal and in the committed secure envelope (kept across rotations); recovery rolls forward only on an exact match. |
| S5 | An interrupted secure save blocks everything | `SecureSessionStore.reconcileIntent`: readable marked envelope → complete (select); missing/malformed → discard; unreadable store → fail closed. Journal recovery runs it first. |
| S6 | Deadlock between the first write and a transition | Suspension is set synchronously when a transition is enqueued (a queued second transition keeps the hold); the database resolver only reads the active profile, no lock and no recovery. |
| S7 | Abandoned issued sessions stay live | Revoked best effort with their own bearer over the auth transport (cancel after the server answered, cancel at the lock, refused merge). Pre-issue merge checks aren't possible: the account behind an identity is only known from the issued tokens. |

**Explicit checks (no change needed):**
- **AuthZ of `POST /v1/auth/link/email/start`:** `any-user` policy (401 without a valid live bearer), registered principals get 403, and the challenge is stored bound to the guest's session: another guest can't consume it (B04 test `Email_link_proof_is_bound_to_purpose_and_guest_session`), and nobody can link an address without the code sent to it.
- **Rate limiting / enumeration:** the `/auth` group's per-IP fixed window (20/min) applies, plus B04's persistent per-address and per-IP throttles in the store. The response is the same generic challenge whether or not a code was sent; an existing account is revealed (409) only after the code is proven.
- **No tokens/PII/email in logs:** the Identity module has no logger calls; the laptop email adapter writes only to its private directory. App failures are fixed enums; `EmailChallengeRef`, `SignInFlow`, journal and envelope `toString`s are redacted; the registry and journal hold hashes only (test `Rule:09.4-no-content-logging`).
- **Path handling in deletion:** `deleteOtherProfile` accepts only `^[a-z0-9][a-z0-9-]{0,63}$` keys (no separators or `..`), joins them under `<appSupport>/profiles/`, refuses the location's own resolved profile, and the coordinator never deletes the registry's active key; Dart's recursive delete removes links without following them.

## Outcome
_A33 closed 2026-10-29 (Claude, lane 3). Built in a time-boxed session, then three review rounds (Codex code + architecture + security). CI evidence on the branch was not polled from the lane (coordinator rule: API quota); the merge script's `ci` gate and the `[it]` run decide._

**Built.** The app works fully as a guest and signs in with an email code (Google behind `GoogleIdTokenSource`, ⚠️ OWNER). A guest upgrades in place: the code comes from a new **authenticated** `POST /v1/auth/link/email/start` (contract-first, server + xUnit tests, generated client), `linkIdentity` keeps the same user id, and the local `local` profile is re-owned without moving data. A `409` asks merge or discard; merge into an account that already has a kept copy here is refused with an explanation (both copies stay, A34 merges). Profile ownership, write permission and credentials change through one **journaled `AccountTransition`** stored atomically with the non-secret profile registry: tokens are durably stored (with a unique commit tag) before any switch or delete, sign-out persists the read-only/removal state and journals the exact credential keys before clearing them, deletion of reserved directories runs last, and the post-frame bootstrap recovers an interrupted transition (rolling a sign-in forward only on its own commit tag, reconciling an interrupted secure save) **before** the API session may acquire anything. While a transition runs, writes and session acquisition are suspended from the moment it is enqueued, the app shows a calm "Updating your account…" state, and a profile switch starts a new **profile generation** (appliers, the router and the app's widget tree are rebuilt, stale-generation writes are refused), so no draft from the old profile can land in the new one. Per-account databases open lazily from the registry (no read before the first frame). Sign-out offers keep (read-only copy, the `ChangeSetApplier` refuses apply and revert inside its serialized entry) or remove (a new, distinct, empty guest; the old directory is reserved until deleted). Abandoned issued sessions (cancelled flow, refused merge, any pre-commit failure) are revoked with their own bearer. Today shows a "Session expired, sign in again" banner (same account and database), a read-only note, or the gentle guest prompt (AC-002 cadence in `fb_domain`, at most weekly after the first week). Me › Account shows the state, sign-in/out, and placeholders for sync (A34) and delete (A35); sign-in is a typed route (`/sign-in`). Buddy keeps the composer text when a save is refused.

**Exit criteria.**
- Patrol E2E guest → email sign-up → same data and user id: **substituted** by an emulator journey over in-app fakes on both HTTP clients (`patrol_test/account_sign_in_test.dart`, `[it]`), plus host tests; the laptop-server run is an owner A55 check (#177). No backend recorded mode exists and `android-it` has no API (as A22a D18).
- Sign out keep → data visible, editing refused: Patrol + host tests. Remove → a clean app: host tests only (`account_service_test`, `account_transitions_test`); the Patrol remove path needs an isolated profiles root first (#174).
- Session expiry → sign in again → same account and database: host tests with a fake API (`AC-001 session expired …`) + the Today banner widget test.
- Guest prompt cadence: unit + property tests (`GuestPromptPolicy`) and controller tests.
- Real Google sign-in on the A55: ⚠️ OWNER (#173).

**Deviations (and why).**
- **Merged `origin/main` instead of rebasing:** the force push of the rebased branch was refused; the squash merge flattens it.
- **New endpoint `startEmailLink`:** the public email start stripped the guest bearer, so a guest got no code; the authenticated endpoint keeps plain sign-in public (contract change done contract-first).
- **Sessions:** `SessionService` gained `suspend`, `endSession(alsoForget:)`, commit tags and `reconcileStorage`; `SecureSessionStore` gained `forgetKeys` and `reconcileIntent` (A20 code, Risky; reviewed in rounds 2–3).
- **Pinned databases** (an explicit switch, the device journeys' throw-away profiles) skip the registry active-profile comparison; generation, transition and read-only checks still apply.
- **Review-round commits** for re-check items 1 and 2 are one commit (they share the not-committed signal).
- **Merge eligibility** can't be checked before issuing (the account behind an identity is only known from the tokens): decided inside the transition lock, refused sessions revoked.

**Reviews and metrics.**
- **Round 1 (Codex code + architecture + security, "changes required"):** 8 groups (distinct guest after remove, applier gate in the serialized entry, fail-closed sign-out, journaled ordering, authenticated link start, flow-bound consent, merge with a kept copy, shared close future) + the transition design note §6. All fixed, one commit per group.
- **Round 2 (security fix check):** 1, 2, 3, 5, 7, 8 verified; 4 and 6 partial; 7 findings S1–S7 (6 major, 1 minor), fixed one commit each with crash-point tests; explicit checks in §7 (authZ, rate limiting/enumeration, logs, deletion paths: no change needed).
- **Round 3 (re-check):** S1, S2, S4, S5, S6 verified; S3 and S7 partial, plus 2 majors (recovery redirecting an open draft, Buddy input lost on refusal): fixed (`4832ddd`, `cc64e06`, `bb266c3`).
- **Size:** planned M; actual L+ (≈40 commits, 92 files, +7.5k lines incl. generated code and tests). The time-boxed first pass left UI and tests that were finished after the reviews.
- **Gates:** `make check-dart` green after every commit; `check-dotnet` + `check-contract` green for the backend; new goldens generated locally alone; no other local test runs (owner rule).

**Follow-ups (backlog).** #173 Google adapter + OAuth client (⚠️ OWNER) and the A55 Google check; #174 Patrol "sign out → remove" with an isolated profiles root; #175 real merge into an account with a kept copy (A34); #176 account-only actions trigger the guest prompt (A34/A35 entry points); #177 laptop-server E2E of the email upgrade (owner A55 session); #178 decide fail-closed handling of a malformed profile registry; #179 server-side cleanup if best-effort revocation of an abandoned session fails; #180 command-level profile-generation binding beyond the app-tree rebuild; #181 owner A55 checks of the sign-in screens, banners and busy state at the largest font.

**Owner items.** ⚠️ Create the Google OAuth web/server client ID (+ Android client with the release SHA-1) and approve `google_sign_in` (#173); sign in on the A55 against the laptop server (email now, Google after #173) (#177); FYI the E2E substitute above.

## Progress log
- 2026-10-29 15:16 — Plan written (Claude, time-boxed session). Status: in progress.
- 2026-10-29 15:30 — WP1 (guest prompt rule) and WP2 (profile registry + account service, `SessionService.endSession`, `SecureSessionStore.forget`) committed. WP3 (lazy active-profile resolution, read-only applier guard, providers) and WP4 (Me › Account section, sign-in screen, ARB) in the working tree → committed as WIP at the time box. **Not done:** guest-prompt UI wiring, session-expired banner on Today, AccountSection/SignIn widget + golden tests, routes via the app router (sign-in is pushed with `Navigator` for now), patrol E2E (WP5), Google adapter (owner OAuth). Deviation: WP2 committed after format + targeted `dart analyze` only (the heavy lock was held by other lanes); full `check-dart` ran on the WP3/WP4 commit. No local tests (owner rule): CI on the branch is the evidence.
- 2026-10-29 15:43 — Time box reached. Commits: plan, WP1, WP2, WP3 (+ app-check fix moving the profile wipe into `DatabaseLocation.deleteOtherProfile`), WP4 as `wip`. `make check-dart` green on 16e7969; CI on the branch is the test evidence (no local test runs). Resume with: widget/golden tests for AccountSection + SignInScreen, app-router routes, guest prompt card (uses `GuestPromptPolicy`, prefs `fb.guest_prompt.v1`), session-expired banner on Today, patrol E2E (WP5), Google adapter after ⚠️ OWNER OAuth setup.
- ~~Status: in progress / built in part, awaiting architecture + code + security review.~~ (superseded below)
- 2026-10-29 17:10 — Review PR1 (Codex code + architecture + security, "changes required") addressed. main (A44) merged in rather than rebased, so the pushed history isn't rewritten (a force push was refused). §6 design note added (journaled `AccountTransition`). Fixes, one commit per group: 2 write gate inside the serialized apply/revert entry, bound to the profile; 3 `endSession` synchronous signing-out + fail closed + `suspend()`; 8 one shared close future; 4 journaled transitions (tokens durable before any switch or delete, sign-out persists state before clearing credentials, cleanup last, crash recovery inside lazy resolution); 1 distinct empty guest + reserved directories; 6 `SignInFlow` binds consent and the Google token to one identity; 7 merge blocked when a kept copy exists; 5 contract-first `POST /v1/auth/link/email/start` (contract + client, server + xUnit tests, app uses it). Lazy resolution confirmed: no registry read until the database opens (test). Local gates: `check-dart` green after every group, `check-dotnet` + `check-contract` (lint, conformance) green. No local test runs, CI not polled (coordinator).
- 2026-10-29 18:05 — Security fix check (PR2) addressed: S1–S7 one commit each with crash-point tests, explicit checks recorded in §7. `check-dart` green after each. UI items paused (local stash in lane 3) and resume next.
- 2026-10-29 19:30 — Re-check (round 3) fixed; UI finished (route, guest prompt, banners, busy state), widget + golden tests, Patrol journey `[it]`; Outcome, backlog #173–#181, board ✅.
- ~~**Status: built, awaiting re-review (architecture + code + security).**~~ (closed below) Still open from the time-boxed session: widget/golden tests, router routes, guest-prompt card, session-expired banner, patrol E2E, Google adapter (⚠️ OWNER).
- 2026-10-29 18:10 — Round-4 majors fixed (28ed59c Buddy thread scoped to the profile generation; 128b701 sign-in marked uncommitted before rollback). Codex fix-check: both VERIFIED, no new blockers/majors. Test gap (retry / in-flight confirm and undo across a profile switch) → backlog #182. Next: merge-step with emulator tests.
