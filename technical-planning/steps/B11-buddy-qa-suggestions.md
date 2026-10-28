# B11 — Buddy Q&A & suggestions

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B08 | M | Claude (TD-085) | ⬜ Not started |

_Old ID: S40 server part (renumbered by TD-063, 2026-10-16). The app side is A31._

**Goal.** Buddy turns questions about the user's own data into query plans the phone executes exactly, and proposes meal options that the phone then checks against real numbers.

**Spec:** AI-110, AI-111, AI-120, AI-121, AI-122, FD-082 (instruction side), AQ-09, T36–T39 · **Decisions:** TD-009, TD-032

## Scope
- **Contract first:** the `Question` intent with a **QueryPlan** from a closed grammar + an answer template + an optional link (`06` §6); `POST /v1/buddy/suggest` (remaining kcal/protein, halal flag, time/Ramadan phase, habitual foods, open batches → 2–4 options resolved to catalog items). Multi-intent replies (T39).
- Prompts, validation (plans outside the grammar are rejected and repaired once), resolver use for suggestion names, halal flags from the catalog.
- **Eval:** AQ-09 cases (T36, T38 + ≥ 20 more incl. AR/Arabizi), T37 server half, T39. The M4 eval half.

## Out of scope
- The QueryEngine, the client-side fit filter and the UI (A31). Workout questions are tested again after B12/A37.

## Exit criteria
- [ ] Contract conformance green; the Dart client regenerated.
- [ ] Every QueryPlan the eval produces is valid in the grammar, and matches the expected plan on the Q&A cases (grader on plans). (AQ-09 = 100% on executed answers is A31's exit and B15's final run.)
- [ ] Suggestions always resolve to catalog items or are dropped (test). T39 passes.

## Read first
`06-buddy-ai.md` §6 · `spec/10-ai-assistant.md` §8–9 · B08 Outcome

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
