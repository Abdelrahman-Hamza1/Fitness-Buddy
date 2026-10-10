# Competitive Analysis

_Round 1 — 2026-10-10. Sources are listed at the bottom. Many review sources in this space are vendor-written, so complaints below are "commonly reported" patterns, not measured facts. Features of competitors change often, so re-verify before relying on a specific claim._

## TL;DR — the gaps Fitness Buddy can fill

1. **Logging friction.** Traditional trackers make you search, pick an entry, and set a serving for *every ingredient*. Natural-language logging exists in some apps, but it's usually a black box: it guesses portions, doesn't ask about ambiguity, and is hard to correct.
2. **Trust in the numbers.** Crowdsourced databases (MyFitnessPal) are full of wrong or duplicate entries. Photo-AI apps (Cal AI and similar) estimate portions from a picture, and the error can be large. Cronometer is trusted because entries are curated and labelled verified vs. user-contributed.
3. **Raw vs. cooked and home cooking.** Almost no app handles "I cooked X, Y, Z together and ate part of it" well. Recipe builders exist but are tedious, and few apps help with cooked-yield weights.
4. **Paywalls and ads.** The most common complaint category (especially MyFitnessPal: barcode scanning moved to Premium, heavy ads).
5. **Fragmentation.** Nutrition apps do workouts badly, and workout apps (Hevy, Strong) do nutrition badly or not at all. Users run 2–4 apps plus Apple Health and lose the cross-insights (e.g. protein intake vs. strength progress, calories vs. trend weight vs. training volume).
6. **Weight noise.** Most apps plot raw scale weight, which swings ±1–2 kg on water and sodium. Only a few (MacroFactor, Happy Scale, Libra) show a smoothed trend and use it to adapt targets.

## Nutrition apps

### MyFitnessPal
- **Strengths:** Huge database (~14M+ entries), wide barcode coverage, brand recognition, lots of integrations.
- **Flaws:** Mostly user-submitted entries with no systematic verification. Some reviews report entries off by more than 25%, and there are many duplicate or contradictory entries for the same food. Aggressive paywalls (barcode scanner went Premium) and ads. The UI is slow and cluttered. Recipe import exists but is clunky. Exercise calories get added back by default, which inflates the intake budget.
- **Take:** Wide coverage matters. Don't repeat the crowdsourced-junk problem.

### Cronometer
- **Strengths:** Curated data (USDA, NCCDB and similar), labels entries as verified vs. crowd-contributed, deep micronutrient tracking (80+ nutrients), well liked by people who care about data.
- **Flaws:** The UI is "functional, not beautiful", with a steeper learning curve. Logging takes as many steps as MyFitnessPal. Ads in the free tier. Less suited to quick casual logging.
- **Take:** Show where each number came from (data provenance). Optional micronutrient depth is a real differentiator for some users.

### MacroFactor
- **Strengths:** An adaptive expenditure (TDEE) algorithm that re-estimates energy needs weekly from intake and trend weight. A smoothed weight trend. Weekly target adjustments ("coach"). Fast logging by action count. No ads. Strong reputation in the evidence-based fitness community. Has reportedly added AI-assisted logging (describe or photo) in 2025 to 2026 (verify).
- **Flaws:** Subscription only, no free tier. Workouts live in a separate app (MacroFactor Workouts). The algorithm assumes fairly consistent logging, and the app is less forgiving of missed days or partial logging.
- **Take:** This is the gold standard for the weight and target logic. Its main weakness is that nutrition and training are split across two apps.

### Lose It!, Yazio, FatSecret, MyNetDiary
- Simpler, friendlier, aimed at casual users. Similar complaints about paywalls and ads, and the databases are mixed quality. FatSecret's free API is widely used by smaller apps.

### AI-first trackers (Cal AI, SnapCalorie, Calorize, etc.)
- **Strengths:** Very low friction: take a photo and you're done. Good for engagement.
- **Flaws:** Portion size can't be estimated reliably from a 2D photo, because hidden oil, sauces and density are invisible. Errors pile up across speech-to-text, food identification, quantity parsing and database matching. Many apps let the LLM *make up* nutrition values instead of looking them up in a database. Users often can't see or fix the assumptions behind a number.
- **Research note:** Studies of multimodal AI logging (e.g. SnappyMeal, arXiv 2511.03907) find that users value speed but lose trust when results are opaque.
- **Take:** Our AI should *parse and ask questions*, not *guess*. Numbers should come from a database whenever possible, and every assumption should be visible and editable.

