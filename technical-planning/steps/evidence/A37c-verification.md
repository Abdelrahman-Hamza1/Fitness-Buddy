# A37c verification (2026-10-30)

Tier **Risky** (atomic multi-op change sets, template updates on the user-data write path). Built by the flutter-engineer in lane 6 (commits `cb97821`, `b879504f`, `903d0ca`, `a745fd9`, outcome draft `e33fc66`, review fixes `2c25d3c`), stacked on A37a `7f6c96b`. This records local evidence. **CI evidence comes from the merge run (TD-108).**

## Exit criteria -> evidence -> status

| Exit criterion (card section 6) | Tests | Status |
|---|---|---|
| Muscle map on the exercise page, picker and custom form; licence notice in About -> Licences | `fb_design_system/test/components/muscle_map_test.dart`: `WO-007 every body region has paths on at least one view, and ...`, `WO-007 muscle map paints primary and secondary regions`, `WO-007 no primary muscle shows the neutral body (RTL, dark)`; `components/license_page_test.dart`: `WO-007 the licence registry carries the muscle map outline MIT ...`; app `exercise_muscle_map_test.dart`: `WO-007 every muscle maps to at least one body region`; `exercise_picker_screens_test.dart`: `WO-003 WO-007 custom exercise form creates an exercise with muscles, map live`; screenshots below | Met locally |
| Exercise page: graph (heaviest set, e1RM toggle), PR tiles, history; reachable from the Workouts tab and Progress | `fb_domain/test/workouts/exercise_progress_test.dart`: `WO-041 heaviest-set series per session; e1RM series by Epley`, `WO-041 reps-only and cardio series use best reps / longest`; `exercise_screen_test.dart`: `WO-041 exercise page toggles e1RM`; `app_router_test.dart`: `WorkoutExercisesRoute`, `WorkoutExerciseRoute`, `ProgressExercisesRoute`, `ProgressExerciseRoute` cases; `progress_screen` golden regenerated (Progress entry row) | Met locally |
| Starter plans copy editable templates + weekdays in one atomic, undoable change set (create, rollback, replace + undo) | `starter_plans_test.dart`: `WO-023 starter plan exercises all exist in data/exercises.yaml`, `WO-023 PPL cycles over 3-6 picked days`, `WO-023 a starter plan is templates then all seven plan days`; `starter_plan_test.dart` (real applier): `WO-023 applying a starter plan creates templates and assigns them in ...`, `WO-023 a rejected op in the starter-plan set leaves no templates and ...`, `WO-023 replacing an existing plan, then Undo, restores the previous ...`; `plan_screens_test.dart`: `WO-023 gallery applies Full body with chosen days`, `WO-020 template editor saves a template`, `WO-021 weekly plan sets a weekday template`; `WO-020 save as template uses targets from the session` | Met locally |
| Template-update offer only when the session differs | `template_update_test.dart`: `WO-022 the offer content exists only when the session differs from ...` (+ differs cases); controller: `WO-022 offer appears only when the session differs from its ...`, `WO-022 offer is absent for sessions without a template`, `WO-022 Update writes the template with undo`; widget: `WO-022 Update writes the template; its Undo also undoes the ...`, `WO-022 a refused Update keeps the workout Undo`, `WO-022 Not now leaves the template and keeps the workout ...` | Met locally |
| Today row on planned days; week strip never shows a missed day | controller/screen: `WO-024 past planned days without a session render like rest days`, `HM-006 planned branch shows today's template only for today or later`, `WO-020 a template starts the form with its exercises, set counts ...`; `WO-043 weekly summary counts sessions, planned only with a plan, and ...` (data for A39a) | Met locally |
| Codex review(s) recorded here | Section below | Done |

## Review fix tests (2c25d3c, 6 tests)

- `WO-022 edits during the template lookup on exit are ignored, never ...` (lookup freeze).
- `WO-020 Save as template writes a pending autosave first`.
- `WO-020 a storage failure in Save or Delete keeps the inputs and lets ...` (template editor leaves "saving").
- Widget: `WO-022 Update writes the template; its Undo also undoes the ...`, `WO-022 a refused Update keeps the workout Undo`, `WO-022 Not now leaves the template and keeps the workout ...` (session Undo kept after every offer outcome).

## Reviews

One combined Codex review (code, UX and security) on `7f6c96b..e33fc66`, then one focused fix-check. Metrics: **1 review round + 1 fix-check; findings 0 blocker, 2 major, 2 minor; all fixed.**

| # | Severity | Finding | Fix (`2c25d3c`) |
|---|---|---|---|
| 1 | major | Updating the template discarded the session Undo | Every offer outcome keeps it; Update gives one snackbar whose Undo reverts the template update then the visit (`showUndoFeedback(thenUndoEntryIds:)`) |
| 2 | major | The template lookup on exit could lose edits | The form freezes before the lookup (`_closing`); the offer derives from the final saved session |
| 3 | minor | "Save as template" used the stale last-saved state | Pending autosaves are written first (`templateSource()`, null on conflict/failure) |
| 4 | minor | Template editor stayed in "saving" after a storage exception | `saving` reset in `finally`; content-free failure result |

Fix-check: **APPROVE**, no new findings. Codex also confirmed the bundled MIT attribution for the body outline matches upstream. Nonblocking suggestion (tests for lookup exceptions, combined-Undo conflict/expiry, `templateSource()` failure/conflict) is backlog #221.

## Tests

32 added: 26 in the work packages (fb_design_system 4, fb_domain 8, app 14; router, picker and custom-form tests extended) + 6 in the review fixes. Run locally one file at a time through `heavy.sh`, all green; `make check-dart` before every commit. No committed golden for the muscle map (TD-104): smoke test plus screenshots.

## Screenshots

- Light: [A37c-muscle-map-light.png](A37c-muscle-map-light.png)
- Dark: [A37c-muscle-map-dark.png](A37c-muscle-map-dark.png)

## CI

Not claimed here. The merge run (`tools/scripts/merge-step.sh`) supplies full-suite evidence on the exact merge commit (TD-108).
