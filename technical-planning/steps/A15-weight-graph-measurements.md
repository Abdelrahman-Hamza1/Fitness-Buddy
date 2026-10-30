# A15 — Weight graph & measurements

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A12, A13a, A14 | L | Claude | A15a ✅ · A15b ⬜ |

_Old ID: S22 (renumbered by TD-063, 2026-10-16)._

**Goal.** The weight graph that replaces the owner's note, with all its overlays, plus body measurements and their graphs. The chart library is confirmed (TD-012) by a feasibility check at the start.

**Spec:** WB-020, WB-021 (goal line, projection cone, phase shading; Ramadan shading data arrives in A41), WB-022, WB-023, WB-040 (form), WB-041, WB-042 (manual body fat), WB-043 (setting), IN-004 · **Decisions:** TD-012

## Scope
- **Feasibility check first (≤ ½ session):** fl_chart with points + trend line + goal line + uncertainty cone + shaded bands + touch tooltips. If any part fails, `CustomPainter` for that layer. **Record TD-012.**
- **Chart widgets** in `fb_design_system` (the wrappers from A02): time-axis handling (chronological in any direction, LC-003-ready), ranges 1M/3M/6M/1Y/All, tooltips.
- **Weight graph** (WB-020–022): raw points + trend, goal weight line, projected path to the goal with a cone (from the trend rate + uncertainty), **shaded phases** (TG-012), a band API for Ramadan periods (fed in A41), tap a point → value, date, note, trend at that date.
- **Summary stats** (WB-023): change since phase start, this month vs the monthly target, average weekly rate.
- **Measurements:** built-in types (waist, chest, hips, arm, thigh, neck) + custom types, a form entry (chat in A29), a graph per type (trend smoothing only with ≥ 5 points), body fat % manual with its own graph (WB-042), and a measurement reminder on/off setting stored for A40 (WB-043).
- **The owner's weight history:** a simple multi-row manual entry (paste import comes with Buddy in A29).

## Out of scope
- Paste import (A29). Ramadan detection (A41). The Progress tab layout (A16).

## Fixed by the plan
- Charts are wrapped in design-system widgets. Screens never use the chart library directly.

## Decide in the low-level plan
- The projection cone method (e.g. a rate ± standard error over the last N weeks).
- Down-sampling for "All" ranges with years of data.

## Exit criteria
- [ ] **TD-012 recorded** with the feasibility result.
- [ ] The weight graph renders the owner's real history with every overlay. The owner signs off ("this replaces my note").
- [ ] Goldens for the graph in each range (light/dark). Tooltip interaction test.
- [ ] Measurements: add, edit, delete with undo. Graphs per type.
- [ ] Rendering 2 years of daily points stays smooth on the A55 (no frame > 16 ms during pan).

## Read first
`spec/14-weight-and-body.md` §3, §5 · `02-tech-stack.md` §1 (charts)

## Owner involvement
Enter your weight history (or hand it over for entry). Review the graph.

---

## Low-level plan
_A15a "Weight graph" part, compacted on 2026-10-29 from the prepared A15 plan (step-planner, architect plan review PA1–PA17 applied; chart research `A15-charts.md`). A15b "Weight history entry & measurements" (WP6–WP10, Risky: contract, two synced tables, migration, multi-row entry, measurement screens) keeps its own plan section when it starts. Owner direction 2026-10-29: plan + code now (time-boxed), architecture and code review later; CI on the branch is the test evidence (no local test runs)._

**Split (D1).** A15a = WP1–WP5, **Normal** (no new write code, no migration): TD-012, the DS chart, projection + stats, the graph screen, entry points. A15b depends on A15a. WB-043 (measurement reminder) moves to A40 (PA10).

