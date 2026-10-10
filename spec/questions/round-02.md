# Questions — Round 2

> **Status: answered & processed (2026-10-10).** Answers are recorded in `decisions.md` as D-037 to D-068. Blank answers got my recommendation as **provisional** decisions, to be confirmed in `round-03.md` R3-1.

_2026-10-10. Round 1 answers have been recorded in `decisions.md` (D-001 to D-036). This round digs into the answers that were short or left things open, and into things round 1 didn't cover._

**How to answer:** same as before. Write under `**A:**`, or reply in chat with `R2-7: b`. "rec" = use my recommendation. ★ = blocking.

---

## 0. Check my reading of your answers

Please mark each one ✅ or correct it:

| #   | You said                                                     | I recorded                                                                                                                                     |
| --- | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| a   | "big 4" (Q26)                                                | calories, protein, carbs, fat (D-019)                                                                                                          | can add fiber too but true                           |
| b   | "That's a nice plus" (Q23)                                   | The AI understands "yesterday dinner", "2h ago" (D-017)                                                                                        |
| c   | "I want the spec to capture all we need" (Q6)                | The spec covers everything, and **each requirement is tagged with a release** (R1/R2/R3/Later) so we still know what to build first. See R2-4. |
| d   | Water, steps, sleep, habits, supplements, fasting timer (Q3) | **Out of scope**, so they don't bloat the app (D-002)                                                                                          | True, but if steps are easily do-able, then lets add |
| e   | "Maybe through AI and written text" (Q14)                    | Import old data by **pasting text** (e.g. your weight note) and letting the AI read it. No MyFitnessPal/Cronometer file importers.             |

**A:**

---

## A. Scope & releases

**R2-1 ★ What exactly is wrong with MyFitnessPal/Cronometer's UI?** "I hate the UI" is the most useful thing you told me, so I want specifics. Tick everything that applies, and add your own:

- [ T] ads
- [T ] too many taps/screens to log one food
- [ T] search results full of duplicates or wrong entries, so you don't know which to pick
- [ T] cluttered screens / too much info
- [ T] key features paywalled (which ones?)
- [ ] slow / laggy
- [ T] looks dated / ugly
- [ T] editing a logged item is painful
- [ T] home-cooked food is a nightmare to log
- [ ] other:

Also: are you still using either one today? If not, why did you stop, and what do you use now?
**A:** i stopped bc of inconvience

**R2-2 ★ Where do workouts sit?** Your first message included workout logging, but your Q3 ranking didn't list it.
a) In the **first release**, kept minimal (you train 3–4×/week, so you'd use it),
b) **Second release**, after nutrition + weight are solid,
c) An **optional module** each user can switch on or off (hidden by default).
_Rec: (a) with (c). Logging a workout through the same chat ("push day: bench 3×8 80kg, OHP 3×10 40kg") is cheap to add once AI logging exists. Users who don't train can hide it._
**A:** First.

**R2-3 ★ What does "solid free tier" mean?**
a) **Free trial**: everything free for N days/weeks, then pay,
b) **Free forever with limits**: all non-AI features free, plus a daily AI allowance (e.g. N AI logs/day on a cheaper model). Paid = higher limits / better model,
c) **Everything free** while it's just you and friends, and pricing gets decided when we go public.
And: **ads ever?** (yes / never)
_Rec: (c) for now, but write the spec for (b) so the product is ready for it. No ads, ever. Ads are one of the main complaints about MyFitnessPal/Cronometer._
**A:** rec

**R2-4 ★ Release stages.** I propose tagging every requirement with one of these:

- **R1 "Me"**: what you need to stop using your current apps and the weight note.
- **R2 "Friends"**: onboarding for people who aren't you, polish, safety guardrails, Arabic UI.
- **R3 "Public"**: billing, store compliance, scale.
- **Later**: nice ideas, not planned.

Proposed **R1** (tick, untick, add):

