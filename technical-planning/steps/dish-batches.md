# Dish batches — reference dishes (A04, A17, A18, A19, A30, A32)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A03 (format frozen), then the previous batch | S each (one session per batch) | Claude (data-curator) | see the board |

**Goal.** Build the reviewed local food knowledge that makes "a plate of maqluba" a trustworthy number: every must-cover item (`spec/11` §6) as a reviewed reference dish or a database food, findable by English, Arabic and Arabizi names.

**Spec:** FD-004, FD-050, FD-051, FD-052, LC-050, LC-051, AT-003, D-046, D-075 · **Decisions:** TD-010

## Batches

| Batch | When (needed by) | Content |
|---|---|---|
| **A04** (was D1) | Before A05 | **Basics** for the offline pack: Arabic names + Arabizi aliases for the generic basics list (`spec/11` §6 "Basics"), yields, portion words. ~~Breakfast & bread~~ (moved to A17 by TD-074) (taboon, pita/khubz, shrak, ka'ak al-quds, labaneh, zaatar + oil, white cheeses, halloumi, olives, eggs, shakshuka, makdous, Arabic salad) |
| **A17** (was D2) | **Deferred by TD-074:** after A41, before A42 (R1) | **Breakfast & bread** (from A04: taboon, pita/khubz, shrak, ka'ak al-quds, labaneh, zaatar + oil, white cheeses, halloumi, olives, shakshuka, makdous, Arabic salad) · **Main dishes A:** maqluba (3 variants), musakhan, mansaf, mujaddara, maftoul, freekeh with chicken, mloukhiyeh with rice, rice with vermicelli, chicken & rice, kabsa, sumaqiyyeh, qidra |
| **A18** (was D3) | **Deferred by TD-074:** after A41, before A42 (R1) | **Out & street food:** falafel (piece, sandwich), chicken shawarma (sandwich, arabi, plate), meat shawarma, hummus plate, ful, msabbaha, fries, zinger, broasted, manakeesh, lahm bi ajeen/sfiha, fatayer, pizza slice, burger |
| **A19** (was D4) | **Deferred by TD-074:** after A41, before A42 (R1) | **Main dishes B + salads & sides:** waraq dawali, mahshi, kofta/siniyyeh, fasoulia, bamia, bazella, shish tawook, kebab, grilled chicken, fatteh, lentil soup, freekeh soup, pasta with sauce · tabbouleh, fattoush, baba ghanoush/mutabbal, tahini salad, yogurt-cucumber, pickles |
| **A30** (was D5) | **Deferred by TD-074:** after A41, before A42 (R1) | **Sweets, drinks, Ramadan staples:** knafeh, qatayef (variants), baklava, harissa/basbousa, ma'amoul, awameh, muhallabiya, halawa · Arabic/Turkish coffee, tea with sugar, sahlab, laban/ayran, juices, soft drinks, qamar al-din, jallab, tamarind · dates |
| **A32** (was D6) | **Deferred by TD-074:** after A41, before A42 (R1); fills what dogfooding logged as `~ estimate` | **Gap fill:** dishes the owner actually logged as `~ estimate` during dogfooding, misses from the eval, anything still failing AT-003 |

## Per-batch session protocol
1. Pick the batch list. Check what's already covered by USDA basics.
2. For each dish: a typical home recipe (whole pot) from **≥ 1 cited source** (2 when they disagree), variants, cooked total weight, portions with grams + ranges for each local portion word, names EN/AR + common Arabizi spellings, notes on variation (oil!).
3. `make catalog` → validation + sanity + per-100 g + AT-003 name resolution.
4. **Owner skim** (≈ 15 min): "does a plate of this look right for how your family cooks it?" Adjust if needed. TQ-08: the owner's family recipes override generic ones.
5. Mark `review.status: reviewed`. Commit as `data(dishes): Axx …`.

## Exit criteria (per batch)
- [ ] Every dish in the batch validates, passes the sanity checks, and resolves by EN, AR and Arabizi.
- [ ] Owner skim done. Notes recorded in the dish files.
- [ ] After **A32**: **AT-003 green** across the whole must-cover list.

## Read first
`07-food-data.md` §4 · `spec/11-foods-and-data-quality.md` §6 · A03 Outcome (format, time per dish)

## Owner involvement
≈ 15 min skim per batch. Family recipes if you want them used (TQ-08).

---

## Low-level plans

### A04 low-level plan
_Written in Phase B (2026-10-17, wave 1, lane F) by the step-planner. Built on A03's planned format (D4 IDs, D5 dish v1, D8 drafts); **re-check after A03's Outcome:** the frozen schema, the measured time per dish (this plan assumes ≈ 10–15 min per dish and ≈ 1 min per basic name set), and the USDA gaps A03 found._

**Summary.** A04 fills `data/` for the first real pack: the **curated basics list** (`data/usda_selection.yaml`) with Arabic names and Arabizi aliases (FD-004), the **yield factors** for the FD-060 staples (`data/yields.yaml`), the **local portion words** per food (`data/portion_words.yaml`, FD-003/LC-051), and the **breakfast & bread** items as reference entries. Everything validates with A03's `make catalog`. Dishes are `draft` until the owner's skim. Branch `step/A04-dish-batch-1` (after A03 merges).

**Decisions**

| # | Decision | Reason |
|---|---|---|
| D1 | **Basics scope ≈ 150–250 curated entries:** every `spec/11` §6 basic in its common states (rice white/basmati/brown dry + cooked, bulgur, freekeh, pasta, lentils red/brown, chickpeas dry/canned/cooked, chicken breast/thigh raw/cooked, minced beef, lamb, 3–4 fish incl. canned tuna/sardines, eggs, milk full/low fat, yogurt, oils, butter, ghee, ≈ 40 fruits and vegetables, ≈ 10 nuts and seeds, tahini, sugar, honey, flour) plus the ingredients the breakfast items and the A17/A18 dishes need first, plus common drinks as basics (cola, juice). No bulk auto-import of USDA | A05 D4. Every basic gets AR + Arabizi now (FD-004); bulk EN-only rows would add search noise and no Arabic |
| D2 | **Single local foods** (Nabulsi, Akkawi, Baladi cheese, halloumi if missing in USDA, labaneh, freekeh if missing, zaatar mix) are `ref:` items with the v1 `per_100g` branch and a cited `nutrient_source` (a product label or a published food-composition table); bread and cooked items (taboon, pita/khubz if not taken from USDA, shrak, ka'ak al-quds, zaatar + oil, eggs boiled/fried/omelette, shakshuka, makdous, Arabic salad) are recipes | Straining (labaneh) and brining (cheese) move nutrients in ways a recipe can't model; breads and mixed items are recipes by nature. Every `per_100g` value is transcribed from the cited source (a specific URL or table entry, or brand + product for a label), never derived or estimated by the curator, and never from Open Food Facts. Sanity must pass or carry a reviewed `sanity_override` |
| D3 | **Variants now:** ka'ak al-quds plain + with egg (with falafel waits for A18's falafel). Eggs (boiled, fried, omelette), olives, pita and halloumi stay **USDA basics** where USDA has them, with `piece` grams from `portion_words.yaml`, not reference items | Database foods keep the ⓓ badge where they exist (FD-011 priority) |
| D4 | **Yields** (`data/yields.yaml`, rows `{group, from, to, factor, source}`): rice, bulgur, freekeh, pasta, lentils, chickpeas/beans (dry → cooked), chicken, beef, lamb, fish (raw → cooked), potatoes (raw → boiled). Sources: USDA Table of Cooking Yields for Meat and Poultry (2014) for meats; for grains and pulses, the ratio of USDA raw vs cooked proximate (water) data, cited per row. Basics carry `yield_group` | FD-060's list. `YieldConverter` uses a direct row or the inverse, never a chain (S08 D6), so one row per group is enough |
| D5 | **Portion words** (`data/portion_words.yaml`, rows `{food, unit, g or ml, range?, source, note?}`): رغيف/`loaf` per bread, حبة/`piece` per fruit, egg and olive (falafel later), كاسة/`glass` per drink and milk (≈ 250 ml), `can` for soft drinks (330 ml), `tbsp`/`tsp` for oils, tahini, honey, labaneh, zaatar. Dish portions (`plate`, `sandwich`) stay in the dish files | FD-003, LC-051. علبة → `can` needs the A05 parser change (A05 D14); the data rows can exist before it |
| D6 | **Owner skim:** all new `ref:` items are `draft` (`reviewed_by: claude-draft`); the release pack excludes them (A03 D8). The owner's morning skim flips them in a tiny follow-up commit `data(dishes): A04 reviewed`. Basics' AR/Arabizi names ship without a skim (database foods) but are in the same skim list | "Unreviewed dishes don't ship" with the owner asleep. Owner check, not a blocker |

**Work packages** (`data-curator` unless noted; sequential)

| WP | Content | Files | Done when |
|---|---|---|---|
| WP1 | Basics list (D1): FDC IDs, short EN names, AR names, ≥ 2 Arabizi spellings where people type the word in Latin, `servings`, `yield_group`, `fiber_zero` where right. `make catalog-usda` | `data/usda_selection.yaml`, `data/usda/extract.jsonl` | `make catalog` green with `--require-ar`; no duplicate normalized names |
| WP2 | Yields (D4) and portion words (D5), each row cited | `data/yields.yaml`, `data/portion_words.yaml` (+ `flutter-engineer` adds `data/schema/{yields,portion_words}.v1.schema.json` + loaders + validation in `tools/catalog` (≈ 0.1 session). A05 reuses them) | Validate green; every FD-060 staple has a row |
| ~~WP3~~ | **Dropped by TD-074** (owner, 2026-10-17: dishes later, basics first). Breakfast & bread dishes move to A17 | — | — |
| WP4 | `make catalog` coverage report: every basics item resolved by EN/AR/Arabizi (drafts included) | — | Report pasted into the Log row below |

**Tests / checks.** Required schema tests (WP2 adds the schemas): `FD-060 yields schema rejects factor ≤ 0 and unknown states`, `LC-051 portion word rows need g or ml, not both`. The batch exit criteria are shown by `make catalog` (validate, sanity, AT-003 coverage for the batch) in CI's `dart` job.

**Risks.** Local cheese and labaneh numbers vary a lot by brand (use a range note and the most common local label). Freekeh may not be in USDA (D2 branch). Volume: if A03 measures much more than 15 min per dish, WP1 still fits but WP3 may spill; the seam is WP3 into the next session. **Size: S/M (~1 session).** Owner: ≈ 15 min skim (D6), non-blocking.

### Plan review (architect, 2026-10-17, wave 1)
- PA1: WP2 schema ownership: `flutter-engineer` adds the yields and portion-words schemas + loaders (≈ 0.1 session); the two schema tests are required.
- PA2: D2 `per_100g` values transcribed from the cited source, never derived, never from Open Food Facts; sanity passes or carries a reviewed override.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-17: Wave 1 (TD-068): plan written, architect group review approve-with-changes, amendments applied. Plan approved by the orchestrator under TD-037 (no blocking owner item). Next: implementation.
- 2026-10-17: Implemented basics-only (TD-074): 246 curated basics with AR + Arabizi, 12 yield rows, 74 portion words, yields/portion-words formats + validation (household units owned by portion_words; servings must agree). Seven local single foods (freekeh, Nabulsi, Akkawi, halloumi, labaneh, zaatar, sumac) added as draft `per_100g` refs per D2, kept here rather than moved to A17 because they are basics people log daily. 'Chicken breast' defaults to skinless. Review (TD-073, one Opus code review): 3 major (real yields/portion files not checked in CI; duplicate portion grams conflicting; uncited freekeh yield), 8 minor, 5 nit; all fixed in b249678. CI green on 018de70. Closed under TD-037. Owner skim pending (non-blocking, D6): the 7 drafts, freekeh yield 3.0 (estimate), bulgur 3.8, pita 60 g (bakery loaves 100–200 g).

## Log
| Batch | Date | Dishes | Notes |
|---|---|---|---|
| A04 | 2026-10-17 | 0 dishes (TD-074); 246 basics, 7 draft single local foods | `make catalog`: 246 basics + 12 dishes valid, 12 yield rows, 74 portion words; must-cover 115: 42 basic, 10 draft, 63 missing (dishes deferred) |
| | | | |
