# S10 — Spike: AI bake-off & eval harness v0

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S03, S08 | L | ⬜ Not started |

**Goal.** Decide the AI provider and model (TD-008) **on evidence**: quality on the owner's kind of messages (English, Arabic, Arabizi, mixed), latency from the region, and cost. The tools built here (the `ILlmClient` port, the interpret prompt v0, `buddy_eval` v0) become the base of S31.

**Spec:** AI-010, AI-016, AQ-02, AQ-03, AQ-06, AQ-07, AQ-11 (reported), AQ-12 (measured) · **Decisions:** TD-008, TD-009, D-080

## Scope
- **Buddy module skeleton** (backend): the `ILlmClient` port (structured output via JSON schema, timeout, token/cost accounting) + adapters for **Anthropic**, **OpenAI** and **Google**. A routing config (task → provider/model/effort).
- **Interpret prompt v0** + an **internal** JSON schema covering `FoodLog` (mentions, canonical EN name, AR name, amount/unit, state, fat, variant/portion dimensions detected, share, time/slot hints), `WeighIn`, `Workout`, `Clarify`, `OutOfScope`, plus language/script detection.
- A dev-only endpoint (or CLI entry point) to run the parse. **Not** the public contract yet (S31 defines that).
- **`tools/buddy_eval` v0** (Dart): case YAML format, ≈ **60 cases** (the parse-relevant T01–T41 + ≈ 20 Arabic/Arabizi messages in the owner's style), a runner calling the backend, deterministic graders for parse-level metrics: foods identified (canonical names), amounts/units read, ambiguity dimensions detected when designed ambiguous / not when unambiguous, language detection. Latency and cost per call.
- **Matrix:** 2–3 models × 1–2 reasoning-effort settings, with prompt caching on.
- **Latency from the owner's network:** a small script the owner runs from home (p50/p90 to each provider via the local backend), plus the same from the staging VM if S05 is done.
- **Report:** `tools/buddy_eval/reports/S10-bakeoff.md`, with per-model scores by language, p50/p90 latency, $/message, observations, and the recommendation.

## Out of scope
- The resolver against the real catalog (S30/S31), the ProposalEngine (S32), the public interpret contract (S31). Vision/labels (measured later in S38 with the same harness).

## Fixed by the plan
- AI interprets, code computes. The model never produces nutrition numbers except the labelled estimate fallback (`06` §1, §4).
- No identity in prompts (AC-041).

## Decide in the low-level plan
- Official SDK vs plain REST per provider (official `Anthropic` NuGet is beta. Weigh stability).
- The exact candidate models available at the time (re-check prices and model IDs).
- Grader tolerances (e.g. canonical-name matching rules).

## Exit criteria
- [ ] All three adapters pass the same `ILlmClient` contract test suite (recorded fixtures).
- [ ] `make eval` runs the 60 cases against a chosen model and writes the report.
- [ ] The bake-off report covers every candidate, with per-language breakdowns and latency measured **from the owner's network**.
- [ ] **TD-008 decided** in `12-decisions-and-questions.md`: the primary model per task + a fallback, with numbers.
- [ ] The prompt v0 + schema are committed and versioned.

## Read first
`06-buddy-ai.md` (all) · `spec/40-acceptance-criteria.md` §2–3 · `spec/10-ai-assistant.md` §2–3

## Owner involvement
API keys with spend caps for the three providers. Run the latency script from home (~10 min). Optionally add 5–10 real messages in your own style.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
