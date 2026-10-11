# 15 — Workouts

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-028 to D-030, D-040, D-057, D-058, D-079, D-080._

Scope: **simple strength logging, usually entered after the session** (D-028). Built for the owner's PPL routine 3–4×/week. Out of scope: RPE/RIR, tempo, periodization, rest timer, notes (NG-7, D-057).

## 1. Exercise library (D-029)

- **WO-001** `[R1]` A built-in list of ~100 common gym exercises (names only: no videos or instructions), each with English names and aliases ("bench", "flat bench", "BB bench"). Buddy still understands Arabic names ("بنش") through the AI (AI-010).
- **WO-006** `[R2]` The built-in exercises also have Arabic names, for the Arabic interface (D-080).
- **WO-002** `[R1]` Equipment variants are **separate exercises** (barbell bench press ≠ dumbbell bench press ≠ machine chest press), so history and PRs stay meaningful.
- **WO-003** `[R1]` Custom exercises can be added by form or chat ("add exercise: cable fly low to high").
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

- **WO-010** `[R1]` A session has: date, optional name (e.g. "Push"), optional start time and duration, and a list of exercises, each with sets.
- **WO-011** `[R1]` Sessions can be logged for any past date ("yesterday push day").

## 3. Routine templates & weekly plan

- **WO-020** `[R1]` Templates: a named exercise list with target sets × reps (e.g. "Push: bench 3×8, OHP 3×10, incline DB 3×10, lateral raise 3×15, triceps pushdown 3×12"). Created by form, by chat, or from any logged session ("save as template").
- **WO-021** `[R1]` **Weekly plan** (optional): which template on which weekdays (e.g. Sat Push, Sun Pull, Tue Legs, Wed Push). Used for the Today screen hint ("Push day today") and for calorie shifting (TG-043).
- **WO-022** `[R1]` Templates are updated only when the user chooses: after a session that differs from its template, the app offers "update the Push template with these changes?" (a proposal).

## 4. Logging

- **WO-030** `[R1]` **By chat** (main path): "push day bench 3x8 80 ohp 3x10 40 dips 3x12" → workout **proposal card** (D-079) showing each exercise matched to the library, its sets, and any assumptions (e.g. "matched 'ohp' → Overhead press (barbell)"). The same inline editing as food proposals (AI-040 to AI-044).
- **WO-031** `[R1]` Shorthand understood: `3x8 80`, `3×8@80`, `80x8x3`, `8,8,7 @80`, varying weights (`80x8, 85x6, 85x5`), bodyweight with load (`dips +10 3x8`), lb/kg units.
- **WO-032** `[R1]` "Same as last push day but bench 82.5" → proposal copying the last session with that template, with the change applied.
- **WO-033** `[R1]` Unknown exercise → Buddy asks: pick the closest match, or create a custom exercise.
- **WO-034** `[R1]` **By form**: pick a template (or empty session) → each exercise shows **last session's numbers** next to the input → enter or adjust sets → save (a direct action, applies immediately with undo).
- **WO-035** `[R1]` Cardio is logged the same way, by chat ("30 min treadmill incline walk") or form (D-030). No GPS, no imports.

## 5. History & progress

- **WO-040** `[R1]` Workout history list (by date) with session summaries.
- **WO-041** `[R1]` Per-exercise page: past sessions, plus a graph of **top set weight** and **estimated 1-rep max** (Epley formula) over time.
- **WO-042** `[R1]` **Personal records** per exercise: heaviest weight, best estimated 1RM, most reps at a given weight. A new PR is marked on the logged-workout card and in the weekly review. It's a plain marker, not a badge or celebration screen (D-033).
- **WO-043** `[R1]` Weekly workout summary (sessions done vs. planned, PRs) feeds the weekly summary and review (`16`, AI-130).

## 6. Module visibility

- **WO-050** `[R2]` Users who don't train can hide the Workouts module entirely (tab, Today hint, review section).

## 7. Relation to nutrition (D-021, D-058)

- **WO-060** `[R1]` Workouts never add calories to the food budget.
- **WO-061** `[R1]` If calorie shifting is on (TG-043), planned training days get their bigger share of the weekly budget, and an unplanned logged workout redistributes the rest of the week.

## Open questions

None currently.
