# S31 — Buddy interpret service

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P4 Buddy core | S10, S30 | L | ⬜ Not started |

**Goal.** The production `POST /v1/buddy/interpret`: turns a message plus minimal context into typed, validated intents whose food items carry real catalog matches, alternatives and ambiguity dimensions. It's fast, cheap, private and measured by the eval suite in CI.

**Spec:** AI-010, LC-001, LC-006, AI-015, AI-016, AI-020, AI-021, AI-022, AI-023 (interpretation side), AI-070, AI-071, AI-072, AI-151 (estimate fallback), AI-003/SF-030 (intents), AC-041, AC-042, MN-005, AQ-02, AQ-03, AQ-10, AQ-12 · **Decisions:** TD-008, TD-009, TD-030

## Scope
- **Public contract** (`04` §4.3, `06` §3): `InterpretRequest`, `Interpretation` with the intents `FoodLog`, `Clarify`, `OutOfScope`, `Medical` (others are added by their steps), `FoodItem` with `match`, `alternatives` (≤ 3, distinct), `amount`, `share`, `dimensions`, `estimate`. Detected language/script on each intent.
- **Pipeline:** validate + bound the context (limits per list) → prompt (registry v1, versioned files, cached prefix) → `ILlmClient` per the routing table (the S10 winner + fallback) → **JSON-schema validation + one repair retry** → **resolver** (personal candidates from the request first, then `IFoodResolver`: catalog → reference dishes) → AI estimate with a range only when nothing matches (badged) → map to public DTOs.
- **Optional rerank call** behind a flag (enabled only if the eval shows a gain).
- **Idempotency:** `Idempotency-Key` = message ID, so no double billing on retries.
- **Usage module (minimal):** per-user daily counters + per-model token/cost metrics. Fair-use limits are R2 (MN-020).
- **Privacy:** no identity in prompts, **no content in logs**, request size limits, image path stubbed for S39.
- **Rate limits** per user (anonymous allowed with tighter limits).
- **`buddy_eval` upgraded:** runs the public endpoint, and the **`eval` CI workflow** with thresholds on the P4 cases (parse-level metrics now, full AQ metrics once S32 lands).

## Out of scope
- The ProposalEngine (S32), UI (S33), other intents (S35–S42), vision (S38/S39).

## Fixed by the plan
- The model never produces numbers except the labelled estimate fallback. Interpretation responses have no write semantics (`03` §5.3).

## Decide in the low-level plan
- The routing table values (model, effort, max tokens, timeouts) from the S10 data.
- How personal candidates are matched against mentions on the server (simple normalized match vs model linking by ID).

## Exit criteria
- [ ] Contract conformance green. The Dart client regenerated.
- [ ] Integration tests with recorded LLM fixtures: valid output, invalid → repair → success, invalid twice → `Clarify` fallback, provider timeout → fallback provider, idempotent replay.
- [ ] The eval in CI passes the P4 parse thresholds on T01–T16, T19, T39–T41 (+ AR/Arabizi variants).
- [ ] Server-side p90 measured on staging. A log scrubber test proves no message text is logged.

## Read first
`06-buddy-ai.md` §1–4, §9–11 · S10 Outcome · `04-backend.md` §4

## Owner involvement
None (the eval is the judge). Optional: add new real messages as cases.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
