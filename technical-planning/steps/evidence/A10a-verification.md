# A10a verification (2026-10-24)

Tier **Normal** (no write-path, schema or contract change). Branch `step/A10a-settings`, HEAD 57931a4. Verified by the verifier against the A10 card (A10a = WP1-WP4; A10b is out of scope) and `10-engineering-practices.md` section 9. Device-only checks are listed as such and are not claimed.

## Full checks

| Command | Result |
|---|---|
| `make test-dart` (full, run by the orchestrator, log in the session scratchpad) | app 1286 passed, 2 skipped; 10 packages passed (not rerun here) |
| `make check-dart`, `make gen-check` (orchestrator) | green (not rerun here); `check-dart` includes the new `patrol-name` rule |
| `make trace` (rerun) | rc 0; R1 319 total, 123 covered; one pre-existing warning (ZZ-060 in the trace tool's own scanner fixture). Every R1 ID the A10a card names is in the covered table: UX-010, UX-013, UX-040, UX-050, UX-051, UX-052, LC-010, LC-011, LC-012, LC-021, LC-033, LC-040, FD-080, FD-022. SF-040 is `[R2]` and so not in the R1 table; it is tagged in 5 tests anyway. DY-010 is covered (A10b's slot work is not part of this) |
| Focused app tests (rerun): `test/features/settings`, `test/core/l10n`, `test/app/router`, `test/features/design_preview`, `test/features/foods/food_search_test.dart`, `test/features/today/presentation/today_golden_test.dart` | all passed (86 + 89 tests in two runs, 0 failures) |
| `packages/fb_domain` `test/a10_settings_test.dart` (rerun) | 10 passed |
| `packages/fb_design_system` switch_row, option_sheet, license_page + both golden tests (rerun) | all passed |
| `tools/app_check` (rerun, includes `patrol-name` guard test) | 78 passed |
| `tools/catalog` `test/fixture_sql_test.dart` (rerun, city fixture rows) | 4 passed |
| `make build-it` (rerun) | rc 0 in 1 min 6 s; dev debug app APK and androidTest APK built |

## Exit criteria

| Criterion (A10a) | Evidence | Status |
|---|---|---|
| 1. Switching to imperial changes all displayed weights/volumes; stored values unchanged | `apps/mobile/test/features/settings/presentation/unit_display_test.dart`: `LC-010 exit 1: switching to imperial changes every food amount on Today rows, expanded details, the amount sheet and undo messages; switching back restores them`; `... changes the amount on search results and the food sheet (default and yield note) ...`; `LC-010 exit 1: the food sheet's yield note and default follow the unit system`; `LC-010 exit 1: after switching, the diary, groups and saved-meal tables are byte-identical (A01 D3 comparison) and the outbox gained only setting rows`; `LC-010 Per 100 g headings and nutrient grams stay metric in imperial`; PA2: `PA2 UX-052 in imperial, opening the amount sheet on a 100 g entry shows 100 g as typed; Save untouched is Unchanged and the row ... is byte-identical`, `PA2 the food sheet's typed buffer is never replaced by a converted display value`; `FD-022 LC-010 imperial search rows open on the sheet default portion`. Display rules: `packages/fb_domain/test/a10_settings_test.dart` (FoodAmountDisplay both directions, density-backed inputs, 1,000-run property, UnitOptions, DefaultPortion) and `test/core/l10n/amount_text_test.dart` (5 tests). Coverage guard: `D4 guard: no presentation file formats a food amount outside amount_text.dart`. All executed, all passed | ✅ |
| 2. Slot customisation and auto-assignment | A10b (WP5-WP7), out of scope | n/a (A10b) |
| 3. Week start changes the week used by `WeekCalendar` | `apps/mobile/test/features/settings/settings_test.dart`: `LC-021 weekCalendarProvider: default week of Thu 2026-10-22 starts Sat 2026-10-17; with monday it starts Mon 2026-10-19; follows a change without restart`; UI: `LC-021 the Week starts on sheet sets the first day, with Undo`. Passed | ✅ |
| 4. Goldens for the settings screens (slot editor goldens are A10b) | `settings_golden_test.dart`, 4 columns each (light/dark x scale 1.0/2.0): `me: settings`, `units option sheet`, `city picker: suggestions`, `city picker: results`, `about`; plus `today: full day, imperial` and DS `switch_row`, `option_sheet` matrices. PNGs committed under `test/features/settings/presentation/goldens/ci/` and `packages/fb_design_system/test/components/goldens/ci/`; goldens pass in the focused run | ✅ |
| 5. Owner: set your real settings; feedback | Backlog #115 (owner check on the A55): imperial/metric, theme, week start, halal, city Nablus, restart and confirm they stick, About and licences page | ⚠️ owner check backlog #115 |