- [ T] AI text logging (English + Arabic) with clarifying questions
- [ T] Photo + text logging
- [ T] Barcode scan
- [ T] Food search + manual logging (offline-capable)
- [ T] Personal foods, "the usual", same-as-yesterday
- [ T] Batch / home-cooked dishes (see R2-7)
- [ T] Daily diary, editable by chat
- [ T] Calorie + macro targets, weekly budget
- [ T] Weight log + graph + trend
- [ T] Monthly / goal targets
- [ T] Weekly summary
- [ T] AI Q&A on your data ("how much protein left?")
- [ T] Simple workout logging (if R2-2 = a)
- [ T] Ramadan mode
- [ T] Accounts + cloud sync

**A:**

## B. The core experience

**R2-5 ★ What's the main screen: a chat or a dashboard?** This shapes the whole app.

```
(a) CHAT-FIRST                (b) DASHBOARD-FIRST            (c) HYBRID
┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
│ Buddy            │          │ Today  1,420/2,000│          │ 1,420 / 2,000 kcal│
│ ─────────────────│          │ P 110 C 140 F 45  │          │ P ███░ C ██░ F █░ │
│ you: 200g rice.. │          │ ─────────────────│          │──────────────────│
│ buddy: logged ✓  │          │ Breakfast   420  │          │ buddy: logged ✓  │
│  rice 260 kcal.. │          │ Lunch       780  │          │  rice, chicken.. │
│ you: how much    │          │ Snacks      220  │          │ you: how much... │
│  protein left?   │          │ Dinner        —  │          │                  │
│                  │          │                  │          │                  │
│ [ type...  📷 ]  │          │ [ tell me... 📷 ]│          │ [ type...  📷 ]  │
└──────────────────┘          └──────────────────┘          └──────────────────┘
 diary & charts = tabs         chat opens as a sheet         numbers pinned on top
```

_Rec: (b). Your day's numbers are always visible, and the input bar is one tap away. A chat history becomes long and makes it hard to see what you actually ate. But (c) fits the "Buddy" idea better, so this is your call._
**A:** rec

**R2-6 Buddy's personality:**
a) neutral & short ("Logged. 640 kcal, 52g protein."),
b) friendly & short,
c) coach-like, gives opinions ("That's light on protein, consider…"),
d) playful.
Should it always reply in the language you wrote in?
_Rec: (b), replying in your language. Opinions only when you ask for them._
**A:**

**R2-7 ★ The cooked-together problem, explained better** (you said "I don't get the point" to Q18, which is fair).

A concrete case: on Sunday you cook a pot with 500g raw chicken, 400g dry rice, 1 onion and 2 tbsp oil. That's about **3,100 kcal** in the pot. You eat some on Sunday, some on Monday and the rest on Tuesday. To log each meal correctly, the app needs to know **what share of the pot** you ate each time. How would you realistically tell it?
a) Weigh the whole pot once after cooking, then weigh my plate each time (most accurate, more effort),
b) Fractions: "I ate about a third",
c) Plates: "one plate of it", and the app estimates,
d) I usually cook single meals and eat all of it, so this rarely happens.

And a very common case in Middle Eastern households: **someone else cooked** (family, friends), and you don't know the ingredients. "I had a plate of mom's molokhia with rice." Should the AI estimate from a typical recipe for that dish (labelled as an estimate)? How often does this happen for you?
_Rec: support all of (a)–(c). The app remembers the dish so later meals are just "leftover chicken rice, a plate". Dishes cooked by someone else are estimated from a typical recipe and labelled._
**A:** I like rec, but also, because we care about weekly deficit, sometimes, it does not matter how a cook is split over X days.

**R2-8 When you don't weigh** (you said you get lazy), is a rough estimate OK as long as it's marked? How should it look?
a) One number with a "~ estimate" tag,
b) A range ("550–750 kcal"),
c) One number, plus the range when tapped.
_Rec: (c)._
**A:** rec

**R2-9 Eating out:** what's typical for you? Chains (McDonald's, KFC, local chains), local restaurants, street food (shawarma, falafel, koshari…), delivery apps? If a chain publishes its nutrition, should we prefer that data?
**A:** Really a mix, nobody puts nutritents facts here too

