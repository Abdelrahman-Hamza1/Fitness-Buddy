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
| **A17** (was D2) | **Phase 1, wave 1** (TD-105; the TD-074 deferral is lifted) | **Breakfast & bread** (from A04: taboon, pita/khubz, shrak, ka'ak al-quds, labaneh, zaatar + oil, white cheeses, halloumi, olives, shakshuka, makdous, Arabic salad) · **Main dishes A:** maqluba (3 variants), musakhan, mansaf, mujaddara, maftoul, freekeh with chicken, mloukhiyeh with rice, rice with vermicelli, chicken & rice, kabsa, sumaqiyyeh, qidra |
| **A18** (was D3) | **Phase 1, wave 1** (TD-105) | **Out & street food:** falafel (piece, sandwich), chicken shawarma (sandwich, arabi, plate), meat shawarma, hummus plate, ful, msabbaha, fries, zinger, broasted, manakeesh, lahm bi ajeen/sfiha, fatayer, pizza slice, burger |
| **A19** (was D4) | **Phase 1, wave 2** (TD-105) | **Main dishes B + salads & sides:** waraq dawali, mahshi, kofta/siniyyeh, fasoulia, bamia, bazella, shish tawook, kebab, grilled chicken, fatteh, lentil soup, freekeh soup, pasta with sauce · tabbouleh, fattoush, baba ghanoush/mutabbal, tahini salad, yogurt-cucumber, pickles |
| **A30** (was D5) | **Phase 1, wave 2** (TD-105) | **Sweets, drinks, Ramadan staples:** knafeh, qatayef (variants), baklava, harissa/basbousa, ma'amoul, awameh, muhallabiya, halawa · Arabic/Turkish coffee, tea with sugar, sahlab, laban/ayran, juices, soft drinks, qamar al-din, jallab, tamarind · dates |
| **A32** (was D6) | Before R1, once dogfooding shows the misses (TD-105); fills what dogfooding logged as `~ estimate` | **Gap fill:** dishes the owner actually logged as `~ estimate` during dogfooding, misses from the eval, anything still failing AT-003 |

## Per-batch session protocol
1. Pick the batch list. Check what's already covered by USDA basics.
2. For each dish: a typical home recipe (whole pot) from **≥ 1 cited source** (2 when they disagree), variants, cooked total weight, portions with grams + ranges for each local portion word, names EN/AR + common Arabizi spellings, notes on variation (oil!).
3. `make catalog` → validation + sanity + per-100 g + AT-003 name resolution.
4. **Independent number check** (D-087): a Codex task, never the authoring agent, checks the numbers (grams, kcal and macros per portion, yields, sanity). Fix what it finds. TQ-08: the owner's family recipes override generic ones when reported.
5. The orchestrator flips `review.status` / `reviewed_by` to `ai-verified`, runs `make catalog`, then commits as `data(dishes): Axx …`.

## Exit criteria (per batch)
- [ ] Every dish in the batch validates, passes the sanity checks, and resolves by EN, AR and Arabizi.
- [ ] Independent number check done (D-087). Notes recorded in the dish files.
- [ ] After **A32**: **AT-003 green** across the whole must-cover list.

## Read first
`07-food-data.md` §4 · `spec/11-foods-and-data-quality.md` §6 · A03 Outcome (format, time per dish)

## Owner involvement
None required; the owner reports issues found in use (D-087).

---

## Low-level plans

### A19 + A30 low-level plan (combined, Codex, 2026-10-30)

One implementation: audit existing basics, author recipe drafts, regenerate, cross-check.
All new refs use `draft` / `claude-draft` (schema's only draft author tag; author is Codex).
Independent number review and release remain the orchestrator's next task (D-087).
Forms after checking the 40 existing refs and 626 USDA basics:
- Waraq dawali: new `waraq_dawali`; meat/rice and vegetarian variants.
- Mahshi: new `mahshi_kousa` and `mahshi_eggplant`; tomato-broth rice/meat fillings.
- Kofta/siniyyeh: new `kofta_bil_tahini`; tahini default and tomato variant.
- Fasoulia, bamia, bazella: new `*_with_rice`; stew-only variants keep rice explicit.
- Shish tawook: new `shish_tawook`; marinated grilled breast, bread/sauces excluded.
- Kebab: new `kebab`; beef and lamb variants; edible cooked weight, drippings excluded.
- Grilled chicken: existing USDA whole roasted chicken, aliases + edible quarter/half/whole portions.
- Fatteh: new `fatteh`; toasted bread default and fried-bread variant.
- Lentil soup: new `lentil_soup`; red lentils, vegetables, water-balance yield.
- Freekeh soup: new `freekeh_soup`; chicken and vegetarian variants.
- Pasta with sauce: new `pasta_with_sauce`; tomato and meat sauce variants.
- Tabbouleh, fattoush: new `tabbouleh`, `fattoush`; bread/oil explicitly counted.
- Baba ghanoush/mutabbal: new `baba_ghanoush`; tahini and vegetable/no-tahini variants.
- Tahini salad, yogurt-cucumber: new `tahini_salad`, `yogurt_cucumber_salad`.
- Pickles: existing `usda:pickled_cucumber_dill`, add English alias and piece grams.
- Knafeh: new `knafeh_nabulsiyeh`; fine semolina dough and cheese, explicit ghee/syrup.
- Qatayef: new `qatayef`; walnut/cheese × fried/baked variants.
- Baklava: new `baklava`; walnut and pistachio, phyllo, ghee and syrup.
- Harissa/basbousa: new `basbousa`; yogurt semolina cake with syrup.
- Ma'amoul: new `maamoul`; date and walnut fillings, butter/ghee explicit.
- Awameh, muhallabiya: new `awameh`, `muhallabiya`; absorbed oil/syrup and milk/sugar.
- Halawa: existing `usda:halawa`; add portion only if missing (label/database composition preferred).
- Arabic/Turkish coffee: existing unsweetened `usda:coffee_brewed`, aliases + small cup portion.
- Tea with sugar: new `tea_with_sugar` recipe (150 g brewed tea + 8.4 g sugar/cup).
- Sahlab: new `sahlab`; milk, starch, sugar, modest coconut/pistachio topping.
- Laban/ayran: existing low-fat buttermilk proxy; retain documented approximation.
- Plain juices, soft drinks, dates: existing basics; add missing names, preserve specific identities.
- Qamar al-din, jallab: new `qamar_al_din`, `jallab`; dilution and added sugar explicit.
- Tamarind: existing `usda:tamarind_nectar`; drink aliases + glass, no invented pulp extraction yield.
Sources intended: Palestine in a Dish (mahshi, kofta, soups, salads), Falasteeni Foodie
(knafeh, qatayef, stews), Feel Good Foodie (grills, salads, sweets), Amira's Pantry
(Ramadan drinks), The Mediterranean Dish (baklava); fetch recipe cards before adapting.
Use two sources when proportions disagree; mark conversions, proxies and retained fats as assumptions.
USDA catalog supplies ingredient nutrients; recipe pages supply quantities, never their nutrition panels.
Cooked weights: ingredient mass + retained water minus steam/drippings; no unexplained yield targets.
Portions: existing piece/plate/bowl/cup/glass/half/serving, plus quarter/whole chicken labels.
Basic chicken servings live in the selection (free-text unit schema); ranges/source are in notes,
because portion_words validation has a closed vocabulary. Add draft label-based `date_syrup` for jallab.
Checks: make catalog + catalog-check; catalog Dart tests; app unit-label and offline-catalog tests;
try the two targeted server classes, report sandbox/Docker limits; no full suites, no git writes.

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
- 2026-10-30: **A17 (dish batch 2) authored** on `step/A17-dish-batch-2` (commits not pushed; merge-step carries the branch). 16 new draft dishes (`claude-draft`): taboon bread, shrak, ka'ak al-Quds (plain, with egg), zaatar with olive oil, shakshuka, makdous, Arabic salad; mansaf, mujaddara, maftoul, freekeh with chicken, rice with vermicelli, chicken and rice, kabsa, sumaqiyyeh, qidra. Maqluba (3 variants), musakhan and mloukhiyeh with rice already existed (A03/A04 drafts) and labaneh, halloumi, Nabulsi, Akkawi, freekeh, zaatar and sumac were released by A47; pita, olives and eggs are USDA basics. All resolve by EN, AR and Arabizi (AT-003 rows), `make catalog` and `make catalog-check` green; the release pack still holds only the 7 reviewed refs (drafts excluded). **No owner skim (D-087): independent number check instead, see the 2026-10-30 check line below.** Check list, plate grams and kcal for the default variant (before the check; mansaf and sumaqiyyeh were reworked):
  - Breakfast: taboon loaf 150 g, 403 kcal (215-591); shrak sheet 110 g, 288 (157-366); ka'ak al-Quds 160 g, 526 (362-822); ka'ak with egg and zaatar sandwich 270 g, 747 (526-1052); zaatar and oil serving 25 g, 197 (94-354; oil eaten is the unknown); shakshuka plate (2 eggs) 400 g, 491 (368-638); makdous piece 55 g, 117 (74-159; oil per piece); Arabic salad bowl 200 g, 118 (71-177).
  - Main dishes: mansaf plate 600 g, 1204 (903-1605; jameed modelled as yogurt plus labaneh, lamb fat counted); mujaddara plate 350 g, 628 (449-807; oil); maftoul with chicken plate 450 g, 922 (717-1229); freekeh with chicken plate 350 g, 730 (584-938; freekeh yield 3.0 is itself an estimate); rice with vermicelli plate 250 g, 402 (289-562); chicken and rice plate 350 g, 734 (587-944); kabsa plate 380 g, 713 (563-938); sumaqiyyeh bowl 350 g, 702 (502-903); qidra plate 420 g, 1081 (850-1416; highest, please check first).
  - Unsure: oil in every pot; lamb fat (mansaf, qidra, sumaqiyyeh: all counted, skimming lowers a plate by 100-250 kcal); loaf and ka'ak sizes (sources disagree 2x); plate size for mansaf and qidra; "chicken and rice" is modelled on a Lebanese recipe (no Palestinian gram recipe found); kabsa has one source; maftoul modelled with couscous. Baladi cheese is still missing (no label found, so no dish added) and stays on the A32 list. TQ-08: the owner's family recipes replace these.
- 2026-10-30: **A18 (dish batch 3) authored** on `step/A18-dish-batch-3` (commits not pushed; merge-step carries the branch). 11 new draft dishes (`claude-draft`): manakeesh zaatar, manakeesh cheese, lahm bi ajeen (large pie + small sfiha), fatayer spinach, fatayer cheese, hummus plate, msabbaha, ful medames, meat shawarma (beef, lamb), chicken shawarma plate, zinger, broasted two-piece meal. Existing falafel (piece, sandwich, plate) and chicken shawarma arabi drafts kept and given the aliases "sandwich falafel", "ساندويش/سندويش/ساندوتش فلافل", "shawarma arabi", "shawarma sandwich", "شاورما عربي", "شاورما" (T12 and T13 phrases resolve; the eval's known misses wait for the draft flip and A49). Skipped, already basics (resolve by EN/AR/Arabizi): fries (usda:fries_fast_food), pizza slice (usda:pizza_cheese), burger (usda:hamburger_single), and broasted chicken pieces (usda:fried_chicken_*; the ref is the meal). usda:chicken_sandwich_crispy already owns "zinger sandwich", so the ref dish uses "zinger" and "برغر زنجر". `ful_medames` resolves by name to the canned fava basic, so its must-cover item got `match: [ref:ful_medames, usda:fava_beans_canned]` (data/must_cover.yaml). `make catalog` and `make catalog-check` green; release pack unchanged (7 dishes). **Check first, for the independent number check (plate grams, kcal at that weight, range):** manakeesh zaatar piece 130 g, 505 (349-776; topping oil); manakeesh cheese piece 145 g, 451 (311-685; cheese per piece varies 23-54 g); lahm bi ajeen large pie 150 g, 351 (234-515), sfiha small 63 g, 167; fatayer spinach piece 100 g, 256 (179-359); fatayer cheese piece 70 g, 215 (138-338; source pies are 45 g); hummus plate 250 g, 584 (421-818; tahini and oil); msabbaha bowl 300 g, 731 (536-975; sources differ 6x on tahini); ful medames plate 300 g, 286 (190-381; oil, no Palestinian gram source); meat shawarma sandwich 250 g, 717 (545-917; sandwich scale copied from the chicken one, no source weights); chicken shawarma plate 545 g, 1161 (895-1385; plate composition from nutrition-app listings, an assumption); zinger sandwich 250 g, 727 (582-930); broasted two-piece meal 620 g, 1632 (1369-1896; weights assumed). Also check: oil in every dough and topping, pomegranate molasses modelled with plain molasses, the USDA fried-chicken entries standing in for broasted.
- 2026-10-30: **A17/A18 independent number check and release (D-087).** A second agent (Codex) recalculated every variant of the 30 changed dishes. Rejected: mansaf (jameed modelled with yogurt and labaneh without a cited composition) and sumaqiyyeh (2.9 kg cooked yield unsupported). Fixes (commits `data(dishes): A17 mansaf and sumaqiyyeh rework`, `A17/A18 number-check fixes`): mansaf is now an explicit yogurt-only sauce model (jameed claims dropped, 1.2 kg sauce, cooked 4.23 kg, plate 530 g = 1135 kcal, chicken variant 998); sumaqiyyeh cooked yield from a water balance (4.1 kg, dill seed added, attribution Rawhiyah Eltayeb, bowl 450 g = 643 kcal). Alias fixes (shakshuka, freekeh, lamb shawarma, sfiha, ful, shawarma arabi), "ful medames", "foul medames" and "zinger sandwich" names moved from the two USDA basics to the dishes (basics qualified: canned ful, US crispy sandwich; the ful must-cover fallback to the canned basic was removed), provenance fixes (Dina URL, La Boite, Go Healthy Ever After, Arise dropped), taboon loaf 185 g (4 loaves), kabsa and manakeesh notes, yeast proxy documented. Release: 26 A17/A18 dishes plus falafel and chicken shawarma arabi are now `reviewed` / `ai-verified`; mansaf and sumaqiyyeh stay `draft` until a fresh check; maqluba, musakhan and mloukhiyeh (not in the check) stay `draft`. Pack: catalog v21, 35 dishes (51 variants), 3894 names, 635 servings; must-cover 115: 31 reviewed, 5 draft, 47 basic, 32 missing.
- 2026-10-30: **Last five drafts checked and released (D-087).** Codex approved with fixes mansaf, sumaqiyyeh, maqluba, musakhan and mloukhiyeh_rice (all numbers pass). Fixes: bare ملوخية and the bare mloukhiyeh/molokhia spellings moved to the stew_only variant (the parent keeps rice-qualified names, plus "ملوخية مع رز" and "mloukhiyeh ma ruz" for coverage); sumaqiyyeh water-balance prose corrected (the initial 120 ml evaporates in browning, steam loss about 0.2 kg, no numbers changed). All five are now `reviewed` / `ai-verified`, so every A17 and A18 dish is released. Pack: catalog v22, 40 dishes (60 variants), 4020 names, 659 servings; must-cover 115: 36 reviewed, 0 draft, 47 basic, 32 missing.

- 2026-10-30: **A19 + A30 authored together by Codex** on `step/A19-A30-dish-batches-4-5`, uncommitted for the orchestrator. Added 29 recipe refs plus the supporting label-based `date_syrup` ref (30 files, 48 variants), all `draft` / `claude-draft` (schema tag, not reviewer attribution). Every batch item resolves by EN/AR/Arabizi; grilled chicken, pickles, halawa, unsweetened Arabic/Turkish coffee, laban/ayran, juices, soft drinks, tamarind and dates use existing USDA basics. Added quarter/whole English labels and explicit coffee/sugar/edible-chicken assumptions. `make catalog` / `catalog-check`, full data validation (70 refs, same 28 old basic warnings), catalog tests (129), `make gen-app`, targeted app tests (15), CatalogTests (5) and BuddyPublicEvalTests (4) passed; fixture hash unchanged. Buddy AQ baseline checks exit 0 with existing M3 18 / B09 1 known misses and AQ-05 backlog notices; no baseline edits. Pack v23 still releases 40 reviewed refs / 60 variants (new drafts excluded), 626 basics, 4047 names, 666 servings; must-cover 36 reviewed / 29 draft / 49 basic / 1 missing (pre-existing Baladi cheese). Heavy wrapper used `FB_HEAVY_LOCK=/tmp/fb-heavy.lock` because the default cache lock is read-only in this sandbox; commands serialized. Sources, conversions, cooked mass balances and retained syrup/fat assumptions are in each YAML. **Independent number check pending (D-087); no review status flipped.** The combined handoff below lists portions and check priorities.
- 2026-10-30: **A19/A30 number-check fix round (Codex, uncommitted).** Doubled qatayef full-batch fillings and rebuilt conditional batch/piece masses and bounds; removed baba vegetable and both mahshi piece portions; restored generic coffee names and added separate draft 30 g Arabic / 60 g Turkish cup identities (coverage follows them); persisted chicken quarter/half/whole ranges through portion words, with validator support and release/SQLite regressions; corrected bamia prose and fattoush URL. Researched all rejected models; cited partial evidence and precise remaining gaps in each review.notes, retaining all review statuses. Checks/results and per-item kcal are recorded in the fix-round handoff below.

## Outcome (A17, 2026-10-30)
16 new draft dishes (7 breakfast and bread, 9 main dishes A) in `data/reference_dishes/`, each with at least two cited recipe sources where they disagree, variants, a modelled whole-pot cooked weight, plate/piece portions with ranges and EN/AR/Arabizi names; maqluba, musakhan and mloukhiyeh with rice were already drafted and left unchanged, and labaneh, halloumi, Nabulsi, Akkawi, freekeh, zaatar, sumac, pita, olives and eggs were already released refs or USDA basics. No new basics were needed. Validation, sanity (no new warnings) and AT-003 name resolution pass for all of them. Released as `ai-verified` after the independent number check (see the Progress log), except mansaf and sumaqiyyeh, which stay `draft`. Not done: baladi cheese (no label source found). Time: about 8-10 minutes of authoring per dish, most of it recipe research (many recipe pages block fetching, so some quantities come from search summaries and are marked in the sources).

## Outcome (A18, 2026-10-30)
11 new draft dishes (manakeesh zaatar and cheese, lahm bi ajeen, fatayer spinach and cheese, hummus plate, msabbaha, ful medames, meat shawarma, chicken shawarma plate, zinger, broasted meal) plus aliases on the existing falafel sandwich and chicken shawarma arabi drafts. Every A18 must-cover item now resolves by EN, AR and Arabizi (fries, pizza slice, burger and broasted pieces through basics); validation, sanity (no new warnings) and name resolution pass. Released as `ai-verified` after the independent number check (see the Progress log). Sources are cited per dish; several recipe pages blocked fetching and some quantities come from search summaries (marked). Dishes without a gram-based Palestinian source (ful, meat shawarma, shawarma plate, broasted meal) say so in their notes.

## A19 + A30 author handoff (Codex, 2026-10-30; number check pending)

All new files remain drafts; `claude-draft` is the only schema draft-author enum. Asterisk = default variant.
The table reports integer kcal and P/C/F grams **at the stated portion mass**, calculated from catalog ingredients,
not recipe-site nutrition panels. These are author calculations, not the independent D-087 check.
Every YAML records source URLs and quantities, edible/cooked ingredient states, water balance, fat/syrup retention,
and household gram ranges. See its additional units (piece, small plate, tablespoon, etc.) as well as the primary unit below.

| New ref ID / variant | Portion g (range g) | kcal | P / C / F g |
|---|---|---:|---|
| `ref:waraq_dawali/meat_rice` * | plate 330 (220–450) | 556 | 22.1 / 63.9 / 23.3 |
| `ref:waraq_dawali/vegetarian` | plate 330 (220–450) | 564 | 8.5 / 61.0 / 33.2 |
| `ref:mahshi_kousa/meat_rice` * | plate 480 (330–650) | 398 | 18.8 / 43.1 / 17.0 |
| `ref:mahshi_eggplant/meat_rice` * | plate 480 (330–650) | 409 | 18.1 / 47.7 / 16.6 |
| `ref:kofta_bil_tahini/tahini` * | plate 450 (330–600) | 756 | 37.1 / 44.2 / 50.0 |
| `ref:kofta_bil_tahini/tomato` | plate 450 (330–600) | 529 | 30.2 / 39.8 / 28.3 |
| `ref:fasoulia_with_rice/with_rice` * | plate 550 (400–750) | 720 | 34.6 / 92.4 / 23.2 |
| `ref:fasoulia_with_rice/stew_only` | plate 400 (300–550) | 526 | 32.2 / 45.0 / 24.6 |
| `ref:bamia_with_rice/with_rice` * | plate 550 (400–750) | 625 | 24.2 / 74.2 / 25.7 |
| `ref:bamia_with_rice/stew_only` | plate 400 (300–550) | 413 | 21.9 / 16.8 / 29.8 |
| `ref:bazella_with_rice/with_rice` * | plate 550 (400–750) | 552 | 24.3 / 72.6 / 18.1 |
| `ref:bazella_with_rice/stew_only` | plate 400 (300–550) | 344 | 21.0 / 23.5 / 19.0 |
| `ref:shish_tawook/breast` * | plate 240 (160–350) | 433 | 64.4 / 4.2 / 16.1 |
| `ref:kebab/beef` * | plate 200 (130–300) | 461 | 48.0 / 5.9 / 26.4 |
| `ref:kebab/lamb` | plate 200 (130–300) | 507 | 43.0 / 5.9 / 33.8 |
| `ref:fatteh/toasted` * | plate 400 (300–550) | 854 | 29.2 / 81.4 / 49.2 |
| `ref:fatteh/fried_bread` | plate 400 (300–550) | 933 | 28.4 / 79.0 / 59.5 |
| `ref:lentil_soup/red_lentil` * | bowl 300 (220–420) | 256 | 12.4 / 34.6 / 8.3 |
| `ref:freekeh_soup/chicken` * | bowl 300 (220–450) | 196 | 15.6 / 17.6 / 6.8 |
| `ref:freekeh_soup/vegetarian` | bowl 300 (220–450) | 154 | 3.8 / 21.0 / 6.4 |
| `ref:pasta_with_sauce/tomato` * | plate 350 (250–500) | 445 | 13.5 / 70.0 / 12.4 |
| `ref:pasta_with_sauce/meat` | plate 350 (250–500) | 480 | 23.7 / 60.6 / 15.6 |
| `ref:tabbouleh/parsley` * | plate 250 (180–350) | 358 | 5.1 / 21.7 / 30.1 |
| `ref:fattoush/toasted` * | plate 350 (250–450) | 275 | 5.1 / 24.2 / 19.1 |
| `ref:fattoush/fried_pita` | plate 350 (250–450) | 346 | 5.0 / 23.6 / 27.4 |
| `ref:baba_ghanoush/tahini` * | bowl 150 (100–230) | 180 | 4.5 / 14.3 / 13.3 |
| `ref:baba_ghanoush/vegetable` | bowl 150 (100–230) | 53 | 1.8 / 12.8 / 0.4 |
| `ref:tahini_salad/vegetables` * | plate 300 (200–420) | 357 | 7.4 / 18.0 / 31.1 |
| `ref:yogurt_cucumber_salad/whole_milk_yogurt` * | bowl 200 (130–300) | 55 | 2.8 / 7.7 / 2.0 |
| `ref:knafeh_nabulsiyeh/fine_cheese` * | piece 145 (90–220) | 483 | 18.6 / 48.2 / 24.2 |
| `ref:qatayef/walnut_fried` * | piece 43 (30–80) | 136 | 2.0 / 17.5 / 7.0 |
| `ref:qatayef/walnut_baked` | piece 41 (30–80) | 119 | 2.0 / 17.5 / 5.0 |
| `ref:qatayef/cheese_fried` | piece 46 (30–80) | 119 | 3.3 / 15.4 / 4.9 |
| `ref:qatayef/cheese_baked` | piece 44 (30–80) | 101 | 3.3 / 15.4 / 2.9 |
| `ref:baklava/walnut` * | piece 50 (30–80) | 221 | 3.1 / 22.1 / 14.4 |
| `ref:baklava/pistachio` | piece 50 (30–80) | 208 | 3.8 / 24.0 / 11.6 |
| `ref:basbousa/ghee_yogurt` * | piece 92 (60–140) | 352 | 4.1 / 51.5 / 15.0 |
| `ref:basbousa/namoura_egg` | piece 80 (50–120) | 270 | 3.7 / 42.7 / 9.9 |
| `ref:maamoul/date` * | piece 35 (25–55) | 141 | 2.4 / 20.0 / 6.1 |
| `ref:maamoul/walnut` | piece 36 (25–55) | 169 | 3.3 / 15.6 / 10.8 |
| `ref:awameh/fried_syrup` * | piece 18 (12–28) | 50 | 0.5 / 8.4 / 1.6 |
| `ref:muhallabiya/milk` * | small_bowl 140 (100–190) | 157 | 4.3 / 24.2 / 5.0 |
| `ref:tea_with_sugar/two_teaspoons` * | glass 158.4 (110–210) | 34 | 0.0 / 8.8 / 0.0 |
| `ref:sahlab/milk_starch` * | glass 267 (200–350) | 277 | 8.7 / 35.4 / 11.7 |
| `ref:qamar_al_din/sweet` * | glass 250 (200–330) | 299 | 2.9 / 77.7 / 0.4 |
| `ref:qamar_al_din/diluted` | glass 250 (200–330) | 225 | 2.1 / 58.2 / 0.3 |
| `ref:jallab/date` * | glass 300 (230–400) | 272 | 2.1 / 53.1 / 6.1 |
| `ref:date_syrup/plain` * | tbsp 20 (16–25) | 54 | 0.2 / 13.0 / 0.1 |

Existing-basic choices (these avoid duplicate recipe identities):

| Batch item | Existing ID / portion | kcal | Why / limits |
|---|---|---:|---|
| Grilled chicken | `usda:chicken_whole_roasted`: quarter 180 g, half 360 g, whole 720 g | 430 / 860 / 1721 | Roasted meat/skin proxy; edible weights exclude bones; whole bird size/yield assumed. Ranges 130–250 / 260–500 / 520–1000 g live in selection notes because basic serving records only store point grams. Added quarter/whole labels; existing half label reused. |
| Pickles | `usda:pickled_cucumber_dill`: piece/small spear 35 g (15–65) | 4 | Brined cucumber proxy; oil/sweet pickles differ. |
| Halawa | `usda:halawa`: piece 30 g (20–60) | 141 | USDA tahini-halva composition already exists; piece modelled near one ounce. |
| Arabic coffee | `usda:coffee_brewed`: Arabic small cup 25–30 g; shared serving 60 g (25–90) | <1 / about 1 | Unsweetened; no grounds eaten. Generic USDA cup remains 237 g. |
| Turkish coffee | `usda:coffee_brewed`: serving 60 g (25–90) | about 1 | Unsweetened brewed proxy; each added tsp sugar is 4.2 g, about 16 kcal. |
| Laban/ayran | `usda:buttermilk_lowfat`: glass about 250 g / 250 ml | 100 | Existing low-fat cultured-milk proxy; watered yogurt ayran is often lighter. |
| Plain juices | `usda:orange_juice` default: glass about 250 g / 250 ml | 113 | No added sugar. Named apple/grape/pomegranate basics retain separate identities and nutrients. |
| Soft drinks | `usda:lemon_lime_soda` / `usda:cola`: can about 330 g / 330 ml | 135 / 139 | Existing sugar-sweetened basics; diet/zero stays separate. |
| Tamarind | `usda:tamarind_nectar`: glass 261 g / about 250 ml (209–345 g) | 149 | Existing owner-approved sweet canned nectar proxy; homemade sugar varies. |
| Dates | `usda:dates_medjool`: 24 g (20–30); `usda:dates_deglet_noor`: 7.1 g (6–10) | 66 / 20 | Existing pitted date basics; large/small dates need different pieces. |

Five check priorities (uncertainty, not a request to release):
1. **Knafeh:** source bakes surplus crumbs; the used fraction is assumed 80%. Ghee volume/density, desalted cheese label proxy and 300 g syrup sugar eaten need scrutiny.
2. **Qatayef:** all four variants assume 30 pieces and 200 g dipping-syrup sugar retained; frying absorption is 3 g/piece versus 1 g brushing oil for baking.
3. **Mahshi (both vegetables):** mixed source pot adapted to one vegetable; 20 cored shells total 1 kg, sauce served and portion allocation are modelled, not weighed.
4. **Grilled chicken:** 720 g edible cooked meat/skin from a 1.5 kg ready-to-cook bird is an explicit 48% yield assumption; bone-in plate weight would be misleading. Skin eaten and quarter anatomy vary.
5. **Jallab:** selected published date-only home variant uses a large 80 g syrup per glass; commercial grape/carob syrup differs. Cup-to-gram density, fill water and nuts dominate. Supporting `date_syrup` label omits fibre (provisional zero, disclosed and cross-checked against another producer's <0.5 g).

Other scope notes: coffee remains unsweetened with sugar added separately; sweet tea explicitly contains 8.4 g sugar
per 150 g brewed tea (about 150 ml). Sahlab is the cornstarch home version, not orchid powder. Qamar al-din uses
the cited homemade leather recipe with its sugar counted, not an uncited commercial leather composition; the
very sweet source pitcher and its 75/25 dilution are separate variants. Baklava follows a documented honey-syrup
recipe (ghee replaces butterfat); a commercial sugar-only syrup would differ. No family recipe claims are made (TQ-08).

Checks: `make catalog`, `make catalog-check`, explicit `catalog validate --require-ar`, catalog `dart test` (129),
`make gen-app`, the two requested Flutter test files (15), targeted `CatalogTests` (5) and `BuddyPublicEvalTests` (4)
all passed. Both Buddy AQ baseline scripts exit 0 while warning on the existing known misses (M3 18, B09 1) and
AQ-05 case backlog. No fixture hash re-pin (pack layout unchanged), no schema/app/server logic change, no full suites.
`git diff --check` and label-file formatting pass. No commits or `.git` writes. New refs stay out of the shipped pack;
the ID lock will gain their IDs when the orchestrator releases them after the independent check.


## A19 + A30 fix-round handoff (Codex, 2026-10-30)

This supersedes the initial author handoff above for the changed items. Existing review statuses and
reviewed_by fields are untouched; both new coffee identities are draft / claude-draft. No commits or
.git writes. The new coffee refs must be rechecked and released together: the current production pack excludes them while draft, so the small-cup search behavior is verified in the draft-enabled pack and takes effect in production only on their release. No rejected dish is supported for release by this round. Their numeric rows remain
explicit diagnostic placeholders while the missing evidence is collected, rather than substituting
new guesses. The independently accepted tahini baba variant, bamia, fattoush and chicken serving
model have their requested fixes, ready for the orchestrator's recheck/status decision.

| Item / main portion | Before → after kcal | Change / evidence limit |
|---|---:|---|
| Qatayef walnut fried, piece 43 → 51.60 g | 136 → 184 | Walnuts 180 → 360 g [300,440], cinnamon 5 → 10 g, honey 63 → 126 g; whole batch 1300 → 1548 g [1388,1718]. |
| Qatayef walnut baked, piece 41 → 49.60 g | 119 → 166 | Same doubled filling; whole batch 1240 → 1488 g [1334,1652]. |
| Qatayef cheese fried, piece 46 → 55.67 g | 119 → 144 | Akkawi 300 → 600 g [500,800]; whole batch 1370 → 1670 g [1483,1907]. |
| Qatayef cheese baked, piece 44 → 53.67 g | 101 → 126 | Same doubled filling; whole batch 1310 → 1610 g [1429,1841]. |
| Baba ghanoush tahini, bowl 150 g | 180 → 180 | Accepted variant unchanged; vegetable 53 kcal/150 g removed (unquantified omitted oils). |
| Bamia with rice, plate 550 g / stew-only plate 400 g | 625 / 413 → same | Notes now say 213 g rice + 337 g stew in the mixed plate. |
| Fattoush toasted / fried pita, plate 350 g | 275 / 346 → same | First recipe URL replaced with the working Palestine in a Dish URL. |
| Mahshi kousa / eggplant, plate 480 g | 398 / 409 → same | Removed both 100 g piece portions. Pot concentration still unsupported; draft. |
| Knafeh, piece 145 g | 483 → 483 | Alternate sources specify dough/syrup for different recipes, but do not establish this flour-dough allocation or finished tray mass; draft. Fresh mozzarella vs generic FDC proxy explicitly distinguished. |
| Awameh, piece 18 g | 50 → 50 | A different batter has a 45-piece yield; published syrup absorption still needs pre-syrup fried mass and oil uptake; no compatible finished weights, so draft. |
| Pasta tomato / meat, plate 350 g | 445 / 480 → same | BHF and Foodbank whole-meal mince/pasta ratios found, but neither supports the old recipe or states a finished pot mass; no invented reduction; draft. |
| Grilled chicken quarter / half / whole | 430 / 860 / 1721 → same | Actual release serving records now carry 180 [130,250], 360 [260,500], 720 [520,1000] g, edible meat + skin, household source. |
| Arabic / Turkish coffee, cup | 2.37 / 2.37 → 0.30 / 0.60 | Explicit names move off generic 237 g cup onto separate draft 30 / 60 g identities. Former shared 60 g serving was 0.60 kcal. Generic names restored exactly, generic cup stays 237 g. New identities await orchestrator recheck/release. |

Qatayef weights are a consistent correction of the previous conditional draft, **not new measured
weights**: the original assumed steam losses carry forward; extra filling masses and bounds are
added; piece masses/bounds divide by the sourced 30-piece count, rounded to 0.01 g, and two_pieces
is twice that displayed portion. Syrup sugar/water and fry/bake oil remain unsupported. The exact
mass derivations and source comparisons are in `qatayef.yaml` review.notes. Counts alone cannot
establish finished concentration. All other rejected dishes' notes likewise identify what each new
source establishes and what is still missing. The Egyptian syrup-absorption PDF timed out; its
search-index finding is recorded as such and was not used to set nutrient rows.

Checks: `make catalog` and `make catalog-check` pass (v24, 626 basics, 40 released dishes / 60
variants; new coffee refs and batch drafts excluded). Catalog `dart test`: **131 passed**, including
new production-release/SQLite chicken range and draft coffee identity/cup regressions. Flutter
`unit_labels_test.dart` + `offline_catalog_test.dart`: **15 passed**. Format verification and
`git diff --check` pass. Direct read-only inspection of both built and app-asset SQLite packs confirms
all three chicken ranges and household sources. Existing review status/author pairs verified unchanged.
No label/ARB changes, so `make gen-app` is unnecessary. The analyzer initially hit read-only
`~/.dartServer`; using `ANALYZER_STATE_LOCATION_OVERRIDE=/tmp/fb-catalog-fix-analyzer` resolved it.
`dart analyze --fatal-infos lib test/real_data_test.dart` passes after replacing the new test
cleanup's deprecated SQLite `dispose()` with `close()`.
No backend import/eval rerun in this fix round: no backend, release schema, pack layout or exporter
logic changed; the existing release serving path is covered by the new SQLite regression. No
fixture SQL/hash change. No Buddy baseline edits. Heavy commands use `timeout 600` and heavy.sh;
sandbox workaround opens the canonical machine-wide cache lock read-only for flock, while the
wrapper writes its own lock/log under `/tmp` (serialization with other lanes preserved).

Files changed: `data/reference_dishes/{qatayef,baba_ghanoush,bamia_with_rice,fattoush,
knafeh_nabulsiyeh,awameh,mahshi_kousa,mahshi_eggplant,pasta_with_sauce,arabic_coffee,
turkish_coffee}.yaml` (last two new); `data/{usda_selection,portion_words,must_cover,
catalog_release}.yaml`; `tools/catalog/lib/src/validate/validate_yields.dart`;
`tools/catalog/test/real_data_test.dart`; this card. Generated local catalog/app assets rebuilt,
tracked fixture SQL unchanged.

## Outcome (A19 + A30, 2026-10-30)
One combined step (owner): plan, authoring and fixes by Codex, independent number check and fix-check by fresh Codex tasks (D-087). 26 dishes released as `ai-verified`: baba ghanoush (tahini), baklava, bamia, basbousa, bazella, date syrup, fasoulia, fatteh, fattoush, freekeh soup, jallab, kebab, kofta, lentil soup, ma'amoul, muhallabiya, qamar al-din, sahlab, shish tawook, tabbouleh, tahini salad, tea with sugar, waraq dawali, yogurt-cucumber salad, Arabic coffee (30 g finjan), Turkish coffee (60 g cup). Basics extended: grilled chicken portions with exported ranges (validator + test), pickles, halawa, juices, soft drinks, tamarind, dates. **Kept draft (no source supports the decisive syrup/oil/yield quantities):** knafeh, qatayef (filling fixed: it used half-batch fillings), awameh, mahshi kousa and eggplant, pasta with sauce; they go to A32 or the owner's family recipes (TQ-08). Must-cover 115: 61 reviewed, 6 draft, 47 basic, 1 missing (baladi cheese). Checks: catalog + catalog-check, catalog tests 131, unit labels/offline catalog 15, CatalogTests 5, BuddyPublicEvalTests 4, known misses unchanged (M3 18, B09 1). Follow-up: app ranker regression test for "finjan qahwa" (backlog).

## Log
| Batch | Date | Dishes | Notes |
|---|---|---|---|
| A04 | 2026-10-17 | 0 dishes (TD-074); 246 basics, 7 draft single local foods | `make catalog`: 246 basics + 12 dishes valid, 12 yield rows, 74 portion words; must-cover 115: 42 basic, 10 draft, 63 missing (dishes deferred) |
| | | | |
| A17 | 2026-10-30 | 16 new drafts (7 breakfast and bread, 9 main dishes A); 3 earlier drafts (maqluba, musakhan, mloukhiyeh) kept | `make catalog` + `catalog-check` green: 626 basics, release pack 7 dishes (drafts excluded); with drafts 28 dishes / 44 variants, sanity 639 ok / 28 warn (all warnings are old basics) / 3 waived; must-cover 115: 5 reviewed, 21 draft, 47 basic, 42 missing; the A17 list is fully covered except baladi cheese |
| A18 | 2026-10-30 | 11 new drafts (street food); falafel and chicken shawarma drafts re-aliased | `make catalog` + `catalog-check` green: 626 basics, release pack 7 dishes; with drafts 40 dishes / 60 variants, sanity 655 ok / 28 warn (old basics) / 3 waived; must-cover 115: 5 reviewed, 31 draft, 47 basic, 32 missing; all A18 items covered |
