# A16 — Progress tab v1

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A13, A15 | L | Claude | 🟨 Awaiting merge |

_Old ID: S23 (renumbered by TD-063, 2026-10-16)._

**Goal.** The Progress tab with calories, macros, weight, measurements and goal progress, all filterable by goal phase, so weekly progress is obvious at a glance (SC-5).

**Spec:** IN-002, IN-003, IN-004, IN-006 (measurements; exercise entry in A37c), IN-007, IN-009, IN-020, IN-021, DY-004 (manual incomplete marking in the UI), SC-5 · **Decisions:** —

## Scope
- **Progress tab layout:** a current-week header (the weekly summary card arrives in A39), then chart sections.
- **Calories chart** (IN-002): daily intake vs daily target, by week or month. **Incomplete days** marked differently.
- **Macros chart** (IN-003): P/C/F/fiber per day vs targets.
- **Weight** (IN-004): the A15 graph embedded, plus a link to the full view.
- **Measurements** entry points (IN-006).
- **Goal progress** (IN-007): the current phase, progress toward the target weight, this month vs the monthly target.
- **Phase filter** (IN-009) on every chart.
- **Mark a day incomplete** from the diary day menu and the chart (DY-004 manual). The suggestion comes in A38.
- Check IN-020/021: no streaks, scores or micronutrient dashboards.

## Out of scope
- The weekly summary + review (A39). The expenditure chart (A38). Exercise progress (A37). The Ramadan comparison (A41).

## Fixed by the plan
- Past targets are recomputed from current data (G10), so charts reflect corrected history.

## Decide in the low-level plan
- Aggregation queries vs the in-memory domain for month views (measure first, `03` §4).

## Exit criteria
- [ ] With one year of seeded data, each chart renders in < 300 ms on the A55 (measured).
- [ ] The phase filter changes every chart (widget tests).
- [ ] An incomplete day is visibly distinct in the calories chart (golden).
- [ ] The owner can answer "how did this week go?" in one tap from Today (SC-5, the review card comes in A39).

## Read first
`spec/16-insights-and-home.md` §2–3

## Owner involvement
Review with your real data.

---

## Low-level plan
_Step-planner, 2026-10-30, lane 1 (`~/work/fitness_buddy`, branch `step/A16-progress-tab` from `origin/main` fe4f671). Planned against the code on main (A15a/A15b merged, A13c, A23a). **Codex plan review round 1 (2026-10-30): approve with changes; PA1–PA6 applied (table at the end of this plan; where they differ, the amended text wins).** **Tier: Risky** (D1, PA2). **Implementation starts after A46 (test diet) merges** (it deletes most goldens and Patrol files; this plan adds no Patrol test and edits none). TD-104 lean tests, TD-105 phase 1: **no Buddy work**. Reviews: Codex (plan, then two parallel tasks: code/architecture incl. UX, and security/data integrity). **Milestone M2:** the verifier runs at close (`13` §3.D.4)._