**R2-10 Nutrition-label photos:** For local products that aren't in any database, would you photograph the label and have the app read it (and save it as a food for next time)? Must / nice / no.
_Rec: must. It's the fix for "this product isn't in the database" in the Middle East, where database coverage is weaker._
**A:** rec

**R2-11 ★ When a food is missing from the database and you add it, who sees it?**
a) Only you (private),
b) Everyone (crowdsourced like MyFitnessPal: the database grows fast, but quality suffers),
c) Everyone, but marked "user-added" until it's verified.
_Rec: (a) now, (c) when public. You liked MyFitnessPal's product variety, and crowdsourcing is how they got it, but it's also where the wrong entries come from._
**A:** rec

**R2-12 Offline behaviour:**

- While offline, AI messages are **queued** and processed when you're back online (they show as "pending"). OK?
- Offline food **search** can't include the whole database on the phone. It would cover your history, your personal foods and a set of common basic foods. OK?
  _Rec: yes to both._
  **A:** rrec

**R2-13 Meals in the diary:**
a) Fixed: Breakfast / Lunch / Dinner / Snacks,
b) Customizable slots (rename, add "Pre-workout", "Meal 4"),
c) No slots, just a timeline with times,
d) Slots picked automatically from the time, and you can override.
_Rec: (b) + (d). During Ramadan, the slots switch to Iftar / Suhoor / Snacks (see R2-17)._
**A:**rec

## C. Region, Arabic, halal, Ramadan

**R2-14 ★ Which country do you live in?** This affects barcode coverage, local brands, restaurant chains and dish names. Will friends and early users be in the same country, or spread across the region or the world?
**A:** Palesitine west bank

**R2-15 Arabic details:**

- Dialect you'd write/speak (Egyptian, Levantine, Gulf, Maghrebi, MSA…)?
- Do you also write **Arabizi / Franco** ("akalt 2 ta3meya w 3esh")?
- Mixed sentences ("200g رز with chicken")?
- Should the **app interface** also be available in Arabic (right-to-left), or English UI with Arabic input only?
  _Rec: understand any dialect + Arabizi + mixed text. Arabic UI in R2._
  **A:**

**R2-16 Halal: how deep?**
a) Nothing special. You know what you eat,
b) Warn when a scanned product or dish likely contains non-halal ingredients (pork, gelatin, alcohol),
c) Suggestions and meal plans only ever suggest halal food,
d) (b) + (c) as a user setting.
_Rec: (d), on by default for you, configurable for others._
**A:**

**R2-17 ★ Ramadan mode:** which of these do you want?

- [ T] Detect Ramadan dates automatically (or switch on manually)
- [ T] Meal slots become Iftar / Suhoor / Snacks
- [ T] Different calorie targets during Ramadan
- [ T] Reminder to eat enough protein / log suhoor before Fajr
- [ T] Weight expectations relaxed (weight fluctuates more while fasting)
- [ T] Insights compare Ramadan vs. normal months

Plus a tricky one: you eat suhoor at 3:30am on the 5th. Which day does it count towards?
a) The 4th (the evening before, the same "eating night" as iftar),
b) The 5th (the calendar day, the day you're fasting).
_Rec: (b)._
**A:** rec

## D. Targets & weight

**R2-18 ★ How is your base calorie target set?**
a) You type the numbers,
b) The app calculates them from your stats (age, height, weight, activity, goal),
c) Adaptive: the app learns your real burn from what you eat + how your weight changes, and adjusts weekly,
d) Start with (b), switch to (c) once there's enough data. You can always override with (a).
_Rec: (d)._
**A:** rec

**R2-19 ★ Weekly weigh-ins vs. accuracy.** One weigh-in can be off by 1–2 kg because of water, salt and food in the gut. With one weigh-in a week, a single bad day can make the graph lie for that whole week, and adaptive targets (R2-18c) react slowly.
a) Keep weekly. The app works with it and is honest about lower confidence,
b) The app _gently_ suggests weighing more often (2–3×/week), never nags,
c) I'd weigh daily if logging it took a few seconds.
_Rec: support any cadence. Show the smoothed trend line plus raw points. Adaptive targets explain what data they need._
**A:** rec

