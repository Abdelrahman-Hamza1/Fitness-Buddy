# Questions — Round 1

> **Status: answered & processed (2026-10-10).** Answers are recorded in `decisions.md` as D-001 to D-036. Follow-ups are in `round-02.md`.

_2026-10-10. Read `research/competitive-analysis.md` and `research/domain-pitfalls.md` for the reasoning behind these._

**How to answer:** write under each `**A:**`. Short answers are fine ("b", "yes", "your rec"). Or reply in chat with numbers (e.g. `Q7: b`).

- ★ = **blocking**: these shape everything else, so please answer them.
- Others: if you don't care, write "rec" and I'll use my recommendation (it gets recorded as a decision you can override later).
- "I don't know yet" is a valid answer. It becomes a tracked open question.

---

## A. Vision, scope & you

**Q1 ★ Who is this app for?**
a) Only me (personal tool), b) me + friends/family, c) a public product on the App Store / Play Store, d) personal first, public later.
This decides auth, backend, costs, compliance, onboarding polish, monetization and safety features. _Rec: (d), but we design the data model and privacy as if it'll be public, so we don't have to rewrite later._
**A:** D, may start with me, then friends, if benefical could go public.

**Q2 ★ Which apps have you used, and what _specifically_ annoyed you about each?** This is the most important question in this round. Please be concrete: "MyFitnessPal: logging chicken took 6 taps, entries were wrong, …". Also: anything those apps did that you _loved_ and want to keep.
**A:** I have used MyFitnessPal and CHronometer, I like the variety of products they have, it's impressive, I hope we can do similar, but I hate the UI, especially free tier

**Q3 ★ Rank these modules by importance (1 = most important), and mark any you don't want at all:**
nutrition logging · weight tracking · body measurements · progress photos · workout logging (strength) · cardio/running · step count · water · sleep · habits · AI coach/chat · meal planning / suggestions · grocery lists · supplements · fasting timer.
**A:** 1. nutrution logging, 2 weight tracking 3 AI chat 4. meal. rest optional, some may derail or bloat the APP, you know what I mean, like they are good to have, like step count etc, but may be inconvient to either use, like water, or not important for starter.

**Q4 ★ If public (Q1 = c/d): business model?** Free, one-time purchase, subscription, freemium? AI calls cost real money per log (likely a fraction of a cent to a few cents each), so "free with unlimited AI" needs a plan. If personal only: what monthly AI/hosting budget is okay for you?
**A:** I want a SOLID free tier, maybe using some of the weaker models for a limited time, then we start billing.

**Q5 ★ Your situation as developer:** solo or a team? Which languages/frameworks do you know well? Rough time per week? Any target date for a usable version? (This decides how big the MVP can be.)
**A:** Solo. BTW, it will be flutter, but I want this to be spec, not technical

**Q6 What does MVP mean to you?** The smallest thing you'd actually use every day instead of your current app(s). E.g. "AI food logging + targets + weight trend; workouts can wait."
**A:** I want the spec to capture all we need.

**Q7 About you as a user** (we design around a real person first):

- Current goal: cut / bulk / maintain / recomp / health?
- Do you weigh food on a kitchen scale? Always / sometimes / never?
- Mostly home cooking, or eating out / delivery?
- Cuisine(s) you eat most, and which country you live in? (Affects food database, local brands, barcodes.)
- Meals per day, and do you meal-prep in batches?
  **A:** IM cutting, I have a scale but get lazy, mix of home cooking and eating out, middle eastern.

**Q8 Languages and units:** Which language(s) will you type or speak food in? (English only? Arabic? Mixed, e.g. English sentences with local dish names?) Should the UI support right-to-left text? Metric only, or imperial too?
**A:** ENglish + arabic. Both systems would be good, default metric

## B. Platform & technology

**Q9 ★ Platforms:** iOS, Android, or both? What phone do you use? Do you need a tablet layout, a smartwatch app, or a web dashboard (desktop view of charts / bulk editing)?
**A:** IOS/Android

