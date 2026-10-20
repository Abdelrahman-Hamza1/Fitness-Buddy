# A11 — Dogfood 1 readiness: export, crash reports, daily build

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A09, A10 · soft: **B03** | M | Codex (TD-078) | ⬜ Not started |

_Old ID: S28 export part + new (TD-063, TD-064, 2026-10-16)._

**Goal.** Make the offline food tracker safe to use every day, so the owner can start **Dogfood 1** long before any cloud server exists. The data lives on the phone (TD-001), so it needs an export the owner can keep, crash reports, and a build that updates in place without ever losing data.

**Spec:** AC-030, AT-006 (export part), PR-11 · **Decisions:** TD-001, TD-019, TD-020, TD-055, TD-064

## Scope
- **Export** (AC-030): generated **on the device** from `user.db`: one CSV per type (diary, foods, saved meals, slots, settings so far) + one JSON with everything. Shared through the OS share sheet. Works offline and for guests. A **versioned export format** documented in the repo. An **export registry**, with a test that every table using the sync-metadata mixin (A01) is in it, so a later step that adds an entity without exporting it fails CI.
- **The owner's daily app is the `prod` flavor** (the final app ID, signed with the stable key, TD-055), so the owner's data never has to move to another app. CI builds a signed prod APK on `main`, next to the staging one. Its API URL points at the **laptop test server** (B03) until production exists (B14). B03 is a soft dependency: if it isn't done yet, Dogfood 1 starts anyway (offline-first) and the `/v1/config` check runs once it is. The staging flavor stays for test builds.
- **API URL from CI:** the staging and prod builds read `FB_API_BASE_URL` from a GitHub Actions variable, not from the repo (the laptop's tailnet name stays out of the public repo). Without a reachable server the app works as before (offline-first).
- **Crash reports:** Sentry for the app, in an EU project with IP storage off and server-side scrubbing. Before setting the DSN: native (Java/NDK) scrubbing or native crash handling off, and a native `beforeSendLog`/`beforeSendMetric` that drops everything (backlog #34, #40). Navigation breadcrumbs with route names only.
- **Update path:** a runbook "install a new build" (sideload over the old one, data kept) and a test that an upgrade over the previous build keeps the data (drift migration tests already cover the schema).

## Out of scope
- Server-side Sentry (B13). Import of an export (not in the spec). Sync (A34).

## Fixed by the plan
- Export runs on the device (TD-020). No product analytics (TD-019): Sentry is errors only, scrubbed.

## Decide in the low-level plan
- The CSV column sets (stable and documented) and the JSON shape.
- How often CI publishes the prod APK (every `main` build, or on a tag).

## Exit criteria
- [ ] The export contains every entity so far (a test compares export counts with DB counts; the registry test fails on a synced table missing from the export) and opens cleanly in a spreadsheet app.
- [ ] **Release-key backup:** the owner confirms an off-laptop copy of the key + password, and the copy's certificate SHA-256 equals the TD-055 pin (GitHub secrets can't be read back, so they aren't a backup).
- [ ] A prod APK from CI installs on the A55, updates over the previous one with the data intact, and fetches `/v1/config` from the laptop server when it is on.
- [ ] A test crash from the A55 appears in Sentry with no user content, device name or IP (scrubber tests + one real event).
- [ ] **Dogfood 1 starts:** the owner logs food daily on the prod build (milestone M1, `README.md` §5).

## Read first
`05-data-and-sync.md` §6 · `09-cross-cutting.md` §4–5 · `spec/20-accounts-and-data.md` §3 · `docs/runbooks/android-signing.md` · B03 Outcome

## Owner involvement
Create a free Sentry account (EU region) and add the DSN as a GitHub secret (the session gives exact steps). **Copy the release key and its password off the laptop** (backlog #48; an exit criterion): from now on the daily app is signed with it, and losing it means reinstalling, which loses the phone's data until sync exists. Install the prod build and use it every day. Try an export and open it.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
