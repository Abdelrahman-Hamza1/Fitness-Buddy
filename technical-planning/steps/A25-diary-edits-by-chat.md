# A25 — Diary edits by chat (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A23, **B09a** (contract) | M | Claude | ⬜ Not started |

_Old ID: S35 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Fix anything with a sentence ("no the rice was 150g", "move the shawarma to lunch", "delete the pepsi", "same breakfast as yesterday"), always as a before → after proposal you confirm.

**Spec:** AI-050, AI-051, AI-090, AI-091, AI-092, DY-032 (chat path), UX-026, T23, T26, T27, T28, T29 · **Decisions:** TD-011, D-079

## Scope
- **Intents** from B09's contract: `DiaryEdit` (target entry IDs + patch: amount / food swap / slot / day / time), `DiaryDelete`, `Copy` (source date+slot → target), `AmbiguousReference` (candidate entry IDs). B09 owns the prompt, the server side and the eval cases.
- **Context:** `recentEntries` (≈ 3 days, IDs + names + grams + slot) in the request. Larger lookbacks ("last Monday's lunch") via date hints the model returns and the app resolves locally.
- **Reference resolution** (AI-091): the model links mentions to entry IDs. **Ambiguity → chips** showing the candidates (T29).
- **Proposal kinds** in the engine + card: **before → after** for edits (with new day totals), "will be removed" for deletes (UX-026), a copy preview for copies.
- **Conflict safety:** ops carry `expectedVersion`. If the entry changed meanwhile, the proposal is regenerated against current data (`03` §5.3).

## Handoff from B09a (contract)
Contract: `diaryEdit`, `diaryDelete`, `ambiguousReference`, `diaryCopy` and the shared `BuddyDayHint`, `BuddyEntryReference`, `BuddyDiaryPatch` (`contracts/openapi/modules/buddy.yaml`; design in the B09 card, D6–D8, §3.1).
- **Null semantics:** in `patch.move`, a null member keeps the entry's day, slot or time, and a move with all three null is invalid. With `replacement` set, `patch.amount` is null. A `replacement.amount` with `explicit: false` and a null value keeps the entry's amount. A state or variant change is a `replacement`. In `diaryCopy`, null `target` members mean today, the source's slot and now. A null `source.slotHint` is clarified in R1 (no whole-day copy).
- **Day hints:** resolve the D8 grammar locally. `lastWeekday:X` is the most recent X strictly before today. A year-less `date:MM-DD` is the most recent past occurrence (`date:02-29` resolves up to 4 years back). Reject future dates. Parse defensively: a `dateHint` you can't parse routes the intent as `unrecognized`.
- **Allow-lists (forward compatibility, `contracts/README.md`):** decode the raw map with an explicit allow-list per kind. An unknown enum value routes `unrecognized`; never default to a destructive operation.
- **`targets: []` + hints → show that day's/slot's entries as chips.** Never auto-pick without a before→after, and no fuzzy NLP on the phone (B09 PA16). The ambiguous chip tap applies the carried `patch`. AI-044 open-card precedence. Send `recentEntries` newest first.
- Exit criterion to add (B09 PA11): engine-level T23, T26–T29 through `buddy_eval`'s adapter.

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
