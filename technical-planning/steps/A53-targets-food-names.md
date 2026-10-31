# A53 — Targets redesign & food-name language

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A38, A41a, A42 | L | Claude | ✅ Closed, awaiting merge |

_2026-10-31, UX overhaul (owner critique + approved sketches `Targets`, `TgDay`, `TgWhy`, `FnSetting`, `FnSearch`). Lane 3 of A51 / A52 / A53. Tier **Risky** (the targets engine, a data migration of synced rows). One engineer (Claude) plans and builds; one combined Codex review._

**Goal.** Targets that are easy: one suggested number a day that the user can change per weekday, the calculation only on demand. Food names in the language the user reads.

**Spec:** TG-021, TG-040–045 (amended by D-090), WO-061 (amended), SF-010/012, LC-* (`18`, D-091), FD-020/023 · **Decisions:** D-090, D-091, TD-112

## Scope
1. **Targets (D-090).** New Targets screen: top card (today's kcal, this week's total, "Same every day | Different by day", a 7-bar weekday chart from the week start; tap a bar → day sheet with − / + steppers, tap to type, quick chips, "Every <day>. Suggested: n · your week becomes total.", Save). Macros card. Rows: "How is this worked out?" (sheet: 3–4 steps, Recalculate, Set my own number), Goal → profile & goal, "More options" (macro split, rebalancing switch). The higher-calorie days UI, the weights-based shifting and the (never-exposed) training-day shifting go.
2. **Food names (D-091).** Setting "Food names": Match my phone (default) / English / Arabic / Both, applied to search results, recents, diary rows, quick add, saved meal items, your foods, Buddy food lines; the food page shows both names + aliases. Search shows "Matched <alias>" when the hit came from another name.

