# A72 — Daily target up front, macros that follow it, and a smart weight number (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A13, A14, A57 | M | Claude (Opus plan + build), one Codex review | 🟨 built, review next |

**Goal.** D-102 (owner, 2026-11-07, from daily use of build 1000): the Targets screen leads with one daily number and a Change sheet whose macro preview updates live (TG-046), seven equal weekday numbers count as that daily number so fat/fiber/carbs follow it, and the main weight number follows weigh-in frequency (WB-011). Design: https://claude.ai/artifact/1Fi58ia6psWKBxEfvkW5PY (boards 1–3).

## Scope
1. **Weight number (WB-011):** one shared rule in fb_domain (fewer than 3 weigh-in days in the last 14 → latest weigh-in as entered with its day and the change since the previous one; else the trend with "last X" next to it); every place that shows the main weight number uses it (Today glance line, Progress weight card, the widget snapshot, Buddy facts/weekly summary only if they label a "current weight"). The weekly rate keeps the trend.
2. **Targets screen top (TG-046):** a daily-target card first ("Daily target · every day", the number, own vs suggested line, Change), the four macro targets under it, the days of the week below with Same / By day.
3. **Change sheet:** − / + (50 kcal), typing, quick picks incl. the suggestion, live preview of protein/fat/carbs/fiber with the old values, rough weekly rate; saves through the existing own-target path (manual target, SF-012 acknowledgement below the floor) with Undo; "Adjust macros myself" opens the existing macro settings.
4. **Seven equal days:** when every weekday has the same number, macros are planned from that number (the base), not from the suggestion; decide in the plan whether this converts to the own-target model or adjusts the macro base, keeping the weekly budget and adaptive check-in rules consistent.
5. Tests (lean): the weight-number rule, the equal-days macro base, the sheet preview maths matching MacroPlan; update goldens/patrol texts the change breaks.

## Low-level plan (Opus, self-approved by the orchestrator)
**P1 — WB-011 rule (fb_domain `body/weight_reading.dart`).** `WeightReading.of(trend, weighIns, date)` → `null` (no weigh-in on or before `date`) or a sealed reading:
- `LatestWeightReading` (fewer than `WeightReading.frequentMin` = 3 trend days, i.e. day choices, in `date` and the 13 days before): the last day choice on or before `date` (its kg and the typed `WeighInInput`), its day, the change vs the previous day choice's raw kg and the days between (both null for the first weigh-in), the trend's weekly rate and staleness from `trend.asOf`.
- `TrendWeightReading` (3 or more): the trend, the last day choice (kg, input, day) and the weekly rate.
Several weigh-ins a day count once because the trend's points are `DayChoice`s. Pure, no clock; unit tests per case.

**P2 — apply it.** A `weightReadingProvider(date)` in body (sync over the weigh-in and trend streams like `weightCard`), exported by the barrel. Today's glance tile: latest → "107.7 kg · Sat" (day label, "today"), trend → unchanged "108.1 kg · −0.4 kg/week" (one half-width line can't hold the raw number; the semantics read it). Progress weight card: a header above the chart in the design's three lines (sparse: "Weight · Sat / 107.7 kg / −1.1 kg since the weigh-in before (10 days)"; frequent: "Trend weight / 108.1 kg / last 107.7 · today · −0.4 kg/week"). Me › Profile "Current weight" row: the same short text as the glance. The typed value shows when its unit is the display unit, else the converted kg. Buddy record facts keep the trend (they compute, they don't label a current weight); the home widget has no weight. Stable heights: the glance stays one `FbGlanceTile` line.

**P3 — Targets top + Change sheet (TG-046).** Domain: `TargetPlan.dailyKcal` (see P4) and `DailyTargetPreview.of(plan:, kcal:, macroWeightKg:, expenditureKcal:)` → the new day's `DailyMacros` (MacroPlan at base = kcal, the stored macro settings), the current daily number's macros ("was"), the P/F/C energy shares and the rough rate `(kcal − expenditure)·7/7700`. `DayTargets` gains `macroWeightKg` (goal weight, else the weight) so the sheet calls the same maths. Screen: card 1 "Daily target · every day" (or "· some days differ"), the number, "Your own number · suggested 2,150" / "Adjusted to your results" / "Suggested for your goal", Change; a row of the four macro targets of the daily number (macro colours; rows from text scale 1.4) and the note; card 2 "Days of the week": today's number, the week total and position, Same / By day, the seven days (as before). The separate macros card goes (its energy note moves into card 1). Change sheet: "Calories every day", − / + 50, tap to type, chips Now / −200 / +200 / Suggested N, "Your day becomes" (each macro, "was X"), the share bar, "about −0.6 kg/week", primary "Use 1,800 every day", text button "Adjust macros myself" (the existing macro sheet). Save: new `TargetsActions.setDailyTarget(shown, kcal)` = the manual-target path (SF-011/SF-012 acknowledgement via the existing below-limit screen, Undo) that also clears the weekday factors and their floor acks; `kcal == null` ("Suggested" picked) → the calculated target (manual → generated) with the factors cleared. Suggested N = the calculation (`explanation.calculated`) for an own number, else the plan's base.

**P4 — seven equal days (decision).** No conversion, no new stored field, no migration: `TargetPlan.dailyKcal` = the planned number when all seven planned numbers are equal (within 0.5 kcal), else the base; `TargetPlan.day` resolves MacroPlan at `dailyKcal` instead of `baseKcal`. Effects: weekly budget and rebalancing read the planned numbers only → unchanged (TG-040–042); fixed mode → unchanged; the adaptive check-in compares the stored base (the suggestion) and the factors stay relative to it (TG-034/043) → unchanged, and after a check-in the equal days still follow; Today, Progress and the widget snapshot read `DayTargets.day.macros` → follow automatically. Days that differ keep today's behaviour (macros from the suggestion).

