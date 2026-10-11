# S39 — Photo logging, body data by chat & paste import

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P5 Buddy breadth | S22, S34 | M | ⬜ Not started |

**Goal.** Three more ways in: a photo of a meal (+ optional text), weigh-ins and measurements by chat, and pasting the owner's old weight note to import years of history in one go.

**Spec:** AI-011, AI-052, AI-057, WB-002, WB-030, WB-031, WB-032, WB-040 (chat path), D-055, T33 · **Decisions:** TD-009

## Scope
- **Photo + text** (AI-011): camera/gallery from the input bar → resize to ~1024 px JPEG → interpret with the image (vision food task) → the same `Interpretation` schema → normal proposal. Portion from a photo alone is always an estimate (badges forced to `~` unless the text gives grams). Photos aren't stored on the server. The local copy stays with the chat message.
- **`WeighIn` and `Measurement` intents** (AI-052, WB-002, T33): proposal with value, date, change vs trend.
- **Paste import** (WB-030–032, AI-057): Me → Weight → "Import from text" (and via chat) → `POST /v1/buddy/import` → rows {date, value, unit?, original text} → **review table proposal** with flags: unclear dates, missing units ("110k" → 110 kg), implausible jumps (WB-005 rule), duplicates of existing entries. Flagged rows are excluded until fixed or accepted. The same for measurements.
- Eval cases: T33, photo cases (≥ 10 with expected identifications), import cases (the owner's real note format + messy variants).

## Out of scope
- Food history import from text (Later, WB-032).

## Fixed by the plan
- Domain validation decides what's implausible, not the model (`06` §8).

## Decide in the low-level plan
- The review-table interaction for fixing flagged rows inline.

## Exit criteria
- [ ] T33 passes. Photo eval cases are reported (identification rate), and estimates are always marked (AQ-10).
- [ ] The owner's real weight note imports correctly, with problem rows flagged and nothing imported silently (owner-verified).
- [ ] Import domain tests (unit inference, jump detection, duplicates).

## Read first
`spec/14-weight-and-body.md` §4 · `06-buddy-ai.md` §8

## Owner involvement
Provide your weight note text. Check the import result.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