### 1. Summary
After A16 the Progress tab opens on **this week** (SC-5: one tap from Today, the bottom-nav tab) and shows, for one selected **period** (Week, Month or a goal **Phase**, IN-009), a **calories chart** (daily intake vs the day's target, incomplete days hatched; IN-002), **macro charts** (P, C, F, fiber vs targets; IN-003), the **weight chart** for the same period with a link to A15's full graph (IN-004), **goal progress** (IN-007) and the **Measurements** entry (IN-006). A day can be **marked incomplete** (and back) from the chart and from a new **day menu** on Today (DY-004 manual), with undo. No schema, sync or contract change: day marks, daily totals and targets already exist (A06, A13).

**Already on main (kept, not redone):** `ProgressScreen` with Weight graph and Measurements rows over an empty state; `WeightGraphScreen` (`/progress/weight`, phases shaded, WB-023 stats), `weightGraphProvider`, `phasePeriods`, `chartTimeOf`, `GraphRangeChips`; the Measurements screens; `DiaryReads.dailyTotalsSql` (indexed `GROUP BY local_date`); `watchDayMarks`; the `MarkDay` op + handler + undo (A06 D11, no UI yet); `TargetsTimeline.day`; `WeightStats` / `MonthlyTargetRate`.

### 2. Decisions
| # | Decision | Why |
|---|---|---|
| D1 | **Tier Risky (PA2).** A new command (`DiaryActionsController.markDay`) and two UI entry points (chart details, Today day menu) on a user-data write path. The write itself goes through the existing `ChangeSetApplier`, `MarkDay` handler, outbox trigger and undo (A06-tested); no new op, table, migration, sync entity or contract. Reviews: two parallel Codex tasks (code/architecture incl. UX; security/data integrity); the security result goes in `steps/evidence/A16-verification.md`. | `PROCESS.md` A2 (user-data write path), B |
| D2 | **Card item "aggregation vs in-memory": indexed SQL per-day aggregates + in-memory domain, no cache table.** Daily totals come from the existing `dailyTotalsSql` (`ix_diary_entries_live`, < 10 ms a year per `03` §4); day marks from `watchDayMarks`; per-day targets and buckets are pure `fb_domain` code over those rows. **Measured** by a host `perf` test (CI) and an A55 profile benchmark (D16). Fallback ladder if a chart misses 300 ms on the A55 (PA3): (1) cache the **shared inputs** only (decoded settings/profile/phases, the trend lookup, per-week intake slices, the training input), never targets: `TargetsTimeline.day` stays evaluated **per date**, because each date depends on its earlier intake, trend weight, effective settings version and same-day workout adjustment; (2) build the series in `Isolate.run`; (3) only then a derived cache table (would need a TD). | `03` §4 "measure first"; a month view is ≤ 31 rows, a 1-year phase 365 |
| D3 | **IN-009 = the period selector, shared by every chart on the tab.** Steady chips **Week · Month · Phase** + a `‹ label ›` stepper: previous/next week (the week-start setting, `WeekCalendar`), calendar month, or goal phase (in date order). Default: the current week. Phase chip hidden when there are no phases. A phase period spans `phase.start … min(phase.end, today)`. `›` stops at the current period; `‹` stops at the earliest data (D14). State is session-only (`progressPeriodProvider`, keepAlive like A15's window). | One control that filters calories, macros, weight and goal progress together; TG-012 "filtered or shaded" |
| D4 | **Buckets by span** (pure, `ProgressBuckets`): ≤ 62 days → daily bars; ≤ 366 days → weekly bars aligned to the week start; longer → calendar-month bars. **Daily buckets keep the day's actual intake and target whatever its status** (an incomplete day with logged food draws its real, hatched bar against its target; PA1). **Exclusions apply only to aggregates:** a week/month bucket's intake and target are **averages over its counted days** (entries > 0 and not marked incomplete); one with no counted day is empty, and its details say how many days weren't counted. | Keeps bars ≥ ~6 dp on a 360 dp phone; TG-032 (missing = unknown, never zero) |
| D5 | **Day status** (domain enum): `logged`, `incomplete` (marked; its bar shows the logged intake, PA1), `unknown` (no entries, not marked: no bar, a baseline tick), `inProgress` (today). Drawing: one neutral brand tone; the part above the target in the `overTarget` grey (no red, PR-12/HM-001); target = a tick per bar; incomplete = outlined + hatched + "not counted" in semantics; today = lighter fill. Meaning never by colour alone (UX-071). | IN-002 "incomplete days marked differently"; IN-020 |
| D6 | **A day's target = `TargetsTimeline.day` with the same inputs as `dayTargetsProvider`**: the settings, profile and phases; the trend weight on that day (`WeightTrend.trendOn`); that week's earlier intake and marks; the week calendar; one `TrainingShiftInput` over the range (`remainingWeights` only checks the day itself, so a multi-week `loggedDates` set is safe). Evaluated **per date** (PA3; only inputs are shared). So the chart's target for a day equals what Today shows for it (`dayTargetsProvider(date)`), recomputed from current data (G10, "Fixed by the plan"). Days before the first settings version have no target. | Single source of the numbers; no second targets engine |
| D7 | **New DS widget `FbBarChart`** (`fb_design_system/src/charts/`, a `CustomPainter` like TD-012's chart): `bars` (`FbBar`: `at` naive day, `value?`, `target?`, `FbBarStyle {solid, hatched, faint}`, `key`), `selected`/`onSelect(int?)`, `formatValue`, `formatLabel`, `semanticLabel(int)`, `emptyLabel`, `compact` (macro height), `aspectRatio`. Bars run in **reading direction** (LC-003, oldest at the start); y from `nice_scale` with a zero baseline over values **and** targets; a tap selects the **nearest bar by x** (tolerance ≥ 24 dp); semantics step the selection like `FbTimeSeriesChart`; tokens only; `RepaintBoundary`, cached labels. Screens never use a chart library directly (A15 "Fixed"). | A time-series painter doesn't fit categorical days with per-bar style/targets; the bars are simple |
| D8 | **Weight on the tab (IN-004):** a compact `FbTimeSeriesChart` over the **period's window** (dots, trend, goal line, phase periods; no pan, no selection, no cone), built from the existing `weightGraphProvider`'s weigh-ins and trend. **The goal line and phase boundaries come from the period, not from today (PA4):** `weightGraphProvider.goalKg` is today's active phase, so for a Phase period the goal is resolved from the **selected phase's** record (`GoalHistory.phases` for selection and boundaries; date/rate goals → target kg, rate-only → no line); Week/Month use the phase active at the period's end. Tapping the card or its "Weight graph" row opens the full view (`WeightGraphRoute`, unchanged). The series/period building shared with `WeightGraphScreen` is extracted into `progress/application/weight_chart_parts.dart` **without changing the full view's output**. | Reuse A15a; the period filters this chart too |
| D9 | **Goal progress (IN-007):** pure `GoalProgress.of({phase expression, phase start/end, trend, today})` → start trend (A15a's stale-start rule via `WeightStats`' start point), latest trend (at `min(end, today)`), target kg (date/rate goals), `fraction` toward the target clamped to 0…1 (moving away = 0, never negative; null without a target, a trend or when start = target), `reached`. The card shows the **current phase** for Week/Month and the **selected phase** for Phase; "this month vs the monthly target" comes from the existing `WeightStats`/`MonthlyTargetRate` and shows only for the current phase. Rate-only goals (weekly/monthly) show change since start and the average weekly rate instead of a bar. | Spec asks for current phase; past phases get the same card for "how did my cut go" at no extra rule |
| D10 | **Current-week header** (top, always this week whatever the period): the week's dates; the **week position** from `dayTargetsProvider(today).week` (the exact HM-002 line Today shows; fixed mode: average eaten vs average target over counted days); days counted of days elapsed; trend change this week (`trendOn(today) − trendOn(weekStart − 1)`, "—" without). A39a replaces it with the weekly summary card. | SC-5 without pre-building A39a's `WeeklySummary` (IN-001 out of scope) |
| D11 | **Mark a day (DY-004 manual).** `DiaryActionsController.markDay(LocalDate, {required bool incomplete})` through the existing `_command` (pending key `day:<date>`, `Origin.direct`, one undo entry; kinds `dayMarkedIncomplete` / `dayMarkedComplete`; already-as-asked → `DiaryActionUnchanged`; a future day → `invalid`). **Chart:** the selected daily bar's details card (date, eaten / target kcal and P/C/F/fiber, status) has *Mark incomplete* / *Mark complete*. **Today:** `FbDateHeader` gains an optional `trailing` widget; Today passes a `FbIcons.more` button opening a `showFbOptionSheet` "day menu" with the one toggle (A41 can add "not fasting" there later); a marked day shows one muted note line in the day header (`_DayHeader` list) with *Mark complete*. Feedback via the diary's undo snackbar helper. | Reuses A06's op; menu is a seam for later day options |
| D12 | **Full-view graphs:** the weight graph stays as is (already shades phases). Measurement type graphs **gain phase shading** (`phasePeriods`, the same `goalHistoryProvider`), so every chart reachable from Progress is phase-shaded; filtering by period applies to the tab's charts. | TG-012 "filtered **or shaded**"; cheap; the full views keep their range chips |
| D13 | **Layout = an ordered list of sections** in `progress_screen.dart`: week header → period bar → calories (+ details) → macros → weight → goal progress → Measurements row → [A37a: exercise progress row] → [A38: expenditure chart]. Later steps add one entry. Empty (nothing logged, no weigh-ins, no setup), loading (skeleton cards) and error (inline banner + Try again) states per section (UX-050–052). | Same seam style as Today's `_DayHeader` |
| D14 | **Earliest bound for `‹`:** the earliest of the first diary date (new `DiaryReads.firstEntryDate()` = `SELECT MIN(local_date) … WHERE deleted_at IS NULL`, live index), the first settings version, the first weigh-in and the first phase start; none → today. | No endless stepping into empty weeks |
| D15 | **IN-020/021:** no streaks, scores, "missed" or "failed" states, no red, no micronutrients (only kcal, P, C, F, fiber). Copy neutral ("under/over", "not counted"). Checked by the Codex UX review, not by tests asserting copy. | TD-104 never assert copy |
| D16 | **Tests (TD-104):** logic tests + one happy-path widget test for the new screen; **one golden** because Progress is one of A46's key screens (follow A46's key-screen matrix); no new Patrol (emulator is nightly); perf: host `perf` test + a UI-free-ish **device benchmark** `apps/mobile/integration_test/progress_benchmark_test.dart` (profile mode over adb, not in CI, the A21 pattern). | TD-104, A46 key-screen list |
| D17 | **Placement:** pure code in a new `fb_domain/src/insights/` (`progress_series.dart`, `goal_progress.dart`; A39a's `WeeklySummary` will join it); app code in `features/progress/` (imports the body, diary, targets, settings, today barrels; no cycle: none of them imports progress). No router change (all routes exist). ARB `progress*` keys; DS strings in `fb_ds_en.arb`. | `03` §3.1–3.2 |

**⚠️ OWNER: none.** **TD candidates: none** (D2 stays inside `03` §4; a cache table would be one, only via the fallback).

### 3. Design

**3.1 `fb_domain/src/insights/progress_series.dart`** (exported from `fb_domain.dart`, README section "Progress series")
- `DayLog {LocalDate date, Nutrients totals, int entryCount, bool incomplete}`: the input per day that has entries or a mark.
- `ProgressDay {date, Nutrients eaten, int entryCount, DayStatus status, double? targetKcal, DailyMacros? targetMacros}`; `DayStatus {logged, incomplete, unknown, inProgress}`.
- `ProgressSeries.build({required LocalDate from, required LocalDate to, required LocalDate today, required Iterable<TargetSettingsRecord> settings, ProfileRecord? profile, Iterable<GoalPhaseRecord> goals, required double? Function(LocalDate) trendOn, required Iterable<DayLog> logs, WeekCalendar calendar, TrainingShiftInput? training})` → `List<ProgressDay>` for every date `from…min(to, today)`. `logs` must cover from `calendar.weekStartOf(from)` (earlier days of the first week feed weekly-mode targets). Per date: intake of that week's earlier days → `TargetsTimeline.day(...)` (D6). Content-free `toString`.
- `ProgressBucketSize {day, week, month}` + `ProgressBuckets.of(List<ProgressDay>, WeekCalendar)` → `List<ProgressBucket {start, end, size, double? avgKcal, double? avgTargetKcal, Nutrients? avgEaten, MacroAverages? avgTargets /* record: kcal, protein, carbs?, fat?, fiber */, int countedDays, int uncountedDays, DayStatus? status /* daily only */}>` (D4). A daily bucket's `avgKcal`/`avgTargetKcal`/`avgEaten`/`avgTargets` are that day's actual values for every status with data, incomplete included (PA1).

**3.2 `fb_domain/src/insights/goal_progress.dart`**: `GoalProgress.of(...)` (D9) → `{double? startKg, double? latestKg, double? targetKg, double? fraction, bool reached}`; content-free `toString`.

**3.3 Design system**
- `charts/bar_chart.dart` (`FbBarChart`), `charts/bar_chart_painter.dart`, `charts/bar_geometry.dart` (pure: index ↔ x in LTR/RTL, nearest bar, y scale over values + targets) and `FbBar`/`FbBarStyle` in `chart_types.dart` (D7). Exported from the DS barrel.
- `components/date_header.dart`: optional `Widget? trailing` after the next button (null = today's layout, no visual change).

**3.4 App: diary**
- `DiaryReads.firstEntryDate()` + `DiaryRepository.watchFirstEntryDate()` (readsFrom `diaryEntries`).
- `DiaryActionsController.markDay` + `DiaryActionKind.dayMarkedIncomplete/dayMarkedComplete` (D11). The undo-snackbar helper used by Today and Progress is exported from the diary barrel (today `reportDiaryOutcome` lives in the unexported `entry_actions.dart`).

**3.5 App: progress application**
- `progress_period.dart`: `sealed ProgressPeriod` = `WeekPeriod(start)`, `MonthPeriod(year, month)`, `PhasePeriod(phaseId)`; `ProgressPeriodController` (keepAlive): `setKind`, `previous`, `next`, `canPrevious/canNext` given today, week calendar, phases and the earliest date; `dates(today, phases)` → `(from, to)` clamped to today.
- `progress_providers.dart`:
  - `progressLogsProvider(from, to)`: combines `watchDailyTotals` + `watchDayMarks` into `List<DayLog>`.
  - `progressDaysProvider(from, to)` → `List<ProgressDay>`: watches the logs (from the first week's start), `targetsDataProvider`, `weekStartProvider`, `weightTrendProvider`, `trainingShiftProvider(weekStart(from), to)`, `todayProvider`; calls `ProgressSeries.build`. No automatic retry (UX-052, like `weightGraphProvider`).
  - `progressViewProvider` → `{period, from, to, days, buckets, bucketSize, canPrevious, canNext}`.
  - `weekGlanceProvider` (D10), `goalProgressProvider` (D9), `progressEarliestDateProvider` (D14), `ProgressSelection` (selected bucket index; cleared when the period changes).
- `weight_chart_parts.dart` (D8): the `FbSeries`/periods/goal builders shared by the full graph and the embedded chart, plus `periodGoalKg(period, GoalPhases, today)` resolving the goal from the selected (or period-end) phase (PA4).

**3.6 App: progress presentation**: `progress_screen.dart` (sections, D13), `progress_week_header.dart`, `progress_period_bar.dart` (steady chips: A45's fixed-width chip if merged, else `FbChoiceChip` and A45's audit catches it), `calories_section.dart` (+ `progress_day_details.dart` with the mark action), `macros_section.dart` (four compact `FbBarChart`s; carbs/fat without target in calories/protein mode), `weight_section.dart`, `goal_progress_card.dart`. `measurement_type_screen.dart`: phase periods (D12).

**3.7 App: today**: `today_screen.dart` passes the day-menu button to `FbDateHeader.trailing`; `day_page.dart` `_DayHeader` gains the incomplete note (reads `DayView.raw.mark`).

**3.8 Rules respected:** single writer (only `ChangeSetApplier`, via `DiaryActionsController`); derived values computed, never stored (`03` §4, G10); feature barrels only; presentation never imports data; local only, offline, no network (rule 3); strings in ARB, directional layout, reading-direction charts; no AI (TD-105); no user content in logs (content-free `toString`s).

### 4. Work packages (one `flutter-engineer`, one commit each; `make check-dart` before every commit; CI is the test evidence)
- **WP1 `feat(insights): progress series, buckets and goal progress`** (flutter-engineer). `fb_domain/src/insights/progress_series.dart`, `goal_progress.dart`, `fb_domain.dart` exports, README section; tests T1–T4, T17. Done: `make check-dart`, CI `dart-test (packages)` green, `fb_domain` coverage gate holds.
- **WP2 `feat(design-system): bar chart and date header trailing slot`**. `chart_types.dart`, `bar_chart.dart`, `bar_chart_painter.dart`, `bar_geometry.dart`, `date_header.dart`, DS barrel, `fb_ds_en.arb` (semantics strings); tests T5–T6. Done: as WP1.
- **WP3 `feat(progress): period, progress providers and marking a day`**. Diary: `diary_reads.dart`, `diary_repository.dart`, `diary_actions.dart`, diary barrel export of the outcome helper. Progress: `progress_period.dart`, `progress_providers.dart`, `weight_chart_parts.dart` (+ `weight_graph_screen.dart` switched to it, same output), codegen; tests T7–T9, T16, T18. Done: `make gen-app check-dart`; existing weight graph tests stay green in CI.
- **WP4 `feat(progress): Progress tab with calories, macros, weight and goal progress`**. Section widgets, `progress_screen.dart`, `measurement_type_screen.dart` (phase shading), ARB `progress*`; tests T10, T11, golden T13. Update the existing UX-013 navigation tests if the Weight/Measurements rows now need a scroll (only those that survived A46). Done: `make gen-app check-dart`; the one new golden image is generated locally **for that single file only**: `tools/scripts/heavy.sh timeout 600 flutter test --update-goldens <progress golden test file>` (the allowed local exception; no `make goldens`); CI is the evidence for everything else.
- **WP5 `feat(today): day menu to mark a day incomplete`**. `today_screen.dart`, `day_page.dart`, ARB; test T12. Grep `patrol_test/` for Progress-tab and Today-header finders (memory rule: UI copy/position → Patrol check); fix finders only if a surviving journey breaks (no new journeys). Done: `make check-dart`.
- **WP6 `test(progress): one-year chart benchmark`**. `test/features/progress/support/progress_workload.dart` (365 days × ~15 entries ≈ 5,500, marks, 365 weigh-ins, 2 phases, 3 settings versions; synthetic), host perf test T14 (`@Tags(['perf'])`), device benchmark T15 (timing per PA5: from the period being set to the **first painted frame of that chart containing its loaded data**, including the SQL reads and the series/projection build; one number per chart: calories, macros, weight, goal card; month and 1-year phase periods; p50/p95 over runs) with run instructions in its header (`flutter test integration_test/progress_benchmark_test.dart --profile -d <A55> --dart-define=A16_DEVICE=A55`). Done: CI `dart-test (app:perf)` green; the A55 run recorded in the Progress log by the orchestrator when the phone is connected.

### 5. Test list (18; 16 run in CI)
| # | Test | Proves |
|---|---|---|
| T1 | `IN-002 G10 each day's target equals TargetsTimeline.day` (weekly mode with rebalancing and an incomplete earlier day; **fixed mode**; a settings version change mid-range; **a trend weight that changes across the range**; **a logged unplanned workout on one day** (same-day adjustment) and training input over two weeks; days before setup → no target) | IN-002, G10, D6, PA3 |
| T2 | `IN-002 DY-004 TG-032 day status: logged, incomplete, unknown, today in progress` | IN-002 incomplete marked differently; missing ≠ zero |
| T3 | `IN-009 buckets: daily to 62 days, weekly from the week start to 366, monthly beyond; averages over counted days only` | IN-009 phase spans, TG-032 |
| T17 | `DY-004 IN-002 an incomplete day with logged intake keeps its intake and target on its daily bar and is left out of the weekly average` | PA1 |
| T4 | `IN-007 goal progress: loss and gain, clamped at 0 and 1, reached, no target or no trend, past phase ends at its end` | IN-007, IN-020 (never negative) |
| T5 | `LC-003 IN-002 bar chart runs in reading direction and a tap picks the nearest bar within 24 dp` (widget, LTR + RTL) | LC-003, selection for DY-004 |
| T6 | `IN-002 bar scale starts at zero and includes the targets` (pure geometry) | targets always visible |
| T7 | `DY-004 markDay marks and unmarks with one undo; already as asked is unchanged; a future day is refused` | DY-004, rule 8 (undo) |
| T8 | `IN-009 period stepping: week start setting, month boundaries, phases in order, never past today or before the earliest data` | IN-009, LC-021 |
| T9 | `IN-002 progress days follow a new entry and a day mark` (in-memory DB, providers) | live charts after writes |
| T16 | `IN-002 G10 progressDaysProvider targets equal dayTargetsProvider for every day of a month` (assembled providers on an in-memory DB: weekly mode with an incomplete day, a weigh-in mid-month, a logged workout, a settings change) | PA3: the assembled inputs, not only the domain function |
| T18 | `IN-009 IN-004 the weight chart's goal line follows the selected phase` (two phases with different target weights: each Phase period resolves its own goal and boundaries; Week/Month use the phase at the period end) | PA4 |
| T10 | `IN-009 the period selector changes every chart` (happy-path screen test: Week → Month → Phase; asserts each `FbBarChart`'s bar count/range and the weight chart's window, never copy; the default period is the current week) | exit 2, SC-5 default |
| T11 | `DY-004 IN-002 marking a day from the chart hatches its bar and undo restores it` | DY-004 chart path |
| T12 | `DY-004 the Today day menu marks the viewed day incomplete and back` | DY-004 day-menu path |
| T13 | Golden `progress_screen` (key screen per A46): a week with a logged, an over-target, an incomplete, an unknown day and today | exit 3 |
| T14 | `IN-002 one year: month and phase series within the host budget` (`perf`, prints SQL + build + first-frame timings) | exit 1 (host early warning) |
| T15 | Device: `IN-002 one year: each chart's first painted frame with loaded data within 300 ms on the device` (PA5 timing; profile, not CI) | exit 1 (A55) |

### 6. Exit-criteria mapping
| Exit criterion | Demonstrated by |
|---|---|
| One year of seeded data: each chart < 300 ms on the A55 (measured) | T15 on the A55 over adb (orchestrator, when the owner connects the phone; per-chart p50/p95 in the Progress log and Outcome), timed per PA5 (first painted chart containing loaded data, SQL + series/projection included, per chart); T14 in CI as an early warning only. **The exit stays outstanding until the A55 number is recorded** (an owner check with a backlog row, like #164; not waived); the verifier marks it ⚠️, and it doesn't hold the merge |
| The phase filter changes every chart (widget tests) | T10 (+ T3, T8 for the window logic, T18 for the weight goal per phase) |
| An incomplete day is visibly distinct in the calories chart (golden) | T13 (+ T2 status, T11 restyle) |
| "How did this week go?" in one tap from Today (SC-5) | The Progress tab (one tap on the bottom nav) opens on the week header + this week's charts: T10 asserts the default period; owner phone check with real data (card "Owner involvement"), collected, non-blocking |
| M2 milestone ("weight-note history entered and charted", backlog #213) | Not an A16 exit: the owner's A15b sign-off; A16's close summary reminds the owner; M2 counts as reached once #213 is done |

### 7. Risks & unknowns
- **A55 speed** (exit 1): D2's fallback ladder inside WP6; the host perf test flags regressions in CI first.
- **Order and shared files:** start only after **A46** merges (rebase; follow its key-screen golden matrix; don't touch deleted Patrol/golden files). **A45** (wave 1, maybe a parallel lane) touches chips and Today: use its steady chip if merged first, else its chip audit covers the new period chips; `today_screen.dart` / `day_page.dart` edits here are additive (one `trailing` argument, one header line) for an easy rebase.
- **Existing navigation tests** (UX-013, from A15a/A15b) tap the Progress rows; the rows move below the charts in a lazy list → scroll in the test (WP4). Patrol journeys that open Progress (if any survive A46) are grepped in WP5; the nightly is the evidence.
- **Weekly-mode targets on past days** are the rebalanced day targets as of that morning, from current data (D6, G10). If the owner expects the plain planned budget per day, that's a review comment after the phone check (backlog), not a blocker.
- **The current workout plan shifts past weeks too** (training input is today's plan, as for Today): a known G10 consequence; logged in the Outcome if visible.
- **Size:** card size L (was M), about 2¾ sessions; one step.
- **Tier** Risky (D1, PA2): two parallel Codex review tasks; a security evidence note at close.

### 8. Size check
**L, about 2¾ sessions** (WP1 ¾, WP2 ½, WP3 ¾, WP4 ¾, WP5 ¼, WP6 ¼, plus CI and the two-task review rounds). Within L: **one step, no split** (PA6).

### Plan review amendments (Codex round 1, 2026-10-30: approve with changes, no blockers)
| # | Amendment | Applied in |
|---|---|---|
| PA1 | Daily buckets keep actual intake and target for incomplete days (to draw the hatched bar); exclusions apply only to week/month aggregates. New test for an incomplete day with logged intake | D4, D5, §3.1, T17 |
| PA2 | Tier → **Risky** (new controller + two UI entry points on a user-data write path); two parallel Codex review tasks | D1, header, §7 |
| PA3 | No "compute each week's targets once": cache shared inputs only, keep per-date `TargetsTimeline.day`. T1 gains fixed mode and changing weight/workout inputs; the assembled provider output is compared with `dayTargetsProvider` | D2, D6, T1, T16 |
| PA4 | The embedded weight chart's goal line comes from the selected phase (`GoalHistory.phases` for selection and boundaries), not `weightGraphProvider.goalKg`; test with two phases of different targets | D8, §3.5, T18 |
| PA5 | The A55 measurement stays an outstanding exit until recorded (owner check, like #164), not waived; timing = first painted chart containing loaded data (SQL + projection included), per chart | WP6, T15, §6 |
| PA6 | No `make goldens`: the one golden is generated for its single file through `heavy.sh` with `timeout 600`; CI is the evidence otherwise. Size ~2¾ sessions, card size L, one step | WP4, §8, header |

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30 · Low-level plan written (step-planner, branch `step/A16-progress-tab` from fe4f671): WP1–WP6, Normal tier, size L, no owner decision. Next: Codex plan review, orchestrator self-approval; implementation after A46 merges.
- 2026-10-30 · Codex plan review round 1: approve with changes, no blockers; PA1–PA6 applied (incomplete days keep their bars, tier Risky, per-date targets with a provider-level equality test, the weight goal per selected phase, the A55 timing definition stays outstanding until recorded, single-file golden via `heavy.sh`, size L ~2¾ sessions). Next: orchestrator self-approval; implementation after A46 merges.
- 2026-10-30 · Implementation started in lane `~/work/fitness_buddy_6` (flutter-engineer, Opus) on the plan + A46's pre-merge base. WP1 done: `fb_domain/src/insights/` (`ProgressSeries`, `ProgressBuckets`, `GoalProgress`; `WeightStats.startPoint` made public for the shared stale-start rule), README section; tests T1–T4, T17. `make check-dart` scope: `dart analyze` clean on `fb_domain`. Next: WP2 (bar chart, date header slot).
- 2026-10-30 · WP2 done: DS `FbBarChart` (`bar_chart.dart`, `bar_chart_painter.dart`, pure `bar_geometry.dart`; `FbBar`/`FbBarStyle`/`FbBarTone` in `chart_types.dart`): reading-direction bars, zero-based scale over values and targets, target mark, over-target grey, hatched/faint styles, baseline tick for no data, nearest-bar tap, semantics stepping; `FbDateHeader.trailing`. Tests T5, T6. No new DS strings were needed (the app supplies every bar's words). Next: WP3.
- 2026-10-30 · WP3 done: `DiaryReads.firstEntryDate` + `watchFirstEntryDate`; `DiaryActionsController.markDay` (pending key `day:<date>`, kinds `dayMarkedIncomplete`/`dayMarkedComplete`, the handler refuses future days); `reportDiaryOutcome` exported from the diary barrel; `progress_period.dart` (sealed `ProgressPeriod`, the selector as kind + periods back, so it follows midnight and the week-start setting; `canGoBack` against the earliest data), `progress_providers.dart` (`progressLogs`, `progressDays`, `progressEarliestDate`, `progressView`, `SelectedProgressBar`, `weekGlance`, `goalProgressCard`, `progressWeight`), `weight_chart_parts.dart` (shared series builders + `periodGoalKg`, PA4; the full graph uses them, same output); codegen. Tests T7, T8, T9, T16, T18. Also fixes WP2's physical corner radius flagged by app-check. Next: WP4.
- 2026-10-30 · WP4 done: the Progress tab as an ordered section list (week card → period bar → calories + bar details → macros 2×2 → weight with "Full graph" → goal progress → Measurements); calories style A (target mark, over-target grey, hatched incomplete, lighter today, legend via the new DS `FbBarLegend`); macros with protein/fiber targets only (the owner's visual); the weight chart's goal from the period's phase; measurement graphs shaded by phase (D12); `markDayWithUndo` lives in the diary feature (`day_mark_actions.dart`) so Today can use it without importing Progress; ARB strings (`progress*`, `diary*` mark/undo, `today*` menu). Period chips are `FbChoiceChip` (A45's steady chip isn't on main). Tests T10, T11, golden T13 (`goldens/ci/progress_screen.png`, generated locally for that file only via `heavy.sh`); the UX-013 navigation test now scrolls to the weight section's link by key. `make check-dart` green. Next: WP5.
- 2026-10-30 · WP5 done: Today's date header gets a ⋮ day menu (`FbDateHeader.trailing`, `showFbOptionSheet` with Mark day incomplete / Count this day again) and a marked day shows a muted note with Count this day again in its header list. Test T12. Patrol grep: no journey uses the Today header buttons or the old Progress rows (the shell journey's "Charts appear after" text is still the empty calories chart). The header's new button changes three existing key-screen goldens (`today_empty_day`, `today_full_day`, `today_targets_under`, `app_shell`): regenerated locally one file at a time via `heavy.sh` + `timeout 600` (a necessary exception beyond the plan's one new golden). Next: WP6.
- 2026-10-30 · WP6 done: `test/features/progress/support/progress_workload.dart` (365 days × 15 entries, a mark every 17 days, 365 weigh-ins, two phases with the first spanning the year, three settings versions; synthetic) and the device benchmark `integration_test/progress_benchmark_test.dart` (T15, PA5 timing per chart, cold runs, p50/p95, fails above 300 ms; written, not run). **T14 (host `perf` test) not added:** A46/TD-104 removed the `perf` tag, the `app:perf` shard and host timing gates (`dart_test.yaml`: "There are no `perf` or `live` tags"), so the A55 run is the only measurement. Backlog #219 added for the A55 run (exit 1 stays open until recorded, PA5); #213's path updated to "Progress › Weight › Full graph". Next: CI on the last push, Outcome.
- 2026-10-30 · Owner rule (via the orchestrator): no more pushes per WP; this Outcome commit stays local, the orchestrator pushes once. Code complete; awaiting CI on the pushed head 6432dda, the two Codex reviews and merge.
- 2026-10-30 · Review round 1 fixes (Codex security approved; code review: 1 major, 3 minors): (1) `FbBarChart` gives every bar but a placeholder its own semantics node (painter `semanticsBuilder`) with its words, selectable or not, a screen-reader tap selects; the old increase/decrease stepping is gone; macro bars now say their target (protein/fiber) and not counted / so far, like the calories bars; (2) the week card and goal card handle loading/error explicitly with an inline Try again (no automatic retry, UX-052); (3) T12 also marks a past day via ⋮ and counts it again via ⋮, today unchanged (and now unmounts so no undo timer is left pending); (4) the earliest-period bound counts live day marks (`DiaryReads.firstDiaryDate`, tombstones ignored). New tests: DS semantics test, `diary_first_date_test`. Local: those test files + T12 green via `heavy.sh`, `make check-dart` green. Committed locally, not pushed.
- 2026-10-30 · Review round 2 fixes: every Progress "Try again" now goes through `retryProgress` (`progress_retry.dart`), which refreshes the shared derived providers (logs, days, earliest date, view, day targets, week card, weight graph, goal card, weight view), so a failed upstream isn't re-read from cache; new test `UX-052 Try again refreshes the failed upstream data…` (the support's `ProviderScope` now disables automatic retry). `BarChartPainter.shouldRebuildSemantics` compares the description callback's identity; the DS semantics test checks new words replace old ones. Found while running the file: T11 hung in a widget test because the setup command waits on fake-async timers; it now seeds targets with ops, as T16 does (the pushed WP4 version would hang in CI). Local: `bar_chart_test`, `progress_screen_test`, `progress_golden_test` green via `heavy.sh`; `make check-dart` green. Committed locally, not pushed.

- 2026-10-30 · Close (orchestrator): Codex security/data-integrity review approved (one minor: earliest date ignored day marks, fixed in round 1). Codex code/UX review requested changes (major: macro bars unreadable by screen readers; minors: error states, T12 coverage); fixed in 541dfc3, fix-check 1 left two minors, fixed in 91675d8 (plus T11 hang); fix-check 2 left the retry scope (backlog #220, cap of 2 rounds reached) and a test gap, which the orchestrator fixed. Merged origin/main (A46/A47/B20) and restored A46's fixed tests and goldens lost by the stale base; backlog #218 renumbered #219 (A47 took #218). Evidence: `evidence/A16-verification.md`.
## Outcome
_Engineer's draft, 2026-10-30 (the orchestrator adds CI, review results and merge)._

**Built.** WP1 `fb_domain/src/insights/` (`ProgressSeries` per-date targets via `TargetsTimeline.day`, `ProgressBuckets`, `GoalProgress`); WP2 DS `FbBarChart` (+ `FbBarLegend` in WP4) and `FbDateHeader.trailing`; WP3 `DiaryActionsController.markDay`, `DiaryReads.firstEntryDate`, the period model and Progress providers, shared weight-chart parts with the period phase's goal (PA4); WP4 the Progress tab (week card, Week/Month/Phase selector, calories style A with bar details and Mark day incomplete / Count this day again, macros 2×2, weight with Full graph, goal progress, Measurements; measurement graphs phase-shaded); WP5 Today's ⋮ day menu and incomplete-day note; WP6 the one-year workload and the A55 benchmark.

**Deviations.**
- T14 (host `perf` test) not written: TD-104/A46 removed the `perf` tag, the `app:perf` shard and host timing gates. 17 of the plan's 18 tests; exit 1 rests on the A55 run only (backlog #219, stays ⚠️ until recorded, PA5).
- Goldens: besides the new `progress_screen` golden, the Today header's new button changed four existing key-screen images (`today_empty_day`, `today_full_day`, `today_targets_under`, `app_shell`); each regenerated locally via `heavy.sh` + `timeout 600`, one file at a time.
- Macros: carbs and fat without target marks in every mode (the owner's approved visual), protein and fiber with targets.
- The period selector is held as kind + "periods back" (not an absolute period), so it follows midnight and a week-start change; `canGoBack` is a pure function rather than a controller getter.
- `markDayWithUndo` lives in the diary feature (`day_mark_actions.dart`) so Today needn't import Progress; mark/undo strings are `diary*` keys.
- No new DS strings (the app passes every bar's words); `FbChoiceChip` for the period choices (A45's steady chip isn't on main; the orchestrator keeps `ScrollToTopOnTabReselect` around the Progress list when A45 merges).
- WP2's physical corner radius (`topLeft`/`topRight`) was caught by app-check and fixed in WP3's commit.

**Tests (17).** fb_domain: T1 `IN-002 G10 each day's target equals TargetsTimeline.day`, T2 day status, T3 buckets, T17 incomplete day keeps its bar, T4 goal progress. DS: T5 reading direction + nearest tap (LTR/RTL), T6 zero-based scale. App: T7 `DY-004 markDay …`, T8 period stepping, T9 progress days follow an entry and a mark, T16 `progressDaysProvider` = `dayTargetsProvider` for a month, T18 weight goal per phase, T10 the selector changes every chart, T11 marking from the chart hatches and Undo restores, T12 Today day menu, T13 golden `progress_screen`; T15 device benchmark (not in CI). Updated: UX-013 navigation test (scrolls to the weight section's link by key).

**Metrics.** A55 timings: open (#219). Local checks: `make check-dart` green; `make gen-app` current; the one golden file generated locally passed. No local test runs otherwise (owner rule).

**Review metrics.** 2 Codex reviews + 2 fix-checks; findings: 1 major, 6 minor (5 fixed, 1 to backlog #220).

**Open items.** #219 (A55 benchmark), #213 (owner's real-history sign-off, M2), owner phone check with real data (card "Owner involvement"); Codex reviews (code/architecture + security/data integrity) and `steps/evidence/A16-verification.md` by the orchestrator.