## Other A10a Done-when items (card section 4, section 5)

- Week start / halal / theme / city / energy: `FD-080 LC-040 Halal switch on by default; turning it off shows Undo`; `LC-012 the Energy row says kcal and is not tappable`; theme: `UX-040 #75 Theme sheet: Dark switches the app to dark at once; the choice survives a restart (new ProviderScope over the same DB); Undo restores System`; `UX-001 the first frame doesn't read the settings store; the theme is read after it`; setting keys/codec/actions tests (names pinned, defaults, undo, `Unchanged` on same value). ✅
- City: `LC-033 city picker: empty query shows the current city then PS/JO suggestions; typing "nab" shows Nablus first; a tap sets it, pops, shows Undo`; `LC-033 city search: "nablus" and "نابلس" ...`; no-pack and no-match states; `D7 "Use my location" shows only in dev, saying Coming soon`; `LC-033 city search perf p95 < 5 ms over 2,300 rows (printed)` (WP1 log: p50 1.696 ms, p95 2.227 ms, max 4.218 ms; fails under load, see backlog #116). ✅
- States (UX-050/051/052): city picker skeleton and read-error with Try again; About skeleton, unavailable credits, version error; passed. ✅
- Text scale and RTL: `UX-070 Me and the city picker at text scale 2.0 do not overflow`, 1.3 variant incl. About, two `RTL UX-070` tests, goldens at 2.0. ✅
- About: `SF-040 About shows the version, the food data version, the USDA and GeoNames credits, the licences link and "Fitness Buddy gives estimates for tracking, not medical advice."`; `D14 about info: only active credits ...`. ✅
- Me structure: `UX-010 the Me tab shows Food (when present), Settings and About in that order; empty sections are hidden; Design preview only in dev`; `UX-013 every setting is 2 taps from Today`. ✅
- No write-path change: `git diff --name-only main...HEAD` has no `core/changes/`, `settings_op_handler.dart`, `settings_ops.dart`, `lib/core/db/`, `contracts/` or `backend/` path. The only `core/db` file is the test helper `apps/mobile/test/core/db/support/db_support.dart` (bounded `db.close()` in tear-down, test-only). The only SQL change is `test/fixtures/catalog_fixture.sql` (10 city rows) with the generator change in `tools/catalog` (documented deviation in the card's Progress log). No migration. ✅
- #87 guard: `tools/app_check/lib/src/patrol_names.dart` (rule `patrol-name`) with `check-dart fails on a patrolTest name with Arabic, ; or /`; app_check suite passes. ✅

## Device checks (not run here; not claimed)

| Item | Status |
|---|---|
| Patrol `A10 settings journey units theme city` (`apps/mobile/patrol_test/settings_test.dart`) | built by `make build-it`; run it on the CI `android-it` job (emulator) |
| Patrol `A10 cold start with a persisted opposite theme` (theme flash measurement, PA5/D6; prints frames and ms until the chosen theme) | CI `android-it`; the measured result must go into the card's Outcome as a known issue if the first frame shows the wrong theme (the test fails only if the chosen theme never shows within 30 s) |
| Owner check on the A55 | backlog #115 |

## DoD (section 9)

1. Spec IDs implemented: ✅ (the A10a IDs above). 2. Domain logic unit-tested: ✅ (fb_domain 100% line coverage per the WP1 log; not re-measured here). 3. UI states, light/dark, scale 2.0, goldens: ✅. 4. Offline: ✅ (settings, cities and About read local stores only; no network on the path). 5. Writes via change sets with undo: ✅ (SettingsActions put/reset; tests above). 6. Strings in ARB: ✅ (61 keys added in `app_en.arb`; `check-dart` green). 7. API: n/a (no contract change). 8. Traceability tags: ✅; CI fully green: pending (CI `android-it` on the pushed HEAD). 9. Performance budget: city search p95 < 5 ms ✅ (printed in WP1; load-sensitive, #116). 10. Docs: the card's **Outcome** section is still empty ("Written in Phase E"); the card Progress log is current through WP4.

## Not met / to do before merge

1. Card **Outcome** not written (Phase E); the Progress log has no entry for the UX-review fix commit 57931a4 or for the Codex/ux reviews.
2. Backlog #75 (theme choice) and #87 (patrol-name guard) are still `open`; both are delivered by this step and should be closed at merge.
3. `android-it` must be green on the pushed HEAD, including the new Patrol settings tests and the cold-start theme measurement; owner check #115 stays open until the owner runs it.
