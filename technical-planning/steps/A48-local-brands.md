# A48 — Local brands & packaged foods

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App (data) | A47 | M | Claude | ⬜ Not started |

_New step (owner, 2026-10-30). Phase 1, wave 2 (TD-105). Tier: Data/docs._

**Goal.** The packaged foods and brands the owner actually buys in Palestine and Jordan are in the offline list, so they log in seconds without a barcode lookup.

**Spec:** FD-004, FD-030 (offline part), D-073 · **Decisions:** TD-010

## Scope
- Packaged foods and brands common in Palestine/Jordan, starting from the owner's examples (dairy, bread, snacks, drinks, canned goods…).
- Values from the label or a source whose licence allows it; check the licence of every source before use (Open Food Facts data stays licence-isolated, `07` §3).
- EN/AR names and Arabizi spellings, serving sizes, barcodes when known.

## Out of scope
- Online barcode lookup (B10a, A28a).

## Exit criteria
- [ ] Every brand item validates and resolves by EN, AR and Arabizi; each records its source and licence.

## Read first
`technical-planning/07-food-data.md` §3–§4 · `spec/11-foods-and-data-quality.md` · A47 card

## Owner involvement
Send examples of the brands and products you buy (photos of labels are fine).

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._