**Decisions (A15a).**
- **D2 TD-012 = `CustomPainter`, settled by research, no prototype** (PA1): fl_chart 1.3.0 works under material_ui but has no culling, repaints every path per pan frame, fights our drag recogniser, still needs our slicing/LTTB/labels/off-scale marker, and ties the DS to in-framework Material. Evidence: `evidence/A15a-chart-feasibility.md`; TD-012 row rewritten (owner FYI).
- **D3 DS API.** `FbTimeSeriesChart` keeps its name: `series`, `range`, `panBounds?`, `onRangeChanged`, `bands` (the cone), `goal` (+ edge marker when off-scale), `periods` (`FbPeriod` start/end/label/`FbPeriodTone {phaseA, phaseB, highlight}`; phase labels top, highlight bottom), `selected`/`onSelect` (`FbPointRef`), `formatValue`, `formatDate`, `semanticLabel`, `emptyLabel`, `aspectRatio`. `FbSeries` gains `selectable`, `tone {primary, secondary, muted}`; `FbSeriesStyle` gains `dashedLine` (open to additions); `FbPoint` gains `key`; `tooltip` removed (details render outside). **Time runs in reading direction** (LC-003, PA2): oldest at start, so in RTL the oldest is at the right. X values are naive wall-clock `DateTime.utc(local fields)` (PA7). **Pan (PA4):** transient internal offset during drag, one `onRangeChanged` with a continuous start on drag end; a new `range` resets it. Selection always drawn (PA8), tap tolerance ≥ 24 dp, semantics increase/decrease step the selection. Tokens only; style differs by dash/dot, not only colour (UX-071).
- **D4 Down-sampling:** LTTB per series over the visible slice (binary search), lines ≤ 1 vertex/dp, dots ≤ 1 per 3 dp; hit-testing on full data; cached axis `TextPainter`s; `RepaintBoundary`.
- **D5 Windows (WB-020)** in `features/progress/application/graph_window.dart`: `GraphRange {m1, m3, m6, y1, all}`, 3M default, ends today, calendar months (day clamped); All = first weigh-in → today (≥ 1 month); future margin ¼ window when a projection shows; pan bounds [first − 7 d, today + margin]; All doesn't pan. `weightGraphWindowProvider` (keepAlive, session-only) holds range + panStart; "Today" chip resets.
- **D6 Y scale** `nice_scale`: 3–5 ticks on 0.1/0.2/0.5/1/2/5/10 steps, 8 % padding, fitted to the visible slice; the goal is included only if it at most doubles the span, else an edge marker.
- **D7 Projection + cone (PA5)** pure `WeightProjection.of` in `fb_domain/src/body/weight_graph.dart`: needs a goal weight, a fresh trend with a weekly rate ≥ 0.05 kg/week toward the goal, not reached. Centre `T + r·t/7` from the latest trend point; σ = OLS slope SE of the day choices in the 56 days ending at the anchor (≥ 4 points over ≥ 14 days), floor 0.1 kg/week; edges centre ± 1.28·σ·t/7, clamped at the goal; drawn until the slow edge reaches the goal or 730 days; reach date where the centre meets the goal ("Goal around {month} at your current trend"); none past 730 days. Rate uncertainty only, never a probability. Constants in `ProjectionConfig`.
- **D8 Goal line, phases, Ramadan seam:** the active phase's target weight (targetDate/targetRate only); `GoalHistory.phases` in view → alternating `phaseA/phaseB` periods labelled by `goalPhaseLabel` (targets barrel, PA9); `chartHighlightPeriodsProvider` returns `const []` for A41.
- **D9 Tap → details (WB-022):** an `FbCard` under the chart: value as typed, date/time, note, "Trend {w} that day"; "Not used for the trend" + **Use for trend** (A14 `chooseForTrend`, undo); **Edit** → A14 `showWeighInSheet(edit:)`. Vanished selection clears.
- **D10 Stats (WB-023, PA3/PA11):** pure `WeightStats.of`: reference = active phase start else first weigh-in; start value `trendOn(start)` or the first trend point after a stale/missing one; change since start; this month = trend today − trend at end of last month (or from a phase start this month, pro-rated target); **monthly target = `monthlyKgFromWeeklyRate` of the same achievable rate A13 shows** (TG-011 line, SF-011-capped), from `targetsExplanationProvider`; average weekly rate after ≥ 14 days, "Average since {date}"; missing pieces "—" + reason.
- **D11/D12 Placement and entry:** screen, providers and window in `features/progress/` (imports body, targets, settings barrels). Routes `TodayWeightGraphRoute` `/today/weight` and `WeightGraphRoute` `/progress/weight`; Today's `WeightCard` gets a "Weight graph" row; the Progress tab gets a Weight row until A16.
- **D21 Copy:** neutral words only (change, trend, projection, goal, "likely range at the current rate"); no red/green; ARB `weightGraph*`; DS strings in `fb_ds_en.arb`.
- **D22 Perf:** host vertex-cap test + printed benchmark; Patrol frame timings and the A55 profile pan run (owner item, recorded here) gate exit 5.

