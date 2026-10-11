# S40 — Q&A, suggestions & halal

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P5 Buddy breadth | S36 | M | ⬜ Not started |

**Goal.** Ask Buddy about your own data and get **exact, computed** answers. Ask what to eat and get options that really fit, halal when the setting is on. This closes Phase 5. **Milestone: Dogfood 2.**

**Spec:** AI-002 (the full Buddy scope is complete at this point), AI-049, AI-110, AI-111, AI-112, AI-120, AI-121, AI-122, FD-082, AQ-09, T36, T37, T38, T39 · **Decisions:** TD-009, TD-032

## Scope
- **`Question` intent** with a **QueryPlan** from a closed grammar + an answer template + an optional link (`06` §6). Contract + prompt + eval.
- **`QueryEngine`** in `fb_domain`: executes plans on local data (metrics: kcal, macros, fiber, weight trend, weigh-ins, workouts, exercise last date/PR, ranges, "since Ramadan/phase start"). Fills the template. "Can't tell from your data" when a plan can't run (AI-111). Tappable links to charts/days (AI-112). Answers need no confirmation (AI-049).
- **Suggestions** (AI-120–122): the `SuggestRequest` intent → `POST /v1/buddy/suggest` with remaining kcal/protein, halal flag, time/Ramadan phase, habitual foods (user model), open batches → 2–4 options → the API resolves names to catalog items → the client computes real numbers and **drops options that don't fit** → tappable suggestions → tapping creates a normal proposal.
- **Halal in suggestions** (FD-082): halal-only options when the setting is on (catalog flags + instruction + a client check).
- **Multi-intent check** (T39): one message → several proposals and/or answers in one reply.
- **Phase 5 acceptance run:** eval + E2E for T17–T29, T33, T36–T38. OF-02. **AT-003 green** (with D6).

## Out of scope
- The weekly review (S44). Workout questions need workout data (S41/S42). The grammar includes them now and they're tested again after S42.

## Fixed by the plan
- Numbers in answers come only from the QueryEngine (AQ-09 = 100%).

## Decide in the low-level plan
- The QueryPlan grammar version 1 (metrics × ops × periods) and how unknown plans degrade.

## Exit criteria
- [ ] **AQ-09 = 100%** on the Q&A cases (T36, T38 + ≥ 20 more incl. AR/Arabizi questions).
- [ ] T37: suggestions all fit the remaining kcal/protein, and are halal with the setting on (property test over the client filter).
- [ ] T39 passes.
- [ ] **Phase 5 exit:** T17–T29, T33, T36–T38 meet the thresholds. OF-02 passes. AT-003 green.
- [ ] **Dogfood 2:** the owner logs mostly through Buddy for a week. Discarded/edited proposals are exported as new eval cases.

## Read first
`06-buddy-ai.md` §6–7 · `spec/10-ai-assistant.md` §10–11

## Owner involvement
A week of Buddy-first logging. Export the misses.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
