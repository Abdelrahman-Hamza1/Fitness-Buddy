# A42 — Performance, accessibility & offline acceptance

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A41a, A35 | M | Claude | ✅ Closed, awaiting review/merge |

_2026-10-30 (TD-105): the last phase-1 step and the gate of milestone M2b. Depends on A41a (not the Buddy half A41b) and A35. The Buddy round-trip speed (UX-005) is measured on what exists then; phase 2 re-checks it at M3._

_Old ID: S48 (renumbered by TD-063, 2026-10-16)._

**Goal.** Measure and fix what users feel: startup, smoothness, speed targets, accessibility and offline behaviour, on the reference device.

**Spec:** AT-004, AT-005, UX-001–007, UX-070, UX-071, OF-01, OF-02, OF-03, SC-2 · **Decisions:** TD-034 (Android-only R1)

## Scope
- **Speed targets** (UX-001–007) measured on the **Samsung A55** (the iPhone pass is R2, D-081): cold start → input bar, repeat meal taps, weigh-in taps, barcode → logged taps, Buddy round trip, no blocking spinners.
- Profiling and fixes: startup work, jank on Today/Progress/charts, DB query plans, image handling, app size.
- **Accessibility:** text scale 1.5/2.0 on every screen, contrast (AA) re-verified, colour never the only signal, tap target sizes.
- **Offline scenarios** OF-01–03 as automated E2E tests on a device/emulator, and once manually on the A55.
- Crash-free sessions over the dogfood period from Sentry (> 99.5%).

## Out of scope
- Screen-reader labels (R2, UX-072).

## Fixed by the plan
- Budgets in `09` §6.

## Decide in the low-level plan
- The measurement method per target (integration test timeline vs manual stopwatch protocol).

## Exit criteria
- [ ] Every UX-001–007 target met and recorded with the method.
- [ ] OF-01, OF-02, OF-03 pass (AT-005).
- [ ] All screens usable at text scale 2.0. The contrast test is green.
- [ ] Crash-free sessions > 99.5%.

## Read first
`09-cross-cutting.md` §6–7 · `spec/30-ux-principles.md` §1, §8 · `spec/40-acceptance-criteria.md` §4

## Owner involvement
Confirm it feels fast on your phone.

---

## Low-level plan
_Claude, 2026-10-31. Tier **Normal** (tests, measurement tooling and layout fixes; no user-data write path changes). One engineer (Claude) builds it; one combined Codex review. Size: M (est. 1 session incl. one fix round)._

