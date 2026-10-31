# A56 — Today summary card with slides

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A45, A52, A53 | M | Claude plans, Codex builds | 🟨 closed, awaiting review |

_2026-10-31. Owner request (verbatim): "On the today page, I want the top part to be a card with slides if you know what I mean. First slide for nutrition, 2nd weight, 3rd workout." Related wish: backlog #74 (Today fits the essentials on one screen). Tier **Normal**. One Codex build, one combined Codex review._

**Naming.** Renamed from A55 to A56 by the orchestrator: "the A55" is the owner's phone and the app track skips that number.

**Goal.** The top of Today is one swipeable card with three slides (Nutrition, Weight, Workout) and page dots. It replaces the separate weight card and workout row, so Today gets shorter.

**Spec:** HM-001–003, HM-005, HM-006, HM-009, WB-011/012, WO-021, UX-051/052, PR-12 · **Amends:** HM-005, HM-006 (D-092, owner approved in the build brief).

## Scope
1. A design-system pager card (`FbSlideCard`) with page dots, and a sparkline (`FbSparkline`).
2. Today's day header: `[slide card]` then the existing conditional notes and the Today-only lines.
3. Nutrition slide = today's `TodayNumbers` (unchanged content). Weight slide = the weight card's content, rebuilt for a slide. Workout slide = the workout row's content plus the no-plan empty state and a small muscle map.
4. Spec amendment D-092 (HM-005, HM-006, HM-009) with the owner's approval; strings in ARB; goldens; sweep updates.

## Out of scope
- Slides for anything else (steps, water), reordering or hiding slides (settings).
- Changing the day-swipe, the diary list, quick-add or the input bar.
- Weight graph or workout screens themselves.

---

## Low-level plan
_Claude (planner), 2026-10-31. Size M, estimate **1–1.5 sessions including one fix round**._

### Summary
After this step Today's header is `FbSlideCard` (fixed height, dots below, 3 slides). Slide 1 shows what the top shows now. Slide 2 shows the latest weigh-in, trend, a small sparkline and "+ Weigh in". Slide 3 shows the day's session or plan or a "Log a workout" prompt, with a small muscle map. `WeightCard` and `WorkoutTodayRow` leave `day_page.dart`; nothing they offered is lost (see D9). Today is about 120–170 dp shorter when weight and workout rows were showing.

