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
_Written in Phase B (2026-10-24) by the step-planner, against `main` at 678c86e (A01–A10a, A12, A20, B03, B17 merged). No contract change, no migration, no user-data write._

_**Tier: Risky** (`PROCESS.md` A.2: "backups or data leaving the phone", "secrets"). Nothing here writes user data (export is read-only, D7), but the export file, crash reports and the backup rule (Q2) are exactly the ways data leaves the phone, and WP3 handles signing and the DSN/URL secrets. So: Codex's separate security session over the whole diff, `steps/evidence/A11-verification.md`, and the M1 `verifier` (`13` §3.D). The Claude-built UI WP (WP4) gets `ux-reviewer`._

### 1. Summary
After A11 the owner's daily app is the **prod** build: CI builds a release-key-signed `app-prod-release.apk` on every `main` run, pointed at the laptop server through a secret, and it installs over the previous one with the data kept. **Me → Your data → Export your data** writes 8 CSV files (one per data type) and one JSON file with everything, on the phone, offline, and hands them to the share sheet. A versioned format is documented in `docs/export-format.md`, and a registry test fails CI when a synced table or column isn't exported. **Sentry** reports Dart errors from the staging and prod builds (EU, scrubbed, errors only, no sessions); native crash capture is off or scrubbed (D12); a test report can be sent from About. Runbooks cover installing a build, the Sentry project and verifying the key backup.

