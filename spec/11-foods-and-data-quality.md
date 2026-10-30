# 11 — Foods & Data Quality

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-011, D-019, D-037, D-046 to D-048, D-051, D-064, D-073, D-075, D-080._

This file defines **what food data the product needs and how it behaves**. Which databases or APIs supply it is decided in technical planning (D-005). Their licences must allow everything below (C-5).

## 1. What a food is

- **FD-001** `[R1]` Every food has: a name in English, aliases, nutrients per 100 g (or per 100 ml for drinks), its state (raw / cooked / dry / as sold), optional brand, optional barcode(s), serving units with their gram weights, a **source**, and a verification status.
- **FD-002** `[R1]` Core nutrients, always present: **calories, protein, carbs, fat, fiber** (D-037). Optional when the data has them: sugar, saturated fat, sodium, and others. They're shown under "more" on an item, never required (D-019).
- **FD-003** `[R1]` Serving units include standard ones (g, ml, oz, cup, tbsp, tsp, piece) and local ones where they make sense (رغيف loaf, صحن plate, حبة piece, كاسة glass, سندويشة sandwich, قرص disc), each with a gram weight for that specific food.
- **FD-004** `[R1]` Must-cover items (§6) and the basics also have an Arabic name and common Arabizi and dialect spellings as aliases (D-080).
- **FD-005** `[R2]` Every food has an Arabic name (D-080, for the Arabic interface, LC-003).

## 2. Sources & provenance (D-011)

| Badge | Source | Trust |
|---|---|---|
| **ⓨ yours** | Personal foods, label scans, saved meals, batch dishes, values edited by you | You own it |
| **ⓓ database** | Verified generic and branded food data | High |
| **ⓡ reference dish** | Reviewed recipes for local and mixed dishes (§6) | Medium: real recipe, typical portion |
| **~ estimate** | AI estimate when nothing else matches | Low: always marked, range shown |

- **FD-010** `[R1]` Each logged item stores and shows its source badge (SC-4).
- **FD-011** `[R1]` When several sources match, priority is: yours → database → reference dish → estimate (AI-070).
- **FD-012** `[R1]` Sanity check on every food: calories should roughly match protein×4 + carbs×4 + fat×9 (+ fiber, alcohol). Foods that fail are not used as "verified", and user-created ones get a gentle warning.

## 3. Search (manual logging)

- **FD-020** `[R1]` One search box, tolerant of typos in English. Arabic script and Arabizi find foods by their listed names and spellings (FD-004) (D-080).
- **FD-024** `[R2]` Arabizi search is also tolerant of unlisted spellings and typos (D-080).
- **FD-021** `[R1]` **No duplicate clutter** (PR-5): results are de-duplicated, and each distinct food appears once. Your foods and recent foods come first, then database results, then reference dishes.
- **FD-022** `[R1]` Picking a result → amount + unit picker (defaulting to your last-used amount for that food) → add. This is a direct action (AI-048), so it applies immediately with undo.
- **FD-023** `[R1]` Offline search covers: your history, your foods, and a built-in set of common basic foods, including all must-cover items (§6) (D-049).

## 4. Barcode

- **FD-030** `[R1]` Scan → product shown (name, brand, per-serving and per-100 g values) → choose amount → logged directly with undo (AI-048).
- **FD-031** `[R1]` Product coverage priorities: **Palestinian, Jordanian, Turkish and other imported products** sold in the West Bank (D-073), plus international brands.
- **FD-032** `[R1]` Not found → "Scan the label instead" goes straight to §5, and the new food is linked to that barcode so the next scan finds it.
- **FD-033** `[R1]` A product found with incomplete data (e.g. missing fiber) can be completed with a label scan.

## 5. Nutrition-label photo (D-047)

- **FD-040** `[R1]` Photo of a nutrition facts panel in **Arabic or English** (D-073), per 100 g/ml or per serving.
- **FD-041** `[R1]` The app reads the values and shows a **review screen** (a proposal, D-079): name (prefilled from the package photo if available, otherwise asked), serving size, core nutrients, plus any other nutrients found. Values that are uncertain or failed the sanity check (FD-012) are highlighted.
- **FD-042** `[R1]` Confirming saves it as **your** food (private, D-048), optionally linked to a scanned barcode, and lets you log an amount straight away.

## 6. Reference dishes — local food coverage (D-046, D-051, D-075)

Restaurants in the region publish no nutrition data, and most home food is mixed dishes. **Reference dishes are how the app gives a trustworthy number for "a plate of maqluba".**