### Decisions
- **D1 First slide: always Nutrition at app start; the chosen slide then follows the user across days for the session.** A session-only `todaySlideProvider` (`Notifier<int>`, not persisted, not synced) holds the slide index. Swiping to yesterday keeps you on Weight so you can compare. A cold start or a tab leave and return keeps the value; a cold start resets to 0. Reason: the diary is the main job (SF/UX speed), no stored state, no startup work. (Persisting the last slide was the alternative: rejected, a surprise on next launch.)
- **D2 One shared slide index, many day pages.** `DayPage` of the viewed day and its two neighbours each own an `FbSlideCard`/PageController. Each controller reads `todaySlideProvider` for `initialPage`, writes it in `onPageChanged` (user swipe or dot tap only), and listens to it, calling `jumpToPage` when its page differs (neighbours are off-screen, so no animation). No loop: `onPageChanged` only writes when the value differs.
- **D3 Gesture conflict (the main risk), resolved explicitly.** Both pagers are horizontal `PageView`s. Flutter's gesture arena gives a horizontal drag that starts on the card to the innermost pager (the slide pager), so on the card a sideways swipe changes the slide and never the day; everywhere else on Today (diary list, empty space below the card) it changes the day (HM-009). The day can still be changed from the card area by the ‹ › header buttons and the date picker (unchanged). No overscroll hand-off to the day pager (fiddly, and would make a swipe on slide 1 unpredictable). The dots and a short "Swipe for weight and workout" first-use hint are **not** added; the dots are the affordance. Consequence for HM-009: amended to "Swiping left or right **below the summary card** changes the day". Tests pin both behaviours (T11, T12). Owner may reject this; the fallback is a thin day-swipe strip, not worth building unless asked.
- **D4 Card height fixed.** `FbSlideCard` takes `height` (dp at text scale 1.0) and scales it with `MediaQuery.textScalerOf(context).scale(height)`, clamped to at most 2.0 scale. Today passes `TodaySlideCard.baseHeight`, chosen as the Nutrition slide's measured height in target mode at scale 1.0 with a Ramadan "maintain" line (the tallest case; Codex measures it in the golden test and sets the constant, expected about 200–230 dp). The other slides are laid out to fit inside (centre/top aligned, `ClipRect`, no inner scrolling). Reason: no jump when swiping; no offstage double-build. Test T9 asserts no overflow of any slide at scale 1.0 and 2.0 in every state. Dots sit under the card, outside `height` (16 dp, `FbSpace`).
- **D5 Dots and accessibility.** `FbPageDots` (7 dp dots, active = `primary`, others `outlineVariant`; the touch target is 48 dp wide per dot via `InkWell` so a tap jumps to that slide). The whole card is one `Semantics` container with `label` = "{slide}, {n} of {count}" (ARB `todaySlideSemantics(name, n, count)`: "Nutrition, 1 of 3") and `onIncrease`/`onDecrease` custom actions so TalkBack's swipe up/down adjusts the slide (plus `liveRegion` off; announce on change with `SemanticsService.announce`). Each dot has the slide's name as its semantic label ("Weight") and `selected`. Reduced motion: `FbMotion.of` zero-duration page animation. Dots do not rely on colour alone: the active dot is wider (20 dp pill).
- **D6 Past days.** Weight slide on a past date shows the trend and the latest weigh-in **on or before** that date (`weightCardProvider(date)` already gives this), "+ Weigh in" logs on that date (`showWeighInSheet(date:)`, as today), the sparkline ends on that date. Workout slide on a past date shows that day's session(s) (as `todayWorkoutProvider` does) or, with none, the **last session before that date** ("Last: Push · 3 days ago", tap opens it) and never a "missed" note; "Log a workout" logs on that date. A future date can't be viewed (DY-003).
- **D7 States.**
  - Nutrition: loading = the existing skeleton; no targets = eaten mode + the "Set up your targets" row (today only), all inside the slide (the slide's height holds it, T9); targets error = the inline banner inside the slide (the banner and its Try again stay as is, UX-052).
  - Weight: loading = `FbSkeleton.card` inside the slide; error = `FbInlineBanner` + Try again (existing strings); no weigh-ins = "Log your first weigh-in" and a primary "+ Weigh in" button, no sparkline; one weigh-in = value, trend if any, no sparkline (needs 2 points); stale trend = existing "Trend X · from {date}" line.
  - Workout: loading = skeleton; planned today = "{name} today" + "Log" (opens `TodayWorkoutLogRoute(template)`); logged = "{title} ✓ · n exercises · k PR" + "+1" more, map of the session's `muscles`, tap opens the session; no plan and no session = "No workout logged" + "Log a workout" button (HM-006 amended: the empty state is shown, never hidden, because the slide exists anyway). Workouts never set up (first run's "Not right now") is the same no-plan state; no extra nag.
  - Ramadan: no change to slides; the `RamadanProposalCard` and the not-fasting note stay below the card (D9). The "maintain" line stays in the Nutrition slide.
  - Guest: identical (nothing here needs an account). The account banner stays below.
