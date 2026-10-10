# Questions — Round 3 (short)

> **Status: answered & processed (2026-10-10).** Answers are recorded in `decisions.md` as D-069 to D-078. The owner's follow-up note about confirming before logging is recorded as D-079 (supersedes D-014).

_2026-10-10. Round 2 is recorded in `decisions.md` (D-037 to D-068). This is the last broad round. Later questions, if any, will come up while writing individual spec files._

**How to answer:** write under `**A:**`, or in chat (`R3-4: b`). "rec" = use my recommendation. ★ = blocking.

---

**R3-1 ★ Confirm recommendations applied to blank answers.** You left these blank in round 2, so I applied my recommendation. Reply "all ok" or correct any of them:

- **D-062** Buddy is friendly and short, replies in your language, gives opinions only when asked.
- **D-063** Understands Palestinian/Levantine Arabic + other dialects, Arabizi ("akalt 2 ta3meya"), and mixed AR/EN. Full Arabic RTL interface in R2.
- **D-064** Halal setting (on for you): warns about likely non-halal products/dishes, and suggestions stay halal.
- **D-065** Progress photos stay on the phone, plus a manual "export my photos". Encrypted cloud backup: Later.
- **D-066** AI features: Q&A, suggestions, weekly review, workout-by-text in R1. Recipe URL in R2. Program generation, fridge meal plans, grocery lists: Later.
- **D-067** Full data export (CSV/JSON) + in-app account deletion.
- **D-068** Steps: read from Apple Health / Health Connect, shown for info only (they don't change your food budget). R2.
- **D-058** (you asked me to decide) Workouts don't change food targets by default. Optional "calorie shifting" gives your planned training days a bigger share of the **same** weekly budget. Reasoning is in the decision log.

**A:**

**R3-2 ★ When does your week start?** This matters for the weekly budget, weekly summary and weekly review.
a) Saturday, b) Sunday, c) Monday, d) user setting.
_Rec: (d), defaulting to Saturday for you (the weekend is Friday, so the week starts after it). Tell me if your week feels different._
**A:**

**R3-3 ★ Today vs. the week on the home screen.** You said the weekly deficit is what matters. Which number should be **big** on the home screen?
a) **Today's remaining** calories (which already includes rebalancing from earlier days this week), with a small "this week: 850 kcal under" line,
b) **This week's remaining**, with today below it,
c) Both, the same size.
_Rec: (a). "How much can I eat today" is the question you have at dinner time. The weekly line keeps the big picture visible._
**A:** rec

**R3-4 Quick batch logging and sharing.** When you log a whole pot at once (D-044), do other people usually eat from it too? If yes, the app needs "my share" (e.g. "I ate about a quarter of it, the family ate the rest") instead of the whole pot.
**A:** ehh minor detail IMO, the AI should be smart enough to handle.

**R3-5 ★ Packaged products in your shops.** Roughly, what do you buy: Palestinian brands, Israeli brands, Jordanian/Turkish/imported, or a mix? Many labels in the West Bank are **in Hebrew**. Should label-photo reading (D-047) support Hebrew labels along with Arabic and English?
_Rec: yes, Arabic + English + Hebrew labels in R1._
**A:** no ISreali brands... arabuc + english

**R3-6 Location for Ramadan and prayer times.** Suhoor/Fajr reminders and the Ramadan day boundary need prayer times for where you are.
a) Pick your city once (no location permission needed),
b) Use the phone's location automatically,
c) Pick city by default, with automatic location as an option.
_Rec: (c)._
**A:**

**R3-7 ★ Your regular dishes.** List the 20–30 foods/dishes you actually eat often, both home-cooked and eaten out. Examples: maqluba, musakhan, mansaf, mujaddara, shawarma (chicken/meat, sandwich/plate), falafel sandwich, hummus, ful, knafeh, labaneh with zaatar, taboon bread, ka'ak, chicken & rice… These become the **must-cover list**: the app is tested against them before R1 is considered done.
**A:** Too broad for me, im lazy to type hhah, just typical palestinian

**R3-8 ★ Your real messages.** This is the most valuable thing you can give the spec. Write **10–15 messages exactly as you'd type them** to log food: your normal language, Arabic/English/Arabizi/mixed, typos, laziness, all of it. Include:

- a couple of home-cooked meals (one with weights, one without),
- something eaten out,
- a packaged product,
- a correction ("no, it was 150g"),
- a question ("how much protein left?"),
- a workout ("push day…").
  These become the **acceptance test set** for AI logging (`40-acceptance-criteria.md`).
  **A:** Im lazy mate, i think you understand me

**R3-9 How much do you trust estimates?** For an unweighed "plate of maqluba", the honest uncertainty might be ±30%. Is that acceptable when you're logging lazily, or would you rather the app nudge you ("weigh it next time for a better number")?
a) Fine, never nudge,
b) Nudge occasionally, e.g. for foods you eat often where weighing once would improve every later log,
c) Always mention it.
_Rec: (b)._
**A:**

**R3-10 Name.** Some ideas that work in both Arabic and English (none checked yet for trademarks or app-store availability):

| Name              | Arabic | Meaning / why                                                                                                        |
| ----------------- | ------ | -------------------------------------------------------------------------------------------------------------------- |
| **Lugma**         | لقمة   | "a bite". Short, food-first, friendly                                                                                |
| **Sahtein**       | صحتين  | what you say over food in the Levant ("bon appétit", literally "two healths"). Warm and local, with a health meaning |
| **Mizan**         | ميزان  | "scale / balance". Covers both weight and balanced eating                                                            |
| **Rafeeq**        | رفيق   | "companion" = buddy. Could be the **assistant's** name inside any app name                                           |
| **Zad**           | زاد    | "provisions, nourishment". Very short                                                                                |
| **Fitness Buddy** | —      | current working title. Clear, but generic                                                                            |

Pick one, mix them (e.g. app "Sahtein", assistant "Rafeeq"), or keep thinking. This doesn't block the spec.
**A:** keep
