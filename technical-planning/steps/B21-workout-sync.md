# B21 — Workout sync entities (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B05 ✅, B20, **A36** ✅ | M | Claude | ⬜ Not started |

_New step (owner, 2026-10-30; backlog #189, A36 D6). Phase 1, wave 2 (TD-105). Tier: Risky (user-data admission). **A34 depends on B21.**_

**Goal.** The server admits, stores, serves and erases the workout entities, so A34 can upload workouts instead of leaving them queued.

**Spec:** WO-003, WO-010, WO-020, WO-021 (data that syncs), AC-010, AC-012, AC-031 · **Decisions:** TD-031, TD-080

## Scope
- Contract first: add `customExercise`, `workoutSession`, `sessionExercise`, `workoutSet`, `workoutTemplate`, `workoutTemplateItem`, `weeklyPlanDay` to the sync registry, matching A36's tables (A36 D6, D7) and any muscle fields A37a adds.
- Server admission: schema plus the wire rules the app applies on write (per-type set fields, ownership inside an aggregate).
- Storage, pull/history, account deletion coverage, Testcontainers tests, a Dart-generated corpus with app parity (like B19/B20).

## Out of scope
- The app upload (A34). Workout chat (B12).

## Exit criteria
- [ ] Contract conformance green; the Dart client regenerated.
- [ ] Admission tests reject rule-breaking rows; deletion erases every workout row.
- [ ] Security review recorded (Risky).

## Read first
A36 card (D6, D7) · B20 card (same pattern) · `contracts/README.md` · backlog #189

## Owner involvement
None.

## A37a handoff (2026-10-30, A37a low-level plan D6, §9)
- `customExercise` gains **`primaryMuscle`** (string or null; one of the 15 codes `chest`, `shoulders`, `biceps`, `triceps`, `forearms`, `traps`, `upper_back`, `lower_back`, `abs`, `obliques`, `quadriceps`, `hamstrings`, `glutes`, `calves`, `adductors`) and **`secondaryMuscles`** (array of at most 4 distinct codes from the same list, never containing `primaryMuscle`; empty allowed).
- App columns (schema v11, A37a): `custom_exercises.primary_muscle` (nullable) and `custom_exercises.secondary_muscles_json` (JSON array, default `[]`).
- Server admission rejects codes outside the list (the app never writes others). `primaryMuscle` stays nullable (custom rows created before v11 have none).
- A37a D25: a session's removed children (session exercises, sets) can be **revived with the same ID**; they arrive as ordinary updates with `deleted` false, so admission must accept an update that clears a tombstone of the same aggregate.

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).
- 2026-10-30: A37a handoff added (custom-exercise muscle fields, child revival).

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._
