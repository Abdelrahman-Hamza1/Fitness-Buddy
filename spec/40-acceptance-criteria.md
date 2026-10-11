# 40 — Acceptance Criteria

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-060, D-075, D-076, D-079, D-080, success criteria SC-1 to SC-6._

## 1. R1 is "done" when

- **AT-001** Every requirement tagged `[R1]` across the spec is implemented, or explicitly moved to a later release by a new decision.
- **AT-002** The AI test set (§3) meets every threshold in §2.
- **AT-003** Every item on the must-cover list (`11` §6) exists as a reviewed reference dish or a database food, and can be found by English, Arabic and Arabizi name.
- **AT-004** The speed targets in `30-ux-principles.md` §1 are met on a mid-range Android phone (the Samsung A55). The same check on a recent iPhone happens in R2 (D-081).
- **AT-005** The offline scenarios in §4 pass.
- **AT-006** Data survives reinstall and a switch to a new phone (SC-6). An export contains everything (AC-030).
- **AT-007** **The owner has used it as their only tracker for 2 weeks** with no blocking issue. (SC-1 is then checked at 4 weeks.)

## 2. AI quality thresholds

Measured on the test set (§3), expanded to **at least 150 messages** before sign-off. The expanded set includes more of each category, and Arabic-script and Arabizi messages written the way the owner writes them (at least a quarter of the cases). Arabic and Arabizi versions of **every** case come in R2 (D-080).

| ID | Metric | Threshold |
|---|---|---|
| AQ-01 | Never adds, changes or deletes anything without confirmation | **100%** |
| AQ-02 | Foods correctly identified | ≥ 95% of items |
| AQ-03 | Explicit amounts and units read correctly | ≥ 98% |
| AQ-04 | Weighed items with a database match: calories within ±10% of the reference calculation | ≥ 95% |
| AQ-05 | Reference-dish portions: calories within ±25% of the reviewer's reference value | ≥ 85% |
| AQ-06 | Asks a clarifying question on cases designed to be ambiguous (with no saved default) | ≥ 90% |
| AQ-07 | Does **not** ask on cases designed to be unambiguous | ≥ 90% |
| AQ-08 | More than 2 questions on one message | **0 cases** |
| AQ-09 | Q&A answers numerically correct vs. calculated from the data | **100%** |
| AQ-10 | Every estimate is marked as an estimate | **100%** |
| AQ-11 | **R2 gate** (D-080): Arabic and Arabizi versions score within 5 percentage points of the English version on AQ-02 to AQ-07. In R1, per-language scores are reported, with no threshold | R2: yes |
| AQ-12 | Proposal shown within 5 s | ≥ 90% of messages |

## 3. AI test set — core cases (D-076)

Written in the owner's style: lowercase, short, typos, mixed languages. "Expected" describes the proposal. Values marked ≈ are reference points for AQ-04/05, to be finalised with the chosen food data.

Assume no saved defaults unless the case says otherwise.

### Home-cooked, with amounts
| # | Message | Expected |
|---|---|---|
| T01 | `fried egg w 1 tbsp olive oil` | Egg, large ×1 (≈72 kcal) + olive oil 1 tbsp (≈119 kcal) ≈ 191 kcal. **No question.** Chip: "all oil eaten". |
| T02 | `200g rice, 200g chicken breast raw, cooked with an onion` | Dish group: rice 200 g, chicken breast raw 200 g (≈240 kcal), onion medium ×1. **Asks:** rice raw or cooked? (≈730 vs ≈260 kcal). **Asks or assumes oil:** "cooked with" → asks about oil (2nd question). |
| T03 | same as T02, with saved default "rice = raw weight" and "cooking oil = 1 tbsp olive oil" | No questions. Chips: "raw weight (your default)", "1 tbsp olive oil (your default)". |
| T04 | `chiken brest 250 cookd` | Chicken breast, cooked, 250 g. Typos tolerated. No question. |
| T05 | `2 eggs omlette w some cheese` | Omelette: eggs ×2 + white cheese ~30 g (`~ estimate`) + cooking fat (default or question). |
| T06 | `500ml milk 3%` | Milk 3% fat, 500 ml. No question. |

### Home-cooked, no amounts / family-cooked
| # | Message | Expected |
|---|---|---|
| T07 | `akalt sahen maqlobe 3nd sitti` | Reference dish maqluba, 1 plate, `~ estimate`. Variant chip (chicken default), with a question only if the variants differ beyond the AI-060 threshold. Reply in English (AI-143). |
| T08 | `صحن ملوخية مع رز` | Mloukhiyeh + rice, 1 plate, reference dish, `~`. Reply in English (AI-143). |
| T09 | `labaneh w zaatar w zeit w taboon` | Labaneh ~2 tbsp, zaatar ~1 tbsp, olive oil ~1 tbsp, taboon bread ×1, all `~`, as one breakfast group. |
| T10 | `i ate my share of the mansaf, big plate, we were 6` | Reference dish mansaf, 1 large plate (the "we were 6" context is noted but a stated plate takes priority), `~`. |
| T11 | `ate a lot at the wedding` | **No proposal.** Asks what was eaten, with typical wedding foods as chips (D-072, AI-152). |

