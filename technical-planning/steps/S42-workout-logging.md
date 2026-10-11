# S42 — Workout logging, history & PRs

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P6 Workouts | S34, S41 | L | ⬜ Not started |

**Goal.** Log a workout after the session in one message ("push day bench 3x8 80 ohp 3x10 40…") or by a form that shows last time's numbers, then see history, per-exercise progress and PRs.

**Spec:** WO-003 (chat), WO-020 (chat), WO-022, WO-030, WO-032, WO-033, WO-034, WO-035, WO-040, WO-041, WO-042 (markers), WO-043 (data for the summary), AI-053, HM-006, IN-006 (exercise progress), AI-001 (input bar on Workouts), UX-010 (Workouts tab), J10, T34, T35 · **Decisions:** TD-009, TD-011

## Scope
- **Workouts tab:** the plan for today, recent sessions, templates, exercises, and the input bar (AI-001).
- **Form logging** (WO-034): pick a template or an empty session → each exercise shows **last session's numbers** next to the inputs → enter/adjust sets → save (a direct action with undo). Cardio by form (WO-035).
- **Chat logging** (WO-030, AI-053): a `Workout` intent (contract + prompt with the exercise library in the cached prefix + custom exercises in context) → **workout proposal card** with exercises matched to the library, sets, and assumption chips ("'ohp' → Overhead press (barbell)"), with the same inline editing as food cards. The parser cross-checks the model's sets. **"Same as last push but bench 82.5"** (WO-032, T35). An unknown exercise → pick the closest or create a custom one (WO-033).
- **Template update offer** (WO-022): after a session that differs from its template → "Update the Push template?" (a proposal).
- **History** (WO-040): a list by date with summaries. **Exercise page** (WO-041): past sessions + a graph of top-set weight and e1RM (chart wrappers from S22).
- **PR markers** (WO-042): a plain marker on the logged-workout card and in history (no celebration screens).
- **Today hint** (HM-006): "Push day today" only with a weekly plan. A tap opens form logging with that template.
- Progress tab entry to exercise progress (IN-006).

## Out of scope
- The weekly workout summary display (S44). The workout reminder (S45).

## Fixed by the plan
- Chat-logged workouts are proposals. Form-logged ones are direct actions (D-079).

## Decide in the low-level plan
- The form layout for fast set entry on a phone.

## Exit criteria
- [ ] **J10, T34, T35** pass (eval + E2E). Dumbbell weight is read per dumbbell.
- [ ] The form shows last session's numbers per exercise (widget test).
- [ ] The template-update offer appears only when the session differs (test).
- [ ] Goldens: workout card, form, history, exercise page.

## Read first
`spec/15-workouts.md` · `spec/01-personas-and-journeys.md` J10 · `06-buddy-ai.md` §8

## Owner involvement
Log your real sessions for a week.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
