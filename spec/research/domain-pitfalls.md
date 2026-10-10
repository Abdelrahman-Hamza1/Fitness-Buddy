# Domain Pitfalls

_Hard problems the spec must explicitly handle. Each one becomes one or more requirements or questions. Round 1 — 2026-10-10._

## Food & nutrition

### P1 — Raw vs. cooked weight
Cooking changes weight but not calories. Rice roughly **doubles to triples** in weight (it absorbs water). Meat **loses ~20–35%** (chicken breast cooked yield is ~70–75%). So "200g rice" means about 730 kcal if weighed raw, and about 260 kcal if weighed cooked. That's a ~3× error from one missing word.
→ The AI **must** work out the state (raw, cooked, dry, drained) or ask. The user may have a default ("I weigh everything raw").

### P2 — Mixed dishes and batch cooking
"I cooked 500g chicken + 300g rice + an onion and ate a third" or "I ate 350g of the pot." Doing this correctly needs: ingredient totals → **final cooked weight of the pot** → nutrition per gram → portion. Without the pot weight, "a third" is the only workable unit.
→ Needs a recipe/batch model with leftovers carried across days.

### P3 — Hidden calories (oil, butter, sauces)
"Cooked with an onion" usually also means cooked in oil. 1 tbsp of oil is about 120 kcal and is the biggest single source of under-reporting. And oil left in the pan isn't eaten.
→ Ask about it, or apply a per-user default with a visible note ("assumed 1 tbsp olive oil, tap to change").

### P4 — Vague quantities
"A bowl", "a handful", "a medium apple", "a plate of rice". Converting these to grams is a guess, and the guess differs by culture and by person.
→ Use standard portion sizes plus a **personal portion memory** ("my bowl ≈ 350g cooked rice"). Show uncertainty.

### P5 — Database quality and provenance
Crowdsourced entries can be wrong by more than 25%. US labels allow ±20% tolerance. Generic entries (USDA) differ from local varieties. An LLM asked for nutrition values directly will **produce plausible but wrong numbers**.
→ AI parses → match to a trusted database → LLM estimate only as a labelled fallback. Store the **source** of every number.

### P6 — Regional food and barcode coverage
US databases cover US foods. Local dishes, local brands and local barcodes are often missing.
→ Needs a decision on the main region and cuisine (see questions).

### P7 — Licensing of food data
USDA FoodData Central: public domain, free. Open Food Facts: free, but the ODbL license has share-alike obligations that must be checked for commercial use. Commercial APIs (FatSecret, Nutritionix, Edamam, etc.) charge per call or per tier, and their terms often restrict caching and storage.
→ This shapes the architecture (can we cache or store their data offline?).

### P8 — Time and day boundaries
Late-night eating after midnight, time zones when travelling, logging yesterday's meal today, the "day" ending at 3am for shift workers.
→ Define what a "day" is, and support retroactive logging by natural language ("yesterday's dinner").

## Weight & body

### P9 — Scale noise
Daily weight swings of ±1–2 kg from water, sodium, carbs/glycogen, digestion, and the menstrual cycle. Raw daily values mislead people and can be demotivating.
→ Smoothed trend weight (e.g. an exponentially weighted moving average). Handle missing days and outliers.

### P10 — Energy expenditure estimation
Formula-based TDEE (Mifflin-St Jeor × activity factor) can be off by hundreds of kcal. Adaptive TDEE (from intake + trend change) is better but needs about 2–3 weeks of consistent data, and it breaks if logging is incomplete.
→ Needs handling for unlogged or partial days (exclude them? flag them?).

### P11 — Exercise calories
Wearables often overestimate active calories by a lot. Adding them back to the food budget is a common reason people don't lose weight.
→ Decide: add none back, a fraction, or a fixed amount, and make it explicit.

## AI

### P12 — Error compounding
Speech-to-text → food identification → quantity parsing → database match → portion assumptions. Each step adds error.
→ Show the **parsed breakdown** before or after saving, so it can be checked quickly.

### P13 — Cost and latency
Every AI log is an LLM call (and possibly a speech or vision call). It has to feel instant (target < 3–5 s) and stay cheap enough to log 5–15 times a day per user.
→ Cache, reuse personal foods without calling the AI, and pick the model by task.

### P14 — Privacy
Food, body weight and photos are sensitive health data. Sending them to an AI provider needs to be a conscious decision (consent, retention, and what gets sent).

### P15 — Safety
Tracking apps can make disordered eating worse. If anyone other than the owner uses the app: minimum-calorie guardrails, no shaming language, and care with rapid-loss goals. Disclaimers: not medical advice.

## Workouts

### P16 — Exercise identity
"Bench", "flat bench", "BB bench press", "barbell chest press" are the same exercise. Dumbbell vs. barbell vs. machine are different. Needs a canonical exercise library plus aliases, or PR history breaks.

### P17 — Load semantics
Per-dumbbell vs. total weight, bodyweight exercises (pull-ups with +10kg), assisted machines (negative load), unilateral sets, kg vs. lb plates. These affect volume and PR math.

### P18 — Data durability
Workout history is years of data (see Strong's data-loss reports). Needs reliable sync, backups and export from day 1.