## Out of scope
- Arabic app UI (R2, D-080). Undo/snackbar labels keep the English name (they're stored with the change).
- Moving the Food names row into A51's Preferences page (the lane that merges second does it).

---

## Low-level plan
_Claude, 2026-10-31. Size L, estimate **1.5–2.5 sessions including one fix round**._

### D1 Per-weekday numbers are stored as a factor of the suggestion (TD-112)
Each weekday may carry a **factor**: that day's number = suggestion × factor (no factor = the suggestion). The suggestion is today's calculated daily target: the stored base (generated, adapted by A38, or the user's own), raised to the safety floor, with Ramadan "maintain" applied. When an adaptive check-in, a recalculation or a profile change moves the suggestion, every changed day moves with it in proportion. The UI shows only absolute numbers; a day typed equal to the rounded suggestion stores no factor.

The factors live in the existing `shift_mon … shift_sun` columns / `shiftMon … shiftSun` wire fields (nullable numbers 0 … 1e6). **No contract, backend or drift schema change.** An offset (kcal) was the alternative but needs negative values, which the v1 wire schema forbids; a factor fits and follows a changing suggestion just as well. Plausible factors are 0.5–2.0 (`TargetRules.input.dayFactor`); a synced factor outside that range reads as none.

### D2 Migration v13 → v14: weights become factors without changing any number
A data-only drift step rewrites every `target_settings` row with a shift weight: factor = the day's planned number under the old engine ÷ base (frozen copy of the old weighted allocation with the ±25 % limits; the floor isn't known in SQL, so a day the old engine raised to the floor is raised by the new engine instead). The rewrite bumps the row's HLC (counter + 1, same device) and `version`, so the outbox captures it and sync pushes the converted row. Rows without shifts are untouched. Historical days keep their numbers (the converted factors reproduce the old planned days).

Risk accepted: a row written by a pre-A53 app on another install after the upgrade would be read as factors. R1 is one user on one phone with no production server.

### D3 Engine
- `TargetPlan` carries `dayFactors`; `plannedKcal(weekday)` = base × factor.
- `WeeklyBudget.calculate(planned: …)`: budget = Σ planned (no longer base × 7). Rebalancing (default on, unchanged meaning) spreads budget − accounted over the remaining days in proportion to their planned numbers, each within ±25 % of its own planned number and never below the floor; a day the user set below the floor is never lowered further. Unknown earlier days reserve their planned number (TG-032).
- Fixed mode: each day its planned number, no weekly logic (no week line).
- PA7 (acknowledged manual below the floor, fixed): factors are ignored; `setManualTarget` below the floor clears them; per-day edits are refused.
- `TrainingShift` / `trainingShiftProvider` / `remainingWeights` are deleted (the training-day weight never had a UI; D-090 removes weights). The `targets.trainingDayWeight` key stays in `AppSettings.all` (retired) so export can name a stored value.

### D4 A day below the floor
The day sheet runs `setDayTarget`; below the floor the command returns `TargetsNeedsAcknowledgement` and the sheet opens the existing full-screen warning (`BelowLimitScreen`) with a per-day line instead of "same every day". Confirmed → the factor is saved together with its confirmation in the synced setting `targets.dayFloorAcks` (weekday → confirmed factor; one change set, one Undo; the wire ties `acknowledged` to `manual`, so the version row can't hold it). The engine raises any other day below the floor to it (SF-010), so migrated or stale factors never go below silently. A kept day shows a calm banner (`TargetIssue.dayBelowFloor`). "Same every day" and a below-floor own target clear the confirmations. (Codex review major 1.)

### D5 Commands
`setDayTarget(shown, weekday, kcal, {acknowledged})` (500–10,000 kcal and factor 0.5–2.0), `sameEveryDay(shown)` (clears every factor), `setBalancing(shown, on)` (on → weekly + rebalancing; off → rebalancing off). All D5 revision rule, one undo entry each. `setShifting` and `setMode` go (the mode list leaves the UI).

### D6 Screen
`TargetsScreen` → top card (`FbCard`), macros card, three rows. "More options" opens a sheet with "Balance over/under across the week" and "Macro split". The manual flow ("Set my own number instead") and "Use the calculated target" move into the "How is this worked out?" sheet. Issue banners (manual needs review, goal needs update, day below floor) stay at the top of the screen. Bars use theme colours (today highlighted, never red).

### D7 Food names
- `fb_domain`: `FoodNameLanguage { phone, english, arabic, both }`, `FoodNameDisplay.of(names, language)` → (primary, secondary?) with the fallback preferred → other → English. Pure.
- `AppSettings.foodNames` (`food.nameLanguage`, default `phone`). `foodNameLanguageProvider` resolves "phone" from the platform locale list: the first of `ar`/`en` in the list wins, else English.
- `FoodNameLines` helper (settings barrel) gives title/subtitle strings; an Arabic name inside a composed LTR line is wrapped in Unicode isolates (FSI … PDI).
- Search keeps the best-matching name key per target; the row shows "Matched X" when X is not one of the names shown.
- `FoodNamesSettingRow` is its own widget in `settings_section.dart` (one-line move for A51).

## Work packages
| WP | Content |
|---|---|
| WP1 | Domain: factors, `WeeklyBudget` by planned days, `TargetPlan`, timeline (drop training), rules, records; tests incl. glados |
| WP2 | App data: mapper, migration v14 + test, providers, `TargetsActions` commands; tests |
| WP3 | Targets UI: screen, day sheet, how sheet, more options; ARB; widget + golden tests |
| WP4 | Food names: domain, setting, provider, rows, search "Matched"; tests |
| WP5 | Spec (D-090, D-091, `13`, `15`, `18`), TD-112, cross-check, Codex review, fixes |

## Test list
- `fb_domain`: TG-040 budget = Σ planned; TG-041 rebalancing proportional; TG-042 ±25 % of each day and floor; property: no rebalancing + no intake → exact planned; Σ targets + accounted − carry = budget; fixed mode; PA7 ignores factors; D-091 name display fallbacks.
- App: migration v13→v14 converts weights (numbers equal to the old engine's), bumps HLC + version, leaves rows without shifts; actions: setDayTarget (factor, usual clears, below floor needs ack, PA7 refused), sameEveryDay undo, setBalancing; Targets screen widget tests + goldens (light/dark, text 2.0); day sheet; food names setting row; result row "Matched"; entry row name by setting.

## Progress log
- 2026-10-31: card written; WP1 started.
- 2026-10-31: WP1 committed (domain). WP2–WP4 built: actions (setDayTarget, sameEveryDay, setBalancing), v14 migration + test, new Targets screen (top card, day sheet, how sheet, more options; DS `FbSegmented`, `FbWeekBars`), food names (domain, setting row, rows, food page, "Matched"). Spec D-090/D-091, TD-112. Goldens updated (targets ×3, food search, food sheet, me settings).

- 2026-10-31: Codex review (code + UX): REQUEST CHANGES, 4 majors, 2 minors. Fixed: (1) below-floor days now need a stored per-day confirmation, others are raised to the floor; (2) the v14 step advances `hlc.last` past the HLCs it assigns; (3) `setDayTarget` recomputes the suggestion (Ramadan maintain included) and refuses `changed` when it differs from the screen's; (4) restoring a pre-A53 server version converts its weights (marker `targets.dayFactorsSinceMs`, else the A53 release day). Minor 6 fixed (how sheet ends with the active suggestion); minor 5 logged (#276, #278). No fix-check (orchestrator wrap-up: all majors fixed).

## Outcome
_2026-10-31._ Built as planned (D1–D7) plus the review fixes above.
- **Targets (D-090):** new screen: today's number, the week's total, Same every day | Different by day, tappable weekday bars (week start from settings); day sheet with − / + (50), tap to type, chips Usual / −250 / +250 / +500, the week line and Save; "How is this worked out?" sheet (steps, Recalculate with today's weight, Set my own number instead, Use the calculated target); Goal row; More options (balance switch, macro split). Per-weekday numbers are factors of the suggestion in the existing `shift_*` fields (TD-112), so adaptive updates move them along; v14 data-only migration converts old weights without changing numbers. Training-day shifting removed.
- **Food names (D-091):** setting row (own widget `FoodNamesSettingRow` in today's settings list, ready for A51's Preferences page), applied to search/recents, diary rows, quick add, saved meal items, your foods; food page shows both names and "Also called"; search says "Matched …" for an alias or the other language's name.
- **Deviations:** fat stays fixed per day (today's macro engine; only carbs follow the day), as the brief asked to keep engine semantics. Quick-add chips show one line in Both (English). Buddy cards, undo labels and some sheet titles keep English (#276). A below-floor day needs a stored confirmation (review fix) rather than being honoured implicitly.
- **Owner checks on the phone:** Targets → tap a day, try +250 and Save, then Undo; "Same every day"; More options; How is this worked out?. Me → Food names → Both / Arabic and look at search, Today and the food page.
