# B12 — Buddy workouts, weekly review & Ramadan

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B08 | M | Claude (TD-085) | ⬜ Not started |

_Old ID: S42, S44 and S46 server parts (renumbered by TD-063, 2026-10-16). The app sides are A37, A39 and A41._

**Goal.** The last Buddy capabilities on the server: workouts in one message, a short kind weekly review from aggregates, and Ramadan-aware suggestions.

**Spec:** WO-030, WO-032, WO-033 (interpretation side), AI-053, AI-130, AI-131, AI-120 (Ramadan context), SF-020, T30–T32, T34, T35 · **Decisions:** TD-009, TD-030

## Scope
- **Contract first** (one commit per group, Progress-log line each): the `Workout` intent (exercises matched to the library, sets, assumption notes; "same as last push but …", T35), the custom-exercise context; `POST /v1/buddy/review` (aggregates only in, ≤ 2 short observations out); the Ramadan phase in the suggestion context.
- Prompts: the exercise library in the cached prefix; the review prompt (factual, kind, < 30 s to read) + EN fallback templates; Ramadan suggestion guidance (suhoor-appropriate, iftar staples).
- **Eval:** T34, T35 (+ the parser cross-check), ≥ 10 synthetic weeks for the review (every number in the text exists in the aggregates, checked by an eval grader; no banned words; length; tone scored by a model judge, reported), T30–T32.

## Out of scope
- The workout UI, NumberGuard, Ramadan calendar and slots (A37, A39, A41).

## Exit criteria
- [ ] Contract conformance green; the Dart client regenerated.
- [ ] T30–T32, T34, T35 meet their thresholds. The review eval passes the number grader and the banned-word check. (The app's NumberGuard is A39's exit.)
- [ ] The review request carries aggregates only (a test fails on any diary text or identity).

## Read first
`06-buddy-ai.md` · `spec/15-workouts.md` · `spec/16-insights-and-home.md` §3 · `spec/18-localization-and-culture.md` (Ramadan) · B08 Outcome

## Owner involvement
None. Tone feedback comes with A39.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
