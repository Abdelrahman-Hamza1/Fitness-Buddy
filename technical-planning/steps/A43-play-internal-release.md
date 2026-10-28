# A43 — Play internal testing release

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A42, **B14** | S | Claude (TD-085; was Codex, TD-078) | ⬜ Not started |

_Old ID: S29 app part (renumbered by TD-063, 2026-10-16). The server side is B14._

**Goal.** The owner installs and updates Fitness Buddy from Google Play (internal testing), on top of the sideloaded prod build, with no data lost.

**Spec:** AT-006 (install path), SC-6 · **Decisions:** TD-034, TD-044, TD-055

## Scope
- **Play Console app** for `io.github.abdelrahmanhamza1.fitnessbuddy`. **Enrol Play App Signing with our existing release key (PEPK) when the app is created, before the first upload** (enrolment is one-way), so a Play build updates the sideloaded prod build in place. Uploads use a **separate upload key** (backlog #51). After enrolment Google holds the app-signing key, which ends the key-loss risk. Fallback if in-place update fails: sync to production first (B14), reinstall from Play, restore by sign-in (AT-006).
- **One monotonic versionCode scheme** across CI sideload builds and Play builds (Play can't update an app whose installed versionCode is higher).
- **`mobile-release` workflow:** tag `app-v*` → signed AAB → internal testing track.
- **Contract tag (TD-044):** with the first `app-v*` release, set `info.version` to 1.0.0 and create `contracts-v1.0.0`; add the `contracts-v*` tag ruleset (backlog #19).

## Out of scope
- Production servers (B14). Closed testing and store listings (R2/R3).

## Exit criteria
- [ ] The app installs from Play internal testing on the A55 over the sideloaded build, with the data intact.
- [ ] AT-006: a fresh install + sign-in on production restores all data. The export is complete.
- [ ] `contracts-v1.0.0` exists and the breaking-change gate blocks from then on.

## Read first
`docs/runbooks/android-signing.md` · `10-engineering-practices.md` §7 · B14 Outcome

## Owner involvement
Create the Play Console account ($25 once) and invite your Google account as an internal tester.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
