# D1–D6 — Reference dish batches (data workstream)

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P1–P5, in parallel with code steps | S11 (format frozen), then the previous batch | S each (one session per batch) | ⬜ Not started |

**Goal.** Build the reviewed local food knowledge that makes "a plate of maqluba" a trustworthy number: every must-cover item (`spec/11` §6) as a reviewed reference dish or a database food, findable by English, Arabic and Arabizi names.

**Spec:** FD-004, FD-050, FD-051, FD-052, LC-050, LC-051, AT-003, D-046, D-075 · **Decisions:** TD-010

## Batches

| Batch | When (needed by) | Content |
|---|---|---|
| **D1** | Before S13 | **Basics** for the offline pack: Arabic names + Arabizi aliases for the generic basics list (`spec/11` §6 "Basics"), yields, portion words. **Breakfast & bread** (taboon, pita/khubz, shrak, ka'ak al-quds, labaneh, zaatar + oil, white cheeses, halloumi, olives, eggs, shakshuka, makdous, Arabic salad) |
| **D2** | During P2 | **Main dishes A:** maqluba (3 variants), musakhan, mansaf, mujaddara, maftoul, freekeh with chicken, mloukhiyeh with rice, rice with vermicelli, chicken & rice, kabsa, sumaqiyyeh, qidra |
| **D3** | During P3 (before S31) | **Out & street food:** falafel (piece, sandwich), chicken shawarma (sandwich, arabi, plate), meat shawarma, hummus plate, ful, msabbaha, fries, zinger, broasted, manakeesh, lahm bi ajeen/sfiha, fatayer, pizza slice, burger |
| **D4** | Before S34 (P4 exit) | **Main dishes B + salads & sides:** waraq dawali, mahshi, kofta/siniyyeh, fasoulia, bamia, bazella, shish tawook, kebab, grilled chicken, fatteh, lentil soup, freekeh soup, pasta with sauce · tabbouleh, fattoush, baba ghanoush/mutabbal, tahini salad, yogurt-cucumber, pickles |
| **D5** | During P5 | **Sweets, drinks, Ramadan staples:** knafeh, qatayef (variants), baklava, harissa/basbousa, ma'amoul, awameh, muhallabiya, halawa · Arabic/Turkish coffee, tea with sugar, sahlab, laban/ayran, juices, soft drinks, qamar al-din, jallab, tamarind · dates |
| **D6** | Before S40 (P5 exit) | **Gap fill:** dishes the owner actually logged as `~ estimate` during dogfooding, misses from the eval, anything still failing AT-003 |

## Per-batch session protocol
1. Pick the batch list. Check what's already covered by USDA basics.
2. For each dish: a typical home recipe (whole pot) from **≥ 1 cited source** (2 when they disagree), variants, cooked total weight, portions with grams + ranges for each local portion word, names EN/AR + common Arabizi spellings, notes on variation (oil!).
3. `make catalog` → validation + sanity + per-100 g + AT-003 name resolution.
4. **Owner skim** (≈ 15 min): "does a plate of this look right for how your family cooks it?" Adjust if needed. TQ-08: the owner's family recipes override generic ones.
5. Mark `review.status: reviewed`. Commit as `data(dishes): Dn …`.

## Exit criteria (per batch)
- [ ] Every dish in the batch validates, passes the sanity checks, and resolves by EN, AR and Arabizi.
- [ ] Owner skim done. Notes recorded in the dish files.
- [ ] After **D6**: **AT-003 green** across the whole must-cover list.

## Read first
`07-food-data.md` §4 · `spec/11-foods-and-data-quality.md` §6 · S11 Outcome (format, time per dish)

## Owner involvement
≈ 15 min skim per batch. Family recipes if you want them used (TQ-08).

---

## Log
| Batch | Date | Dishes | Notes |
|---|---|---|---|
| | | | |