**R2-20 Your weight note:** paste a few lines of it here (fake numbers are fine). I want to see the format (dates? units? comments?) so "paste your note and import it" is specified properly.
**A:** oct 10 2025: 110k, oct 20 2025: 150kg...

**R2-21 "Different targets": which kinds?**

- [ ] Training day vs. rest day
- [ ] Specific weekdays (e.g. higher on Friday)
- [ ] Weekly budget: eat less on some days and more on others, as long as the week adds up
- [ ] Automatic rebalancing: if you go over on Monday, the remaining days of the week adjust
- [ ] Protein as a fixed daily gram target, while calories flex
      _Rec: all of them, configurable. Default: a fixed daily protein target and a weekly calorie budget._
      **A:** rec

**R2-22 Progress photos vs. switching phones:** photos stay only on the phone (D-026), so they're **lost if you change or reset your phone**, unlike everything else. Choose:
a) Accept that,
b) Device-only, plus a manual "export my photos" option,
c) Optional _encrypted_ backup that the user switches on (we can't see the photos).
_Rec: (b) for now, (c) later._
**A:**

## E. Workouts (if in scope per R2-2)

**R2-23 Minimal workout feature set.** Tick what's in:

- [ ] Log by chat: "push day: bench 3×8 80kg, OHP 3×10 40kg, dips 3×12"
- [ ] Log by form (pick exercise, enter sets)
- [ ] Routine templates (Push / Pull / Legs with their exercise lists)
- [ ] "Same as last push day, but bench 82.5"
- [ ] See last session's numbers while logging
- [ ] Graph per exercise (weight / estimated max over time)
- [ ] Personal records (PRs)
- [ ] Notes per workout / exercise
- [ ] Rest timer (only useful if logging live, so probably not)
      _Rec: the first seven._
      **A:** rec

**R2-24 Should workouts affect nutrition?** E.g. if you log a workout, that day automatically uses "training day" targets (ties to R2-21).
**A:** Hmmm idk, idk what makes more sense from fitness perspective. you research and decide

## F. AI features

**R2-25 ★ Put each in R1 / R2 / Later / Never** (my proposal is in brackets):

- Q&A on your data: "how much protein left?", "avg calories last week?" [R1]
- Suggestions: "what can I eat with 600 kcal left to hit protein?" [R1]
- Weekly review written by Buddy [R1]
- Workout logging by text [R1, if workouts are in R1]
- Workout program generation [Later]
- Meal plan from what's in your fridge [Later]
- Recipe import from URL [R2]
- Grocery list from meal plan [Later]
  **A:**

## G. Accounts, speed, misc

**R2-26 Sign-in:**

- Google + email, as you said. FYI: Apple's App Store rules require offering **Sign in with Apple** (or an equivalent privacy-focused option) when an app offers Google sign-in, so iOS gets that too.
- Can people **try the app without an account** (data stays on the phone until they sign up)?
  _Rec: yes, guest mode, with a prompt to sign in to keep your data safe._
  **A:** rec

**R2-27 Export & deletion:** Both stores require in-app account deletion. Should users also be able to **export all their data** (CSV/JSON)?
_Rec: yes. It builds trust, and it's cheap to do._
**A:**

**R2-28 Speed targets.** I propose these. Accept or adjust:

- Typed meal → numbers on screen: **≤ 5 s** in 9 out of 10 cases
- "The usual breakfast" / repeat meal: **≤ 2 taps**, no AI wait
- Open app → cursor in the input bar: **≤ 2 s**
- Log a weigh-in: **≤ 3 taps**
- Quick entry from outside the app (home-screen widget, share a photo/link into the app): **R2**
  **A:** sure

**R2-29 Name:** Is "Fitness Buddy" the final name or a working title? Does the AI assistant have its own name (e.g. "Buddy")? An Arabic name?
**A:** im not final on the naame, happy to hear more suggestions.

**R2-30 Anything that came to mind since round 1?**
**A:** nope