**Work packages.**
- **WP1** `docs(A15a): TD-012 chart feasibility result`: evidence note + TD-012 row.
- **WP2** `feat(design-system): time-series chart with bands, periods, selection and pan`: §5.1 tests, `time_series_chart` golden matrix (replaces `chart_placeholder`), mockups updated.
- **WP3** `feat(body): weight projection and stats`: `weight_graph.dart` + tests (glados property on the cone), README section.
- **WP4** `feat(progress): weight graph with goal, projection, phases and point editing`: window, providers, screen, details, stats, routes, Progress row, ARB, widget tests, goldens.
- **WP5** `feat(body): weight graph entry on Today`: `WeightCard` row + goldens, Patrol `weight_graph_test.dart`; close commit `[it]`.

**Tests (spec ID first).** DS: `IN-004` matrix golden, `LC-003` RTL reading direction + drag follows finger, `WB-022` tap ≥ 24 dp / full-data hit test / selection drawn / semantics stepping, `WB-020` pan offset → one `onRangeChanged`, LTTB keeps extremes and caps, 2 years → ≤ 360 vertices / 120 dots, nice scale + goal edge rule. Domain: `WB-021` centre, σ, edges, clamp, horizon, reach date, every no-projection reason, glados cone property; `WB-023` start value (stale rule), this month (pro-rated), monthly target from the rate, average after 14 days, no phase; toString carries no values. App: `WB-020` windows (31 Mar − 1 month = 28/29 Feb), chips (3M default, survives leaving), pan + Today; `WB-021` overlays drawn + unnamed phase label + Ramadan seam; `WB-022` tap shows value/date/note/trend, Use for trend with undo, Edit opens the sheet; `WB-023` stats; `LC-010` lb; `UX-050/051/052`; `HM-005` card row → graph, Back → Today; `UX-013` Progress row. Goldens per range light/dark + text scale 2.0.

**Exit mapping (A15a).** TD-012 → WP1. Overlays + goldens per range + tooltip test → WP2/WP4. Real-history sign-off → A15b close. A55 smooth pan → host caps + Patrol timings + owner profile run (verifier ⚠️ until recorded).

**Risks.** A55 pan perf (mitigation: static-layer `Picture` cache). Golden antialiasing (integral strokes, CI goldens). Shared files with A13c (targets presentation: untouched here, only the barrel is read) and A44 (palette: tokens only, so goldens regenerate after A44 lands).

## Progress log
- 2026-10-29 · A15a low-level plan written into the card (compacted from the prepared, architect-reviewed A15 plan). Branch `step/A15a-weight-graph`.
- 2026-10-29 · WP1 (TD-012 = `CustomPainter`, row rewritten, `evidence/A15a-chart-feasibility.md`), WP2 (DS chart: `chart_types`, `time_series_painter`, `chart_geometry`, `lttb`, `nice_scale`; reading-direction x, transient pan → one `onRangeChanged`, tap ≥ 24 dp on full data, semantics stepping, goal edge marker, cached labels; `time_series_chart` golden matrix replaces `chart_placeholder`; mockup goldens regenerated), WP3 (`fb_domain/src/body/weight_graph.dart`: `WeightProjection`, `WeightStats`, glados cone property; README "Weight projection"; TD-099 Proposed after the main merge), WP4 (`features/progress/`: `graph_window.dart`, `weight_graph_providers.dart`, `weight_graph_screen.dart`; routes `/today/weight`, `/progress/weight`; Progress Weight row; `weightGraph*` ARB) and the WP5 card row committed and pushed. CI on bd2e3b8 failed in `dart-test (packages)` (chart semantics: increase/decrease need neighbouring values; fixed in e16520f, chart tests green locally) and `dart-test (app:3/3)` (not inspected: GitHub API quota exhausted; likely goldens). **Not done (next session):** check CI on the branch head; regenerate the goldens CI reports (weight card + Today now have row 3); WP4 widget tests + weight graph goldens per range (§5 tests list); `HM-005`/`UX-013` navigation tests; Patrol `weight_graph_test.dart` + `[it]` close commit; A55 profile pan run (owner item); `GoalMonthTarget` shared helper not created (stats take the TG-011 rate from `targetsExplanationProvider`, deviation for review).
- 2026-10-29 · Review round (architecture approved; Codex review findings fixed): merged `origin/main` (A44 Embrace, B09b; a fast-forward merge instead of a rebase, because the force-push was refused) with the projection TD renumbered **TD-099**; points sorted by chart time with a rollback test (e5a39e3); `MonthlyTargetRate` (manual / generated / unavailable), so a manual target that needs review shows no monthly target (3e8ad3c); the graph follows `todayProvider` and refreshes on resume (fb4e1a2); a refused Use for trend shows a snack bar (0aaa2a1); the value scale fits only visible dots plus interpolated line edges (108663e); goldens regenerated for the card's row 3 and Embrace (4b94b17); evidence: screen widget tests, HM-005/UX-013 navigation, `weight_graph_ranges`/`weight_graph_states` goldens, Patrol `weight_graph_test.dart` with printed pan frame timings, the router location test lists both graph routes (f9004fa). Onboarding and weigh-in Patrol finders are unaffected by row 3 (they target row texts, not positions). Open: the A55 profile pan run (owner item); `ux-reviewer` pass.
- **Status: built; architecture approved; review findings fixed, awaiting CI and the code-review close** (owner direction 2026-10-29: plan + code time-boxed; reviews later). Not merged.