### D1 Measurement method per target (the card's open decision)
| Target | Method | Gate |
|---|---|---|
| UX-001 open → input bar ready ≤ 2 s | Two parts on the A55, both release/profile builds: **(a)** `make cold-start` (process start → first Flutter frame, `am start -W`, 10 cold runs, median/p90; existing S06 D20 script) and **(b)** new `integration_test/startup_benchmark_test.dart`: the real wiring (`appOverrides`, a throw-away file profile seeded with a realistic month), timed from `runApp` to the first frame where Today's numbers are loaded and the input bar is enabled, cold container + fresh DB open every run, p50/p90. UX-001 ≈ (a) p90 + (b) p90 ≤ 2,000 ms. Host gate unchanged: the UX-001 tests that nothing touches storage or the network before the first frame (`startup_test`, `app_shell_test`, `session_bootstrap_test`) | owner A55 check (optional, D-087) |
| UX-002 message → card ≤ 5 s p90 | Existing `integration_test/buddy_round_trip_test.dart` (A22 D19, paid, owner's scope). No new Buddy work (TD-105); phase 2 re-checks at M3 | owner check, optional |
| UX-003 confirm in 1 tap | Host: `buddy_sheet_test` "UX-003 … one tap" (existing) | CI |
| UX-004 repeat meal ≤ 2 taps | Host: `quick_add_bar_test` "UX-004 … 1 tap (tap counter)" (existing) | CI |
| UX-005 weigh-in ≤ 3 taps | Host: `today_weight_test` "WB-001 UX-005 …"; device: `patrol_test/weigh_in_test.dart` (nightly) | CI + nightly |
| UX-006 barcode → logged ≤ 3 taps | Host: `barcode_scan_screen_test` "FD-030 T17 UX-006", `food_sheet_test` "AI-048 UX-006" (existing) | CI |
| UX-007 instant, no blocking spinners | **Host:** the route sweep (D2) fails when any routed screen shows a `CircularProgressIndicator` once its local data is loaded; the query-plan audit (D3). **Device:** new `integration_test/jank_benchmark_test.dart` (`IntegrationTestWidgetsFlutterBinding.watchPerformance`: Today day swipes + scroll, Progress scroll + period switch, Workouts history scroll on seeded data), prints build/raster p90/p99 and missed-frame counts; budget p90 build and raster < 16 ms. Existing `progress_benchmark_test` (charts < 300 ms) and `proposal_recompute_benchmark_test` (≤ 50 ms) stay | host in CI; device = owner check |

**One command for the device numbers:** new `make perf-device` (phone over adb; runs the startup, jank, Progress and recompute benchmarks in profile mode with the dev flavor, which the existing commands' docs were missing) + `make cold-start`. Documented in `apps/mobile/README.md`.

### D2 Accessibility route sweep (`test/acceptance/`)
- `support/acceptance_app.dart`: the whole app (`pumpApp`, offline `TestPhone`) on a seeded in-memory profile (today's entries in several slots, 30 days of history, a saved meal, a personal food, 30 weigh-ins, a measurement, a custom exercise + two sessions + a template) and the list of **every routed screen** (all `AppRoute`s except the dev-only design preview), with IDs taken from the seed; plus the Buddy and weigh-in sheets.
- `text_scale_sweep_test.dart`: one test per scale (1.5, 2.0) at 360 × 800 dp (narrower than the A55): visits every route and collects every Flutter error (RenderFlex overflow, layout errors) per route; fails listing them. Plus a 1.0 pass with `androidTapTargetGuideline` (48 dp) and the UX-007 spinner check, and `textContrastGuideline` in light and dark if stable (else dropped, token test is the gate).
- Fix what it finds (layout, not copy). Goldens regenerate only where a fix changes them.
- **Contrast:** the token test exists (`contrast_test.dart`); add a theme-level test in `fb_design_system` over the built `ColorScheme` role pairs (primary/onPrimary … inverseSurface/onInverseSurface, both themes) so a theme mapping can't bypass the token pairs.
- Colour never alone: covered by existing SF-021/macro label tests; the sweep doesn't re-test it.

### D3 Query-plan audit (`test/acceptance/query_plan_audit_test.dart`)
- The seeded app on a database wrapped in a drift `QueryInterceptor` records every SELECT issued while visiting every route; each distinct statement gets `EXPLAIN QUERY PLAN`; fails on a full `SCAN` of a growing table (diary, weigh-ins, measurements, workout sessions/exercises/sets, chat messages, proposals, outbox, personal foods, saved meals). Fix with an index (a drift migration) or a query change; small fixed tables (slots, settings, targets) are allowed.

### D4 Offline acceptance (AT-005)
- **OF-01** `test/acceptance/offline_of01_test.dart`: the whole app on an offline phone (every request fails): log a quick-add chip, edit an entry's amount, log a weigh-in, log a workout by the form, open Progress with its charts: each lands in the profile; the request log shows only failed background calls, never a blocked screen. **Patrol:** `patrol_test/offline_test.dart`, the same journey on the nightly emulator (no API reachable there).
- **OF-02:** barcode half = an app-level test: a typed barcode offline joins the pending list; online again (fake server answers), the next trigger makes it ready and one tap logs it. **Buddy half (AI-047) is A23b's** (phase 2, TD-105; card test list already names it): recorded as a gap, not built here.
- **OF-03** = `packages/fb_sync/test/convergence_test.dart` (engine) + `make sync-spike` (real API). Add an app-level two-device test (`test/acceptance/offline_of03_test.dart`): two drift profiles, the app's applier and sync store, one fake server; the same diary entry edited offline on both; after sync both show the later edit and the earlier one is readable via `readEarlierVersions` and restorable.

### D5 Crash-free sessions
Sentry Release Health, read after dogfooding: documented in `docs/runbooks/` (where to look, the 99.5 % threshold, what counts). Owner/ops check.

### D6 Other fixes
App size: the 2026-10-30 prod release APK is 32.2 MB (budget < 40 MB); nothing to do. Startup path already defers all I/O past the first frame; fix only what the benchmarks or sweeps expose. Backlog #73 (Today at 2.0) is closed by the sweep if it passes; #248 left as is.

### Work packages
WP1 plan · WP2 sweep support + text-scale/tap-target sweep + fixes · WP3 query-plan audit + fixes · WP4 theme contrast test · WP5 offline OF-01/02/03 tests + Patrol case · WP6 device benchmarks + `make perf-device` + runbook · WP7 A41a merge (if landed), cross-check, Outcome, board, backlog.

## Outcome
_Claude, 2026-10-31; revised after Codex review 1 (6 majors, fixed in round 1). Tier Normal, one engineer, size M+ (one session plus one fix round)._

**What was built**
- **Accessibility sweep** (`apps/mobile/test/acceptance/accessibility_sweep_test.dart`, support in `test/acceptance/support/`). It visits every routed screen of a seeded profile (a month of diary, today's meals, saved meal, personal food, 31 weigh-ins, a measurement, exercises, sessions, a template): each route must show its own screen (`screenOf`, an exhaustive switch), and the visited paths must equal the router's registered paths (`registeredPaths`), so an omission or a duplicate fails. Every vertical list is scrolled through a little less than a screen at a time (lazy items are built), Today's meals are all opened with an entry's details, the Buddy and weigh-in sheets are opened, and setup's five pages are walked on a fresh, unconfigured profile. All at 360 × 800 dp (narrower than the A55):
  - text scale **1.5 and 2.0**: no overflow or layout error anywhere (> 60 places checked per run);
  - scale 1.0: **48 dp tap targets** and **no spinner over local data** (UX-007). Found the 44 dp compact list rows → `FbDensity.rowMinHeight` 48 (8 goldens moved). **Not covered by the 48 dp claim** (exempt, with reasons in the test): chart data marks (a week bar is 37 dp on a 360 dp phone; above WCAG 2.2's 24 px minimum, values also in text), so "every tap target ≥ 48 dp" holds for controls, not chart marks; and nodes cut by their scroll view's edge (judged at another scroll stop);
  - **rendered contrast, light and dark**: each visible paragraph and each field's typed text, its colour and its backdrop both painted through every fill (physical models, boxes, `InputDecorator` fills, the scaffold) and every opacity above it, as the engine composites them; disabled controls exempt; 4.5:1, or 3:1 for large text. Planted cases (faint text, text in a faded dark panel at about 4:1, typed text, text on a dark field fill) prove each path. Flutter's pixel-sampling `textContrastGuideline` was tried first and dropped: its only findings were false.
- **Ramadan (A41a, merged 3b298b8)**: the sweeps also run a profile whose clock is a day of Ramadan 1448 with the mode on: Today with the Ramadan meals (all opened), Today marked not fasting, Settings › Ramadan, the Ramadan meal times, Progress with the Ramadan comparison card (its data required), Targets; at 1.5/2.0, tap targets, spinners and contrast in both themes → green. Both new routes are in `everyRoute` (the registry check requires them). The sweep found one bug in A41a's code, fixed: `ramadanComparisonProvider` called `ref.watch` after an await, so leaving Progress while it loaded threw `UnmountedRefException` (an error report); it now returns when the provider was disposed meanwhile.
- **Theme contrast** (`fb_design_system/test/tokens/contrast_test.dart`): every `ColorScheme` role pair the built themes define (primary, secondary, tertiary, the fixed roles, containers, error, inverse, all surfaces incl. bright/dim) and outlines at 3:1, light and dark, on top of the token pairs.
- **Query-plan audit** (`test/acceptance/query_plan_audit_test.dart`): the seeded app on an intercepted database with the fixture food pack (real food search, not a stub) visits every route, state and sheet, then searches foods and exercises, switches Progress periods and weight-graph ranges and swipes to past days. Every distinct SELECT gets `EXPLAIN QUERY PLAN`; any `SCAN` of a growing table (a whole-index walk too), with aliases resolved, fails unless it's on the accepted list with its reason: by design (personal foods list, the weigh-in trend and history, measurement history, the workout history, `LIMIT 0` probes, the partial pending-proposals index) or a logged gap (#265 Today's workout row reads the whole history; #266 the per-slot entry counts need an index in the next migration; proposals by kind are indexed since A41a's v13). A unit test checks the detector against real SQLite plans.
- **Offline acceptance (AT-005)**, production wiring and a network that **hangs** (requests are taken and never answered, so any path that awaits the network can't finish): `offline_of01_test.dart` (pack updates, online search and notification scheduling on, the chip resolved through the bundled fixture pack: quick-add chip, entry edit, weigh-in, workout by the form, Progress charts), `offline_of02_test.dart` (barcode typed offline → pending → online, next scanner visit → ready → one tap logs it; only the server endpoint is faked), `offline_of03_test.dart` (two phones with the app's applier and drift sync store; both sync orders: later edit wins on both, the earlier one is in the history and restores). Engine-level OF-03 stays in `fb_sync` and `make sync-spike`. Nightly Patrol `patrol_test/offline_test.dart`: airplane mode on, all five OF-01 actions. **OF-02's Buddy half (AI-047) is A23b's** (#261).
- **Device benchmarks**: `make perf-startup` (UX-001 end to end: one seed run, then 10 fresh app processes, each timed from the process's own start to Today ready with loaded data and a tappable input bar, then the bar must open Buddy's sheet and take text; p50/p90); `make perf-device` (the jank benchmark under the `benchmarkLive` frame policy with real flings over ten months of diary and 120 workouts, each fling must move its list, p90/p99/max and the share over 16 ms, fails on any frame over 16 ms; plus the Progress and recompute benchmarks with the flavor flags they lacked).
- **Crash-free**: release health is off by design (A11), so the runbook reads "observed dogfood errors" (a proxy); the > 99.5 % criterion stays unverified unless release health is turned on or waived (#262, owner question).
- App size: the 2026-10-30 prod release APK is 32.2 MB (budget < 40 MB).

**Measurement method per target (D1, revised)**
| Target | Method | Status |
|---|---|---|
| UX-001 ≤ 2 s | `make perf-startup`: process start → Today ready, one sample per fresh process, p90; `make cold-start` as a second view; host: nothing touches storage/network before the first frame | host ✓; **A55 numbers pending** (#260) |
| UX-002 ≤ 5 s p90 | `buddy_round_trip_test` (paid, owner scope); phase 2 re-checks at M3 | pending, optional |
| UX-003/004/005/006 taps | host tap-count tests (`buddy_sheet_test`, `quick_add_bar_test`, `today_weight_test` + Patrol `weigh_in_test`, `barcode_scan_screen_test`/`food_sheet_test`), OF-02's one-tap log | CI ✓ |
| UX-007 | host: sweep spinner check + query-plan audit; device: jank benchmark (no frame > 16 ms), Progress and recompute benchmarks | host ✓; **A55 numbers pending** (#260) |

**Exit criteria**
- [ ] UX-001–007 met and recorded: methods in place and host gates green; the device numbers (UX-001, UX-007) are still to be measured on the A55 (#260). Owner checks are optional (D-087), so this doesn't block the merge, but the criterion isn't recorded as met.
- [~] OF-01 ✓, OF-03 ✓, OF-02 barcode ✓; OF-02 Buddy half waits for A23b (#261).
- [x] All screens usable at text scale 2.0 (sweep), contrast tests green (tokens, themes, rendered text).
- [ ] Crash-free > 99.5 %: unverified; release health is off (#262).

**Tests run locally** (each through `heavy.sh`, `timeout 600`): `test/acceptance` (sweep 7, query audit 2, OF-01 1, OF-02 1, OF-03 2: all ✓), `fb_design_system` contrast ✓ (and the full package, 130 ✓, in the first round), app presentation/feature dirs touched by the row height (286 ✓, first round), goldens regenerated (8). `make check-dart` ✓, `make gen-app` no diff. The device benchmarks and the Patrol journey can't run on the laptop (no emulator, 7 GB): nightly / owner.

**Owner checks on the A55** (optional, never block; #260)
1. `make perf-startup` (phone over adb): prints 10 samples and p50/p90; UX-001 is met at p90 ≤ 2,000 ms.
2. `make perf-device`: UX-007 per-journey frame lines, Progress chart p95s, recompute p95.
3. `make cold-start` with the prod or staging build installed (`COLD_START_APP=io.github.abdelrahmanhamza1.fitnessbuddy` for prod).
4. Airplane mode once: quick-add chip, edit an entry, weigh-in, workout, Progress; scan a barcode, then go online and reopen the scanner.
5. After two weeks of use: the "observed dogfood errors" reading in `docs/runbooks/crash-reports.md`.

**Review 1 (Codex): 6 majors, fixed** (sweep proof, contrast through layers, stricter query audit, offline production paths + hanging network + airplane-mode Patrol, UX-001 end to end, live-scheduled jank). Minors: theme roles widened, crash-free labelled a proxy, perf criterion marked pending, retired benchmarks documented.

**Backlog:** new #260–#266; #61, #84, #90 closed as retired by A46 (no replacement for the DB-write, food-search and Today-latency device workloads, by A46's choice); #219 reopened (now runnable through `make perf-device`).

## Progress log
- 2026-10-31: plan written (Normal tier, self-approved; one engineer, one Codex review).
- 2026-10-31: built 3283e7ad (a11y sweep, 48 dp rows), fbeb5bf6 (query plans), 1b9d489d (theme contrast), c54bccde (offline), 0ae5ab5f (device benchmarks); closed, awaiting Codex review. A41a not on main yet: its screens join the sweeps when it lands.
- 2026-10-31: Codex review 1 (6 majors): fixed in 09468785 (sweep, contrast, audit), 00f29878 (offline), 777f6ae0 (startup, jank), plus minors and docs; A41a still not on main.
- 2026-10-31: merged origin/main (A41a, 3b298b8): Ramadan routes and states in the sweeps, the comparison provider fix, backlog renumbered #260–#266; goldens (me_settings) regenerated.
- 2026-10-31: fix-check 1: perf-startup now fails on a failed Flutter run and the sample prints only after the typing checks; Outcome marks chart marks as outside the 48 dp claim.