### Eating out
| # | Message | Expected |
|---|---|---|
| T12 | `شاورما دجاج عربي وبيبسي` | Chicken shawarma arabi (reference dish, `~`) + Pepsi 330 ml can (database). |
| T13 | `falafel sandwich + small fries` | Falafel sandwich (ref) + fries small (ref), `~`. |
| T14 | `2 slices pizza yesterday dinner` | Pizza slice ×2 (`~`), dated yesterday, slot Dinner. Asks size/type only if the threshold is met. |
| T15 | `knafe piece` | Knafeh nabulsiyeh, 1 piece (ref), `~`. |
| T16 | `zinger meal` | Zinger sandwich + fries + soft drink (ref, `~`). Chip: drink type / regular vs. diet. |

### Packaged
| # | Message / action | Expected |
|---|---|---|
| T17 | Barcode of a product in the database | Product shown → amount picker → logged directly with undo (no AI proposal, AI-048). |
| T18 | Barcode not found → label photo (Arabic label) | Label review screen with values read, sanity-checked. Saved as your food, linked to the barcode. |
| T19 | `1 snickers` | Snickers bar, standard size (database). No question. |

### Batch
| # | Message | Expected |
|---|---|---|
| T20 | `cooked a pot: 1kg chicken, 500g rice dry, 2 onions, 3 tbsp oil. ate like a third` | Batch proposal with ingredients + "log ⅓ now" portion. Batch stays open for leftovers. |
| T21 | (after T20) `leftovers of the chicken rice, a plate` | Portion from the open batch by plate weight, `~`. Remaining batch amount goes down. |
| T22 | `cooked 3 cups rice for the family i had 1 plate` | Asks whether rice is cooked plain (or a ref dish). Logs 1 plate of cooked rice, `~`. |

### Repeats & memory
| # | Message | Expected |
|---|---|---|
| T23 | `same breakfast as yesterday` | Proposal copying yesterday's breakfast. |
| T24 | `my shake` (personal food exists: 40 g whey + 300 ml milk) | Personal food, ⓨ badge. No question. |
| T25 | `remember i always weigh rice raw` | Memory proposal: "Rice → raw weight". |

### Corrections
| # | Message | Expected |
|---|---|---|
| T26 | `no the rice was 150g` | Edit proposal on the most recent rice entry: before 200 g → after 150 g, totals updated. |
| T27 | `move the shawarma to lunch` | Edit proposal: slot change. |
| T28 | `delete the pepsi` | Delete proposal showing the item. |
| T29 | `the chicken yesterday was thighs not breast` | Edit proposal swapping the food on yesterday's entry. If several chicken entries exist, asks which. |

### Ramadan
| # | Message | Expected |
|---|---|---|
| T30 | `iftar 3 tamrat w laban w shorbet adas` | Slot Iftar: dates ×3, laban 1 glass, lentil soup 1 bowl (ref, `~`). |
| T31 | `suhoor at 3:30, 2 eggs, ful, bread` | Slot Suhoor on the **calendar day of 03:30** (the fasting day, DY-001). |
| T32 | `3 qatayef with cheese fried` | Qatayef cheese, fried ×3 (ref, `~`). |

### Weight, workouts, questions
| # | Message | Expected |
|---|---|---|
| T33 | `weighed 97.3 today` | Weigh-in proposal 97.3 kg, today, change vs. trend shown. |
| T34 | `push day bench 3x8 80 ohp 3x10 40 dips 3x12 incline db 3x10 30` | Workout proposal: 4 exercises matched; DB weight read as per dumbbell (WO-005). |
| T35 | `same as last push but bench 82.5` | Copy of last Push session with bench at 82.5. |
| T36 | `how much protein left` | Calculated answer, e.g. "62 g left (118/180)". No proposal. |
| T37 | `what can i eat w 600 kcal left` | 2–4 suggestions fitting ~600 kcal and remaining protein; halal; tapping one creates a proposal. |
| T38 | `avg calories last week?` | Calculated answer with link to the week. |

### Robustness
| # | Message | Expected |
|---|---|---|
| T39 | `breakfast 2 eggs and labaneh, lunch shawarma, also weighed 97.2` | 3 proposals (Breakfast, Lunch, weigh-in) in one reply (AI-015). |
| T40 | `what's the weather` | Polite decline, back to topic (AI-003). |
| T41 | Message sent offline | Pending "will process when online". Becomes a proposal after reconnect. |

## 4. Offline scenarios

- **OF-01** Airplane mode: log a quick-add chip, edit an entry, log a weigh-in, log a workout by form, view charts → all work.
- **OF-02** Airplane mode: send a Buddy message and scan a barcode → both queued as pending → processed into proposals after reconnect.
- **OF-03** Edit the same entry on two devices offline → after sync, the latest change wins and the other is recoverable (AC-012).

## Open questions

None currently. The test set is a draft (D-076). The owner can add real messages at any time, and each one becomes a new test case.
