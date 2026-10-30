# A29 — Photo logging, body data by chat & paste import (app)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A15, A23, **B10b** (contract) | M | Claude | ⬜ Not started |

_Old ID: S39 app part (renumbered by TD-063, 2026-10-16)._

**Goal.** Three more ways in: a photo of a meal (+ optional text), weigh-ins and measurements by chat, and pasting the owner's old weight note to import years of history in one go.

**Spec:** AI-011, AI-052, AI-057, WB-002, WB-030, WB-031, WB-032, WB-040 (chat path), D-055, T33 · **Decisions:** TD-009

## Scope
- **Photo + text** (AI-011): camera/gallery from the input bar → resize to ~1024 px JPEG → interpret with the image (B10's vision food task) → the same `Interpretation` schema → normal proposal. Portion from a photo alone is always an estimate (badges forced to `~` unless the text gives grams). Photos aren't stored on the server. The local copy stays with the chat message.
- **`WeighIn` and `Measurement` intents** (AI-052, WB-002, T33): proposal with value, date, change vs trend.
- **Paste import** (WB-030–032, AI-057): Me → Weight → "Import from text" (and via chat) → `POST /v1/buddy/import` (B10) → rows {date, value, unit?, original text} → **review table proposal** with flags: unclear dates, missing units ("110k" → 110 kg), implausible jumps (WB-005 rule), duplicates of existing entries. Flagged rows are excluded until fixed or accepted. The same for measurements.

## Out of scope
- Food history import from text (Later, WB-032).

## Fixed by the plan
- Domain validation decides what's implausible, not the model (`06` §8).

## Decide in the low-level plan
- The review-table interaction for fixing flagged rows inline.

## Exit criteria
- [ ] T33 works end to end with recorded fixtures, and photo-based items are always marked as estimates (AQ-10). (The photo and import eval cases are B10's.)
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