- **FD-050** `[R1]` A reference dish has: names (EN, AR, common spellings), a typical recipe (ingredients + amounts), typical cooked weight per portion for each portion word used (plate, sandwich, piece, bowl, small/large), common variants (e.g. maqluba with chicken / cauliflower / eggplant), and the likely range (for the `~` range display, D-045).
- **FD-051** `[R1]` Reference dishes are **reviewed** before shipping: checked against at least one published recipe, with sanity-checked numbers. A dish that hasn't been reviewed falls back to "~ estimate".
- **FD-052** `[R1]` Every item on the must-cover list below exists as a reference dish or a database food before R1 is done (see `40-acceptance-criteria.md`).
- **FD-053** `[R2]` Users can say "my version": save a reference dish with their own changes (e.g. "my mom's maqluba uses less oil"), which becomes their own food.

### Must-cover list (draft — the owner may skim; D-075; dishes ship after an independent AI number check, D-087)

**Main dishes:** maqluba (chicken / cauliflower / eggplant) · musakhan (piece, roll) · mansaf · mujaddara · maftoul · freekeh with chicken · mloukhiyeh with rice · rice with vermicelli (ruz bi sh'arieh) · chicken & rice · kabsa · sumaqiyyeh · qidra · waraq dawali (stuffed grape leaves) · mahshi (kousa, eggplant) · kofta bil tahini / siniyyeh · fasoulia with rice · bamia with rice · bazella with rice · shish tawook · kebab · grilled chicken (quarter / half / whole) · fatteh (hummus fatteh) · lentil soup (shorbat adas) · freekeh soup · pasta / spaghetti with sauce

**Out & street food:** falafel (piece, sandwich) · chicken shawarma (sandwich, arabi, plate) · meat shawarma · hummus plate · ful medames · msabbaha · fries · zinger sandwich · broasted chicken · manakeesh (zaatar, cheese) · lahm bi ajeen / sfiha · fatayer (spinach, cheese) · pizza slice · burger

**Breakfast & bread:** taboon bread · pita / khubz · shrak / markouk · ka'ak al-quds (plain, with egg/falafel) · labaneh · zaatar with olive oil · white cheese (Nabulsi, Akkawi, Baladi) · halloumi · olives · eggs (boiled, fried, omelette) · shakshuka · makdous · Arabic salad

**Salads & sides:** tabbouleh · fattoush · baba ghanoush / mutabbal · tahini salad · yogurt-cucumber salad · pickles

**Sweets:** knafeh nabulsiyeh · qatayef (walnut / cheese, fried / baked) · baklava · harissa / basbousa · ma'amoul · awameh / luqaimat · muhallabiya · halawa

**Drinks:** Arabic coffee · Turkish coffee · tea with sugar · sahlab · laban / ayran · fresh juices · soft drinks · qamar al-din · jallab · tamarind (tamer hindi)

**Ramadan staples:** dates · qatayef · lentil soup · qamar al-din · jallab (also listed above, so they're covered in Ramadan mode suggestions)

**Basics (generic database):** rice (dry/cooked), bulgur, freekeh, pasta, lentils, chickpeas, chicken breast/thigh, minced beef, lamb, fish, eggs, milk, yogurt, oils (olive, vegetable), butter, ghee, common fruits and vegetables, nuts, tahini, sugar, honey.

## 7. Cooking conversions

- **FD-060** `[R1]` Raw ↔ cooked yield factors for staples: rice, bulgur, freekeh, pasta, lentils, chickpeas/beans, chicken, beef, lamb, fish, potatoes. Used whenever the stated state differs from the matched food's state (AI-023).
- **FD-061** `[R1]` Fried foods: by default, stated oil is counted in full (assumption chip "all oil eaten", AI-033), with an alternative "most oil left in the pan" (counts a reduced share). Deep-fried database items already include absorbed oil.
- **FD-062** `[R1]` Yield factors are shown to the user when used ("200 g dry rice ≈ 500 g cooked").

## 8. Your foods (D-016, D-048)

- **FD-070** `[R1]` Personal foods are created from: chat ("my shake = 40g whey + 300ml milk"), label scans, the manual form, saved meals and batch dishes (`12`).
- **FD-071** `[R1]` Personal foods are **private** in R1 and R2 (D-048).
- **FD-072** `[R3]` A user-added food can be shared with everyone. It's marked **"user-added"** until verified, and never outranks verified data for other users.
- **FD-073** `[R1]` Personal foods can be edited, renamed, merged (duplicates) and deleted. Past diary entries keep their logged values (editing a food doesn't silently rewrite history).

## 9. Halal (D-064)

- **FD-080** `[R1]` Halal setting (on by default for the owner, offered at onboarding for others in R2).
- **FD-081** `[R1]` When on, products or dishes that likely contain pork, alcohol, or gelatin/emulsifiers of unknown source show a **warning** on scan, search result and proposal card. It's a warning, never a block, and "unknown" is worded as unknown, not as non-halal.
- **FD-082** `[R1]` When on, suggestions and meal ideas only include halal options (AI-120).

## Open questions

None currently.
