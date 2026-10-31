# A54 — Catalog expansion: natural foods and generic store products

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App (data) | A47 ✅ | L | Claude (data curator) | ✅ Closed, awaiting merge |

_New step (owner, 2026-10-31: "add as MUCH natural food and store products as possible as long as it's free"). Tier: Data/docs._

**Goal.** The offline catalog covers most of what people buy or cook: natural foods (fruit, vegetables, legumes, grains and flours, meat cuts raw and cooked, poultry, fish and seafood, eggs, dairy, nuts and seeds, herbs and spices, oils and fats) and generic store products (breads, crackers, cookies, cakes, cereals, cheeses, yoghurts, drinks, canned foods, sauces, snacks, sweets, ice cream, deli meats), each findable by English, Arabic and Arabizi names.

**Spec:** FD-001, FD-004, FD-050, LC-050, LC-051 · **Decisions:** TD-010, TD-074, C-5 (licensing)

## Source and licence
USDA FoodData Central only: **SR Legacy 2018-04** and **Foundation Foods 2026-04-30**, both CC0, pinned in `data/usda/sources.yaml` and fetched by `tools/scripts/fetch-usda.sh` (outside the repo). **No Open Food Facts** (ODbL is an owner decision, not taken). **No USDA Branded Foods.** Every number comes from USDA through the importer (`make catalog-usda`); the generator and the name files hold names, never nutrition.

## Selection rules
- One representative per real choice (e.g. a cut raw and cooked, a food canned and frozen), not a dozen USDA variants. When USDA has several rows for one concept the generator prefers Foundation, then "without salt", then the shortest description.
- Skipped: baby foods, fast-food chains and restaurant foods, American Indian/Alaska Native foods, brand-named products (brands, "Includes foods for USDA's Food Distribution Program" noise), foods USDA gives no fibre for (unless the food is meat, fish, dairy, fat, drink, sweet or has under 1 g carbs, where `fiber_zero: true` is the existing convention), rows with a negative nutrient, and rows the importer cannot read.
- Very rare foods without a common Arabic word (obscure fish, game, tropical fruit) are left out: the release requires an Arabic name and the curator does not invent one.
- A name never duplicates an existing name (FD-004). New foods do not take an alias that an existing food or dish already owns, and the top result for the common words (rice, chicken, bread, laban, milk, tea, ...) is checked before and after.
- Servings come from USDA portions only: piece (countable labels only), slice, can, cup, tbsp, tsp. Household units stay owned by `data/portion_words.yaml`.
- Energy sanity: a USDA row whose energy differs from 4P+4C+9F by more than the check allows is dropped, or waived with a stated reason when the gap is the fibre energy discount (`sanity_override`).

## How it works
`tools/scripts/catalog_expand/` (Python 3, stdlib + PyYAML):
- `expand.py` reads the USDA CSVs and `names/*.tsv` (USDA head phrase | EN | AR | Arabizi | flags), parses each USDA description into head phrase and state, picks the best row per (food, state), composes names (Arabic state words agree with the noun's gender) and writes `data/usda_selection.yaml` entries.
- `gen_meats.py` writes `names/meats.tsv` (regex concepts for meat cuts, organs and poultry).
- `sanity_fix.py` waives or drops foods the catalog sanity check rejects.
- `usda_load.py`, `normalize.py` are helpers (the validator stays the authority on name keys).
Run order: `fetch-usda.sh <dir>` → `expand.py … --out p.yaml` → append to the selection → `make catalog-usda USDA_DIR=<dir>` → `catalog validate --require-ar` → `sanity_fix.py` → `make catalog`.

## Batches
| Batch | Content | New basics |
|---|---|---|
| 1 | vegetables, fruits and juices, legumes, grains, flours, pasta | 436 |
| 2 | beef, lamb, veal, pork cuts raw and cooked, poultry, fish, shellfish | 326 |
| 3 | breads, crackers, cookies, cakes, dairy and eggs, oils, dressings, nuts, seeds, spices, drinks, sweets, snacks, cereals, soups, sauces, deli meats, organ meats | 690 |
| 4 | more vegetable/fruit forms, sprouts, canned and frozen forms, flours, snacks, syrups, plant milks, name corrections | 204 |

## Progress log
- 2026-10-31 batch 1 (436): vegetables, fruits, legumes, grains. Pack 1.3 → 1.7 MB.
- 2026-10-31 batch 2 (326): meat, poultry, fish. Pack 2.1 MB.
- 2026-10-31 batch 3 (690): store products and pantry. Pack 2.8 MB. Spot check: top result unchanged for 48 of 49 common words; "tuna" fixed with an exact alias.
- 2026-10-31 batch 4 (204): more forms, name corrections, collision fixes. Rebuilt from main in one pass: **+1,656 basics** (626 → 2,282; 1,601 SR Legacy, 55 Foundation), catalog version 27, pack 1.3 → 3.0 MB (assets 3.0 MB).
- Collision fixes found by the server eval: the Postgres resolver ranks USDA matches above dishes and also takes fuzzy (trigram 0.3) matches, so new names that contain a dish word (maqluba, mutabbal, chicken and rice, kebab, kofta, mahshi, jibneh baida, qamar el din, kaak bi simsim) or share trigrams with a mention (lima beans "large" vs "mansaf large") were renamed. Eval AQ gate unchanged (18 / 1 known misses, none new). Exact aliases added so common single words keep their old top result: Tuna, Pepper, Beans, Oil, Turkey (basics), Salad, Soup (dishes).
- Checks: catalog validate + sanity, make catalog-check, tools/catalog tests (138), app catalog/unit-label/food-search tests (35), server CatalogTests (5), BuddyPublicEvalTests (4) + check-buddy-eval, make eval.

## Exit criteria
- [x] Every new basic validates (`catalog validate --require-ar`), passes the sanity check, has EN and AR names and resolves by name.
- [x] `make catalog`, `make catalog-check`, `tools/catalog` tests and the app catalog tests pass.
- [x] Pack well under the 10 MB budget (3.0 MB).
- [ ] Owner acceptance by use (no skim): names the owner misses go to the backlog.
