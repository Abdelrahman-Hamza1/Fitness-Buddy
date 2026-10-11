# S41 — Workout domain, library & templates

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P6 Workouts | S13, S14, S19 | M | ⬜ Not started |

**Goal.** The data and rules behind simple strength logging: the exercise library and custom exercises, sessions and sets by exercise type, templates and the weekly plan, PRs and e1RM, a shorthand parser, and the link to calorie shifting.

**Spec:** WO-001, WO-002, WO-003 (form), WO-004, WO-005, WO-010, WO-011, WO-020 (form + from session), WO-021, WO-031 (parser), WO-042 (domain), WO-060, WO-061, TG-043 (wiring) · **Decisions:** TD-009, TD-011

## Scope
- **Library:** built-in exercises from the catalog pack (S13 data: ≈ 100, types, equipment variants as separate exercises, EN aliases). **Custom exercises** table (name, aliases, type, equipment), created by form here (chat in S42).
- **Types** (WO-004): weight×reps, bodyweight×reps (+added), assisted, reps only, time, cardio (duration + optional distance). Per-set fields by type. **Dumbbell weight is per dumbbell** (WO-005).
- **Tables:** `workout_sessions` → `session_exercises` → `sets`, `workout_templates` (+ items with target sets×reps), `weekly_plan` (weekday → template). Change ops for each, with undo.
- **Set-notation parser** in `fb_domain` (WO-031): `3x8 80`, `3×8@80`, `80x8x3`, `8,8,7 @80`, varying weights `80x8, 85x6`, `dips +10 3x8`, kg/lb. Also used to cross-check the model (AQ-03).
- **PRs and e1RM** (WO-042): heaviest weight, best Epley e1RM, most reps at a given weight. Derived, not stored.
- **Shifting wiring** (TG-043, WO-061): the weekly plan feeds training days into the S19 engine. An unplanned logged session redistributes the rest of the week. Workouts never add calories (WO-060).
- Workout entities added to the sync registry (S26/S27).

## Out of scope
- Logging UI, chat, history and graphs (S42).

## Fixed by the plan
- Simple logging only: no RPE, tempo, rest timer or notes (NG-7).

## Decide in the low-level plan
- How a "session matches a template" is determined (for WO-022 in S42).

## Exit criteria
- [ ] Parser golden cases (≥ 40 notations) pass, including lb/kg and per-dumbbell semantics.
- [ ] PR/e1RM unit tests. Property: PRs never decrease when sessions are added.
- [ ] Shifting property tests: the weekly sum is preserved when a workout is logged on an unplanned day.
- [ ] Migration tests for the new tables.

## Read first
`spec/15-workouts.md` · `spec/13-targets-and-goals.md` §5

## Owner involvement
Share your PPL routine so templates can be seeded for testing.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
