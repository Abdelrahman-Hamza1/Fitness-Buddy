# S35 — Diary edits by chat

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P5 Buddy breadth | S34 | M | ⬜ Not started |

**Goal.** Fix anything with a sentence ("no the rice was 150g", "move the shawarma to lunch", "delete the pepsi", "same breakfast as yesterday"), always as a before → after proposal you confirm.

**Spec:** AI-050, AI-051, AI-090, AI-091, AI-092, DY-032 (chat path), UX-026, T23, T26, T27, T28, T29 · **Decisions:** TD-011, D-079

## Scope
- **Intents** (contract + backend + prompt): `DiaryEdit` (target entry IDs + patch: amount / food swap / slot / day / time), `DiaryDelete`, `Copy` (source date+slot → target), `AmbiguousReference` (candidate entry IDs).
- **Context:** `recentEntries` (≈ 3 days, IDs + names + grams + slot) in the request. Larger lookbacks ("last Monday's lunch") via date hints the model returns and the app resolves locally.
- **Reference resolution** (AI-091): the model links mentions to entry IDs. **Ambiguity → chips** showing the candidates (T29).
- **Proposal kinds** in the engine + card: **before → after** for edits (with new day totals), "will be removed" for deletes (UX-026), a copy preview for copies.
- **Conflict safety:** ops carry `expectedVersion`. If the entry changed meanwhile, the proposal is regenerated against current data (`03` §5.3).
- Eval cases T23, T26–T29 (+ AR/Arabizi variants) added to `buddy_eval`.

## Out of scope
- Edits to weigh-ins/workouts by chat (their own steps).

## Fixed by the plan
- Every chat edit is a proposal. Direct taps remain direct actions with undo (D-079).

## Decide in the low-level plan
- How far back the app resolves references locally, and how it asks when it can't.

## Exit criteria
- [ ] T23 and T26–T29 pass in the eval (thresholds in `spec/40` §2).
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
