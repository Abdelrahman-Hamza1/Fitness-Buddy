# A47 — Food basics expansion

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App (data) | A05 ✅ | M | Claude | ⬜ Not started |

_New step (owner, 2026-10-30: "Bigger food list, it needs to be done soon"). Phase 1, wave 1 (TD-105). Tier: Data/docs._

**Goal.** The offline food list covers what people actually eat: the basics grow from about 250 to about 600, each findable by English, Arabic and Arabizi names with real portions.

**Spec:** FD-001, FD-004, FD-050, LC-050, LC-051, AT-003 (basics part) · **Decisions:** TD-010, TD-074, D-080

## Scope
- About 350 new basics through the existing USDA pipeline (A03/A05): fruit, vegetables, meat, fish, dairy, grains, legumes, nuts, oils, sauces, snacks, drinks.
- Each with an Arabic name and common Arabizi spellings, portions and servings (piece, cup, slice, local portion words), yields where cooked/raw differ.
- Densities for liquids where needed (helps backlog #148).
- `make catalog` validation, sanity checks and name resolution.

## Out of scope
- Reference dishes (the dish batches). Packaged and branded foods (A48).

## Exit criteria
- [ ] About 600 basics in the offline pack; every new one validates and resolves by EN, AR and Arabizi.
- [ ] Pack size and search speed stay within the A05/A07 budgets.

## Read first
`technical-planning/07-food-data.md` §4 · `spec/11-foods-and-data-quality.md` §6 · A03, A05 cards

## Owner involvement
Optional skim of the new list; name foods you miss.

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._