**Q10 Tech stack preference?** Flutter, React Native (Expo), native Swift/Kotlin, or "you recommend". Backend preference (Firebase, Supabase, own server, none)?
_Rec: decide after Q1/Q5/Q9. For cross-platform plus a solo developer, Flutter or Expo are the main options._
**A:** Flutter

**Q11 ★ Offline:** Must logging work with no internet (gym basement, flights)? AI logging needs internet, but should the app at least queue the text and process it later? Should workout logging and weigh-ins be fully offline?
_Rec: offline-first for everything except AI parsing. AI requests get queued while offline._
**A:** Hmm tough ask, if possible, we should be able to do things offline, obv non AI

**Q12 Accounts & sync:** Should you be able to use multiple devices, reinstall, or switch phones without losing data? Is local-only + manual backup acceptable, or do you want cloud sync?
**A:** Yes

**Q13 Integrations — which matter (must / nice / no)?**
Apple Health · Google Health Connect · smart scale (which brand do you own?) · Garmin / Fitbit / Whoop / Oura · Strava · Apple Watch / Wear OS companion.
**A:**I have never used, I guess not that important

**Q14 Import your history?** Do you have data in MyFitnessPal, Cronometer, MacroFactor, Hevy, Strong, etc. that you'd want imported? Which ones?
**A:** Ehhh, not sure, maybe through AI and written text,

## C. AI food logging (the core feature)

**Q15 ★ Input modes — which do you want (must / nice / no)?**
typed text · voice (speak) · photo of the meal · photo of a nutrition label · barcode scan · restaurant menu / screenshot · recipe URL · "same as yesterday" style shortcuts.
**A:** types is a must, voice is optional, can be done later, imagies are good, but idk how robust they can be, we can do img + text, barcode scan is good, URL is also good.

**Q16 ★ Where should the numbers come from?**
a) The AI estimates everything itself (fast, broad coverage, but can make up plausible-but-wrong numbers),
b) The AI only _understands_ the text, and the numbers come from a trusted database (USDA, etc.), with AI estimation only as a clearly labelled fallback,
c) Something else.
_Rec: (b). It's the main way we can be more trustworthy than Cal AI-style apps._
**A:** Your REC.

**Q17 ★ Ambiguity: ask or assume?** For "200g rice" (raw or cooked? a ~3× calorie difference), what should happen?
a) Always ask when the answer changes the calories by more than X%,
b) Assume using my personal defaults (e.g. "I weigh grains dry and meat raw") and show the assumption so I can tap to fix it,
c) Assume silently,
d) Mix: use defaults when I have them, ask when I don't.
How many follow-up questions per log are acceptable before it gets annoying? (0 / 1 / up to 3?)
_Rec: (d), at most 1–2 questions per log, always shown as quick-tap chips, not typing._
**A:** I like your rec

**Q18 ★ The cooked-together problem.** In your example ("200g rice, 200g chicken breast raw, cooked with an onion…"), did you eat **all** of it? If you cook a dish and eat part of it, how would you naturally say so?

- "…and I ate half"?
- "…the pot weighed 900g after cooking, I ate 350g"?
- Logging the dish once, and then for the next days saying "leftover chicken rice, 300g"?
  Which of these do you actually do in real life?
  **A:** I dont get the point

**Q19 Cooking fats and hidden calories:** Should the AI always ask about oil/butter when something was cooked, or use a personal default (e.g. "assume 1 tsp olive oil per pan dish")? Do you even want to track oil?
**A:** Sure

**Q20 ★ Confirmation flow:** after you send a message, which is it:
a) Show a breakdown (items, grams, kcal, macros, assumptions) → you tap "Save",
b) Save immediately and show the breakdown with "undo/edit",
c) Configurable per user.
_Rec: (b) for speed, with a clear "edit" path. Anything the AI is unsure about is highlighted._
**A:** good rec

