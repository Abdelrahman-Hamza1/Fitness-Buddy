# 15 — Workouts

_Status: **Draft v1** · 2026-10-10, amended 2026-10-30 · Main decisions: D-028 to D-030, D-040, D-057, D-058, D-079, D-080, D-085._

Scope: **simple strength logging, usually entered after the session** (D-028). Built for the owner's PPL routine 3–4×/week **and for people who train without a plan** (D-085): a plan is never required. Out of scope: RPE/RIR, tempo, periodization, rest timer, notes (NG-7, D-057), and in R1 warm-up sets, supersets and drop sets (D-085).

## 1. Exercise library (D-029)

- **WO-001** `[R1]` A built-in list of ~100 common gym exercises (names, aliases and muscles: no videos, photos or instructions), each with English names and aliases ("bench", "flat bench", "BB bench"). Buddy still understands Arabic names ("بنش") through the AI (AI-010). Each built-in exercise has a curated **popularity rank**: the picker lists "Your recent" (with the last result) then "Most popular" before anything is typed, and search breaks ties by popularity (D-089).
- **WO-007** `[R1]` Every exercise, built-in and custom, shows a **muscle map** (D-085): front and back body, main muscles dark, secondary muscles lighter. Drawn by us from an MIT-licensed body outline; no photos. The log form shows each exercise's map next to its name, and the session's combined map and muscles at the top (D-089).
- **WO-006** `[R2]` The built-in exercises also have Arabic names, for the Arabic interface (D-080).
- **WO-002** `[R1]` Equipment variants are **separate exercises** (barbell bench press ≠ dumbbell bench press ≠ machine chest press), so history and PRs stay meaningful.
- **WO-003** `[R1]` Custom exercises can be added by form or chat ("add exercise: cable fly low to high"), with their main and secondary muscles for the muscle map (WO-007).
- **WO-004** `[R1]` Each exercise has a **type**, which decides which fields are logged:

| Type | Logged per set | Examples |
|---|---|---|
| Weight × reps | weight, reps | bench press, squat |
| Bodyweight × reps (+ optional added weight) | reps, added kg | pull-ups, dips |
| Assisted | reps, assistance kg | assisted pull-up machine |
| Reps only | reps | push-ups |
| Time | duration | plank |
| Cardio | duration, optional distance | treadmill, cycling, walking |

- **WO-005** `[R1]` Dumbbell exercises record **weight per dumbbell** (the usual gym convention), and the app says so in the input field.

## 2. Sessions

- **WO-010** `[R1]` A session has: date, optional name (e.g. "Push"), optional start time and duration, and a list of exercises, each with sets. Without a name, it's named from its main muscles ("Chest & triceps", D-085).
- **WO-012** `[R1]` Only **working sets** are logged: no warm-up sets, supersets or drop sets in R1. Weights are in **kg**; lb typed to Buddy is converted (D-085).
- **WO-011** `[R1]` Sessions can be logged for any past date ("yesterday push day").

## 3. Routine templates & weekly plan

- **WO-020** `[R1]` Templates: a named exercise list with target sets × reps (e.g. "Push: bench 3×8, OHP 3×10, incline DB 3×10, lateral raise 3×15, triceps pushdown 3×12"). Created by form, by chat, or from any logged session ("save as template").
- **WO-021** `[R1]` **Weekly plan** (optional, never required, D-085): which template on which weekdays (e.g. Sat Push, Sun Pull, Tue Legs, Wed Push). Used for the Today screen hint ("Push day today") and for calorie shifting (TG-043).
- **WO-023** `[R1]` **Starter plans** (D-085): an optional gallery (Full body 3 days, Upper/Lower 4, Push/Pull/Legs 3–6, Build my own). Picking one asks for the weekdays, then shows each workout day **empty** with suggested exercises to add (one by one or all): the app never assumes the exercises (D-089). Finishing saves the templates and weekdays in one change with Undo; nothing changes before that.
- **WO-024** `[R1]` **No-plan training is first-class** (D-085): log by picking exercises or telling Buddy, **Repeat** any past session, the week view shows only trained days, and the app never shows "missed day" messages. The Workouts tab puts today's action first (today's plan card or "Log a workout", recent sessions with Repeat, one "Your plan" row); with nothing logged and no plan it is the setup point (D-089).
- **WO-022** `[R1]` Templates are updated only when the user chooses: after a session that differs from its template, the app offers "update the Push template with these changes?" (a proposal).

## 4. Logging

- **WO-030** `[R1]` **By chat** (main path): "push day bench 3x8 80 ohp 3x10 40 dips 3x12" → workout **proposal card** (D-079) showing each exercise matched to the library, its sets, and any assumptions (e.g. "matched 'ohp' → Overhead press (barbell)"). The same inline editing as food proposals (AI-040 to AI-044).
- **WO-031** `[R1]` Shorthand understood: `3x8 80`, `3×8@80`, `80x8x3`, `8,8,7 @80`, varying weights (`80x8, 85x6, 85x5`), bodyweight with load (`dips +10 3x8`), lb/kg units.
- **WO-032** `[R1]` "Same as last push day but bench 82.5" → proposal copying the last session with that template, with the change applied.
- **WO-033** `[R1]` Unknown exercise → Buddy asks: pick the closest match, or create a custom exercise.
- **WO-034** `[R1]` **By form** (the main way, after the session): pick exercises, a template, or **Repeat** a past session → each exercise shows **last session's numbers** next to the input → enter or adjust sets. The form **saves as you type** (a direct action with undo, D-085).
- **WO-035** `[R1]` Cardio is logged the same way, by chat ("30 min treadmill incline walk") or form (D-030). No GPS, no imports.

## 5. History & progress

- **WO-040** `[R1]` Workout history list (by date) with session summaries.
- **WO-041** `[R1]` Per-exercise page: past sessions, the muscle map, plus a graph whose main line is the **heaviest set**; **estimated 1-rep max** (Epley formula) is a toggle (D-085).
- **WO-042** `[R1]` **Personal records** per exercise: heaviest weight, best estimated 1RM, most reps at a given weight. A new PR is marked on the logged-workout card and in the weekly review. It's a plain marker, not a badge or celebration screen (D-033).
- **WO-043** `[R1]` Weekly workout summary (sessions done, vs. planned only when there's a plan; PRs) feeds the weekly summary and review (`16`, AI-130).

## 6. Module visibility

- **WO-050** `[R2]` Users who don't train can hide the Workouts module entirely (tab, Today hint, review section).

## 7. Relation to nutrition (D-021, D-058)

- **WO-060** `[R1]` Workouts never add calories to the food budget.
- **WO-061** `[R1]` If calorie shifting is on (TG-043), planned training days get their bigger share of the weekly budget, and an unplanned logged workout redistributes the rest of the week.

## Open questions

None currently.
