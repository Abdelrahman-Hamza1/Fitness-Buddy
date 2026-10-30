# A37 — Workout logging, history & PRs (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A37a: A36, A15a · soft: A16; A37b: A37a, A23b, **B12** (contract) | A37a L + A37b M (split 2026-10-30) | Claude | ⬜ A37a (wave 2) · ⬜ A37b (phase 2) |

_Old ID: S42 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Log a workout after the session in one message ("push day bench 3x8 80 ohp 3x10 40…") or by a form that shows last time's numbers, then see history, per-exercise progress and PRs.

**Spec:** WO-003 (chat), WO-020 (chat), WO-022, WO-030, WO-032, WO-033, WO-034, WO-035, WO-040, WO-041, WO-042 (markers), WO-043 (data for the summary), AI-053, HM-006, IN-006 (exercise progress), AI-001 (input bar on Workouts), UX-010 (Workouts tab), J10, T34, T35 · **Decisions:** TD-009, TD-011

## Split (2026-10-30, TD-105, D-085)
- **A37a Workouts without AI** (phase 1, wave 2): everything below except the chat path, plus the owner's workout decisions (D-085, `spec/15` WO-007, WO-012, WO-023, WO-024):
  - **Muscle map** on every exercise page and in the picker (front/back, main dark, secondary lighter), drawn by us from an MIT-licensed body outline (e.g. the react-native-body-highlighter / Flutter muscle_mapper lineage; check the licence and keep the notice). **Never ship the free-exercise-db photos** (scraped). Needs **secondary muscles** in `data/exercises.yaml` (today only `primary_muscle`) and on custom exercises (backlog #217).
  - **No plan required:** log by picking exercises; sessions auto-named from muscles ("Chest & triceps"); **Repeat** any past session; week view shows trained days only; never a "missed day" message.
  - **Starter plans** gallery (Full body 3, Upper/Lower 4, Push/Pull/Legs 3–6, Build my own): picking one copies editable templates + weekdays.
  - Form logging after the session, **saves as you type**; working sets only; kg.
  - Today row only on planned days or after logging ("Push ✓ · 5 exercises · 1 PR"); nothing for no-plan users until they log (HM-006).
  - Exercise page: main line = heaviest set, e1RM a toggle. Calorie shifting stays off by default.
  - Muscle fields on custom exercises go into the sync contract with B21.
- **A37b Workout logging by chat** (phase 2): the chat path (WO-030, WO-032, WO-033 by chat, AI-053, T34, T35) on B12's contract, the workout proposal card, and "Same as last push but bench 82.5".

## Scope
- **Workouts tab:** the plan for today, recent sessions, templates, exercises, and the input bar (AI-001).
- **Custom exercise form** (name, aliases, type, equipment; create and edit) on A36's operations (moved from A36 by TD-078).
- **Form logging** (WO-034): pick a template or an empty session → each exercise shows **last session's numbers** next to the inputs → enter/adjust sets → save (a direct action with undo). Cardio by form (WO-035).
- **Chat logging** (WO-030, AI-053): a `Workout` intent (B12's contract and prompt; the app sends custom exercises in the context) → **workout proposal card** with exercises matched to the library, sets, and assumption chips ("'ohp' → Overhead press (barbell)"), with the same inline editing as food cards. The parser cross-checks the model's sets. **"Same as last push but bench 82.5"** (WO-032, T35). An unknown exercise → pick the closest or create a custom one (WO-033).
- **Template update offer** (WO-022): after a session that differs from its template → "Update the Push template?" (a proposal).
- **History** (WO-040): a list by date with summaries. **Exercise page** (WO-041): past sessions + a graph of top-set weight and e1RM (chart wrappers from A15).
- **PR markers** (WO-042): a plain marker on the logged-workout card and in history (no celebration screens).
- **Today hint** (HM-006): "Push day today" only with a weekly plan. A tap opens form logging with that template.
- Progress tab entry to exercise progress (IN-006).

## Out of scope
- The weekly workout summary display (A39). The workout reminder (A40).

## Fixed by the plan
- Chat-logged workouts are proposals. Form-logged ones are direct actions (D-079).

## Decide in the low-level plan
- The form layout for fast set entry on a phone.

## Exit criteria
- [ ] **J10, T34, T35** pass E2E with recorded fixtures (the eval is B12's). Dumbbell weight is read per dumbbell.
- [ ] The form shows last session's numbers per exercise (widget test).
- [ ] The template-update offer appears only when the session differs (test).
- [ ] Goldens: workout card, form, history, exercise page.

## Read first
`spec/15-workouts.md` · `spec/01-personas-and-journeys.md` J10 · `06-buddy-ai.md` §8

## Owner involvement
Log your real sessions for a week (A37a). The PPL routine is no longer needed: start from the PPL starter plan or just log (backlog #190 closed).

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: split into a/b (TD-105, owner).

## Outcome
_Written in Phase E._