**Q21 Corrections by conversation:** Should you be able to say "actually the rice was 150g", "move that to lunch", "delete the snack", "add a coffee with milk to breakfast"? Should the whole food diary be editable by chat, or only the most recent log?
**A:** yes

**Q22 Memory & personalisation — which do you want?**

- Personal foods ("my protein shake" = 40g whey + 300ml milk)
- Personal portions ("my bowl" ≈ 350g)
- Habits ("the usual breakfast", "same as Monday lunch")
- Learning from corrections (if you keep fixing "rice" to "basmati, cooked", it learns that)
- Favorite brands (when you say "yogurt" it picks your usual brand)
  **A:** SOunds nice! I like it

**Q23 Time handling:** Do you log meals right after eating, or at the end of the day / the next morning? Should the AI understand "yesterday dinner" or "2 hours ago"? Do you think in meal slots (breakfast/lunch/dinner/snacks) or just a timeline of times? Should slots be customizable (e.g. "pre-workout", "meal 4")?
**A:**That's a nice plus

**Q24 AI provider and privacy:** Any preference (Claude, OpenAI, Gemini, on-device/local models)? Are you okay with meal text, voice and photos being sent to a cloud AI provider? Any data you'd never want to leave the phone?
**A:** I want cheap and solid, I am ok

**Q25 AI beyond logging — which do you want (MVP / later / never)?**

- Questions about your data ("how much protein do I have left today?", "what was my average calories last week?")
- Suggestions ("what can I eat to hit my protein with 600 kcal left?")
- Weekly review / coach summary
- Workout logging by text ("bench 3x8 @ 80kg, felt easy")
- Workout program generation
- Meal plans from what's in your fridge
  **A:** Those sound nice

## D. Nutrition tracking

**Q26 Which nutrients do you care about?** Calories + protein/carbs/fat only? Plus fiber, sugar, sodium, saturated fat? Full micronutrients (vitamins/minerals, like Cronometer)? Alcohol? Caffeine? Water?
_Note: good micronutrient data is much harder to get than macros, and it limits which databases we can use._
**A:** I care about the big 4, others are a nice plus, but not a must

**Q27 ★ Targets:**
a) I set fixed calorie and macro targets manually,
b) The app calculates them once from my stats (formula),
c) **Adaptive** (MacroFactor-style): the app estimates my real expenditure from intake + weight trend and adjusts weekly,
d) Combination.
Also: different targets on training vs. rest days? Weekly calorie budget (eat less Mon–Fri, more on weekends)?
**A:** I like different, weekly budgte, etc.

**Q28 Exercise calories:** Should burned calories (from a watch or workouts) increase your food budget? None / a percentage / full amount? (Pitfall P11: wearables overestimate.)
**A:** not IMO

**Q29 Special diets / modes:** Any you follow or want supported (keto/net carbs, intermittent fasting window, vegetarian/vegan, halal, allergies, Ramadan fasting schedule)? Any that matter to you personally vs. "maybe for others"?
**A:**I do eat halal, ramadan etc

**Q30 Recipes:** Besides batch cooking (Q18), do you want a saved recipe library? Import recipes from URLs? Scale recipes by servings?
**A:** MAybe yeah, sounds cool!

## E. Weight & body

**Q31 Weigh-ins:** How often do you weigh (daily / weekly / random)? Manual entry or from a smart scale? Do you want the smoothed trend as the main number (with the raw value shown smaller)?
**A:** WEekly, manual, BTW, I also want to be able to see graph of my weight, currently, i store it in a note...

**Q32 Body measurements & composition:** Which do you track (waist, chest, arms, thighs, hips, neck…)? Body fat %: from a smart scale, manual entry, calculated (Navy method), or not at all?
**A:** currently none, but If i had nice graphs, etc, i would do it.

