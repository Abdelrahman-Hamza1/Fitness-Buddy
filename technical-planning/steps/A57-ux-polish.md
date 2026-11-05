# A57 — UX polish: stable, named, recoverable, smooth, accessible + Today top

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A56 (reworks it), A53, A54 | XL (one step by the owner's choice) | Claude plans and builds (one Opus `flutter-engineer`), one Codex review | ✅ Closed (owner acceptance by use, TD-037) |

_2026-11-05. One combined step (owner): the five UX-polish work packages A57–A61 from the Codex audit, plus a rework of the top of Today ("T"). One plan, one engineer, one Codex review; the orchestrator approves the plan (no separate plan review). Tier **Normal** (see D1)._

**Goal.** Nothing on screen moves while you type, validate or wait; food names follow the setting everywhere; loading and errors never pretend to be empty; opening and closing things is smooth and consistent; dense screens work at large text and with TalkBack. Today's top goes back to one calories card with one slim weight · workout line under it, and day swipe works everywhere again. The red nightly emulator suite goes green again.

**Spec:** HM-001–009, AI-045, DY-025, LC-007, WB-001, WB-011, WB-012, WO-021, TG-043, UX-005, UX-012, UX-024, UX-025, UX-050–052, UX-070–071 · **Amends:** D-092 (superseded by D-093), HM-004/005/006/009, AI-045, DY-025, LC-007, TG-043 wording; adds UX-045/046 (D-093–D-095, owner decisions of 2026-11-05).

**Read first:** `technical-planning/ux-audit-2026-10-31.md` (80 items with file:line and fix), the owner's mockups `~/work/ux-sketches/ux-review-2026-11-05/` (Main, Today, A57-Stable … A61-Access), `A56-today-summary-card.md` (what T undoes), `spec/16`, `spec/decisions.md` D-090–D-092, `PROCESS.md` (lean tests, TD-104).

## Owner decisions (2026-11-05, final)
T = B (one calories card + one slim weight | workout line, fixed height, day swipe everywhere) · S1 A (dashes, both lines kept) · S2 B (one reserved supporting line: hint, error in the same place) · N1 A (Both = English, Arabic underneath, everywhere) · N2 A (quick-add chips: main name only; semantics read both) · R1 A (stale results fade to ~35 %, not tappable, thin progress line; skeletons only for the first search) · R2 B (pending Buddy proposals as a count on the Buddy bar; no strip) · M1 A (`FbMotion` 200/300 ms, standard + emphasized-decelerate easing, zero under reduced motion, incl. 200 ms tab fade-through) · C1 A (set row: "last time" above inputs at large text / narrow width, PR on its own reserved line) · C2 B (per-day targets as 7 rows). Scope: all 80 items.

## Source split (folded into this step)

| Former step | Work package | Audit items | Acceptance evidence |
|---|---|---|---|
| old A57 | Stable logging and editing | A01–A08, A15, A65, A79 | Type, clear and replace values repeatedly. No field, footer or numeric-column moves at 1×, 1.3× or 2×, including digit-count boundaries and validation failures. |
| old A58 | Food names everywhere | A30–A40 | Take the same food through search → log → diary → edit → Buddy → saved meal → barcode → feedback, in all four settings. Include missing Arabic names and mixed-script punctuation. |
| old A59 | Recovery and unfinished work | A41–A49, A62–A64, A66–A71 | Inject provider errors, dismiss and reopen Buddy, return from barcode creation, retry. No false-empty screens, trapped loaders or lost drafts. |
| old A60 | Consistent motion | A09–A14, A16–A29, A80 | One motion vocabulary (`FbMotion`, 200 ms local / 300 ms structural, M3 easing). Controls stay anchored, scroll position holds, and durations are zero under reduced motion. |
| old A61 | Accessible charts and dense screens | A50–A61, A72–A78 | TalkBack pass; narrow-phone and 2× text screenshots; composited contrast checks; long-list profiling. |

The work-package order below regroups these by shared code, not by former step.

## Exit criteria
1. T: Today's top is one calories card plus one slim weight | workout line; no slides or dots; the line's height is identical in every state; day swipe works anywhere on Today.
2. R2: pending Buddy proposals show as a count on Today's Buddy bar and one tap opens Buddy at them.
3. No layout movement: the stability tests (list below) pass at text 1.0/1.3/2.0 for fields, sheets, rows and the Today line.
4. Food names follow the setting on every surface in the audit's A30–A40 list, in all four settings.
5. No false-empty or trapped-loading screen in the A42–A49 list; each has loading / error+retry / empty.
6. One motion vocabulary; every new animation is zero under reduced motion.
7. Contrast ≥ 3:1 (composited) for the changed informative marks; 48 dp targets; set rows and Progress charts usable at 2× / 320 dp.
8. Every audit item A01–A80 and T is built or explicitly deferred (coverage table).
9. The nightly emulator suite is green on a manual CI run with `android-it` (`[it]`) before the merge.

---

## Low-level plan (A57–A61 + T, combined)
_Claude (step planner), 2026-11-05. Size **XL**, estimate **4–6 sessions including one fix round** (see Size check). Paths are relative to `apps/mobile/` unless they start with `packages/`, `spec/` or `technical-planning/`._

### Summary
After this step Today's top is one `FbCard` with `TodayNumbers` and, directly under it, `TodayGlanceLine` (weight | workout, fixed height). The A56 slide machinery is deleted and day swipe works on the whole page. Today's Buddy bar says "2 waiting" when proposals are pending. The design system gains one motion vocabulary (`FbMotion`), a reserved supporting line in every field, a fixed-width number slot and two reveal widgets; every screen named in the audit uses them. Food names are carried as structured `FoodNames` to the presentation layer and resolved there. Loading and error states are explicit everywhere the audit found blanks. Set rows, per-day targets and Progress charts adapt to large text. The three red Patrol tests are fixed.

### Decisions
- **D1 One step, tier Normal.** The step is presentation work; nothing changes in `ChangeSetApplier`, the DB schema, sync or contracts. Two items are write-adjacent: A71 (settings coalescing, D22) and A35 (in-memory `RemovedLine`). The single combined Codex review is briefed to check data integrity on those two. Reason: the owner wants one review; neither touches the writer itself.
- **D2 T layout.** `TodaySummaryCard` (`features/today/presentation/today_summary_card.dart`) = `FbCard` around the unchanged `TodayNumbers`, then `TodayGlanceLine` **under the card** (not inside it), with the card's horizontal padding. Reason: the card reads exactly like option A; the line is the only addition (mockup T-B).
- **D3 Weight half.** Shows the **as-of trend weight and weekly rate** ("72.4 kg · −0.3 kg/week", existing `weightText`/`weightRateText` formatters) from `weightCardProvider(date, isToday:)`. Stale: "{trend} · {day}". No weigh-ins on or before the day: "Weigh in" with a ＋ icon. **Tap → weigh-in sheet for the viewed day** (`showWeighInSheet(date: isToday ? null : date)`): tap, type, Save = 2 non-digit taps (WB-001, UX-005). The graph stays one tab away (Progress). Reason: WB-011 makes the trend the main weight number; the owner's mockup says "tap the weight to weigh in". **If the owner meant the raw latest weigh-in, it's a one-line swap** (`state.latest.kg`); flagged under Risks.
- **D4 Workout half.** From the unchanged `todayWorkoutProvider(date)`: `Logged` → "{title} done", tap opens the session (`TodayWorkoutSessionRoute`); `Planned` (today and future only, as now) → "{name} today", tap → `TodayWorkoutLogRoute(template:)`; `Last` / `None` and every past day without a session → "Log workout", tap → free session on the viewed day (`TodayWorkoutLogRoute(template: null)`). There's no last-session text and no "missed" note, ever. The provider is kept, since `workouts_screen.dart:47` reads it.
- **D5 Fixed height.** `TodayGlanceLine` = `Row(Expanded(weight), vertical divider, Expanded(workout))`. Each half is a `ConstrainedBox(minHeight: 48)` `InkWell` with a leading icon and **one** line of text (`maxLines: 1`, ellipsis). Loading = an `FbSkeleton.line` in the same box. Error = a muted "Unavailable" text whose tap retries (invalidate). Every state has the same structure, so the same height. At text scale ≥ 1.5 the halves stack (two 48 dp rows): chosen by **scale, never by state**. A test pins the equal heights (T-T3).
- **D6 Day swipe.** Removing the inner pager is all that HM-009 needs. The A56 gesture tests (swipe on the card changes the slide) are replaced by one test: a swipe that starts on the card changes the day.
- **D7 Deleted** (each grepped for readers first): `FbSlideCard`/`FbSlide`/`FbPageDots` (`packages/fb_design_system/lib/src/components/slide_card.dart`), `FbSparkline` (`sparkline.dart`) and their exports, tests and goldens (`slide_card_test.dart`, `slide_card_golden_test.dart`, `goldens/{ci,linux}/slide_card.png`); `WeightSlide` (`features/body/presentation/weight_slide.dart`), `sparklineValues` (`body/application/weight_sparkline.dart` + test), `WorkoutSlide` (+ `workout_slide_test.dart`), `TodaySlideCard`, `todaySlideProvider` (`today/application/today_slide.dart` + `.g.dart` + test), `today_slide_card_test.dart`, `today_slides_golden_test.dart` + `goldens/ci/today_slides.png`; `TodayWeightGraphRoute` (its only reader was the slide; remove from `core/navigation/app_route.dart`, `app/router/app_router.dart:130,648` and `app_router_test`); ARB keys `todaySlide*`, `weightSlideAdd`, `workoutSlide*` (this also resolves A75's string). `TodayWorkoutLogRoute` with a nullable template and `TodayWorkoutSessionRoute` stay. `alchemist` stays in the DS pubspec (other goldens use it).
- **D8 Where the weight extras go.** The sparse-history note, the "rate after 2 weeks" note and the 30-day "weigh in 2–3 times a week" tip move to Progress's `WeightSection` (`features/progress/presentation/weight_section.dart`), as one quiet line under the chart. It reads `weightCardProvider(today, isToday: true)`, and the tip is marked shown when that line is built, dismissible as before (WB-012). Editing the last weigh-in: from the weight graph screen. WP3 checks that `weight_graph_screen.dart` offers edit on a weigh-in; if it doesn't, it adds edit on its latest-weigh-in line. HM-005 is amended to match.
- **D9 R2 count.** `pendingProposalCountProvider` (`features/buddy/application/pending_proposals.dart`, `@riverpod Stream<int>` over `proposalRepository.watchPending().map((l) => l.length)`, all kinds; exported from `buddy.dart`). `FbInputBar` gains `String? badge` (a small tonal pill at the end, before the camera and barcode buttons; the bar keeps its 52 dp minimum and only the hint's width shrinks) and `String? semanticsHint`. Only Today passes `l10n.todayBuddyWaiting(n)` ("{n} waiting", ICU plural). Tap → `showBuddySheet(context, date:, revealPending: true)`, which scrolls the message list to the oldest open card (`MessageList.revealCard(id)`, reusing WP6's follow logic). Reason: owner R2 B. HM-004 / AI-045 / DY-025 are amended.
- **D10 Name plumbing.** Structured names travel to the presentation layer and are formatted there:
  - Outcomes carry `FoodNames`, not `String`: `LogFoodOutcome` (`foods/application/log_food.dart:106`), the food-sheet entry outcome (`foods/presentation/food_sheet_entry.dart:73`), `QuickAddController` outcomes (`quick_add/application/quick_add_controller.dart:102`), the personal-food merge outcome, the diary action messages (`diary/presentation/entry_actions.dart:29`, `move_entry_sheet.dart:70`, `entry_amount_sheet.dart:88`), `RemovedLine(id, FoodNames names)` (`buddy/application/buddy_thread_state.dart:198`, captured at `buddy_thread_controller.dart:386`) and `FoodCardView` question and assumption references (`buddy/application/food_card_view.dart:168`).
  - `PendingScan` gains an optional `nameAr`, stored as JSON key `name_ar`. Old entries without it still read; no migration (shared_preferences JSON).
  - Domain: `DayLayout` `summaryNames: List<String>` → `summaryFoods: List<FoodNames>` (`packages/fb_domain/lib/src/diary/day_layout.dart:129`). A user-written group name becomes `FoodNames(en: typed)`, so every setting shows it as typed (Arabic falls back to it).
  - Helpers in `features/settings/presentation/food_name_text.dart`:
    - `watchFoodNames` (rows, existing);
    - new `watchFoodNameInline(ref, names) → String`: the primary name, `isolateName`-wrapped, for titles, sentences and snackbars. In **Both** it's the English name only: a sentence never mixes scripts, per the owner's N1 reasoning.
    - new `foodNameSpoken(lines)`: "English, Arabic", for semantics.
  - Every interpolation of a name, query, alias or product name into ARB text goes through `isolateName` (A40).
- **D11 N2.** `QuickAddChip` shows `lines.primary`; its semantics label is `foodNameSpoken(lines)` (`quick_add/application/quick_add_model.dart:31` keeps `FoodNameLines`, not only `primary`).
- **D12 S2 reserved supporting line.** `FbNumberField`, `FbTextField` and `FbCodeBoxes` stop using `InputDecoration.errorText`/`helperText`. They render their own `_FbSupportingLine` below the field, `supportingLines` lines tall (default 1; 0 = none, for dense inline fields), measured at the current `TextScaler`:
  - Normally it shows the new `supportingText` (the hint; the existing `hint` stays the placeholder).
  - With an error it shows `errorText` in `scheme.error` in the same box, `Semantics(liveRegion: true)`, and the field border shows the error state (`InputDecoration.error: SizedBox.shrink()` for the red outline with no Material error row).
  - Text beyond the reserved lines is ellipsised; forms with long errors pass `supportingLines: 2`.
  - `maxLength`'s counter moves into the same line, end-aligned.
  - Reason: Material's helper line still grows when an error wraps; a reserved box can't.
- **D13 S1 dashes.** `_Nutrition` in `food_sheet.dart:447` and its twin in `entry_amount_sheet.dart:178` always render both lines. An incomplete amount → `foodSheetKcalPending` "— kcal" and `foodSheetMacrosPending` "P — · C — · F — · Fiber —". A real zero shows "0 kcal". Numbers sit in `FbNumberSlot`s, so 248 → 2,475 moves nothing.
- **D14 `FbNumberSlot`** (DS, `components/number_slot.dart`): `FbNumberSlot({required String text, required TextStyle style, String sample = '8,888', TextAlign align = TextAlign.end})`. Width = a `TextPainter` of `sample` in `FbType.numeric(style)` at the current scaler; text end-aligned with a single-line ellipsis. Used for diary trailing kcal (A03, sample "8,888"), food-sheet values, macro values (A04), the targets day list (C2) and history rows.
- **D15 Macro-bars mode (A04).** `_columnsFit` (`macro_bars.dart:111`) measures a **representative** `valueText` per macro (a new `FbMacroValue.sampleText`, default "888 / 888 g") instead of the live value. The mode depends only on width and scale.
- **D16 `FbMotion` vocabulary** (`packages/fb_design_system/lib/src/tokens/motion.dart`):
  - `local = 200 ms`, `structural = 300 ms` (`normal`/`slow` stay as deprecated aliases, removed by the sweep; `fast` 120 ms stays for tap highlights);
  - `standard = Cubic(.2, 0, 0, 1)`, `emphasizedDecelerate = Cubic(.05, .7, .1, 1)`; `curve` now points at `standard`;
  - `FbMotion.localOf(context)` / `structuralOf(context)` give zero under `disableAnimations`.
  - Explicit "no motion" list in the doc comment: keystrokes, validation, search reorders, initial chart drawing.
  - **TD-113** (motion vocabulary + reserved-geometry conventions in the DS), recorded in WP1 in `technical-planning/12-decisions-and-questions.md`.
- **D17 Reveal widgets** (DS, `components/reveal.dart`):
  - `FbReveal({required bool visible, required Widget child, bool appearOnMount = false})`: a clipped `SizeTransition` (`axisAlignment: -1`, so it grows downward and whatever is above stays put) plus a fade, `localOf`, `standard` easing. `FbReveal.entering(child)` animates in on first mount (for sliver rows).
  - `FbSizeFade({required Widget child})`: `AnimatedSize` + `AnimatedSwitcher` fade, `structuralOf`, for swapping states inside one region (notices, proposal resolution, export states).
  - Both are zero under reduced motion.
- **D18 Diary disclosure in the sliver list (A16/A17).** `DayPage` becomes a `ConsumerStatefulWidget` that remembers the last row keys.
  - When the **expanded set** changed (meal, group, entry details), newly present rows mount in `FbReveal.entering`. Rows removed by a collapse stay for `localOf` as `_ExitingRow` (`FbReveal(visible: false)`, `IgnorePointer`, `ExcludeSemantics`), then drop.
  - Data changes (log, delete, move) keep today's immediate behaviour.
  - Only rows below the tapped header change, so the header never moves. Keys stay `_keyOf`.
- **D19 Tab fade-through (A27).** `app_router.dart:110` moves from `StatefulShellRoute.indexedStack` to `StatefulShellRoute(navigatorContainerBuilder: …)` with `_FadeThroughBranches`: an `IndexedStack` that keeps every branch mounted (`TickerMode` off for hidden ones) and fades the incoming branch 0 → 1 over `localOf`. The `NavigationBar` animation is unchanged. **Fallback:** if branch state or `ScrollToTopOnTabReselect` breaks, A27 goes to the backlog with that reason.
- **D20 C1 set row** (`workouts/presentation/set_row.dart`). `LayoutBuilder`: **compact** when width < 360 dp or text scale ≥ 1.3.
  - Compact: line 1 = set-number menu target + "last 60 × 8"; line 2 = inputs + checkbox; line 3 = one reserved caption line for PR or the invalid message. The reserved line is always present in compact mode.
  - **Normal** layout (one row) keeps PR in a **fixed-width status slot** before the checkbox (A05). The invalid state there shows an error icon in the same slot (tooltip + semantics "Check this set") instead of inserting a line.
  - Set inputs use `supportingLines: 0`.
- **D21 C2 per-day targets** (`targets/presentation/targets_screen.dart:262`).
  - `FbWeekBars` is replaced by `_DayTargetList`: 7 `FbListRow`s (≥ 48 dp) in week-start order, full weekday name, the number in an `FbNumberSlot` ("2,100 kcal"), tap → `showDayTargetSheet`.
  - Changed days: `primaryContainer` row tint **plus** a bold number and a "Changed" semantics suffix (not colour alone). Today keeps the existing "today" semantics string.
  - Numbers tween over `structuralOf` (A25, `TweenAnimationBuilder<int>`), with the UX-024 highlight on change.
  - `FbWeekBars` (`week_bars.dart`) is deleted if nothing else reads it (grep). That also resolves A57's contrast item.
- **D22 A71 latest intent.** In `settings/application/settings_actions.dart:160`, a second `_set` for a key with a write in flight stores its value in `_queued[key]` and returns a new `SettingsQueued`, not `SettingsPending`. When the in-flight write completes, if `_queued[key]` differs from the stored value, it's written through the same `store.put` path (own change set and undo entry). Nothing is dropped and the writer is untouched. The control stays enabled.
- **D23 R1 search state** (`foods/application/food_search_controller.dart:110`, `food_search_screen.dart:169`).
  - The state gains `resultsQuery`; `stale = loading && query != resultsQuery`.
  - Stale rows: `AnimatedOpacity(0.35, localOf)` + `IgnorePointer` + `ExcludeSemantics`.
  - A 2 dp `LinearProgressIndicator` slot is always reserved under the field (transparent when idle).
  - The first search with nothing to show: 6 skeleton rows at row height.
  - No announcements per keystroke.
- **D24 Success haptic (A80).** `core/ui/success_haptic.dart` `successHaptic()` → `HapticFeedback.lightImpact()`, called once on a completed direct food log (search/sheet, quick-add) and a weigh-in save. Not on keystrokes or navigation; Buddy confirm keeps its own.
- **D25 Tests stay lean (TD-104).** Logic and stability tests plus one happy path per changed screen. No new goldens; touched goldens are regenerated and each image is looked at. Never assert UI copy: use keys. The Patrol fixes follow the same rule where they touch a finder.
- **D26 Deferrals:** none planned. Device-only checks are built and listed in the owner checklist. A78 gets the cheap fix (derive validation on draft change, not in `build`) with no extra caching (the audit asks for profiling first).
- **D27 Spec text (owner-approved decisions, written in WP1):**
  - **D-093 "Today: one calories card and a slim weight · workout line"**: supersedes D-092, amends HM-005, HM-006, HM-009 and the Today clauses of D-084/D-085. Text: the calories card only, no slides; one line under it, always visible, fixed height: weight (as-of trend and weekly rate, tap to weigh in on the viewed day) | workout (the day's session "done" / today's plan "today" / "Log workout"); no missed-day notes; the sparse note and weigh-in tip live in Progress; the last weigh-in is edited from the weight graph; day swipe anywhere on Today.
  - **D-094 "Unfinished Buddy proposals as a count on the Buddy bar"**: amends HM-004, AI-045, DY-025. Text: no strip on Today; Today's Buddy bar shows "{n} waiting" while proposals are pending; one tap opens Buddy at them; pending never counts toward totals.
  - **D-095 (approved by the orchestrator under the owner's "trust your decisions on the rest", 2026-11-05) "Still layouts, one motion vocabulary, names in every place"**: adds UX-045 (nothing moves while typing, validating or loading: reserved supporting lines, fixed number columns, skeletons shaped like the result, dashes for incomplete amounts) and UX-046 (200 ms local / 300 ms structural, one easing, zero with "remove animations", no motion on keystrokes, validation or search reorders). It amends LC-007 (applies to every place a food name appears, including meal previews, edit sheets, Buddy cards, barcode, merge and messages; quick-add chips in Both show the main name with both read aloud; inside sentences the main name only) and TG-043 (per-day numbers are a list of seven days). These codify the owner's S1/S2/M1/N2/C2 answers; **rec: ok**. Without approval, WP1 writes only D-093/D-094 and the code is unchanged.

### Design

**Today (after T and R2):**
```
TodayScreen
 FbDateHeader                         (unchanged)
 PageView (days)                      (swipe anywhere: no inner pager)
  DayPage(date)                       (ConsumerStatefulWidget, D18)
   _DayHeader
    TodaySummaryCard                  new: FbCard(TodayNumbers) + TodayGlanceLine
     TodayGlanceLine                  new (today/presentation/today_glance_line.dart)
      WeightGlance(date, isToday)     new (body/presentation/weight_glance.dart; exported from body.dart)
      WorkoutGlance(date)             new (workouts/presentation/workout_glance.dart; exported from workouts.dart)
    FbSizeFade(notes column)          Ramadan proposal, not-fasting, incomplete, ready scans, account, sync (A09)
   meals …                            disclosure rows via FbReveal (D18)
 QuickAddBar                          chips: main name, both in semantics (N2)
 FbInputBar(badge: "2 waiting")       R2, pendingProposalCountProvider
```
- `TodayNumbers` loses nothing. A10: its loading skeleton gains the setup-row slot once `setupStatusProvider` says `notSetUp`, and eaten vs target mode is crossfaded (`FbSizeFade`) inside the card.
- Keys: `today-summary-card`, `today-glance-weight`, `today-glance-workout`, `today-buddy-waiting`. `today-weigh-in` and `workout-today-row` are retired; WP10 retargets the Patrol finders.

**Design-system additions** (exported from `packages/fb_design_system/lib/fb_design_system.dart`):

| Component | File | What it does | Used by |
|---|---|---|---|
| `FbMotion` | `tokens/motion.dart` | D16 | all motion |
| `_FbSupportingLine` + `supportingText` / `supportingLines` | `components/number_field.dart`, `text_field.dart`, `code_boxes.dart` | D12 | every form |
| `normalizeDigits(String)` | `components/digits.dart` (extracted from `FbDecimalInputFormatter`) | Arabic-Indic and Persian digits → ASCII | number fields, code boxes (A60) |
| `FbNumberSlot` | `components/number_slot.dart` | D14 | diary rows, food sheet, macros, targets list |
| `FbReveal`, `FbSizeFade` | `components/reveal.dart` | D17 | disclosures, notices, cards |
| `FbInputBar.badge` | `components/input_bar.dart` | D9 | Today |
| `FbSkeleton.row` | `components/skeleton.dart` | a skeleton row the height of an `FbListRow` (title + subtitle) | search, earlier versions, workouts, measurement |
| `ChartColors.muted` → new `rawPoint` role | `charts/time_series_painter.dart:18` | composited ≥ 3:1 on surface and card in both palettes (A56) | weight charts |

**No contract, DB or writer change.** Data flow stays one-way: providers → presentation. The only application-layer changes are outcome types carrying `FoodNames` (D10), `DayLayout.summaryFoods`, `PendingScan.nameAr`, `SettingsActions` coalescing (D22), the search controller's `resultsQuery` (D23), measurement drafts per type (A68) and `pendingProposalCountProvider` (D9). Module boundaries: `today` imports only the `body`, `workouts`, `buddy` and `settings` barrels. Strings go in `lib/l10n/app_en.arb` (then `flutter gen-l10n`); DS-intrinsic strings go in the DS ARB. Layout stays directional (`EdgeInsetsDirectional`, `AlignmentDirectional`).

**New or changed ARB keys** (en): `todayBuddyWaiting` (plural), `todayBuddyWaitingSemantics`, `todayGlanceWeigh` "Weigh in", `todayGlanceWeight` "{weight} · {rate}", `todayGlanceWeightStale` "{weight} · {day}", `todayGlanceWorkoutDone` "{title} done", `todayGlanceWorkoutPlanned` "{name} today", `todayGlanceWorkoutLog` "Log workout", `todayGlanceUnavailable`, `foodSheetKcalPending`, `foodSheetMacrosPending`, `searchSearching` (semantics), `workoutSetCheck`, `targetsDayChanged`, `newMessages` ("New message" pill, A67), `scanSavedAsYours` / `scanDataFromOff` (A50), `signInSending` / `signInVerifying` (A79), `quietFromTitle` / `quietUntilTitle` (A73; reuse the existing "Quiet from" / "Quiet until" strings if present), and error/retry keys for A42–A49 (reuse `foodTryAgain` / `*LoadFailed` where they exist). Removed keys: see D7.

### Work packages (one `flutter-engineer`, Opus; one local commit per WP; no pushes)
Before every commit: codegen if touched (`dart run build_runner build --delete-conflicting-outputs`, `flutter gen-l10n`), `make check-dart`, focused tests through `timeout 600 tools/scripts/heavy.sh flutter test <files>`, `git grep` of every changed or removed string and key in `patrol_test/`, `integration_test/` and `test/`, then the `cross-check` skill.

- **WP1 Spec and decisions** (docs). Files: `spec/decisions.md` (D-093, D-094, D-095 per D27), `spec/16-insights-and-home.md` (status line, the diagram, HM-004/005/006/009), `spec/10-ai-assistant.md` (AI-045), `spec/12-diary-meals-recipes.md` (DY-025), `spec/18-localization-and-culture.md` (LC-007), `spec/30-ux-principles.md` (UX-045/046), `spec/13-targets-and-goals.md` (TG-043 wording). Done when: `make trace` runs clean, with no new missing IDs beyond UX-045/046, which the WP tests tag.
- **WP2 Design-system foundations.** Items: A02 (DS part), A04, A56, A60. D12, D14–D17, D9's `badge`, `FbSkeleton.row`, `normalizeDigits`, the chart `rawPoint` token. Files: as in the DS table above, plus DS tests `test/components/{number_field,text_field,code_boxes,number_slot,reveal,input_bar,macro_bars}_test.dart`, `test/tokens/{tokens,contrast}_test.dart`. Done when: the DS tests pass, and the app still compiles (fields keep `hint`; `supportingText` defaults to null, so app forms just gain the reserved line).
- **WP3 Today top (T) + Buddy count (R2).** Items: T, A09, A10, A28, A58, A62, A75.
  - Build `TodaySummaryCard`, `TodayGlanceLine`, `WeightGlance`, `WorkoutGlance`, `pendingProposalCountProvider`, `showBuddySheet(revealPending:)`, `FbSizeFade` around the notes.
  - Do D7's deletions and D8's move (`progress/presentation/weight_section.dart`).
  - Rewrite the tests: `test/features/today/presentation/{today_screen,today_navigation,today_weight,today_numbers,today_targets_journey}_test.dart`, the new `today_summary_card_test.dart` and `today_glance_line_test.dart`, `test/features/body/presentation/weight_card_test.dart`, the `progress` weight-section test, the new `test/features/buddy/application/pending_proposals_test.dart`, and `test/acceptance/{support/acceptance_app.dart,accessibility_sweep_test.dart,offline_of01_test.dart,query_plan_audit_test.dart}`, `test/helpers/pump_app.dart`, `today_support.dart`.
  - Regenerate goldens: `today_golden_test`, `today_targets_golden_test`, `app_shell_golden_test`, `progress_golden_test`.
  - Done when: those pass, and `git grep -n "Slide\|slide-dot\|today-weigh-in\|workout-today-row"` finds nothing outside history.
- **WP4 Stable forms, numbers and sheets.** Items: A01, A02 (apply), A03, A06, A11, A12, A13, A14, A15, A65, A72, A73, A74, A79.
  - A01: dashes (D13), `food_sheet.dart:447`, `diary/presentation/entry_amount_sheet.dart:178`.
  - A02: every `FbNumberField`/`FbTextField`/`FbCodeBoxes` user (18 files): pass `supportingText` where a hint exists; `supportingLines: 0` for dense inline fields (set row, weight-history rows, proposal line pad).
  - A03: `diary/presentation/entry_row.dart:85` → `FbNumberSlot`.
  - A06: `personal_food_form_screen.dart:565`: one reserved validation region, updated on blur or submit.
  - A11: `account/presentation/account_section.dart:25`, `me/presentation/me_screen.dart:179`: card- and row-shaped skeletons instead of `SizedBox.shrink`.
  - A12: `settings/presentation/export_sheet.dart:57`: reserved status region, fixed primary/secondary action slots.
  - A13: `notifications/presentation/notification_settings_screen.dart:24/55/99`: wait for persisted prefs (skeleton rows), reserved subtitle lines, `FbReveal` for section reveals.
  - A14: `ramadan/presentation/ramadan_screen.dart:47/161/265`: row skeletons, `FbReveal` for the mode rows, prayer-time loading / error / unavailable states.
  - A15: `body/presentation/weight_history_screen.dart:393`: a reserved validation line per row; the Keep/Use-unit actions move into the row's reserved line.
  - A65: `food_sheet.dart:314`: Add goes into `FbSheet.actions` (pinned).
  - A72: `foods/application/food_search_row.dart:50`: `NotComputed` → `null` → "—".
  - A73/A74: `notification_settings_screen.dart:168/185`: a titled time-picker wrapper plus one shared `deviceTimeFormat(context)` (`core/l10n/time_format.dart`), also used by `weigh_in_sheet.dart:584`.
  - A79: `account/presentation/sign_in_screen.dart:139`: the button keeps its bounds, shows "Sending code…" / "Verifying…" with a progress glyph, `Semantics(liveRegion)`; cancellation is unchanged.
  - Tests: the stability tests T-S1–S7. Goldens: `food_sheet`, `personal_foods`, `targets_screens`, `setup`, `account`, `settings`, `weigh_in_sheet` (regenerated, each looked at).
- **WP5 Food names everywhere.** Items: A30–A40, A50.
  - D10 plumbing (domain `DayLayout.summaryFoods` + `packages/fb_domain` tests; outcome types; `PendingScan.nameAr`).
  - Surfaces:
    - A30: `diary/presentation/slot_header_row.dart:53`;
    - A31: `quick_add_model.dart:31`;
    - A32: `entry_amount_sheet.dart:20`, `nutrient_override_sheet.dart:98`;
    - A33: `entry_actions.dart:29`, `move_entry_sheet.dart:70`, `entry_amount_sheet.dart:88`;
    - A34: `buddy/presentation/cards/proposal_line_row.dart:140`, `food_proposal_card.dart:301`;
    - A35: `food_card_view.dart:168`, `buddy_thread_controller.dart:386`;
    - A36: `food_search_screen.dart:126`, `food_sheet.dart:274`;
    - A37: `barcode/barcode_scan_screen.dart:115/316`;
    - A38: `personal_foods/merge_food_sheet.dart:72/194`;
    - A39: `log_food.dart:106`, `food_sheet_entry.dart:73`, `quick_add_controller.dart:102`, the merge feedback;
    - A40: `isolateName` at `food_search_screen.dart:222`, `barcode_scan_screen.dart:297` and every embedded name or query; standalone Arabic titles get `textDirection` from their first strong character;
    - A50: `foods/application/food_choice.dart:323` + `barcode/scanned_product_header.dart:53`: "Saved as your food" and "Data from Open Food Facts" on separate lines.
  - Tests: T-N1–N4.
- **WP6 Buddy sheet: anchored, lazy, and following only when wanted.** Items: A07, A08, A66, A67, A77.
  - A07: `food_proposal_card.dart:79`, `packages/fb_design_system/lib/src/components/proposal_card.dart:106`: questions, reasons and removed items in `FbSizeFade`, resolution swap through `FbSizeFade`; the volatile editing feedback gets a reserved line.
  - A08: `buddy_sheet.dart:201`: the follow-up chip reveals (`FbReveal`) in a slot directly above the composer; the composer's position doesn't change.
  - A77: `message_list.dart:76/90`: `ListView.builder` with keyed turns; following moves out of `build` into a `ref.listen` on the thread.
  - A67: follow only when within 48 dp of the bottom; otherwise show a "New message" pill (key `buddy-new-messages`) that jumps there.
  - A66: on reopen with an in-memory thread, jump to the latest turn (or to the pending card when `revealPending`).
  - Tests: T-B1–B4. Golden: `food_card_golden_test`.
- **WP7 Recovery and unfinished work.** Items: A41, A42, A43, A44, A45, A46, A47, A48, A49, A63, A64, A68, A69, A70, A71.
  - A41: D23.
  - A42: `workouts/presentation/{workouts_screen:63,exercise_screen:61,custom_exercise_screen:108,template_editor_screen:115}`: skeleton / error+retry / empty.
  - A43: `workout_history_screen.dart:18`: an explicit `AsyncValue` switch.
  - A44: `weekly_plan_screen.dart:35`: loading/error, editing enabled only with data.
  - A45: `workout_log_screen.dart:369`: not-found vs failed load (retry, draft kept).
  - A46: `body/presentation/measurement_sheet.dart:193/242`: keep the `AsyncValue`; error + retry.
  - A47: `onboarding/presentation/setup_screen.dart:38`: loading vs failure, retry keeps the draft.
  - A48: `adaptive/presentation/adaptive_cards.dart:59/301/353`: calm error + retry; "Change back" never disappears.
  - A49: `sync/presentation/earlier_versions_sheet.dart:39`: `FbSkeleton.row`s + retry (+ Sign in when signed out).
  - A63: `barcode_scan_screen.dart:165`: `await` the form route, then resume the camera if the scanner is still mounted and active.
  - A64: `barcode_scan_screen.dart:182/365`: `viewInsets` padding around the whole manual form and its footer.
  - A68: `body/application/measurement_form.dart:99`: drafts kept per type; `withType` restores that type's draft.
  - A69: `weight_history_screen.dart:377`: removing a populated row offers a local Undo snackbar.
  - A70: `merge_food_sheet.dart:20`: the confirm step gets "Choose a different food", which returns to the picker.
  - A71: D22.
  - Tests: T-R1–R8. Golden: `food_search_golden_test`, `workouts_golden_test`.
- **WP8 Motion sweep.** Items: A16, A17, A18, A19, A20, A21, A22, A23, A24, A26, A27, A29, A80.
  - A16/A17: D18 in `today/presentation/day_page.dart`.
  - A18: `food_sheet.dart:532` `FbReveal`; More/Less stays anchored above.
  - A19: the amount pads in `food_sheet.dart:314`, `entry_amount_sheet.dart:202`, `proposal_line_row.dart:95` in `FbReveal`; actions stay pinned.
  - A20: `weigh_in_sheet.dart:417`: `FbSizeFade` for the note/keypad/confirmation swaps; amount and footer stay anchored.
  - A21/A22: `exercise_log_card.dart:158/159`, `personal_food_form_sections.dart:554`, `weight_history_screen.dart:257`: keyed `FbReveal.entering` insertions and timed exits; focus moves to the new row's first field.
  - A23: `progress/presentation/calories_section.dart:70` `FbReveal`.
  - A24: `packages/fb_design_system/lib/src/charts/bar_chart.dart:158`: value tween over `structuralOf` when the bar dates match, a 200 ms fade-through when the period changes.
  - A26: `setup_screen.dart:264`, `sign_in_screen.dart:114`: keyed shared-axis (`FadeTransition` + 8 % slide), `structuralOf`; focus goes to the heading and scroll resets.
  - A27: D19.
  - A29: `onboarding/presentation/pages/plan_page.dart:121` `FbReveal`; `workouts/presentation/plan_setup_screen.dart:234` uses `animateTo` only when `localOf > 0`, else `index =`.
  - A80: D24.
  - Every new animation reads `FbMotion`, and the `normal`/`slow` aliases are removed once unused.
  - Tests: T-M1–M4.
- **WP9 Dense and accessible.** Items: A05, A25, A51, A52, A53, A54, A55, A57, A59, A61, A76, A78.
  - A05/A51: D20.
  - A52/A57/A25: D21.
  - A53: `progress/presentation/macros_section.dart:52`: one column when the plotting width at the current scale is < 140 dp.
  - A54: `exercise_screen.dart:226`: PR tiles stack below 360 dp or scale ≥ 1.3.
  - A55: `packages/.../big_number.dart:86`: scale up to 2.0, with a floor on the fitted size (≥ the 1.0-scale headline size); the caption wraps to a second line.
  - A59: `account/presentation/account_busy_scope.dart:24`: `BlockSemantics` + `ExcludeSemantics` on the background, plus a `liveRegion` status.
  - A61: `packages/.../amount_display.dart:43`: `Focus` + `onKeyEvent` maps digits (incl. Arabic), the decimal separator, Backspace and Enter to the pad callbacks.
  - A76: `personal_foods/personal_foods_screen.dart:76`: `ListView.builder` with `ValueKey(food.id)`.
  - A78: `weight_history_screen.dart:147`: batch validation derived in the form controller when a draft changes, not in `build`.
  - Tests: T-A1–A7. Goldens: `targets_screens`, `workouts_golden_test`, `progress_golden_test`.
- **WP10 Nightly Patrol suite, sweep and close.** Items: the three failing nightly tests plus every Patrol finder this step changes.
  - **P1 `patrol_test/app_test.dart:88`** (Progress expects 'Charts appear after', finds 0).
    - First reproduce on the host: an acceptance test (`test/acceptance/progress_fresh_install_test.dart`, `acceptance_app.dart` with a fresh profile, offline) opens Progress and checks whether `FbBarChart` takes its empty branch (`bar_chart.dart:137`).
    - Likely causes: (a) on a fresh install the calories bars aren't all "empty" (e.g. today's in-progress bar carries `value: 0` or a target), so the chart paints axes and no empty state. That's a **screen bug** (UX-050): fix `caloriesBars` so that days with no entries and no target are placeholders, and keep the assertion. Or (b) the card is below the `ListView` build extent on the emulator: the test scrolls to `ValueKey('progress-calories-chart')`.
    - Either way the assertion moves to the key + the empty branch's semantics label, not to copy.
  - **P2 `patrol_test/offline_test.dart:163`** (no `SlotHeaderTile` for `slot` after the chip logs).
    - Likely cause: the day page's `SliverList.builder` builds rows lazily. Since A56's ~304 dp header the meal row sits beyond the viewport plus cache on the emulator, so the element doesn't exist and `tapExactly`'s `ensureVisible` fails.
    - Also check that `section.key` still equals the slot ID after A53/A54.
    - Fix: scope the finder to today's `dayPage(today)`, then `scrollUntilVisible` on that page's vertical `Scrollable` before `tapExactly`. The fix must not depend on T's smaller header.
  - **P3 `patrol_test/weigh_in_test.dart:81`** and the twin at **`offline_test.dart:~201`** (both tap `fb-slide-dot-1`): retarget to `ValueKey('today-glance-weight')`. The "invite" check (`'Log your first weigh-in'`) becomes the glance's empty state via key. The tap count stays ≤ 3 (UX-005): glance → pad → Save.
  - Copy greps (`git grep` in `patrol_test/`, `integration_test/`) for every string WP3–WP9 changed. The known users are in Risks R9.
  - `integration_test/jank_benchmark_test.dart`: the day-swipe origin can return to the page centre (no card exception).
  - Then `make trace`, `make progress` if the board changed, the cross-check, this card's Progress log and Outcome, and the device checklist below.
  - Proof: the orchestrator runs a manual CI run with `android-it` (commit tag `[it]`) on the branch before `merge-step.sh`.

### Coverage (every item exactly once)

| Item | WP | How |
|---|---|---|
| T | WP3 | one calories card + slim glance line, slides deleted (D2–D8) |
| A01 | WP4 | both nutrition lines kept, dashes (D13) |
| A02 | WP2 + WP4 | reserved supporting line in the DS (D12), applied to every form |
| A03 | WP4 | diary kcal in `FbNumberSlot` |
| A04 | WP2 | macro mode from width, scale and a sample (D15) |
| A05 | WP9 | PR status slot / reserved line (D20) |
| A06 | WP4 | stable validation region in the personal-food form |
| A07 | WP6 | `FbSizeFade` for proposal states, reserved feedback |
| A08 | WP6 | follow-up chip slot above an anchored composer |
| A09 | WP3 | Today notes in one `FbSizeFade` |
| A10 | WP3 | skeleton matches the result, setup slot reserved |
| A11 | WP4 | Me/account placeholders |
| A12 | WP4 | export status region and fixed action slots |
| A13 | WP4 | notification settings wait, reserve, reveal |
| A14 | WP4 | Ramadan row skeletons, reveal, prayer-time states |
| A15 | WP4 | weight-history row validation reserved |
| A16 | WP8 | meal expansion (D18) |
| A17 | WP8 | group and entry disclosure (D18) |
| A18 | WP8 | optional nutrients `FbReveal` |
| A19 | WP8 | amount pads `FbReveal`, pinned actions |
| A20 | WP8 | weigh-in mode swaps `FbSizeFade` |
| A21 | WP8 | workout card collapse `FbReveal` |
| A22 | WP8 | keyed list insert and remove |
| A23 | WP8 | chart detail reveal |
| A24 | WP8 | bar tween / period fade-through |
| A25 | WP9 | targets numbers tween + highlight (rows, D21) |
| A26 | WP8 | setup and sign-in step transitions |
| A27 | WP8 | tab fade-through (D19; fallback backlog) |
| A28 | WP3 | resolved by removal: slide dots deleted (T) |
| A29 | WP8 | plan explanation reveal, reduced-motion tab change |
| A30 | WP5 | meal previews resolve `summaryFoods` |
| A31 | WP5 | chips main name, both in semantics (N2) |
| A32 | WP5 | edit-sheet titles inline name |
| A33 | WP5 | diary feedback inline names |
| A34 | WP5 | Buddy rows, swap and amount labels |
| A35 | WP5 | Buddy explanations, `RemovedLine` names |
| A36 | WP5 | "Replacing…" / "Log as…" names |
| A37 | WP5 | pending scans keep `nameAr` |
| A38 | WP5 | merge picker and confirmation names |
| A39 | WP5 | outcomes carry `FoodNames` |
| A40 | WP5 | `isolateName` at every embed; paragraph direction |
| A41 | WP7 | stale results fade, not tappable (R1, D23) |
| A42 | WP7 | workout screens: skeleton / error / empty |
| A43 | WP7 | history failure vs none |
| A44 | WP7 | weekly plan loading/error, no invented rests |
| A45 | WP7 | session not-found vs read error |
| A46 | WP7 | measurement error + retry |
| A47 | WP7 | setup failure + retry |
| A48 | WP7 | adaptive cards error + retry |
| A49 | WP7 | earlier versions skeleton + retry |
| A50 | WP5 | "saved as your food" vs "data from Open Food Facts" |
| A51 | WP9 | responsive set row (C1, D20) |
| A52 | WP9 | 7-row day list, 48 dp (C2, D21) |
| A53 | WP9 | macro charts stack at large text |
| A54 | WP9 | PR tiles stack |
| A55 | WP9 | hero number scaling floor |
| A56 | WP2 | raw-point token ≥ 3:1 + contrast test |
| A57 | WP9 | resolved by removal: bars replaced by rows (C2) |
| A58 | WP3 | resolved by removal: slide dots deleted (T) |
| A59 | WP9 | busy scope blocks background semantics |
| A60 | WP2 | code boxes accept Arabic digits |
| A61 | WP9 | keyboard entry for amount pads |
| A62 | WP3 | "n waiting" on the Buddy bar (R2, D9) |
| A63 | WP7 | camera resumes after manual creation |
| A64 | WP7 | manual barcode form above the keyboard |
| A65 | WP4 | food-sheet Add pinned |
| A66 | WP6 | reopen at the latest turn |
| A67 | WP6 | follow only near the bottom + "New message" |
| A68 | WP7 | measurement drafts per type |
| A69 | WP7 | Undo for a removed filled row |
| A70 | WP7 | "Choose a different food" in merge |
| A71 | WP7 | latest-intent settings writes (D22) |
| A72 | WP4 | "—" for uncomputed search previews |
| A73 | WP4 | titled quiet-hour pickers |
| A74 | WP4 | one device-aware time format |
| A75 | WP3 | resolved by removal (`workoutSlideLast` deleted); WP3 greps for other `{n} days ago` strings and makes them ICU plural |
| A76 | WP9 | Your Foods lazy builder |
| A77 | WP6 | Buddy turns lazy, follow in a listener |
| A78 | WP9 | weight-history validation off `build` |
| A79 | WP4 | sign-in busy labels, same bounds |
| A80 | WP8 | one success haptic (D24) |

Deferred: none. A27 has a stated fallback (D19).

### Test list
Shared helper `test/helpers/layout_stability.dart`:
- `expectStableSize(tester, finder, act, {scales: [1.0, 1.3, 2.0]})` pumps the widget at each text scale, measures the target box (and optionally an anchor's global top) before and after `act`, and expects equal sizes.
- `expectStableTop(tester, finder, act)` does the same for an anchor's global top.
- DS tests use a local twin in `packages/fb_design_system/test/helpers/`.

Stability (S):
- T-S1 `food sheet keeps its height when the amount is cleared, grown and set to 0` (A01, S1, UX-045): 150 → 1500 → empty → 0 at 1.0/1.3/2.0; the Add button's top doesn't move; the incomplete state shows the pending key, and zero shows a real number (by key, not copy).
- T-S2 `entry amount sheet keeps its height when the amount is cleared` (A01).
- T-S3 `FbNumberField/FbTextField/FbCodeBoxes keep their height when an error appears and wraps` (A02, S2): error on/off, long error, three scales.
- T-S4 `forms don't move on validation`: personal-food form (A06), targets own number, measurement sheet, sign-in code (A02 applied). One test each; the field below the error keeps its top.
- T-S5 `diary rows cut the name at the same width for 85 and 1,240 kcal` (A03).
- T-S6 `FbMacroBars mode doesn't change when a value gains a digit` (A04).
- T-S7 `weight-history row keeps later rows still when a value crosses validation` (A15); `export sheet actions keep their positions across states` (A12); `sign-in buttons keep their bounds while busy` (A79).

Today (T):
- T-T1 `Today has one calories card and no pager` (HM-001–003, T): no `PageView` inside `DayPage`.
- T-T2 `a swipe starting on the card changes the day` (HM-009).
- T-T3 `glance line height is equal in every state`: loading, error, no weigh-ins, trend, stale, logged, planned, none, past day; at 1.0/1.3/2.0 (stacked at ≥ 1.5, equal across states).
- T-T4 `weight glance logs on the viewed day in two taps` (WB-001, UX-005), today and a past day.
- T-T5 `workout glance`: logged opens the session; planned opens the template log; none/last/past opens a free session on that date; never a "missed" state (HM-006, WO-021).
- T-T6 `weight tip and sparse note show on Progress, the tip marked shown once` (WB-012, D8).
- T-T7 `Today header reads no weight or workout provider before first frame work`: the existing laziness test is reworked; the glance watches its providers only inside its halves.

Buddy (R2, B):
- T-B1 `pending count streams the number of pending proposals; 0 hides the badge` (AI-045, R2).
- T-B2 `tapping the bar with pending opens Buddy at the oldest open card` (HM-004 amended).
- T-B3 `message list doesn't follow while the reader is up; New message jumps down` (A67); `reopen shows the latest turn` (A66).
- T-B4 `follow-up chip reveal doesn't move the composer` (A08, `expectStableTop`).

Names (N):
- T-N1 `inline name follows the setting`: a matrix over the four settings × {both names, no Arabic, user-typed group name} for `watchFoodNameInline` and `foodNameSpoken` (LC-007, N1).
- T-N2 `name sweep`: one food (en + ar) through meal preview, quick-add chip semantics, edit-sheet title, delete/move/amount snackbars, the Buddy row and removed-line text, the pending scan row, the merge confirmation and the log snackbar, in the **Arabic** setting. Each surface's text contains the Arabic name and not the English one (names are data, not UI copy). Plus **Both** for rows (two lines) and sentences (English only).
- T-N3 `PendingScan JSON round-trips nameAr and reads old entries without it` (A37).
- T-N4 `isolateName wraps embedded RTL names in search queries and scan names` (A40).

Recovery (R):
- T-R1 `stale search results are faded, ignore taps and are excluded from semantics; the progress slot is always reserved` (A41, R1).
- T-R2 `workouts / exercise / custom exercise / template editor show error + retry on a provider error, skeleton while loading` (A42).
- T-R3 `workout history error isn't "no workouts"` (A43); `weekly plan loading isn't all rest` (A44); `session read error isn't "gone"` (A45).
- T-R4 `measurement sheet error + retry` (A46); `setup error + retry keeps answers` (A47); `adaptive card error keeps Change back` (A48); `earlier versions retry` (A49).
- T-R5 `scanner resumes after the manual form returns` (A63, fake scanner controller).
- T-R6 `measurement draft survives a type switch and back` (A68).
- T-R7 `removing a filled history row offers Undo and restores it` (A69); `merge confirm can go back to the picker` (A70).
- T-R8 `rapid setting changes: the last value wins, nothing is dropped, each write has an undo entry` (A71, D22), a unit test on `SettingsActions` with a delayed store.

Motion (M):
- T-M1 `FbMotion durations are zero under disableAnimations` (UX-046): `localOf`, `structuralOf`, `FbReveal`, `FbSizeFade`, bar tween, tab fade.
- T-M2 `meal expansion animates and the tapped header doesn't move` (A16/A17): mid-animation the header's top is unchanged; the exiting rows are gone after `localOf`.
- T-M3 `tab switch keeps each branch's state with the fade-through` (A27): scroll position and route stack per tab survive.
- T-M4 `reduced motion: plan setup changes tab without animateTo` (A29).

Accessibility (A):
- T-A1 `set row at 320 dp and 2.0 text: last time above the inputs, PR line reserved, checkbox on screen` (A51, C1); `normal row keeps input widths when PR appears` (A05).
- T-A2 `targets day list: 7 rows ≥ 48 dp, full names, changed rows not marked by colour alone` (A52, C2).
- T-A3 `contrast`: composited raw weigh-in point on `surface` and card surfaces ≥ 3:1 in light and dark (A56). Also the input-bar badge text ≥ 4.5:1 and the changed-day row tint keeps text ≥ 4.5:1 (UX-071). Added to `packages/fb_design_system/test/tokens/contrast_test.dart` through `fbContrastPairs`, with alpha compositing.
- T-A4 `code boxes accept Arabic-Indic and Persian digits, typed and pasted` (A60).
- T-A5 `account busy scope hides background semantics` (A59); `amount display takes keyboard digits` (A61).
- T-A6 `macro charts stack, PR tiles stack, big number not below the floor at 2.0` (A53–A55).
- T-A7 `accessibility sweep` (existing `test/acceptance/accessibility_sweep_test.dart`) stays green with the new Today and targets scenes (48 dp, labels, 2.0 text).

Patrol (P, run only in CI `android-it`): `app_test` (four-tab walk), `offline_test` (OF-01), `weigh_in_test` (A14), with P1–P3 fixed as in WP10.

### Exit-criteria mapping
1. T → T-T1–T-T5, regenerated `today_golden_test`, `weigh_in_test` (Patrol).
2. R2 → T-B1, T-B2.
3. No movement → T-S1–S7, T-T3, T-B4, T-A1, T-M2.
4. Names → T-N1–N4.
5. Recovery → T-R1–R8.
6. Motion → T-M1–M4, plus the `FbMotion` grep: no raw `Duration(milliseconds:` in the changed presentation files.
7. Contrast, targets, text → T-A1–A7.
8. Coverage → the table above, checked by Codex.
9. Nightly → the manual `[it]` CI run with `android-it` green on the branch head, recorded in the Progress log.

### Risks and unknowns
1. **Reserved line grows every form** (S2). Every form with a field gets one caption line taller, so goldens churn in `setup`, `account`, `targets_screens`, `personal_foods`, `food_sheet`, `weigh_in_sheet` and `settings`. Dense inline fields must opt out (`supportingLines: 0`); WP4 audits all 18 files. Regenerate only failing goldens and look at each image.
2. **Sliver exit rows (D18)** interact with `findChildIndexCallback` and row keys. A mis-keyed exiting row could hand state to a neighbour. T-M2 checks it, and `_ExitingRow` keys are `exit:<key>`. Patrol taps mid-animation are covered by `tapExactly`'s retries.
3. **Tab fade-through (D19)** replaces `indexedStack`. It risks deep links, `ScrollToTopOnTabReselect` and `app_tabs_test`. Fallback: backlog A27 with the reason.
4. **Name plumbing** changes outcome types across five features. It's compile-driven, with no DB change. `PendingScan` JSON stays backward compatible (T-N3).
5. **A71 coalescing** is the only write-adjacent logic. It uses the same store path, and Codex is asked to check it (D1).
6. **Patrol root causes are hypotheses.** The emulator can't run on the 7 GB box. P1 is reproduced on the host first; P2 is fixed by scrolling, whatever the cause. Budget one extra `[it]` CI round. A test that still fails twice without a real bug is rewritten (TD-104).
7. **Glance weight number**: the trend (WB-011) vs the raw latest weigh-in, which the owner said "latest value". **Ask** (rec: trend; it matches the old slim row and WB-011).
8. **Bar-chart tween (A24)** must keep hit-testing and semantics on final values: draw the tweened values, describe the final ones.
9. **UI copy used by Patrol and integration tests** (grep before each commit):
   - `'Log your first weigh-in'` (`weigh_in_test`: retargeted to a key);
   - `'Charts appear after'` (`app_test`: P1);
   - `'Your workouts will show up'` (`app_test`: A42/A43 keep this empty-state copy);
   - `'Added Pita bread, white to '` (`food_search_add_test`: English names; `isolateName` wraps only RTL text, so it's unchanged; confirm);
   - `'Logged '`, `'Log it'`, `'Any cooking oil?'`, `'Cooked'` (`buddy_journeys_test`: A07 must keep the texts);
   - `'Save 101.0 kg'`, `"That's +3.6 kg"`, `'Weigh-in saved: 97.4 kg'` (`offline_test`, `weigh_in_test`: A20 keeps the copy);
   - `'Continue with email'`, `'Check your email'`, `"You're signed in"`, `'Sign in'` (`account_sign_in_test`: A79 changes the labels only while busy; the test waits for the next screen);
   - `'Offline oats'` chips and rows (`offline_test`: N2 keeps the English main name);
   - `'Amount'`, `'Add'`, `'Search foods'` (`food_search_add_test`: A65 keeps "Add").
   - Patrol files this step edits: `app_test.dart`, `offline_test.dart`, `weigh_in_test.dart`. Files it checks but shouldn't need to edit: `food_search_add_test.dart`, `buddy_journeys_test.dart`, `account_sign_in_test.dart`, `session_storage_test.dart`. Integration: `jank_benchmark_test.dart` (origin comment), `progress_benchmark_test.dart` (check).
10. **Context size.** 80 items is a lot for one agent. If the engineer's context gets large, a fresh `flutter-engineer` takes over at a WP boundary on the same branch (TD-095), resuming from the Progress log.

### Size check
**XL: 4–6 sessions including one fix round** (WP1 0.1, WP2 0.5, WP3 0.7, WP4 0.7, WP5 0.6, WP6 0.4, WP7 0.7, WP8 0.6, WP9 0.5, WP10 0.3, plus a review fix round 0.5–1). That's above L. The owner chose one step, so it stays **one branch, one review, one merge**. If a split is ever needed, the natural seam is after WP5: **A57a** = WP1–WP5 (spec, DS, Today, stable forms, names: the daily-use wins) and **A57b** = WP6–WP10.

### Owner device checklist (A55, after merge; optional, D-087)
1. Today: the calories card and the slim line; swipe days starting on the card; tap weight → pad → Save; tap the workout part on a plan day, a done day and a free day; a past day.
2. Large text (Settings › Display › Font size max): the Today line stacks; set rows show "last time" above the inputs; Targets day list; Progress macro charts; PR tiles; the big number.
3. Food sheet: type 150, 1500, clear, 0. Nothing jumps; Add stays under the thumb with a long scanned product.
4. Forms: wrong values in the food form, Targets own number, measurement, sign-in code (also Arabic digits). Nothing moves.
5. Names: set Food names to Arabic, then Both, and log, edit, move and delete a food; Buddy card; barcode pending scan; merge duplicates. Check punctuation with Arabic names.
6. Search: type fast. Old results fade and can't be tapped.
7. Barcode: add a food by hand from the scanner, and the camera comes back; type a code by hand on the short screen.
8. Buddy: leave a card unconfirmed, close Buddy, and Today's bar says "1 waiting"; tap it; scroll up during a reply.
9. Motion: open and close meals, the food "More", amount pads, workout cards, tab switches; then turn on "Remove animations" and repeat (everything instant).
10. TalkBack: sign-in while busy; the Today line; the Targets day list; weigh-in chart dots in sunlight.
11. Haptic: one light tick on a direct log and on a weigh-in save; none while typing.
12. Settings: flip a toggle quickly several times; it ends where you left it.
13. Arabic names used as standalone sheet titles look right (isolateName, A40).
14. Patrol P1 (`patrol_test/app_test.dart`, Progress check): proven by a manual CI run with `android-it` or the next nightly.

## Outcome
_Claude, 2026-11-05. Tier Normal, one `flutter-engineer` (Opus), 10 WPs, one local commit per WP, one combined Codex review plus one fix-check. Planned XL (4-6 sessions incl. one fix round)._

**What was built**
- **WP1 spec + decisions**: D-093 (supersedes D-092), D-094, D-095; spec amendments HM-004/005/006/009, AI-045, DY-025, LC-007, TG-043; new UX-045/046; TD-113.
- **WP2 design system**: reserved supporting line on fields, `FbNumberSlot`, `FbReveal`/`FbSizeFade`, one motion vocabulary (`FbMotion` local/structural, M3 easing), `FbInputBar.badge`, `FbSkeleton.row`, `normalizeDigits` (code boxes take Arabic digits).
- **WP3 Today top (T)**: `TodaySummaryCard` + slim `TodayGlanceLine` (weight | workout, stacks at >= 1.5 text scale), Buddy "waiting" count on the input bar; A56 slides, sparkline and weight-graph route deleted; Patrol P2/P3 retargeted.
- **WP4 stable forms**: shared nutrition summary with reserved line heights, instruction hints as supporting text, number slots in entry/meal rows, note snapshot on blur/save, export fixed slots, busy buttons, 12h/24h time pickers.
- **WP5 food names everywhere**: `DayLayout.summaryFoods`, name helpers (inline, spoken, undo args), Both-mode secondary names on proposal lines, pending-scan Arabic name, A50 scan lines.
- **WP6 Buddy sheet**: lazy keyed message list, follow only at the bottom or after a send + "New message", reopen at the latest turn, reserved reason line on the food card.
- **WP7 recovery**: latest-intent settings (`SettingsQueued`), stale search rows + progress line, shared `LoadFailedView`/`LoadingRows`, session-gone vs read failure, calm retries on adaptive cards, versions list states, type-code sheet with pinned Look up, drafts per type, local Undo in weight history.
- **WP8 motion**: disclosure motion in the diary, food "More", pads, weigh-in, card collapse, day details, bar chart tween, step transitions, fade-through tab branches, plan reveal, success haptic.
- **WP9 dense screens**: compact set row, Targets day list (`FbWeekBars` removed), stacked macro charts and PR tiles at large text, `FbBigNumber` to 2.0, busy-scope semantics, tappable amount display.
- **WP10**: Patrol P1 fixed in the test (scrolls to `progress-calories-chart`); host reproduction `progress_fresh_install_test.dart`; `make trace` clean.
- **Review fixes (6)**: `RevealedColumn` finished exits dropped; weight-history rows own their controller; `FbInert` on leaving states and hidden reveals; stale search stays unpickable after a failed newer search; `_RowLine` stacks answers on a reserved line at narrow/large text; period-switch and quick-add chip switchers use `FbInert.switcherLayout`.

**Deviations (all logged in the Progress log)**
- `FbSizeFade` returns the child directly under reduced motion (AnimatedSize cannot run at zero duration); new DS `FbGlanceTile` (one fixed height for both halves).
- `TodayRig`/`fakeToday` override `pendingProposalCountProvider`; T-T7 not a separate test.
- Standalone Arabic titles are FSI-isolated rather than given an explicit `textDirection` (device check, A40); undo-label args for diary entries still carry English (nothing renders them).
- Step transitions drop the old step at once and fade the new one in (a cross-fade put two text fields on screen and broke `enterText`).
- Newest queued settings caller gets the write's outcome; superseded callers get `SettingsQueued`.
- D20 "narrow" = screen width < 360 dp or text >= 1.3; A53 stacks at half width / text scale.
- T-S4 not separate for Targets number and measurement sheet; T-R4 not separate for measurement and setup; T-N2 split across several existing test files; T-M1/T-M3 covered by DS tokens and tab tests.
- Not fully done: A22 (no focus move to the new row; personal-food serving rows not animated), A26 (no focus move to the step heading), A63 (built, camera resume not automated). All in the backlog.

**Measurements**
| Item | Planned | Actual |
|---|---|---|
| Size | XL, 4-6 sessions incl. fix round | 10 WPs + 1 fix round, 23 commits; 238 files, +8673 / -4047 |
| Review rounds | 1 Codex review + fix-checks as needed | 1 review + 1 fix-check (verdict "fixes OK") |
| Findings | n/a | 0 blocker / 3 major / 3 minor, all fixed |

**Tests added**: layout stability helpers (DS and app); T-S3 DS stability; day_motion_test (T-M2), plan_screens_test T-M4; message_follow_test (T-B3 x2, T-B4), DS proposal_card reserved reason; today_names_test, quick_add_bar_test, card_adjust_test, merge_food_test, food_names_test, barcode_lookup_test (T-N1-N4); T-A1 workout_screens_test, T-A2 targets_screen_test, T-A3 contrast pair, T-A5 amount_display_test + account_busy_scope_test, T-A6 display_test + progress_screen_test; progress_fresh_install_test (acceptance); fix round: revealed_column_test, weight_history_screen_test, food_search_test, DS reveal_test, bar_chart_test. Tests for deleted features (slides, `FbWeekBars`) removed.

**Goldens changed**: food_card_with_estimate, food_search_results, targets_screen_weekly, today_empty_day, today_full_day, today_targets_under (plus app_shell, progress_screen, weight_graph_ranges, food_sheet_portion, personal_food_form_new, entry_amount_sheet in WP3/WP4, each checked).

**Not proven yet**: Patrol P1 is fixed in the test but has not run on the emulator; a manual CI run with `android-it` or the next nightly will prove it (backlog #287).

**Follow-ups**: backlog #281-#287 (plus the owner device checklist above).

**New decisions**: D-093, D-094, D-095 (spec/decisions.md); TD-113.

**Exit criteria**: all built and tested on the host; owner acceptance by use (TD-037).


## Progress log
- 2026-10-31: card and board rows written from the audit (orchestrator).
- 2026-11-05: combined into one step A57 (A57–A61 + T) by the owner; low-level plan written (planner).
- 2026-11-05: plan approved by the orchestrator (D-095 ok, trend weight on the line, TD-113 in WP1); card renamed A57-ux-polish.md; board rows A58–A61 folded into A57; build starts (one Opus flutter-engineer, WP1–WP10).
- 2026-11-05: WP1 done: D-093/D-094/D-095 + spec amendments (HM-004/005/006/009, AI-045, DY-025, LC-007, TG-043, UX-045/046), TD-113 recorded (engineer).
- 2026-11-05: WP2 done: DS FbSupportingLine (number/text/code fields), FbNumberSlot, FbReveal/FbSizeFade, FbMotion local/structural + M3 easing (normal/slow aliases replaced directly, 14 uses), FbInputBar.badge, FbSkeleton.row, normalizeDigits (code boxes take Arabic digits), macro sampleText, raw-point alpha 0.8 composited contrast pair (engineer). Deviation: FbSizeFade returns the child directly under reduced motion (AnimatedSize can't run at zero duration).
- 2026-11-05: WP3 done: TodaySummaryCard (FbCard + TodayNumbers) + TodayGlanceLine (WeightGlance | WorkoutGlance, stacks ≥1.5), pendingProposalCountProvider + FbInputBar badge + showBuddySheet(revealPending), slides/sparkline/TodayWeightGraphRoute deleted, weight notes + tip moved to Progress WeightSection, A09 notes FbSizeFade, A10 setup slot + mode crossfade; Patrol P3 (weigh_in_test, offline_test weight step) and P2 (offline_test scroll-to-meal scoped to today's page) done early because the files no longer compiled. Deviations: new DS FbGlanceTile (one fixed height for both halves); TodayRig/fakeToday override pendingProposalCountProvider (real stream left a drift timer); T-T7 not a separate test (halves watch their providers only inside themselves; startup_test unchanged and green). Goldens regenerated and checked: today_empty_day, today_full_day, today_targets_under, app_shell, progress_screen, weight_graph_ranges (raw points darker, A56). (engineer)
- 2026-11-05: handover after WP3 (engineer context large). Next: WP4. Notes for the next engineer: DS fields already reserve the supporting line (`supportingText`/`supportingLines`, 0 for dense inline fields); `FbNumberSlot`, `FbReveal`/`FbSizeFade` (instant under reduced motion), `FbSkeleton.row`, `FbGlanceTile` exist. A01: `foodSheetNoKcal` is '—' today; both nutrition lines live in food_sheet.dart `_Nutrition` and entry_amount_sheet.dart ~l.170 (a shared widget in core/ui fits; reserve the macro line's height with an invisible full-value sample so wrapping can't change it). A12 idea: always two fixed action slots (failed → primary Try again, secondary Close), status in FbSizeFade above the pinned buttons. A06 idea: snapshot the notes on focus change (FocusManager listener) and on save attempt. Test rigs: `fakeToday(waiting:)` and TodayRig override `pendingProposalCountProvider`; pump a `SizedBox` between ProviderScopes when changing overrides in one test. Patrol P2/P3 already done in WP3; P1 (app_test.dart:88) still open for WP10.
- 2026-11-05: WP4 done (1c46a785): shared `core/ui/nutrition_summary.dart` (A01 dashes, line heights reserved by an invisible sample: kcal "8,888", macros "888 g"; beyond ~1 kg of a macro the line may wrap once more), A02 instruction hints → `supportingText` (aliases, barcodes, barcode code, goal name, workout aliases, sign-in email/code notes; examples stay placeholders), set row + weight history `supportingLines: 0`, targets typed field 2 lines; A03 `FbNumberSlot` in entry rows, saved-meal rows and slot headers; A06 note snapshot on blur/save; A11 account/Me skeletons; A12 export fixed slots (Try again is now the primary button; idle shows Close as secondary); A13 notif wait/reveal/reserved line; A14 Ramadan skeleton rows, reveal, prayer-time loading/failed/none (2 new ARB keys); A15 `_RowLine` (48 dp or 2 lines); A65 `FoodSheet` builds its own `FbSheet` (opened with `showFbStatefulSheet`, key `FoodSheet.addKey`); A72; A73/A74 `core/l10n/time_format.dart` `deviceTimeFormat` + `showFbTimePicker(title:)`; A79 `FbButton.busy` + `signInSending`/`signInVerifying`. Fixed a WP2 bug: `FbSizeFade` squeezed the outgoing state (overflow). Deviations: T-S4 for targets own number and measurement sheet not separate tests (the DS T-S3 stability test covers the fields; personal food + sign-in code have app tests); removed ARB `foodSheetNoKcal`. Goldens regenerated and checked: food_sheet_portion, personal_food_form_new, food_search_results, entry_amount_sheet, today_empty_day, today_full_day, today_targets_under, app_shell, sign_in_email, sign_in_code. (engineer)
- 2026-11-05: handover after WP4 (engineer context large). Next: WP5 (names). Notes: `test/helpers/layout_stability.dart` (app twin of the DS helper: `expectStable`, `stabilityScales`); food-sheet tests that pump `FoodSheet` directly must not wrap it in `FbSheet` or a scroll view (it is its own sheet now); `FbSizeFade` keys each state's child; app-check flags string literals in `text:` even for measuring probes — use a `static const` field. Patrol P1 (app_test.dart:88) still open for WP10.
- 2026-11-05: WP5 done (0a99fc15): `DayLayout.summaryFoods` (only reader: slot header); `foodNameInline`/`watchFoodNameInline`/`readFoodNameInline`/`foodNameSpoken`/`foodNameArg` in `food_name_text.dart`; FoodNames in `FoodLogged`, `QuickAddLogged`, personal-food undo args (merge/save/delete messages), `RemovedLine`, `FoodChipView`/`FoodQuestionView`; `FbProposalLine.secondaryName` (Both); chips main name + spoken both; `PendingScan.nameAr` (`name_ar`); A50 lines `scanSavedAsYours` / `scanDataFromOff` (keys `scan-saved-as-yours`, `scan-data-from-off`; the © credit stays verbatim inside). Deviations: standalone Arabic titles are FSI-isolated (sheet titles take a String) instead of getting an explicit `textDirection`, to keep them start-aligned in the English UI (device check, A40); undo-label args for diary entries (`diary_actions.dart`) still carry English, as nothing renders them; T-N2 split into today_names_test (diary), quick_add_bar_test, card_adjust_test (Buddy), merge_food_test, food_names_test (pending scan, T-N1/T-N4) and barcode_lookup_test (T-N3); some reused rig finders still use control labels (`Amount`, `Meal`, `More options`), names are asserted as data. For Codex: `RemovedLine` change is in memory only (no writer change); entry-amount Save gained key `entry-amount-save`. (engineer)
- 2026-11-05: WP6 done (416912df): lazy keyed `BuddyMessageList` (A77), follow only at the bottom or after a send + "New message" (`buddy-new-messages`, ARB `newMessages`) (A67), reopen at the latest turn and lazy reveal of the oldest open card by stepping up a screen at a time (A66), follow-up chip in `FbReveal` (A08), card resolution/questions in `FbSizeFade`, removed rows `FbReveal.entering`, new DS `FbProposalActions.reserveReason` (A07, food card only; adaptive/Ramadan cards unchanged). Tests: message_follow_test (T-B3 ×2, T-B4), DS proposal_card_test reserved reason. Golden regenerated and checked: food_card_with_estimate (reserved reason line). Note: `tester.runAsync(thread.send)` hangs in a widget test; the tests build the thread through the UI. For Codex: the A67 decision is taken in the provider listener before the new content lays out (`_atBottom` = where the reader was). (engineer)
- 2026-11-05: handover after WP6 (engineer context large). Next: WP7 (recovery), then WP8–WP10. Notes: name helpers live in `settings/presentation/food_name_text.dart` (`foodNameInline`, `watch…`/`read…`, `foodNameSpoken`, `foodNameArg` for undo-label args that may hold `FoodNames`); `TodayRig(names:)` and `BuddyHarness(overrides:)` set the "Food names" setting in tests; Buddy widget tests must build threads through the UI (`sendInSheet` + `settleBuddy`), never `tester.runAsync(h.thread.send)` (hangs); `BuddyMessageList.followSlack`/`newMessagesKey` are public for tests. Run each `heavy.sh flutter test` as its own command (a chained second run keeps the heavy lock after the first is stopped). Patrol P1 (app_test.dart:88) still open for WP10. (engineer)
- 2026-11-05: WP7 done (dda07412): A71 latest intent (`SettingsQueued`; queued intents are changes of the current value, so `updateNotificationPrefs` part-changes and `setRamadanSeason` compose instead of overwriting; `SettingsPending` removed); A41 stale search rows (35 %, `IgnorePointer`, `ExcludeSemantics`), DS `FbProgressLine` (2 dp slot, keys `food-search-progress`/`food-search-results`/`food-search-skeleton`); shared `core/ui/load_states.dart` (`LoadFailedView` key `load-failed`, `LoadingRows` key `loading-rows`) for A42–A47; `WorkoutSessionGone` vs read failure (A45); adaptive cards calm retry, Change back kept (A48, keys `check-in-load-failed`, `expenditure-load-failed`, `incomplete-day-load-failed`); earlier versions rows / Try again / Sign in (A49, `versions-loading`/`versions-failed`/`versions-signed-out`); A63 resume on route current again; A64 type-code sheet via `showFbStatefulSheet` with pinned Look up (`barcode-type-code`, `barcode-type-look-up`); A68 drafts per type; A69 local Undo (`WeightHistoryForm.restore`); A70 `merge-choose-another`. ARB: `searchSearching`, `workoutsLoadFailed`, `workoutLoadFailed`, `measurementLoadFailed`, `setupLoadFailed`, `checkInLoadFailed`, `incompleteDayLoadFailed`, `expenditureLoadFailed`, `weightHistoryRowRemoved`, `personalFoodMergeChooseAnother`. Deviations: the newest queued settings caller gets the outcome of the write that carries it (so its Undo snackbar shows), superseded callers get `SettingsQueued`; T-R5 (camera resume) not automated (`MobileScannerController` has no seam; device checklist 7); T-R4 for measurement and setup not separate tests (same `LoadFailedView` path; adaptive + earlier versions tested). Golden regenerated and checked: food_search_results (2 dp progress slot). (engineer)
- 2026-11-05: WP8 done (de652961): D18 disclosure motion in `DayPage` (rows wrapped in `FbReveal` keyed by `_keyOf`; the header row unwrapped), A18 More above the extras (`food-sheet-more`), A19 pads in `FbReveal` (grouped with a neighbour so a closed pad adds no Column gap), A20 weigh-in reveals + confirmation `FbSizeFade` (`weigh-in-confirmation`), A21 card collapse reveal, A22 `core/ui/revealed_column.dart` (set rows, weight-history rows), A23 day details `FbSizeFade`, A24 `FbBarChart` value tween (structural) + period fade (local, old period excluded from semantics and hit-tests), A26 `core/ui/step_transition.dart`, A27 `app/shell/fade_through_branches.dart` via `StatefulShellRoute(navigatorContainerBuilder:)` (no fallback needed: router, tabs and acceptance tests green), A29 plan reveal + `_next` without `animateTo` under reduced motion, A80 `core/ui/success_haptic.dart`. Tests: day_motion_test (T-M2), plan_screens_test T-M4; T-M1 by the DS tokens test + the reduced-motion suites; T-M3 by app_tabs_test (runs with animations on). Deviations: steps drop the old step at once and fade/slide the new one in (an AnimatedSwitcher cross-fade put two steps' text fields on screen together, which broke `enterText` in account_upgrade_journey_test and would break Patrol's sign-in test); no focus move to the new row (A22) or step heading (A26); personal-food serving rows not animated (rows have no stable identity; `ObjectKey` of an immutable row would animate on every keystroke). No golden changed. (engineer)
- 2026-11-05: WP9 done (eed58be3): D20 set row (compact when the screen is < 360 dp or text ≥ 1.3; keys `workout-set-compact-<id>`, `workout-set-last-<id>`, `workout-set-status-<id>`; invalid in the normal row = error icon with the existing `workoutSetInvalid` as tooltip/semantics, so no `workoutSetCheck` key); D21 `_DayTargetList` (keys `targets-day-list`, `targets-day-<weekday>`; ARB `targetsDayChanged`; changed = a day factor ≠ 1; `Material` tint so the ink shows; `FbWeekBars` + its test deleted); A53 `MacrosSection.singleColumnBelow` (half card / text scale < 140 → `progress-macros-stacked`); A54 PR tiles stack (`exercise-prs-stacked`); A55 `FbBigNumber.maxTextScale` 2.0 with a headline-size floor (TextPainter fit instead of FittedBox); A59 busy scope `ExcludeSemantics` + `IgnorePointer` behind, `BlockSemantics` on the cover (`account-busy`); A61 `FbAmountDisplay.onKey`/`onSubmit` (tap also focuses), wired in the food sheet, entry amount and weigh-in sheets; A76 `ListView.builder` + `LoadingRows`; A78 memoised batch check. Tests: T-A1 (workout_screens_test), T-A2 (targets_screen_test), T-A3 contrast pair onSurface/primaryContainer, T-A5 (amount_display_test, account_busy_scope_test), T-A6 (display_test big number, progress_screen_test macros). Deviations: "narrow" in D20 = the screen width (the row itself is ~300 dp on a 360 dp phone); A53 threshold = half width / text scale (an axis allowance stacked the charts at 1.0 on a 360 dp phone). Goldens regenerated and checked: targets_screen_weekly (seven rows, Friday tinted), today_empty_day, today_full_day, today_targets_under (big number larger at 2.0). (engineer)
- 2026-11-05: WP10 done (e0fa22ae): P1 fixed in the test, not the screen: the Progress `ListView` builds lazily, so on the emulator the calories card was past the build extent; `patrol_test/app_test.dart` now scrolls to `progress-calories-chart` and checks its empty branch by the chart icon (no copy). Host reproduction `test/acceptance/progress_fresh_install_test.dart` (fresh profile, offline, 411 × 914): the chart takes its empty branch, so cause (a) is ruled out. P2/P3 were done in WP3. Copy and key greps in `patrol_test/` and `integration_test/` for WP7–WP9 changes: nothing else to retarget (`jank_benchmark_test` origin already updated in WP3). `make trace`: UX-045/046 covered, no new missing IDs. Coverage check (engineer's pass, for Codex to confirm): every item A01–A80 and T is built; partial, with the reason in the WP7/WP8 lines: A22 (no focus move to a new row; personal-food serving rows not animated), A26 (no focus move to the step heading), A63 (built, test not automated: no scanner seam; owner checklist 7). Not done here (orchestrator): Outcome, the `[it]` CI run, merge. (engineer)
- 2026-11-05: WP7–WP10 done (dda07412…decc02b0). Phase D: one combined Codex review started (task-mw3z92jt-osh1mw), read-only on the local branch. Branch pushed for a manual CI run with android-it (the token can't dispatch it; the owner taps Run workflow or the nightly after merge proves P1). (orchestrator)
- 2026-11-05: Codex review fixes (engineer): (1) `RevealedColumn` drops a finished exit from its list and starts exits only for children live in the last build (no repeating timers); (2) weight-history rows own and dispose their controller (`_RowEditor` stateful), so a removed row keeps a live controller during its exit and an Undo mid-exit keeps the text; (3) DS `FbInert` (IgnorePointer + ExcludeFocus + ExcludeSemantics) wraps FbSizeFade's leaving state, and a hidden `FbReveal` now also excludes focus (a focused field in a leaving row lets go); (4) search `stale` = rows answer another query, so they stay faded and unpickable after a failed newer search; (5) `_RowLine` stacks the answers on their own reserved line (unscaled, 48 dp) when the screen is < 360 dp or text ≥ 1.3, FittedBox removed; (6) `FbBarChart` period switch uses `FbInert.switcherLayout`; same fix in `QuickAddBar`'s chip switcher (pre-existing). Tests: revealed_column_test, weight_history_screen_test (focused removal + Undo mid-exit; 320 dp / 2× hit targets), food_search_test (stale after failure), DS reveal_test (mid-swap inert), bar_chart_test (period-switch semantics). No golden changed.
- 2026-11-05: Codex fix-check (task-mw3zy7jz-kim4ta): all 6 fixed, no new blocker/major, verdict fixes OK; test gap → backlog #281. Outcome written; merging via merge-step.sh. (orchestrator)
- 2026-11-05: merge CI red (run 42104029436): stale workout_log_controller.g.dart and app_shell golden (WP8/WP9 changes). Regenerated both, golden viewed; merge retried. (orchestrator)