## Outcome
### A15a "Weight graph"
**Built by Claude (TD-085, TD-095: one agent) in lane 4, 2026-10-29: plan and code time-boxed by the owner, reviews afterwards. Size about the planned L for WP1–WP5, plus one review-fix round. A15b (weight history entry & measurements) is still to do.**
- **Built:** TD-012 settled as a DS-owned `CustomPainter` chart (evidence `evidence/A15a-chart-feasibility.md`). `FbTimeSeriesChart` with:
  - time running in reading direction (LC-003) on plain wall-clock dates;
  - LTTB down-sampling of the visible slice, readable value ticks fitted to visible values (interpolated line edges), and an edge marker for an off-scale goal;
  - cone bands, labelled periods (phase labels at the top, highlight at the bottom), and tap selection within 24 dp on the full data, with the selection always drawn;
  - screen-reader stepping between points, and a transient pan offset reported once on drag end;
  - cached labels and a `RepaintBoundary`.

  `fb_domain`: `WeightProjection` (the card's rate, a cone from the OLS slope standard error, clamped at the goal, a 730-day horizon, a reach date) and `WeightStats` (change since the phase start with the stale-start rule, this month against the pro-rated TG-011 target, average since a date), plus `MonthlyTargetRate`. The progress feature: `graph_window.dart` (calendar-month ranges, 3M default, pan bounds), `weightGraphProvider` (independent of the window, follows `todayProvider`, no automatic retry), `WeightGraphScreen` (range chips, Today reset, dots, trend, goal line, projection cone, goal phases, the A41 `chartHighlightPeriodsProvider` hook, point details with Edit and Use for trend with undo, the WB-023 summary, empty/loading/error states). Routes `/today/weight` and `/progress/weight`; the weight card's third row "Weight graph"; a Weight row on the Progress tab.
- **Deviations:** no fling (only a drag pans; it reports once on drag end). The PA3 shared month-target helper is **`MonthlyTargetRate`** (manual / generated / unavailable with a reason, read from the targets explanation), and `WeightStats` does the month conversion and pro-rating. A manual target that needs review shows no monthly target. Main was merged into the branch instead of rebasing it (the force-push was refused); it squash-merges the same way. TD-012 was rewritten as **Accepted** (`CustomPainter`; it was Pending, so no owner gate; owner FYI). The projection TD is **TD-099 (Proposed)**. In the Patrol journey, point selection calls the chart's `onSelect` (pixel hit-testing is proved by the DS tests).
- **Reviews:** architecture approved (boundaries; projection and pro-rating match the plan). Codex code review: **1 major** (chart points sorted by chart x, not UTC: clock rollback) and **4 minors** (no generated fallback for a manual target that needs review; the date follows midnight and resume; feedback when Use for trend is refused; scale fitted to visible values), all fixed with tests (e5a39e3, 3e8ad3c, fb4e1a2, 0aaa2a1, 108663e). The first CI run also found a chart semantics bug (increase/decrease need the neighbouring values), fixed in e16520f.
- **Metrics:** about 72 tests added:
  - DS: 20 chart tests plus a golden matrix (light/dark × LTR/RTL × 1.0/2.0);
  - `fb_domain`: 26 (projection, stats, `MonthlyTargetRate`, a glados property on the cone);
  - app: 21 widget/provider/navigation tests (HM-005, UX-013) plus goldens `weight_graph_ranges` (1M/3M/6M/1Y/All, light/dark) and `weight_graph_states` (3M at 2.0, selected, empty);
  - Patrol `A15 weight graph ranges pan and point edit with two years of weigh-ins`, with printed pan frame timings;
  - a printed host benchmark for slicing, LTTB and scaling 730×2 points.
- **TDs:** TD-012 Accepted (`CustomPainter`). TD-099 weight projection & cone, Proposed.
- **Follow-ups:** backlog #164 (owner A55 profile pan run, exit 5), #165 (`ux-reviewer` pass on the graph), #166 (fling on the chart, if wanted).