**Q33 Progress photos:** Want them? Must they stay only on the device (never uploaded)? Side-by-side comparison / overlay / timelapse?
**A:** I dont like them a lot, but they are a must stay on device.

**Q34 Goals and phases:** Do you set a target weight, a rate (e.g. −0.5 kg/week), or a date? Should the app track "phases" (cut from Jan–Apr, maintenance, bulk…) and show history per phase?
**A:** Up to the person, I use a monthly target

## F. Workouts

**Q35 ★ What training do you do?** Gym strength (barbell/dumbbell/machines), calisthenics, running, cycling, swimming, sports, classes, home workouts? How often?
**A:** Stenght, 3-4 a week

**Q36 ★ How deep should workout logging be?**
a) Simple: exercise + sets × reps × weight,
b) Hevy/Strong level: routines/templates, rest timer, PRs, estimated 1RM, supersets, warm-up sets, notes, plate calculator,
c) Advanced: plus RPE/RIR, tempo, progression rules (e.g. double progression), periodized programs, deloads.
**A:** Simple i think for now

**Q37 Live or after?** Do you log during the workout (phone on the bench, set by set) or afterwards? Would you use text/voice logging for workouts ("did 3x8 bench at 80")?
**A:** Prob after

**Q38 Programs:** Do you follow a specific program (PPL, 5/3/1, GZCLP, a coach's plan)? Should the app suggest the next session's weights (progressive overload)?
**A:** I do PPL

**Q39 Exercise library:** Built-in library with instructions/images/videos, or just names (you know the exercises)? Custom exercises?
**A:** If we can fetch from somewhere, cool, but i dont want them to make the app a lot more complex.

**Q40 Cardio:** Manually logged, imported from a watch / Strava / Health, or both? GPS tracking inside our app (probably not)?
**A:** Ehhh, maybe manually, or through AI chat.

## G. Progress, insights & notifications

**Q41 Which insights would you actually look at?** e.g. weekly summary, trend charts, adherence streaks, protein vs. strength gains, calories vs. trend weight, expenditure estimate, PR history, volume per muscle group. What's on the **home screen** when you open the app?
**A:** Weekly summary, charts, calories and weight

**Q42 Notifications:** Which reminders do you want (log meals, weigh-in, workout, water, protein target not reached, weekly review)? How pushy, from "never" to "nudge me"?
**A:** SHould be configurable, with a default of in between

**Q43 Gamification / social:** Streaks, badges, sharing, friends, leaderboards? Or explicitly none?
**A:** Nah none, kinda lame

## H. Data, privacy, safety

**Q44 Export & ownership:** Full export (CSV/JSON) required? Automatic backups (e.g. to your own Google Drive/iCloud)?
**A:** Ideally data should be tied to an account, like google or email, and our backend should handle storage

**Q45 Health safety (if others will use it):** Should the app enforce minimum calories, warn about aggressive deficits, avoid "bad food" language? Medical disclaimers? Any users under 18?
**A:** Yeah sure

## I. UX & design

**Q46 Design taste:** Apps whose look and feel you love (any category)? Dark mode only, light, or both? Minimal or data-dense?
**A:** I cant recall of the top, i want both themes, I like minimal but to a limit, not overly minimal, i like clean apps uk

**Q47 Speed budget:** What's acceptable for "open app → food logged"? (e.g. under 10 seconds for a typical meal?) Do you want a home-screen widget, a share-sheet entry, a Siri/Google Assistant shortcut, or a lock-screen quick log?
**A:** CAn't tell, we need it to be efficient

## J. Spec process

**Q48 Spec depth:** Besides the product spec, should `spec/` also hold the **technical** design (architecture, data model, API contracts, AI prompt design, test plan, AI accuracy benchmarks)? _Rec: yes, everything. Code gets written only from spec._
**A:** No, after spec, I will do tech planning seperatly.

**Q49 Anything I didn't ask that bugs you about fitness apps, or a feature you've always wanted?**
**A:**