**P5 — tests (lean).** Domain: reading cases (weekly, daily, mixed, single, gap > 14 d, several a day, lb), `dailyKcal`/equal-days macros (+ budget unchanged), preview matches `MacroPlan`. App: `setDailyTarget` (clears factors, ack path, suggested path), glance/Progress/targets widget tests updated, goldens regenerated where the screens change (targets, Today/Progress weight).

## Exit criteria
1. On the A55: weekly weigh-ins show the typed number; setting 1,800 from the top card updates protein/carbs/fat/fiber everywhere (Today, widget).
2. CI green; Codex review passed.

## Progress log
- 2026-11-07: card from D-102; one engineer plans + builds (owner: one plan, one exec, one review).
- 2026-11-07: low-level plan written (P1–P5) `25f195e7`; self-approved per the brief.
- 2026-11-07 · WP1 `f3d283f0`: fb_domain `WeightReading.of` (sealed `LatestWeightReading` / `TrendWeightReading`, 3 weigh-in days in 14); `weight_reading_test.dart` (10 cases).
- 2026-11-07 · WP2 `d9e9d397`: `WeightCardState.reading`; Today's glance ("107.7 kg · Sat" or "108.1 kg · −0.4 kg/week"), Progress weight card header (`WeightReadingHeader`), Me › Profile current weight; `dayLabelShort`; unused `todayGlanceWeightStale` / `weightCardTrendFromSemantics` removed; `progress_screen.png` regenerated; `weight_glance_test.dart` updated (+2).
- 2026-11-07 · WP4 `a67994cf`: `TargetPlan.dailyKcal` + `macrosFor`, `DayTargets.macroWeightKg`, `DailyTargetPreview`; `daily_target_test.dart`.
- 2026-11-07 · WP3 `cb919de0`: Targets top card + `MacroTargetsRow`, "Days of the week" card (the macros card is gone; `targetsMacrosTitle/Note` removed), `DailyTargetSheet`, `setManualTarget(everyDay:)` + `useSuggestedEveryDay`; `daily_target_actions_test.dart`, `daily_target_sheet_test.dart`, goldens `targets_screen_weekly.png` (regenerated) + `targets_daily_sheet.png` (new).
- 2026-11-07 · checks: `make gen-app` committed, `make check-dart` ✓, fb_domain `dart test` ✓ (1101), focused app tests ✓ (TZ=UTC: targets, today, home_widgets, adaptive, progress, body, me, buddy/presentation, onboarding, acceptance; unit_display, app_router), `make trace` lists TG-046 and WB-011 covered.
- 2026-11-07 · Codex review (2 majors, 2 minors), all fixed in one commit: (1) "Suggested N", the own-number line and the sheet's rate come from `TargetsTimeline.generated` at today's trend weight and goal (the same call the save uses; `useSuggestedEveryDay(expectedKcal:)` refuses `changed` if it moved); (2) the sheet's "nothing to save" is judged on the stored state (own number, no day numbers), so seven equal day numbers + Use store the own target (SF-012/fixed path below the floor); (3) the whole Change sheet incl. its button sits above the keyboard; (4) Me › Profile's weight row shows the WB-011 supporting line and reads `readingSemantics`. Tests: changed weight + target-date goal, equal days save + Undo, below-floor equal days, keyboard at ×1.0/×2.0, profile both modes, refusal. `make gen-app`, `make check-dart` ✓, focused tests ✓ (TZ=UTC: targets, body, progress, today, adaptive: 355; fb_domain targets).
- 2026-11-07 · Codex fix-check round 1 (one major: Ramadan "maintain"): "Suggested" from an own number now previews and checks `TargetsTimeline.suggestedBase` (the generated base through `TargetsTimeline.day`: floor and Ramadan "maintain" applied), so preview, the "suggested" line, `expectedKcal` and the saved plan agree. Test: manual → suggested during Ramadan maintain (+550 refused as the unadjusted number, saved base = preview). `make gen-app`, `make check-dart` ✓, targets tests ✓ (104), fb_domain targets ✓.

## Outcome

_Built 2026-11-07 (lane 1). Not pushed; the Codex review and the merge are the orchestrator's._

**Reviews:** Codex code review: changes requested (2 majors, 2 minors), all fixed (see the log).

**Built:** WP1–WP4 as planned (commits in the log), WP5 = this card. No drift migration, no stored field, no contract change.

**Decisions:**
- **Seven equal days (P4):** the macro base is derived, not stored: `TargetPlan.dailyKcal` is the planned number when all seven are equal (±0.5 kcal), else the suggestion. Weekly budget, rebalancing, fixed mode and the adaptive check-in (base = suggestion, factors relative to it) are unchanged; Today, Progress and the home widget follow through `DayTargets.day.macros`.
- **Change sheet save:** an own number every day (`setManualTarget(everyDay: true)`: factors and floor confirmations cleared in the same change set, SF-011/SF-012 screen first, Undo). "Suggested N" (or typing that number) goes back to the calculated target (`useSuggestedEveryDay`).
- **Weight:** the trend-mode glance keeps "trend · rate" (one half-width line); the latest raw shows on Progress and in the semantics. Progress got a small number header (it had no weight number before).

**Known approximations / for the owner:**
- The sheet's "about −0.6 kg/week" uses today's formula expenditure; after check-ins have adapted the base it is a rough figure ("about").
- Change replaces "by day" numbers (the sheet says so when days differ).

**Exit criteria:** 1 (on the A55) needs a device build; 2 after review + CI.