### 2. Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **Who builds what.** WP1–WP3 and WP5 (export core, crash-reporting config, build/CI/scripts/runbooks, backup rule) → **Codex** (`--write`, no git; gates per WP). WP4 (Me section, export sheet, About test-report gesture, ARB, goldens) → `flutter-engineer` (Sonnet; Opus retry). WP0 research → `tech-researcher`. Codex WPs return **typed outcomes only**, no display text (A07 PA8) | TD-078 marks A11 Codex because its core is non-UI; the one Me row and sheet are UI, so they follow the A07–A10 split |
| D2 | **Export scope:** one file per synced table, **8 CSVs** (`diary-entries`, `dish-groups`, `day-marks`, `meal-slots`, `personal-foods`, `saved-meals`, `saved-meal-items`, `settings`) + **one JSON** with all of them. **Live rows only** (tombstones excluded in both: no import exists, and the user deleted them). Files are named `fitness-buddy-<YYYY-MM-DD>-<type>.csv` / `fitness-buddy-<YYYY-MM-DD>.json` (local date) | AC-030 "one file per type + JSON (everything)"; the 8 synced tables are everything so far (`AppDatabase.syncedTables`); a file per table keeps CSV flat |
| D3 | **CSV columns (stable, documented, D10):** `id`, then every **content** column of the table in registry order (SQL snake_case names), then `created_at`, `edited_by_user`. **Derived** columns for readability: diary `occurred_at` (ISO-8601 local time with offset, from `occurred_at_utc` + `tz_offset_min`) and `meal` (the slot's `name`, else its `default_key`, e.g. `breakfast`: no l10n in the writer); saved-meal items `saved_meal_name`. **Excluded everywhere:** `device_id` and `updated_hlc` (the install id and the HLC that embeds it, TD-053: an export may be shared), `deleted_at` (always null). `version` and `origin` are JSON-only | Spreadsheet-friendly without losing a value; no install identity in a file the user may send to someone |
| D4 | **JSON shape:** `{"format":"fitness-buddy-export","formatVersion":1,"exportedAt":"<UTC ISO>","app":{"version","build"},"schemaVersion":4,"counts":{<entity>:n},"data":{<entity>:[{…}]}}`. Keys = entity wire names (`diaryEntry`, …, as in sync) and the CSV column names; adds `version`, `origin`; each `*_json` column is emitted **parsed** (nested value) under the same name; real numbers as JSON numbers, booleans as booleans, ms timestamps as numbers + `created_at` ISO | Self-describing, typed, one schema shared with the CSVs, no import promised |
| D5 | **CSV encoding:** UTF-8 **with BOM** (Excel shows Arabic names correctly), **CRLF**, RFC 4180 quoting, header row, `.` decimals with no grouping (doubles printed shortest round-trip; whole values as `100`), `true`/`false`, null = empty cell. **Formula-injection guard:** a text cell starting with `=`, `+`, `-`, `@`, tab or CR gets a leading `'` (CSV only; JSON exact; documented) | "Opens cleanly in a spreadsheet app"; food names (and later OFF product names, A28) are untrusted text |
| D6 | **Export registry** (`core/export/export_registry.dart`): `ExportTableSpec(entity, fileStem, table, columns, excluded: Map<column, reason>)`. Tests: (a) every table in `db.allTables` that has the sync columns has a spec; (b) every column of each such table is either exported or in `excluded` with a reason (so a **new column** also fails CI); (c) `docs/export-format.md` mentions every `file.column` | Card: "a later step that adds an entity without exporting it fails CI"; column level closes the same gap for A13–A16's additions |
| D7 | **Reading: `ExportReader` in `core/export/`** over the drift tables, in **one read transaction** (a consistent snapshot), `WHERE deleted_at IS NULL`, ordered by `id` (UUIDv7 = creation order; diary by `local_date, occurred_at_utc, id`). Read-only by construction: `WriteGuard` rejects any write outside the applier (a test pins that the export runs unauthorized). **Not through feature repositories:** they return domain views (versions, joins), and 8 new raw-dump methods would only be re-flattened; the registry is the single place that knows every column | Single-writer rule untouched; `core/` imports no feature (app_check) |
| D8 | **Writing and sharing.** Encoding runs in `Isolate.run` (UX-007; ~20k entries ≈ 15 MB JSON). Files go to `<temporary dir>/export/` (app-private), **wiped at the start of each export**. Shared with **`share_plus`** (multiple files, `ACTION_SEND_MULTIPLE` via its FileProvider) behind a port `ExportSharer` in `core/export/` (the only importer; `share_plus` joins app_check's `ioPackages`). New dependency, one-line justification in `pubspec.yaml`, version per WP0 | No network anywhere (TD-020, guests included); multiple plain files open directly in Sheets/Excel without unzipping (no `archive` dependency) |
| D9 | **UI entry (AC-030 "from settings"): a new Me section "Your data"** between Settings and About, one row **"Export your data"** → `showFbSheet`: "Your diary, foods, saved meals and settings as spreadsheet files (CSV) and one JSON file. Made on this phone; nothing is uploaded." + **Export** (busy while building) → share sheet. Failure → `FbInlineBanner` "Couldn't create the export. Try again." Amends A10 D8's section order (A33 may add account deletion to this section) | Data ownership (spec 20 §4) gets one obvious place, 2 taps from Today (UX-013) |
| D10 | **Format doc + versioning:** `docs/export-format.md` (v1): files, every column with type/unit/meaning, encoding rules (D5), JSON shape (D4). **`formatVersion` changes only on a rename, removal or meaning change;** new files/columns are additive (readers ignore unknown ones) | Stable for the owner's spreadsheets; cheap to extend at A13–A16 |
| D11 | **Sentry (Dart), errors only:** keep S06 D12/A5 options; add `enableAutoSessionTracking = false` (session envelopes carry an install id, and release health is not "errors only"), keep `tracesSampleRate = 0`; **navigation breadcrumbs** via `SentryNavigatorObserver(enableAutoTransactions: false, setRouteNameAsTransaction: false)` on the GoRouter, whose data the scrubber already cuts to `state/from/to` route names (#42: routes carry no user data). Release/environment as today | Card: "Navigation breadcrumbs with route names only"; TD-019 errors only |
| D12 | **Sentry native side (backlog #34, #40), research-gated (WP0 R1):** preferred = **no native-origin events**: `enableNativeCrashHandling = false`, `anrEnabled = false`, `enableNdkScopeSync = false`, plus native logs/metrics dropped (a native `beforeSendLog`/`beforeSendMetric`, or not starting those integrations), **provided Dart events still deliver** (sentry_flutter sends Dart envelopes through the native SDK on Android). Fallback if R1 shows that can't hold: a Kotlin `beforeSend` that applies the same allow-list (user, request, extra, device name/ids, exception values). **Proof in WP2:** a local envelope sink on the emulator (dev build, DSN `http://k@127.0.0.1:<port>/1` via `adb reverse`) receives the canary Dart error with no canary, user, device name or install id, and `adb shell am crash` produces no envelope (or a scrubbed one) | One scrubber in one language; native crashes are rare in an app with little native code; the card requires this before the DSN is set |
| D13 | **DSN and API URL from CI secrets:** `FB_SENTRY_DSN` and **`FB_API_BASE_URL` as repository secrets** (the card says "variable"; variables are printed in step env headers of this **public** repo's logs, secrets are masked: stricter, same intent). `build-android.sh` merges them over `config/<flavor>.json` into a `mktemp` defines file (deleted on exit, values never echoed), **staging and prod only**; checks: URL `https://host[:port]` only; DSN `https://<key>@o<n>.ingest.de.sentry.io/<n>` (**EU ingest enforced**). Unset → the repo placeholders (Sentry off, offline-first app unchanged). Dev and `android-it` never get them. Laptop builds accept the same env vars | Card scope; the tailnet name and DSN stay out of the repo; a non-EU DSN can't ship by mistake |
| D14 | **Prod APK cadence: every `main` run** (each squash merge, plus the weekly scheduled run so a fresh APK always exists within the 30-day retention). In the **existing `android` job**: on `main` and `merge/*` it also runs `make build-android FLAVOR=prod` (merge/* = pre-merge check, no upload); on `main` with the key it uploads `app-prod-release.apk` (unzipped, 30 days). Step branches build staging only. versionCode = run number (monotonic). No new job, so the `ci` gate and TD-060 are unchanged; job timeout 30 → 45 min | Every merge is already a gated release; a tag would add a manual step for no gain |
| D15 | **Update path:** (1) drift migration tests from every shipped schema (exist); (2) new host test: a populated `user.db` file reopened by a fresh `AppDatabase` + the post-frame bootstrap with a **newer catalog pack** keeps every row (export counts before = after); (3) runbook `docs/runbooks/install-a-build.md` (Chrome → Actions run on `main` → artifact → install over; never uninstall; what a signature-conflict error means); (4) the owner's A55 update as the real proof. **No CI emulator upgrade test:** release APKs are arm64-only, the emulator is x86_64 | Covers what can break data on update (schema, pack swap, startup) without a flaky device job (#112) |
| D16 | **Release-key backup check:** `tools/scripts/verify-key-backup.sh <copy.jks>` reads the password with `read -s`, prints only the copy's certificate SHA-256 and compares it with `RELEASE_CERT_SHA256` read from `build-android.sh` (one pin); self-test with a throwaway keystore. `android-signing.md` §2 gains the "verify the copy" step | Exit criterion 2 needs a checked copy, and GitHub secrets can't be read back |
| D17 | **Test error report:** About → **long-press the version line** → confirm sheet "Send a test error report?" → `ErrorReporting.sendTestReport()` captures a handled `TestErrorReport` whose message holds a canary food text; the event must arrive with value `[scrubbed]`. Present in every flavor, inert with an empty DSN | Exit criterion 4 needs one real event from the A55 on the prod build; a hidden gesture adds no visible control |
| D18 | **Card amendments (no spec change):** Spec line gains the IDs the tests prove (AC-030, AT-006 export part, PR-11); A10 D8's section order gains "Your data" (D9); `FB_API_BASE_URL` is a secret (D13); backlog #34 and #40 close with WP2, #48 with the exit check, #45 with Q2's answer; #36 closes as covered (the update screen already says "Install the latest one", and the runbook says where) | Keeps the card honest |

**⚠️ OWNER questions** (ask before WP3/WP5 merge; each answerable with "ok"):
- **Q1 (security trade-off):** the daily prod APK, like today's staging one, is a CI artifact that any signed-in GitHub user can download from this public repo, and it contains the laptop's tailnet URL and the Sentry DSN. **Rec: ok** (the tailnet name is already public in certificate-transparency logs for `tailscale serve`, the tailnet ACL lets only the A55 in, and a DSN can only send events; spam is capped by Sentry's spike protection).
- **Q2 (privacy, backlog #45, A01 PA4, "answer before A11"):** back up the diary database through Android? Until sync (A34), losing the phone loses the data except the last export. **Rec: yes, device-to-device transfer + Google cloud backup only when end-to-end encrypted** (`disableIfNoEncryptionCapabilities="true"`, Android 12+; 8–11 stay excluded; install device id and session keys stay excluded). On "no", WP5 is dropped and the export is the only backup.

**Owner actions (not decisions):** create the free Sentry org in the **EU** region and set the project per `docs/runbooks/crash-reports.md`; add secrets `FB_SENTRY_DSN` and `FB_API_BASE_URL`; copy the key + password off the laptop and run D16's check; install the prod build, export once and open a CSV, send the test report.

**TD candidates:** (a) **Export format v1 + coverage registry** (every synced table and column exported or excluded with a reason, enforced by test; tombstones and install identity excluded) for `05` §6. (b) **Sentry on Android: Dart events only, native capture off or allow-list-scrubbed, no sessions, EU DSN enforced at build** (D11–D13), detailing TD-019 for `09` §4–5. Neither changes an Accepted TD (TD-060's gate is untouched by D14; TD-055's key and pin are unchanged).

### 3. Design

**3.1 `core/export/`** (data layer; imports `core/db` only)
```
export_registry.dart  ExportColumn(name, sqlName?, kind: text|int|real|bool|utcMs|json|derived), ExportTableSpec, exportRegistryV1  [WP1]
export_reader.dart    ExportReader(AppDatabase).snapshot() → ExportSnapshot(meta, rows by entity) (D7)                          [WP1]
csv_codec.dart        pure: encodeCsv(header, rows) with D5 rules                                                               [WP1]
export_builder.dart   pure: ExportBuilder.build(snapshot) → List<ExportFile(name, mime, bytes)>; run via Isolate.run          [WP1]
export_sharer.dart    port ExportSharer.share(List<File>) + SharePlusExportSharer (only share_plus importer)                    [WP1]
export_service.dart   DataExportService.export() → ExportOutcome {Shared(fileCount, rowCount) | Dismissed | Failed(kind)}     [WP1]
export_providers.dart dataExportServiceProvider, exportSharerProvider (overridable in tests)                                  [WP1]
```
`features/settings/application/data_export.dart` [WP1]: `DataExportController` (autoDispose): `idle | working | done | failed(kind)`, one export at a time.

**3.2 Crash reporting** [WP2]: `core/errors/error_reporting.dart` (D11, D12 options, `sendTestReport()`), `core/errors/pii_scrubber.dart` (unchanged unless R1 needs it), `app/router/app_router.dart` (observer), `core/config/app_config.dart` (D13 DSN shape check in staging/prod, empty allowed), native per R1 (`android/app/src/main/kotlin/…`, manifest meta-data), `tools/scripts/sentry_envelope_sink.py` + `test_sentry_envelope_sink.py` (canary grep over captured envelopes).

**3.3 Build and CI** [WP3]: `tools/scripts/build-android.sh` (D13 merged defines), `Makefile` (pass-through, help text), `.github/workflows/ci.yml` (`android`: secrets in env for staging; prod build on main/merge/*; A20 session check over both flavors; prod upload on main; summary lines for both), `tools/scripts/verify-key-backup.sh` (+ self-test), runbooks `docs/runbooks/install-a-build.md`, `docs/runbooks/crash-reports.md` (Sentry: EU org, "Prevent storing IP addresses", data scrubber + default scrubbers on, spike protection, DSN → secret), `android-signing.md` (D16, D13 secrets table).

**3.4 Presentation** [WP4]: `features/me/presentation/me_screen.dart` ("Your data" section), `features/settings/presentation/export_sheet.dart` (D9), `features/settings/presentation/about_screen.dart` (D17 long-press + confirm), ARB (≈ 10 keys), goldens for the sheet (light/dark, 1.0/2.0).

**3.5 Backup rule** [WP5, only on Q2 = yes]: `android/app/src/main/res/xml/data_extraction_rules.xml` (`<cloud-backup disableIfNoEncryptionCapabilities="true">` + `<device-transfer>` include the profile DB, keep excluding the device-id prefs and secure storage) and `backup_rules.xml` (Android 8–11: exclude, as today); `apk_hardening_check.py` pins the rule.

Layering: `presentation → application → core/export` (app_check); `core/export` reads only, never calls `runAuthorizedWrite`; no network client is reachable from it.

### 4. Work packages (sequential; the orchestrator commits after each WP once it has checked the diff and rerun the gates)

| WP | By | Tasks | Done when |
|---|---|---|---|
| WP0 | tech-researcher | **R1** sentry_flutter 10 on Android: which options stop native-origin events, sessions, ANRs, native logs/metrics while Dart events still deliver (`enableNativeCrashHandling`, `anrEnabled`, `autoInitializeNativeSdk`, native init in `MainApplication`); what a native event carries by default (user.id install id, device name). **R2** `share_plus` current version, multi-file API, Android manifest/FileProvider needs, minSdk 26 fit, licence | Cited, dated notes in `research-notes.md` |
| WP1 | Codex | §3.1 + `docs/export-format.md` + `share_plus` dependency + app_check `ioPackages`; tests T1–T10, T20 | `make gen-app check-dart test-dart` green |
| WP2 | Codex | §3.2; envelope-sink proof on the emulator (run by the orchestrator, evidence file); T11–T15 | gates + sink evidence (Dart canary scrubbed, `am crash` → no unscrubbed envelope) |
| WP3 | Codex | §3.3; T16–T19 | `make check test`, `bash -n`, script self-tests; a laptop `make build-android FLAVOR=prod` with test override values passes the hardening and signer checks; branch CI builds staging; the `merge/A11` run builds prod before `main` moves |
| WP4 | flutter-engineer | §3.4; T21–T24; grep `patrol_test/` for changed copy | `make check-dart test-dart`, goldens updated on CI |
| WP5 | Codex | §3.5 if Q2 = yes; T25 | hardening check self-test + `make build-android` passes |
| WP6 | orchestrator + owner | Secrets set; key backup verified (D16); prod APK from `main` installed on the A55, then an update over it; laptop API log shows `GET /v1/config` 200 from the prod build; test report in Sentry (no user, IP, device name, canary); export opened in a spreadsheet; verifier (M1); Dogfood 1 starts | `A11-verification.md` complete |

### 5. Test list
- **T1** `AC-030 every synced table has an export spec` (from `db.allTables` with sync columns, not from a hand list).
- **T2** `AC-030 every column is exported or excluded with a reason`.
- **T3** `AT-006 export counts equal live DB counts per table` (seed every table incl. tombstones and Arabic names; CSV row counts and JSON `counts`/arrays equal live counts; tombstones absent).
- **T4** `AC-030 JSON round-trips every exported value` (typed, `*_json` parsed, no `device_id`/`updated_hlc` anywhere in the output).
- **T5** `AC-030 CSV: BOM, CRLF, header, equal column counts, quotes/commas/newlines/Arabic survive a RFC 4180 parse`.
- **T6** `AC-030 CSV formula guard prefixes = + - @ tab CR text cells only` (numbers like `-5` untouched).
- **T7** `AC-030 empty database exports headers only and valid JSON`.
- **T8** `export reads in one transaction and is rejected by nothing in WriteGuard` (+ no `runAuthorizedWrite`).
- **T9** `export works with no network` (no API dependency injected; fake failing client untouched) · `export dir is wiped before each export`.
- **T10** `docs/export-format.md lists every file.column of the registry`.
- **T11** `PR-11 Sentry options: no sessions, no traces, no replay, native per D12` (plain `test`, S06 gotcha).
- **T12** `scrubber: canary food text in exception value, message params, breadcrumb, contexts → absent from the serialized envelope`.
- **T13** `navigation breadcrumbs keep route names only` (router push with arguments).
- **T14** `DSN shape: EU ingest accepted, US/http/garbage rejected in staging/prod, empty = off`.
- **T15** `sendTestReport sends one scrubbed event; inert with an empty DSN`.
- **T16** `build-android merges URL/DSN overrides, rejects bad values, never prints them, deletes the temp file` (bash self-test).
- **T17** `verify-key-backup accepts the pinned cert, rejects another keystore` (throwaway keystores).
- **T18** `ci: prod build runs on main and merge/*, uploads only on main` (CI structure check in the existing workflow self-test, or a `yq` assertion).
- **T19** `AT-006 reopening a populated user.db with a newer catalog pack keeps every row` (D15 (2)).
- **T20** `DataExportController: working → done/failed; second tap ignored while working`.
- **T21** `Me shows Your data → Export your data; tap opens the export sheet` (widget).
- **T22** `export sheet states: idle, busy, failure banner + retry; shares through the fake sharer` + goldens.
- **T23** `About long-press → confirm → test report; cancel sends nothing`.
- **T24** `UX-070 export sheet at text scale 2.0` (golden row).
- **T25** `backup rules: cloud backup only with E2E capability; device id and secure storage excluded` (hardening check fixture).

### 6. Exit-criteria mapping
| Exit criterion | Shown by |
|---|---|
| Export contains every entity; registry fails on a missing table; opens in a spreadsheet | T1–T7, T10 (CI) + owner opens a CSV in Sheets/Excel on the A55 (WP6) |
| Release-key backup confirmed, copy's SHA-256 = TD-055 pin | D16 script output on the copy, recorded in the evidence file (owner runs it; no secret printed) |
| Prod APK from CI installs, updates with data intact, fetches `/v1/config` | `android` job on `main` uploads `app-prod-release.apk` (job summary SHA-256 + cert); owner install + update over it (About build number changes, diary intact); laptop API log line; T19 + migration tests |
| Test crash in Sentry with no user content, device name or IP | T11–T15 + WP2 sink evidence + one real event from the A55 (event JSON screenshot/notes: no `user`, no IP, no device name, value `[scrubbed]`) |
| Dogfood 1 starts | Owner confirms daily logging on prod; recorded in the Outcome; board M1 |

### 7. Risks & unknowns
- **Native Sentry path (R1).** If Dart events can't deliver with native capture off and a Kotlin scrubber is needed, WP2 grows (+0.5 session). Fallback order: native off → Kotlin allow-list → ship with **DSN unset** and Sentry tracked as A11b (Dogfood 1 starts without crash reports; ask the owner, as it changes an exit criterion).
- **share_plus multi-file on Android** may route poorly to some targets; the JSON alone is complete. If owner testing shows it's awkward, a follow-up zips the set (logged, not in scope).
- **Prod CI time:** a second release build on `main`/`merge/*` adds ~6–8 min to `android` (runs parallel to `android-it`); timeout raised to 45. Merge waits may also hit the emulator flake (#112, unrelated): use `MERGE_REUSE=1` rules, never bypass.
- **First prod install is a new app** (no `.staging` suffix): data in a staging install doesn't move. Runbook says so; Dogfood starts on prod from day one.
- **Large exports:** 20k entries ≈ 15 MB JSON in the isolate; T3 runs a sized case and prints the time (non-gating).
- **B03 soft dependency is met** (✅); if the laptop is off the app runs offline and the `/v1/config` check waits for a laptop session.
- **Owner availability.** Q1/Q2 (⚠️ OWNER) gate the merge. WP6's phone checks are collected under `PROCESS.md` A.6, except the **key-backup check, which must pass before the owner starts logging real data on prod** (losing the key loses that data until A34).
- **TD-019 is still "Proposed"** although TD-029 (Accepted) names Sentry; WP3's close should propose accepting TD-019 with TD candidate (b), not change it silently.

### 8. Size check
**L, ~3–4 sessions** (WP0 0.25, WP1 1, WP2 0.5–1, WP3 0.75, WP4 0.5, WP5 0.25, WP6 owner-paced). Above the card's M because the native-Sentry proof and the prod pipeline are larger than the card assumed. **No split now;** natural seam if needed: **A11a** export + UI (WP1, WP4) and **A11b** crash reports + prod build (WP2, WP3, WP5, WP6). M1 needs both.

## Outcome
_Written in Phase E._