- **D8 Performance and laziness.** No new startup work and no network. The inner `PageView.builder` builds only the visible slide (+ the adjacent one the framework keeps with `allowImplicitScrolling: false`, i.e. only what is dragged into view); Weight and Workout providers are watched **only inside their slide widgets**, so they are not read until the slide is first shown (the weigh-in stream is warm anyway on Today today via `weightCard`; moving the watch into the slide makes Today's first frame cheaper, not dearer). `AutomaticKeepAlive` is off; a slide rebuilds from warm providers when revisited. The sparkline is a `CustomPainter` over at most 30 values, no animation. T10 (acceptance sweep, performance) must stay inside its existing budget.
- **D9 What moves, and nothing is lost.**

  | Today now | After |
  |---|---|
  | `TodayNumbers` (number, bar, week line, macros, Ramadan maintain, setup row, targets banner) | Slide 1, widget unchanged (wrapped, not edited, except its outer padding moves to the card) |
  | `WeightCard` full card (trend, weekly rate, sparse note, 2–3 times a week tip, last weigh-in edit, graph link) and slim row (value · trend, ＋, opens graph) | Slide 2: tap the value area → graph (`TodayWeightGraphRoute`); "+ Weigh in" button → sheet (2 taps, HM-005); the "Last weigh-in …" line (tappable, edit sheet) stays; the sparse note and the monthly tip show as a quiet note line **only while Weight is the selected slide** (the tip's "shown" mark must not fire from an unseen slide). `WeightCard`'s state provider `weightCardProvider` is reused as is; the widget `WeightCard` is deleted after its content is ported into `WeightSlide` (the slim/full switch goes: the slide is always the same shape) |
  | `WorkoutTodayRow` (logged / planned / nothing) | Slide 3 (adds the last-session and no-plan states, the map). `todayWorkoutProvider` is reused and extended with a `TodayWorkoutLast`/`TodayWorkoutNone` result (see Design). `WorkoutTodayRow` is deleted |
  | `RamadanProposalCard`, `_NotFastingNote`, `_IncompleteNote` | Stay below the card (rare, conditional, must be seen) |
  | `ReadyScansTodayHint`, `AccountTodayBanner`, `SyncTodayLine` | Stay, below those notes |
  | Tab re-tap scroll to top, day swipe, ‹ ›, date picker, day menu | Unchanged |

- **D10 Sparkline.** New `FbSparkline` in the DS (no axes, no labels, 2 dp line in `primary`, last point dotted, `Semantics` excluded since the slide's text carries the numbers). Data: the viewed day's last 30 days of **weigh-in values** (kg) from `weighInsProvider`, one point per day (the day's last), shown only with ≥ 2 points, converted to display units only for text, never for the shape. Reason: cheap, no new provider, no trend maths in the widget. (A trend-line sparkline from `weightTrendProvider` is a follow-up.)
- **D11 Free "Log a workout" from Today.** `TodayWorkoutLogRoute.template` becomes nullable (no `template` query parameter when null; the router's `log.template!` is replaced by passing null to `WorkoutLogScreen.newSession(inToday: true)`), so the no-plan button opens the log form nested in the Today tab like the planned row does. Reason: stays on Today's stack (A37 D13), no tab switch. If the screen's picker flow needs the Workouts tab, Codex falls back to `WorkoutLogRoute(date:)` and notes it in the Outcome.
- **D12 Spec.** Add D-092 to `spec/decisions.md` (amends HM-005, HM-006, HM-009): "Today's top is a card with slides (Nutrition, Weight, Workout). Weight and workout are slides, not rows; the workout slide always shows (empty state 'Log a workout'). Day swipe works below the card." Edit HM-005/006/009 text and `spec/16`. **Owner approval:** explicitly authorized in the A56 build brief, including D-092 and the three HM amendments.

### Design

**Widget tree (Today page, a day):**
```
DayPage (sliver list row 'numbers' → _DayHeader)
 _DayHeader (Column)
  TodaySlideCard(date, isToday, totals)            // new, features/today/presentation/today_slide_card.dart
   FbSlideCard(height, labels, index, onChanged)   // new DS
    page 0  TodayNumbers(date, isToday, totals)    // unchanged widget
    page 1  WeightSlide(date, isToday)             // features/body/presentation/weight_slide.dart
    page 2  WorkoutSlide(date)                     // features/workouts/presentation/workout_slide.dart
   FbPageDots                                      // inside FbSlideCard, below the pager
  if isToday RamadanProposalCard
  _NotFastingNote, _IncompleteNote (as now)
  if isToday ReadyScansTodayHint, AccountTodayBanner, SyncTodayLine
```
`_DayHeader`'s doc comment (ordered list) is updated: numbers+weight+workout become "the summary card".

**New DS (packages/fb_design_system, exported from `fb_design_system.dart`):**
- `FbSlideCard({required List<FbSlide> slides, required int index, required ValueChanged<int> onIndexChanged, required double height, required String Function(String name, int n, int count) semanticLabel, Key? pagerKey})`; `FbSlide({required String label, required WidgetBuilder builder})`. Uses `PageView.builder` + `PageController(initialPage: index)`; didUpdateWidget jumps when `index` differs; padding is the card padding (`FbCard`, `FbDensity.cardGap` below); dots below. Keys: `fb-slide-card`, `fb-slide-dot-$i`.
- `FbPageDots({count, index, labels, onSelect})`.
- `FbSparkline({required List<double> values, double height = 36})` + painter (min/max scale, flat line when all equal).
- Widgetbook/gallery entry if the DS has a gallery (`features/design_preview`); optional.

**Providers:**
- `todaySlideProvider` in `features/today/application/today_slide.dart`: `@riverpod class TodaySlide extends _$TodaySlide { int build() => 0; void select(int i) => state = i; }` with `keepAlive: true` (screen rebuilds don't reset; process death does).
- `WeightSlide` watches `weightCardProvider(date, isToday: isToday)` and `weighInsProvider` (sparkline: pure function `sparklineValues(List<WeighIn>, LocalDate)` in `body/application/weight_sparkline.dart`).
- `todayWorkoutProvider(date)` returns `TodayWorkout?` today. Extend the sealed class with `TodayWorkoutLast(summary, daysAgo)` and `TodayWorkoutNone`; the provider returns `Logged` > `Planned` (today, future) > `Last` (the newest session before `date`, any date) > `None`. It never returns null any more (the slide draws "None"). `WorkoutTodayRow` (deleted) is the only other reader (grep to confirm; notifications use `workoutPlan` directly).

**Layout of the slides (all inside the card, 16 dp padding, `FbType` tokens, no new colours; neutral language, PR-12):**
- Nutrition: as today.
- Weight: label "Weight" (`weightTitle`); big trend number (`FbType.numeric(FbType.title)`) "78.4 kg"; line "Trend, −0.3 kg/week" (existing `weightCardTrend`/`weightRateText`); sparkline to the right at ≥ 160 dp width, below the numbers at text scale ≥ 1.4; last weigh-in line (tappable); `FbButton` "+ Weigh in" (key `today-weigh-in`, 48 dp). The old `weightCardLog*Semantics` strings are reused for the main region.
- Workout: label "Workout"; title line (planned/logged/last/none); `ExerciseMuscleMap.union(summary.muscles, height: 64)` on the end side when `MediaQuery.textScalerOf(context).scale(1) <= 1.3` (as `workout_session_tile`), omitted at larger text; button "Log" / "Log a workout" (key `today-workout-log`); tapping the title area opens the session when one is shown (key `workout-today-row` is kept on that tap area for the Patrol/acceptance finders).

**Contract/DB:** none. No `ChangeSetApplier` involvement: the slides only read and launch the existing weigh-in sheet and workout log routes (single writer untouched). Layers: slides are presentation; the only application code added is the slide index provider, the sparkline function and the provider extension. No cross-feature internals: `today` imports `body.dart`/`workouts.dart` barrels (add `WeightSlide`/`WorkoutSlide` exports there), as `day_page.dart` already does.

**ARB (en only; add to `lib/l10n/app_en.arb`, run `flutter gen-l10n`):** `todaySlideNutrition` "Nutrition", `todaySlideWeight` "Weight", `todaySlideWorkout` "Workout", `todaySlideSemantics` "{name}, {n} of {count}", `todaySlideDot` "{name}", `weightSlideAdd` "+ Weigh in" (reuse `weightRowAdd` if its text matches), `weightSlideSparkSemantics` (none; excluded), `workoutSlideLast` "Last: {title} · {when}", `workoutSlideNone` "No workout logged", `workoutSlideLogNew` "Log a workout", `workoutSlideLog` "Log", `workoutSlideOpenSemantics`. Reuse the existing weight/workout strings otherwise. Strings that become unused (`weightCard` slim/row ones) are removed only if nothing else uses them (grep).

### Work packages (all `flutter-engineer`, built by Codex; order matters)
- **WP1 DS components.** `FbSlideCard`, `FbPageDots`, `FbSparkline` + exports; DS widget tests and a golden each (light/dark, text 2.0). Done when `cd packages/fb_design_system && flutter test` passes (focused files).
- **WP2 Providers and data.** `todaySlideProvider`; `sparklineValues`; `TodayWorkout` extension (`Last`, `None`) + tests; `TodayWorkoutLogRoute` nullable template + router + `workout_log` wiring (D11); `flutter pub run build_runner build` for `.g.dart`. Done when the provider and route tests pass.
- **WP3 Slides.** `WeightSlide`, `WorkoutSlide`, `TodaySlideCard`; port content; delete `WeightCard` widget (keep `weightCardProvider`), `WorkoutTodayRow`; update `_DayHeader`, barrels, ARB. Done when `today_*` widget tests pass.
- **WP4 Tests and goldens.** Update/replace tests (list below), regenerate **only touched** goldens, fix the acceptance sweep and offline tests, Patrol finders.
- **WP5 Spec and close.** D-092, HM-005/006/009 text, `steps/README.md` row, backlog #74 note, cross-check, Codex review, fixes, Outcome.

### Test list
Unit: 
- T1 `sparklineValues` — last 30 days, one per day (the day's last), ≥ 2 else empty, ends on `date`, ignores later days (WB-011).
- T2 `todayWorkout` — logged beats planned; planned for today/future; **last** for a day with none (before it), `None` with no sessions; past day never "planned" (HM-006, WO-021).
- T3 `todaySlide` — default 0; select; survives rebuilds.

DS widget:
- T4 `FbSlideCard` — swipe changes index and calls back; dot tap jumps; semantics label "Nutrition, 1 of 3" and increase/decrease actions; reduced motion has zero-duration; external `index` change jumps.
- T5 `FbPageDots`/`FbSparkline` — states, flat series, ≥ 48 dp targets (UX-0xx tap size).

App widget (`apps/mobile/test/features/today/presentation/today_slide_card_test.dart`, `today_weight_test.dart` rewritten, `workout_slide_test.dart`):
- T6 HM-001–003 Nutrition slide is first and unchanged (existing `today_numbers_test.dart` still passes).
- T7 HM-005 Weight slide: value/trend/last line; "+ Weigh in" opens the sheet in 2 taps and logs; with none: "Log your first weigh-in"; past day = as-of trend, logs on that date; tip shows and is marked shown only while Weight is selected (WB-012).
- T8 HM-006 Workout slide: planned "{name} today" + Log → `TodayWorkoutLogRoute(template)`; logged "Push ✓ · 5 exercises · 1 PR" opens the session; last session; no plan shows "Log a workout" → route with null template; map hidden at text scale ≥ 1.4.
- T9 No overflow for every slide × state (loading, error, empty, full, Ramadan maintain, setup row) at text 1.0 and 2.0; card height equal across slides.
- T10 Laziness: with only slide 0 shown, `weightCardProvider` and `todayWorkoutProvider` are not read (provider-observer test).
- T11 HM-009 swipe on the card changes slide, **not** the day (`todayControllerProvider` unchanged).
- T12 HM-009 swipe below the card changes the day; ‹ › still work; slide index kept when the day changes (D1/D2); neighbour pages follow (D2).
- T13 Notes still show below the card: Ramadan proposal, not-fasting, incomplete (HM-004 family), account banner, sync line.
- T14 Guest and signed-in render the same card.

Goldens (light, dark, text 2.0, touched only): Today with slide 0 (existing `today_golden_test.dart`/`today_targets_golden_test.dart` regenerate), a new `today_slides_golden_test.dart` for slides 1 and 2, DS component goldens. 

Acceptance: `accessibility_sweep_test.dart` — Today scenes include each slide (tap targets ≥ 48 dp, labels, contrast, text 2.0); the sweep step that finds `WeightCard` changes to the slide finder; performance sweep keeps its Today budget; `offline_of01_test.dart` (weigh-in from Today: swipe to the Weight slide, tap "+ Weigh in", Save) and `patrol_test/weigh_in_test.dart` (`_slimAdd` → `find.byKey(const ValueKey('today-weigh-in'))` after a swipe on `fb-slide-card`), `patrol_test/offline_test.dart` (line ~200, `find.byType(WeightCard)`). Grep `patrol_test` and `integration_test` for "Weight", "workout-today-row", "weightCard" before finishing (UI-copy rule).

### Exit-criteria mapping
- Card with three slides and dots, Nutrition first → T4, T6, golden.
- Weight and workout rows gone from Today, content kept → T7, T8, D9 table, cross-check list.
- Today shorter (backlog #74) → widget test T15: with a weigh-in and a planned workout the page's header height is smaller than before (assert against a stored constant, the pre-change height measured by Codex at 1.0 scale and put in the Outcome).
- No gesture fight → T11, T12.
- Accessibility → T4 label, sweep.
- No startup/network cost → T10, performance sweep.

### Risks and unknowns
1. **Gesture conflict (D3).** Accepted trade-off; flagged to the owner. Fallback: day-swipe strip. The nested vertical `CustomScrollView` plus nested horizontal `PageView` hit-test in tests (`tester.fling` on the card) — T11/T12 prove it.
2. **Fixed height (D4).** Large text on Nutrition in eaten mode + setup row, or the Ramadan line, may exceed the measured height; T9 catches it. If it does, raise `baseHeight` (the card is meant to be tallest-slide) rather than shrink content; expect the saving versus today to be smaller at text 2.0.
3. **Provider laziness.** Moving watches into slides changes when the weight stream loads; a first swipe to Weight could show a skeleton for a frame. Mitigation: the existing `weightCardProvider` is synchronous over warm streams (A14 note); keep it so, and T7 checks no skeleton on the first swipe in tests.
4. **Test churn.** Finders for `WeightCard`/`workout-today-row` in about 6 files; keep key `workout-today-row` on the slide's tap area to limit edits.
5. **`TodayWorkoutLogRoute` change** touches the router and notification links (they pass a template; unaffected).
6. **Owner items:** D-092 spec text (D12).

### Size check
M (1–1.5 sessions). No split needed; WP1 could be a separate commit but not a separate step.

### Implementation notes for Codex
- Work on branch `step/A56-today-summary-card` in `~/work/fitness_buddy_3`; local commits per WP, **no pushes** (each push is a full CI run; `tools/scripts/merge-step.sh` carries it). Conventional Commits, e.g. `feat(today): A56 summary card`. Trailer lines as the repo requires.
- Setup: `export PATH=~/development/flutter-3.47.7/bin:$PATH`. Focused tests only: `timeout 600 tools/scripts/heavy.sh flutter test apps/mobile/test/features/today/presentation/today_slide_card_test.dart` (run from `apps/mobile`, so the path is `test/features/...`; DS tests from `packages/fb_design_system`). Full suites run in CI at merge. Codegen: `dart run build_runner build --delete-conflicting-outputs` in `apps/mobile` (providers are `@riverpod`), and `flutter gen-l10n` after ARB edits.
- Files to touch:
  - DS: `packages/fb_design_system/lib/src/components/slide_card.dart`, `page_dots.dart`, `src/charts/sparkline.dart` (or components), `lib/fb_design_system.dart` exports, DS tests/goldens.
  - Today: `lib/features/today/application/today_slide.dart`(+`.g.dart`), `presentation/today_slide_card.dart`, `presentation/day_page.dart` (`_DayHeader`), `lib/features/today/today.dart` barrel if needed.
  - Body: `lib/features/body/presentation/weight_slide.dart`, `application/weight_sparkline.dart`; delete the `WeightCard` widget in `weight_card.dart` (keep `weightCardProvider` in `weight_card_state.dart`); `body.dart` barrel; `weight_card_mockup.dart` in `design_preview` references `WeightCard` by name only if it imports the widget (grep and fix).
  - Workouts: `presentation/workout_slide.dart`; delete `workout_today_row.dart`; `application/workout_views.dart` (+`.g.dart`) sealed-class extension; `workouts.dart` barrel.
  - Navigation: `core/navigation/app_route.dart` (`TodayWorkoutLogRoute.template` nullable), `app/router/app_router.dart` (~452–460 and ~594).
  - ARB: `lib/l10n/app_en.arb` (and any other locale file the repo keeps; strings in ARB only, no literals).
  - Tests as listed; `test/acceptance/accessibility_sweep_test.dart`, `offline_of01_test.dart`, `support/acceptance_app.dart`; `patrol_test/weigh_in_test.dart`, `patrol_test/offline_test.dart`.
  - Docs: `spec/decisions.md` (D-092), `spec/16-insights-and-home.md` (HM-005/006/009), this card's Outcome, the board row.
- Patterns: `FbType`/`FbSpace`/`FbDensity` tokens, directional padding (`EdgeInsetsDirectional`), `FbMotion.of(context)` for animations (zero under reduced motion), `FbCard`/`FbButton`/`FbSkeleton`/`FbInlineBanner` from the DS, theme colours only, neutral language (never red, PR-12). No user content in logs. `ChangeSetApplier` is **not** touched; nothing here writes data except through the existing weigh-in sheet and workout log screens.
- Tests: **the CI-only riverpod lint rule** forbids inline `ProviderScope(overrides: [...])` in tests; use the repo's test helpers (see `test/features/today/presentation/support/` and `test/acceptance/support/acceptance_app.dart`) and look at how `today_weight_test.dart` builds its scope. Regenerate goldens with `flutter test --update-goldens <file>` **only for the files you touched**; look at each changed golden image (Read tool) before keeping it. Add `// Covers: HM-005` style traceability tags per `10-engineering-practices.md`, then run `make trace`.
- Do not touch: targets engine, diary rows, `QuickAddBar`, sync, contracts.
- Before hand-back: `make check` for the touched packages (analyze + format), grep `patrol_test`/`integration_test`/`test` for removed strings and keys, then a cross-check of the D9 table.

## Progress log
- 2026-10-31: plan written (planner).

- 2026-10-31: WP1–WP3 implemented: lazy DS pager/dots/sparkline, session slide provider, as-of sparkline, workout Last/None, nullable Today log route, slide content and day header. Old presentation widgets removed; write paths untouched.
- 2026-10-31: WP4: updated Today/weight/workout tests, offline acceptance and Patrol finders, outer-day pager finders and day-swipe benchmark origins. New loading/error, laziness, gesture, session lifetime and height coverage. Focused checks only; no full suites.
- 2026-10-31: Owner approved adaptive height during build: compact at normal text, taller from scale 1.4; every slide uses the same height. Populated Nutrition/Ramadan and sparse weight notes determine the final compact baseline of 256 dp (304 including card/dots). Large-text baseline is 390 dp before DS scaling (clamped at 2.0). Compact card uses density block-gap vertical padding; weight keeps its last-value edit and log button side by side at normal text.
- 2026-10-31: WP5: recorded owner-authorized D-092 and amended HM-005/006/009. Separate review is orchestrator-owned; skipped the WP5 Codex review as instructed. Changes are intentionally uncommitted.

- 2026-10-31: close: focused tests/goldens and full accessibility/query-plan sweeps passed; final tap-target recheck and final body/acceptance analysis passed. Format, diff whitespace, trace and progress checks complete. Board marked closed, awaiting review; all changes left uncommitted.

- 2026-10-31: review fixes after eb2dcd92: allow a missing template on the Today log route, reject only a supplied malformed UUID, and add real-router URL/action regressions. Resolve height once at 256–400 dp; bounded slides scroll vertically to preserve large text. Added height/overflow/scroll-reachability and child semantics-action regressions; refreshed affected goldens. Fixes remain uncommitted.

## Outcome

Built the three-slide Today summary, accessible named dots and adjustment actions, shared session selection, lazy weight/workout reads, raw 30-day weight sparkline, last-session and always-visible empty workout states. Graph, weigh-in logging on the viewed date, latest-value editing, sparse-history note and dismissible monthly tip remain available. Notes, account, sync and scan hints remain below the summary. No contract, DB, startup network or ChangeSetApplier change. The free workout route stays on Today; no D11 fallback was needed.

**Deviations:** the owner explicitly approved adaptive height instead of D4's single baseline multiplied by text scale. Final normal baseline 256 dp, larger baseline 390 dp from scale 1.4, shared by all slides. Populated macro text needed more than the initial approximately 230 dp estimate. Vertical padding uses the compact density block gap. A temporary reconstruction of the original widgets measured the prior weighed-in/planned header at **310 dp** (360 dp phone, populated targets with Ramadan maintain); the new summary measures **304 dp**. Thus T15 proves a reduction, but the plan's estimated 120–170 dp saving does not apply to the already-slim A45 weighed-in case. The feature remains a consolidation, and backlog #74 remains open. Temporary measurement widgets were removed after recording this constant.

**Validation:** final results recorded below before hand-back. Goldens retain light/dark and text 1.0/2.0 variants. No full suites, emulator, paid service or network smoke was run. Default heavy-lock location was read-only in this sandbox; checks used the supported `FB_HEAVY_LOCK=/tmp/fb-heavy-a56.lock` override, sequentially. This does not coordinate with other lanes using the default lock.

**Review/follow-ups:** closed, awaiting the separately arranged reviewer; no self-review task spawned. Owner can judge the compactness in use; backlog #74 remains the broader one-screen goal. Actual size: one sustained build session with layout/test fix rounds. No commits or pushes.


### Review fixes (after eb2dcd92)

- **Blocker fixed:** `/today/workout-log?date=...` without a template opens `WorkoutLogScreen.newSession(inToday: true)` with the date intact. Only a supplied invalid template UUID redirects to Today. Updated the stale route comment. New `app_router_test` checks both cases, and `workout_slide_test` taps the empty-state action through the real app/router and verifies the resulting log screen rather than a recorded location.
- **Height fixed:** `FbSlideCard.height` now means final logical pixels and is never scaled internally. Today resolves it once, smoothly from 256 dp at 1.0 to 400 dp at 2.0 (299.2 at 1.3; 313.6 at 1.4), identically for all slides. This supersedes the initial 390-dp baseline and its unintended second multiplication. Tests pin final DS height, monotonic growth, the 420-dp upper bound, equal slide heights and no overflow in loading/error/empty/populated/Ramadan states at all four requested scales.
- **Necessary layout adjustment:** bounded slide contents can scroll vertically instead of growing toward a full screen, shrinking text or dropping information. This supersedes the original no-inner-scroll assumption. The 2.0 weight test scrolls to the actual weigh-in control and verifies it is hit-testable without changing the slide. The acceptance helper reveals controls in the inner vertical viewport before positioning the outer day list.
- **Minor covered:** the widget test performs real semantics tap actions on both the weigh-in and workout Log controls beneath the pager's container semantics; it verifies the sheet/route opens.
- **Validation:** the 129-test focused Today/workouts/router regression run passed; DS slide-card/widget/golden checks passed (5); affected app goldens passed (5) with light/dark/text-2.0 retained. Final card/scroll/semantics recheck passed (26 tests). The broader accessibility sweep passed its other six cases; its 2.0 case exposed a helper dragging the inner viewport rather than the outer list, now fixed and passing on focused rerun (1). Both folder-scoped analysis and the final helper analysis report no issues; format verification and `git diff --check` passed. All six refreshed golden images were visually inspected. No full app suite or emulator run. Changes intentionally remain uncommitted for the orchestrator.

### Final validation

- Focused feature tests passed: `today_slide_test.dart`, `weight_sparkline_test.dart`, `today_slide_card_test.dart`, rewritten `weight_card_test.dart`, `today_weight_test.dart`, `workout_slide_test.dart`, `workout_log_controller_test.dart`, existing `today_numbers_test.dart`, `today_navigation_test.dart`, `today_screen_test.dart`, `today_targets_journey_test.dart`.
- Cross-checks passed: `app_router_test.dart`, `app_tabs_test.dart`, offline acceptance `offline_of01_test.dart`, full focused-file accessibility sweep (1.5/2.0 layout, 48 dp targets, light/dark contrast), and `query_plan_audit_test.dart` (9 sweep/audit tests passed). Its listed existing scan exceptions remain unchanged.
- DS widget/sparkline/semantics tests and DS light/dark/text-2.0 goldens passed. App `today_golden_test.dart`, `today_targets_golden_test.dart`, new `today_slides_golden_test.dart` passed with only those goldens regenerated. All six resulting golden images were visually inspected.
- `make gen-app` passed (l10n and provider generation). Folder-scoped `dart analyze` passed with no issues across changed app/DS code, test helpers, Patrol and integration folders. Changed Dart files pass format verification; `git diff --check` passed.
- `make trace`: passed, R1 251/325 covered, 74 missing, 14 repository-wide warnings (no scope expansion to fix existing trace coverage). `make progress` and `make progress-check` passed.
- Patrol and integration references were searched; no removed widget/key references remain there. Finders now select Weight and use `today-weigh-in`; the device day-swipe benchmark starts below the summary. **Not run:** emulator Patrol/integration and the device frame-budget benchmark. The host query-plan audit and lazy-provider tests passed; no new device timing claim is made.
- Accessibility clarification: existing full-unit “Log a weigh-in” semantics annotate the log button; the value area's semantics name the weight graph, matching its actual action. The sweep helper scrolls only the vertical list when locating a control inside the inner horizontal pager, preventing accidental day/slide changes.

### Changed-file manifest

Initial build manifest, including generated code, goldens and the two removed widgets. The orchestrator committed this build as eb2dcd92; the review fixes above remain uncommitted.

```text
PROGRESS.md
apps/mobile/integration_test/jank_benchmark_test.dart
apps/mobile/lib/app/router/app_router.dart
apps/mobile/lib/core/navigation/app_route.dart
apps/mobile/lib/features/body/application/weight_sparkline.dart
apps/mobile/lib/features/body/body.dart
apps/mobile/lib/features/body/presentation/weight_card.dart
apps/mobile/lib/features/body/presentation/weight_slide.dart
apps/mobile/lib/features/today/application/today_slide.dart
apps/mobile/lib/features/today/application/today_slide.g.dart
apps/mobile/lib/features/today/presentation/day_page.dart
apps/mobile/lib/features/today/presentation/today_numbers.dart
apps/mobile/lib/features/today/presentation/today_slide_card.dart
apps/mobile/lib/features/workouts/application/workout_views.dart
apps/mobile/lib/features/workouts/application/workout_views.g.dart
apps/mobile/lib/features/workouts/presentation/workout_slide.dart
apps/mobile/lib/features/workouts/presentation/workout_today_row.dart
apps/mobile/lib/features/workouts/workouts.dart
apps/mobile/lib/l10n/app_en.arb
apps/mobile/lib/l10n/gen/app_localizations.dart
apps/mobile/lib/l10n/gen/app_localizations_en.dart
apps/mobile/patrol_test/offline_test.dart
apps/mobile/patrol_test/weigh_in_test.dart
apps/mobile/test/acceptance/accessibility_sweep_test.dart
apps/mobile/test/acceptance/offline_of01_test.dart
apps/mobile/test/acceptance/query_plan_audit_test.dart
apps/mobile/test/acceptance/support/acceptance_app.dart
apps/mobile/test/features/body/application/weight_sparkline_test.dart
apps/mobile/test/features/body/presentation/weight_card_test.dart
apps/mobile/test/features/today/application/today_slide_test.dart
apps/mobile/test/features/today/presentation/goldens/ci/today_empty_day.png
apps/mobile/test/features/today/presentation/goldens/ci/today_full_day.png
apps/mobile/test/features/today/presentation/goldens/ci/today_slides.png
apps/mobile/test/features/today/presentation/goldens/ci/today_targets_under.png
apps/mobile/test/features/today/presentation/support/today_support.dart
apps/mobile/test/features/today/presentation/today_golden_test.dart
apps/mobile/test/features/today/presentation/today_navigation_test.dart
apps/mobile/test/features/today/presentation/today_screen_test.dart
apps/mobile/test/features/today/presentation/today_slide_card_test.dart
apps/mobile/test/features/today/presentation/today_slides_golden_test.dart
apps/mobile/test/features/today/presentation/today_targets_journey_test.dart
apps/mobile/test/features/today/presentation/today_weight_test.dart
apps/mobile/test/features/workouts/application/workout_log_controller_test.dart
apps/mobile/test/features/workouts/presentation/workout_slide_test.dart
apps/mobile/test/helpers/pump_app.dart
packages/fb_design_system/lib/fb_design_system.dart
packages/fb_design_system/lib/src/components/slide_card.dart
packages/fb_design_system/lib/src/components/sparkline.dart
packages/fb_design_system/pubspec.yaml
packages/fb_design_system/test/components/goldens/ci/slide_card.png
packages/fb_design_system/test/components/goldens/linux/slide_card.png
packages/fb_design_system/test/components/slide_card_golden_test.dart
packages/fb_design_system/test/components/slide_card_test.dart
spec/16-insights-and-home.md
spec/decisions.md
technical-planning/steps/A56-today-summary-card.md
technical-planning/steps/README.md
technical-planning/steps/backlog.md
```
