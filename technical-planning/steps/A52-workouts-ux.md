# A52 — Workouts UX overhaul

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A37a, A37c (merged) | L (estimate 1–1.5 days of agent time incl. one Codex fix round; actual ≈ 1 session) | Claude | ✅ closed, awaiting merge |

**Goal.** The owner, using the app daily: "The workouts page is quite hard to use"; "on logging, show the muscle map next to the exercise"; "sort the workouts by popularity"; "when a user selects a plan we should ask them to select exercises, not assume them". Sketches `WoHome`, `WoLog`, `WoPicker`, `WoPlans`, `WoPlanDay`, `MuscleMap` (`~/work/ux-sketches/project/`, approved 2026-10-31).

**Spec:** WO-001, WO-007, WO-020, WO-021, WO-023, WO-024, WO-034, WO-040 · **Decisions:** D-089 (new), D-085, TD-111 (only if needed).

## Scope
1. **Workouts tab (WoHome):** this-week strip (trained days filled, today outlined, never "missed"); today's plan card (name, first exercises, muscle map, "Log <name>" + "Something else"); a "Log a workout" card without a plan; Recent rows with a session muscle map, name, day · exercises · sets and Repeat; See all → history; one "Your plan" row (plan name + weekdays, or "No plan" → plan chooser); exercise library behind a top-bar search icon. Empty state = setup point ("Log a workout", "Choose a plan").
2. **Your plan page** (`WorkoutPlanRoute`): weekday → workout rows, the plan's workouts (templates) with edit/log, new workout, "Change plan".
3. **Log form (WoLog):** a session summary (map + muscle names + "1 of 5 exercises logged"); each card a ≈56 dp map left of the name; set rows dominant (Set | Last time | kg | Reps | ✓); untouched planned cards collapsible. Autosave, notes, menus unchanged. Maps never repaint while typing.
4. **Picker (WoPicker):** with an empty query, "Your recent" (own sessions, newest first, "last: 62.5 kg × 8") then "Most popular"; search ties broken by popularity; equipment filter.
5. **Popularity rank:** `popularity: 1..100` per exercise in `data/exercises.yaml`, through schema, contract, pipeline, pack and app (tolerant of older packs).
6. **Plans (WoPlans, WoPlanDay):** chooser ("No plan, I'll log as I go" first, Full body, Upper/Lower, PPL with mini maps and day tags, "Make my own") → weekdays → per-day tabs starting **empty** ("Your Push exercises", "Find any exercise", "Suggested for Push" with + and "Add all N"). Finish writes templates + weekday plan in one change set with one Undo. Route `WorkoutStarterPlansRoute` stays (A51's first run opens it).

## Out of scope
Rest timers (spec: none in R1), chat logging (A37b), Arabic names (R2).

## Decisions
- **D1 Popularity in the catalog.** A new required load-file field `popularity` (integer 1–100, unique, 1 = most popular), additive like A37a's `secondary_muscles` (schema_version stays 1). Pack column `exercises.popularity INTEGER NOT NULL`; the app reads it only when the attached pack has the column (older downloaded packs: no rank → library order). Custom exercises have no rank and sort after ranked ones on ties.
- **D2 Search ties.** `ExerciseSearch` keeps prefix > word prefixes > substring; ties go to the better popularity, then the candidates' order (name). An empty query lists by popularity.
- **D3 Recent exercises** (`fb_domain` `RecentExercises`): distinct exercises of the user's sessions, newest session first (history order), with that session's top set (heaviest weight, then most reps; time/cardio: the first set). At most 5 in the picker.
- **D4 Session muscles** (`fb_domain` `MuscleUnion`): primary = every exercise's main muscle; secondary = every secondary muscle that isn't primary. Names in the log header: distinct primary muscles in exercise order.
- **D5 Plans never auto-assign.** `StarterPlan.ops` takes the user's chosen items per starter template (`itemsOf`); the suggestions are the starter templates' items, shown, never added unless tapped. Each day needs at least one exercise to finish. The replace-plan question stays.
- **D6 Map performance.** `FbMuscleMap` wraps each view in a `RepaintBoundary` and marks the paint complex/static, so a log form's edits don't repaint maps; `ExerciseMuscleMap.muscles` takes sets of muscles (union maps) and a `compact` size.

## WPs
- **W1** popularity data + pipeline + pack + app read; domain search ties.
- **W2** domain: `RecentExercises`, `MuscleUnion`, `StarterPlan.ops(itemsOf:)`; tests.
- **W3** picker: recent + popular sections, equipment filter.
- **W4** Workouts tab + Your plan page + session map rows.
- **W5** log form: maps, summary header, collapse, repaint isolation.
- **W6** plan chooser + plan day editor; `applyStarterPlan` with chosen exercises.
- **W7** docs: D-089, spec edits, card, board, goldens/patrol.

## Tests
- Domain: `WO-001 search ties by popularity`, `RecentExercises` (order, top set), `MuscleUnion` (property: primary ∩ secondary = ∅), `WO-023 ops use only chosen items`.
- Catalog tool: popularity validation (range, unique, required), pack column; fixture re-pin.
- App: picker sections, Workouts tab (empty state, plan card, recent rows), plan setup flow writes one change set with undo and nothing auto-added, log summary header.

## Progress log
- 2026-10-31: card, plan, D-089 + spec edits (`ad8d64a9`).
- 2026-10-31: W1 popularity rank (100 exercises ranked by common gym use; `make catalog` → release v26; fixture re-pinned) (`7cc2835d`); W2 domain (`1ae942c0`); W3–W6 app (`282bcfce`): tab, Your plan page, log maps/summary/collapse, picker sections + equipment filter, chooser + plan setup, golden `workouts_tab`. Cross-check: catalog tests ✓, CatalogTests (server) ✓, app router/today/unit labels ✓, workouts tests ✓ (102), fb_domain workouts ✓. Next: Codex review.
- 2026-10-31: Codex review (code + UX): 0 blockers, 3 majors, 1 minor, all fixed (`a53ed2b1`); fix-check 1: 1 major (route ownership during a pending save) fixed (round 2); fix-check 2: 1 major (the chooser popped through the global router, so a tab switch during a pending write could close another tab's screen) fixed by popping its own Navigator (round 3, no further recheck: the 2-round cap; real-shell regression test → #271). `make gen-app` no diff. Backlog #268–#271.

## Outcome
- **Workouts tab** (WoHome): week card ("This week · N workouts", trained days filled, today outlined, no missed days), today's plan card (name, first exercises "+N", union muscle map, "Log Push" + "Something else"; buttons stack at large text) or a "Log a workout" card, Recent rows with session maps, day ("Today", "Yesterday", "Wed") · exercises · sets and Repeat, See all → history, one "Your plan" row (names + weekdays, or "No plan" → chooser; with templates but no plan → Your plan). Library behind the search icon. Setup point when nothing is logged and there's no plan or template: "Log a workout" / "Choose a plan" (first-visit copy keeps "Your workouts will show up here", Patrol unchanged).
- **Your plan page** (`WorkoutPlanRoute`): weekday rows, the workouts (templates) with maps, edit and Log, New template, "Choose a different plan".
- **Log form** (WoLog): session summary (union map, primary muscles "Chest · Shoulders", "1 of 5 exercises logged · 3 sets"); each card a 56 dp map, muscle group · equipment (· kg per dumbbell); untouched cards after the first untouched one start hidden ("3 sets planned"), show/hide per card. Autosave, set rows, menus unchanged. `FbMuscleMap` views are separate raster-cached layers, so edits don't repaint maps.
- **Picker** (WoPicker): "Your recent" (top set of the latest session, "last: 62.5 × 8") then "Most popular"; equipment filter; search ties by popularity.
- **Popularity**: 100 exercises ranked (1 = barbell bench press … 100 = outdoor cycling); data schema, catalog contract (additive), backend `release.json`, loader (unique, 1–100), pack column, app read tolerant of older packs; catalog release v26.
- **Plans** (WoPlans, WoPlanDay): chooser (No plan first, Full body / Upper-Lower / PPL with maps and day tags, Make my own) → weekdays sheet → day tabs that start empty, suggestions with + and "Add all N", "Find any exercise", sets × reps sheet, remove; Save plan needs one exercise per day, asks before replacing a plan, writes one change set with one Undo, keeps every choice if refused. "No plan" with a plan clears it (one Undo). `WorkoutStarterPlansRoute` unchanged for A51.

**Deviations from the sketches:** no column header row in the log (field labels stay, #269); the log keeps Done at the bottom and its title instead of name + "saved as you type" in the app bar; the week strip drops the plan initials (screen-reader text keeps planned days); "last" results use the log's "62.5 × 8" format (no "kg"); "Make my own" = one template, then Your plan (#268); no "Popular first" sort chip (always popular).

**Tests:** fb_domain `A52 D4` union (+ glados property), `A52 D3` recent exercises, `WO-001` popularity ties, `WO-023 D-089` chosen items only; catalog `WO-001` popularity validation + real ranks 1..N, pack column; app plan setup VM, picker sections, tab (plan card / no plan), log summary + collapse, plan flow (empty days, one change, Undo), refused save, tabs at 2.0, single Continue, pending save navigation, No plan clear + Undo; golden `workouts_tab` (light, dark, text 2.0).
