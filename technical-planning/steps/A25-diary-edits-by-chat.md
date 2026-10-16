# A25 — Diary edits by chat (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A23, **B09** (contract) | M | Claude | ⬜ Not started |

_Old ID: S35 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Fix anything with a sentence ("no the rice was 150g", "move the shawarma to lunch", "delete the pepsi", "same breakfast as yesterday"), always as a before → after proposal you confirm.

**Spec:** AI-050, AI-051, AI-090, AI-091, AI-092, DY-032 (chat path), UX-026, T23, T26, T27, T28, T29 · **Decisions:** TD-011, D-079

## Scope
- **Intents** from B09's contract: `DiaryEdit` (target entry IDs + patch: amount / food swap / slot / day / time), `DiaryDelete`, `Copy` (source date+slot → target), `AmbiguousReference` (candidate entry IDs). B09 owns the prompt, the server side and the eval cases.
- **Context:** `recentEntries` (≈ 3 days, IDs + names + grams + slot) in the request. Larger lookbacks ("last Monday's lunch") via date hints the model returns and the app resolves locally.
- **Reference resolution** (AI-091): the model links mentions to entry IDs. **Ambiguity → chips** showing the candidates (T29).
- **Proposal kinds** in the engine + card: **before → after** for edits (with new day totals), "will be removed" for deletes (UX-026), a copy preview for copies.
- **Conflict safety:** ops carry `expectedVersion`. If the entry changed meanwhile, the proposal is regenerated against current data (`03` §5.3).

## Out of scope
- Edits to weigh-ins/workouts by chat (their own steps).

## Fixed by the plan
- Every chat edit is a proposal. Direct taps remain direct actions with undo (D-079).

## Decide in the low-level plan
- How far back the app resolves references locally, and how it asks when it can't.

## Exit criteria
- [ ] T23 and T26–T29 work end to end with recorded fixtures (the eval thresholds are B09's).
- [ ] An E2E edit + confirm + undo round trip (patrol).
- [ ] A conflict test: an entry edited on another device before confirm → the proposal regenerates.
- [ ] Goldens for the before→after and delete cards.

## Read first
`spec/10-ai-assistant.md` §4.6, §8 · `06-buddy-ai.md` §3.2

## Owner involvement
Use it. Report misses (they become eval cases).

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