## Workout apps

### Strong
- **Strengths:** Simple, fast set logging. Good CSV export.
- **Flaws:** Development has stalled, with few new features. There are reports of workouts and routines being lost with large histories (1000+ workouts).
- **Take:** Data durability and export aren't optional.

### Hevy
- **Strengths:** Modern UI, social feed, good free tier, routines, PR tracking.
- **Flaws:** Some progress analytics are paywalled. Reported sync problems with wearables. Can't save changes made mid-workout back to the routine easily (reported). Choosing which routines show on the watch is limited. Export is less complete than Strong's.
- **Take:** Let "update the routine from this session" be a single action. A watch companion is a nice-to-have, not core.

### Fitbod and other AI programmers
- Generate workouts based on recovery and equipment. The AI programming is often seen as generic. Some users want to log their *own* program, not follow an AI one.

## Weight-trend apps (Happy Scale, Libra)
- Simple apps that do one thing: smoothed trend weight, goal projection, and showing that a daily spike is noise. Popular because the scale number is emotionally hard to deal with.
- **Take:** Show trend weight first and raw weight second.

## What nobody does well (opportunity list)
| # | Gap | Notes |
|---|---|---|
| G1 | Conversational logging with **clarifying questions** instead of silent guesses | e.g. "Was the 200g of rice weighed raw or cooked?" |
| G2 | **Home-cooked batch meals**: ingredients in, cooked pot weight, portions out over days | Mostly tedious recipe builders today |
| G3 | **Personal memory**: "my usual oats", "same as Tuesday", default cooking oil, personal portion sizes | Partially in some apps |
| G4 | **Unified nutrition + training + body** insights in one place | Usually split across apps |
| G5 | **Transparent numbers**: provenance and confidence for every value | Only Cronometer, partly |
| G6 | **Conversational corrections**: "actually it was 150g", "move that to lunch" | Rare |
| G7 | **Regional and local foods** (non-US cuisines, local brands, local barcodes) | Big weakness of US-centric databases; depends on where the user lives |
| G8 | **Ownership of your data**: full export, import from MyFitnessPal/Cronometer/Hevy/Strong | Mostly poor |

## Sources
- [Calorie tracking apps ranked by 1-star reviews (2026) — unstar.app](https://unstar.app/blog/calorie-tracking-apps-ranked-1-star-reviews-2026)
- [Diet App Scorecard Feb 2026 — MyNetDiary (vendor)](https://www.mynetdiary.com/diet-app-scorecard-february-2026.html)
- [MacroFactor vs Cronometer (vendor)](https://macrofactor.com/macrofactor-vs-cronometer/)
- [MacroFactor vs MyFitnessPal 2025 (vendor)](https://macrofactor.com/macrofactor-vs-myfitnesspal-2025/)
- [MyFitnessPal vs Cronometer vs MacroFactor 2026 — Nutrola (vendor)](https://nutrola.app/en/blog/myfitnesspal-vs-cronometer-vs-macrofactor-2026)
- [MacroFactor vs MyFitnessPal 2026 — Welling](https://www.welling.ai/articles/macrofactor-vs-myfitnesspal-2026)
- [How accurate is voice logging — Nutrola (vendor)](https://nutrola.app/en/blog/how-accurate-is-voice-logging-for-calorie-tracking)
- [SnappyMeal: multimodal AI food logging study (arXiv)](https://arxiv.org/html/2511.03907v1)
- [MIT spoken food logging (Korpusik 2019)](https://people.csail.mit.edu/korpusik/nutrition2019_korpusik.pdf)
- [Hevy vs Strong — Setgraph](https://setgraph.app/ai-blog/hevy-vs-strong)
- [Gym app recommendations — MacPowerUsers forum](https://talk.macpowerusers.com/t/gym-iphone-app-recommendation/32667)
- [Hevy reviews — JustUseApp](https://justuseapp.com/en/app/1458862350/hevy-gym-trainingstagebuch/reviews)
