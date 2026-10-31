# Decision Log

Append-only. Never edit or delete a past decision. If a decision changes, add a new entry that **supersedes** the old one, and mark the old one `Superseded by D-XXX`.

Entries marked _(interpretation)_ are Claude's reading of a short answer. They're listed for confirmation in the following question round.

Format:

```
## D-001 — <short title>
- Date / Source: YYYY-MM-DD · round-NN Q#
- Decision: <what>
- Why: <reasoning, alternatives rejected>
- Open: <what still needs deciding, with link>
```

---

## D-001 — Staged audience
- Date / Source: 2026-10-10 · round-01 Q1
- Decision: Built for the owner first, then friends, then possibly a public store release. Data, privacy and safety are designed **as if public from day one**.
- Why: Avoids rewrites at each stage.

## D-002 — Module priority
- Date / Source: 2026-10-10 · round-01 Q3
- Decision: 1. Nutrition logging · 2. Weight tracking · 3. AI chat · 4. Meal planning/suggestions. Everything else is optional and must not bloat the app. Water, steps, sleep, habits, supplements and fasting timers are **out** unless a later decision adds them.
- Why: The owner explicitly worries about feature bloat and inconvenient features (e.g. water logging).
- Open: Where workouts rank → round-02 R2-2.

## D-003 — Free tier
- Date / Source: 2026-10-10 · round-01 Q4
- Decision: There must be a solid free tier. Paid billing comes later. Cheaper AI models may power the free tier.
- Open: What exactly is free, and for how long → round-02 R2-3.

## D-004 — Platforms
- Date / Source: 2026-10-10 · round-01 Q5, Q9, Q10
- Decision: iOS and Android phones. No tablet layout, smartwatch app or web dashboard. Built by a solo developer in **Flutter** (recorded as a constraint; technology is otherwise out of spec scope, see D-005).

## D-005 — Spec is product-only
- Date / Source: 2026-10-10 · round-01 Q5, Q48
- Decision: `spec/` describes **what** the product does and why, plus acceptance criteria. Architecture, data model, APIs, AI prompt design and stack choices are planned separately afterwards.
- Why: Owner preference.

## D-006 — Languages & units
- Date / Source: 2026-10-10 · round-01 Q8
- Decision: English and Arabic input. Metric is the default, with imperial supported.
- Open: Arabic UI/RTL, dialects, Arabizi → round-02 R2-15.

## D-007 — Offline
- Date / Source: 2026-10-10 · round-01 Q11
- Decision: Every non-AI feature should work offline. AI features need connectivity.
- Open: Queueing AI requests and offline food search → round-02 R2-12.

## D-008 — Accounts & cloud storage
- Date / Source: 2026-10-10 · round-01 Q12, Q44
- Decision: Data belongs to an account (Google or email sign-in) and is stored by our backend. Switching or reinstalling phones and using multiple devices keeps all data.
- Open: Guest mode, Apple sign-in, export → round-02 R2-26, R2-27.

## D-009 — No third-party integrations initially
- Date / Source: 2026-10-10 · round-01 Q13
- Decision: Apple Health, Health Connect, scales and wearables are not required. Tagged **Later**.

## D-010 — Input modes
- Date / Source: 2026-10-10 · round-01 Q15
- Decision: Typed text is **required**. Wanted: photo + text, barcode scan, recipe URL. Voice: **Later**.
- Open: Nutrition-label photos → round-02 R2-10.

## D-011 — Where numbers come from
- Date / Source: 2026-10-10 · round-01 Q16
- Decision: The AI only interprets input. Nutrition values come from trusted food data. An AI-estimated value is allowed only as a fallback and is always clearly labelled as an estimate.
- Why: Trust is the differentiator against photo/AI-guess apps.

## D-012 — Ambiguity handling
- Date / Source: 2026-10-10 · round-01 Q17
- Decision: Use personal defaults when known (e.g. "I weigh rice dry"). Otherwise ask. At most 1–2 follow-up questions per log, answered with quick-tap choices. Every assumption is visible and can be changed with a tap.

## D-013 — Cooking fats are tracked
- Date / Source: 2026-10-10 · round-01 Q19
- Decision: Oil and butter used in cooking are tracked. The AI uses the user's default if one is set, and asks otherwise (within the D-012 question budget).

## D-014 — Save first, edit after
- Status: **Superseded by D-079**
- Date / Source: 2026-10-10 · round-01 Q20
- Decision: An AI log is saved immediately, then shown as a breakdown with undo/edit. Low-confidence items are highlighted.

## D-015 — Diary editable by conversation
- Status: **Amended by D-079** (chat edits are proposals that need confirmation)
- Date / Source: 2026-10-10 · round-01 Q21
- Decision: Any diary entry (not just the latest) can be changed by chat: change amounts, move between meals, delete, add to an existing meal.

## D-016 — Personalisation
- Date / Source: 2026-10-10 · round-01 Q22
- Decision: All of the following are in scope: personal foods, personal portion sizes, habits ("the usual", "same as Monday"), learning from corrections, and favourite brands.

## D-017 — Natural time references
- Date / Source: 2026-10-10 · round-01 Q23 _(interpretation)_
- Decision: The AI understands "yesterday dinner", "2 hours ago" and similar.
- Open: Meal slots vs. timeline → round-02 R2-13.

## D-018 — AI provider
- Date / Source: 2026-10-10 · round-01 Q24
- Decision: Requirement is "cheap and solid". Sending meal text and photos to a cloud AI provider is acceptable. The provider choice is left to technical planning.

## D-019 — Nutrients
- Status: **Amended by D-037** (fiber added)
- Date / Source: 2026-10-10 · round-01 Q26 _(interpretation: "big 4" = calories, protein, carbs, fat)_
- Decision: Calories, protein, carbs and fat are required everywhere. Other nutrients (fiber, sugar, sodium…) are shown when the data has them, but are never required.

## D-020 — Flexible targets
- Date / Source: 2026-10-10 · round-01 Q27
- Decision: Targets can differ by day, and a weekly calorie budget is supported.
- Open: How the base target is set (manual, formula, adaptive), and what "different" means → round-02 R2-18, R2-21.

## D-021 — Exercise calories not added to food budget
- Date / Source: 2026-10-10 · round-01 Q28
- Decision: By default, burned calories do **not** increase the food budget.

## D-022 — Halal & Ramadan
- Date / Source: 2026-10-10 · round-01 Q29
- Decision: Halal eating and Ramadan fasting are first-class concerns, not afterthoughts.
- Open: Depth → round-02 R2-16, R2-17.

## D-023 — Recipe library
- Date / Source: 2026-10-10 · round-01 Q30
- Decision: A saved recipe library is wanted (release tier to be decided).

## D-024 — Weight tracking
- Date / Source: 2026-10-10 · round-01 Q31
- Decision: Manual weigh-ins, typically weekly. **A weight graph is core.** The owner currently keeps weight in a phone note; replacing that note is a concrete goal.
- Open: Trend smoothing with weekly data, importing the note → round-02 R2-19, R2-20.

## D-025 — Body measurements
- Date / Source: 2026-10-10 · round-01 Q32
- Decision: Optional measurements (waist, chest, etc.), each with a graph. Good graphs are what would make the owner actually use them.

## D-026 — Progress photos are low priority and device-only
- Date / Source: 2026-10-10 · round-01 Q33
- Decision: Progress photos are optional and low priority. They **never leave the device**.
- Open: This conflicts with D-008 (photos are lost when switching phones) → round-02 R2-22.

## D-027 — Goals are per user
- Date / Source: 2026-10-10 · round-01 Q34
- Decision: Users choose how to set a goal: target weight, rate per week, target date, or **monthly target** (the owner's style).

## D-028 — Workouts: simple strength logging
- Date / Source: 2026-10-10 · round-01 Q35–Q38
- Status: Amended by D-085 (no plan required, starter plans).
- Decision: Strength training (owner: PPL, 3–4×/week). Simple logging: exercise, sets × reps × weight, usually logged **after** the session. No RPE, tempo or periodization initially.
- Open: Rank and scope → round-02 R2-2, R2-23.

## D-029 — Exercise library stays simple
- Date / Source: 2026-10-10 · round-01 Q39
- Status: Amended by D-085 (a muscle map for every exercise).
- Decision: Exercise names (with aliases) plus custom exercises. Media/instructions only if they add no complexity. They're optional and Later.

## D-030 — Cardio
- Date / Source: 2026-10-10 · round-01 Q40
- Decision: Cardio is logged manually or via AI chat. No GPS and no imports.

## D-031 — Insights
- Date / Source: 2026-10-10 · round-01 Q41
- Decision: Priority insights: weekly summary, charts, calories, weight.

## D-032 — Notifications
- Date / Source: 2026-10-10 · round-01 Q42
- Decision: All reminders are configurable. Default intensity is moderate.

## D-033 — No gamification or social
- Date / Source: 2026-10-10 · round-01 Q43
- Decision: No streaks, badges, leaderboards, friends or social feed.

## D-034 — Safety guardrails
- Date / Source: 2026-10-10 · round-01 Q45
- Decision: Minimum-calorie guardrails, warnings on aggressive deficits, neutral non-judgmental food language, medical disclaimer, and an age gate.

## D-035 — Visual direction
- Date / Source: 2026-10-10 · round-01 Q46
- Decision: Light and dark themes. Clean and minimal, but not stripped-down. Information stays visible.

## D-036 — AI features beyond logging wanted
- Date / Source: 2026-10-10 · round-01 Q25
- Decision: Q&A on own data, suggestions, weekly review, workout text logging, program generation and fridge-based meal plans are all wanted in principle.
- Open: Release tiering → round-02 R2-25.

---

# Round 2 decisions

_Entries marked **(provisional)** apply Claude's recommendation to a question that was left blank. They're listed for confirmation in round-03 R3-1._

## D-037 — Fiber is a core nutrient
- Date / Source: 2026-10-10 · round-02 §0a
- Decision: Core tracked nutrients are **calories, protein, carbs, fat, fiber**. Amends D-019.

## D-038 — Interpretations confirmed
- Date / Source: 2026-10-10 · round-02 §0b, c, e (left unmarked, no objection)
- Decision: D-017 (natural time references), release tagging of every requirement, and pasted-text import (D-056) stand as recorded.

## D-039 — Pain points we design against
- Date / Source: 2026-10-10 · round-02 R2-1
- Decision: The owner **stopped using MyFitnessPal/Cronometer because of inconvenience**. Every one of these was confirmed as a pain point: ads, too many taps per food, duplicate or wrong search results, cluttered screens, paywalled core features, dated look, painful editing, home-cooked food being hard to log. (Speed was *not* a complaint.) Each becomes a design principle in `00-vision-and-scope.md`.
- Why: **Convenience is the #1 success criterion.** If logging is a chore, the app has failed, no matter how accurate it is.

## D-040 — Workouts are in R1
- Date / Source: 2026-10-10 · round-02 R2-2
- Decision: Minimal workout logging ships in the first release. (Hiding the module for users who don't train: R2.)

## D-041 — Monetization
- Date / Source: 2026-10-10 · round-02 R2-3
- Decision: Everything is free for R1 and R2. The spec describes the target model for R3: **free forever** for all non-AI features plus a daily AI allowance on a cheaper model; paid tier = higher limits / stronger model. **No ads, ever.**

## D-042 — Release stages
- Date / Source: 2026-10-10 · round-02 R2-4
- Decision: Requirements are tagged **R1** (owner) / **R2** (friends) / **R3** (public) / **Later**. R1 includes all 15 proposed items: AI text logging (EN+AR) with clarifying questions, photo+text, barcode, food search + manual logging (offline), personal foods & repeats, batch/home-cooked dishes, chat-editable diary, calorie+macro targets with weekly budget, weight log + graph + trend, monthly/goal targets, weekly summary, AI Q&A on own data, simple workout logging, Ramadan mode, accounts + cloud sync.

## D-043 — Dashboard-first home
- Date / Source: 2026-10-10 · round-02 R2-5
- Decision: The home screen shows the day's numbers and diary, with an always-visible "tell me what you ate" input bar. The chat opens as a sheet over the dashboard. The diary, not the chat history, is where your data lives.

## D-044 — Batch & family cooking
- Date / Source: 2026-10-10 · round-02 R2-7
- Decision: Batch dishes can be portioned by (a) cooked pot weight + plate weight, (b) fractions, or (c) "a plate". The app remembers the dish for leftovers. Dishes cooked by someone else are estimated from a typical recipe and labelled as estimates.
- Plus a **weekly-accuracy principle** (owner's insight): since the goal is a weekly deficit, how a batch is split across days barely matters. So a **quick path** must exist: log the whole batch (or "my share") once and be done. Exact per-day splitting is optional.

## D-045 — How estimates are shown
- Date / Source: 2026-10-10 · round-02 R2-8
- Decision: One number with an estimate marker. Tapping it shows the likely range.

## D-046 — Local restaurants have no nutrition data
- Date / Source: 2026-10-10 · round-02 R2-9
- Decision: In the owner's region, restaurants (chains included) generally don't publish nutrition facts. Eating out is a mix of chains, local restaurants and street food. So **estimating local dishes is a primary path, not an edge case.** The product needs reviewed reference recipes/portions for common local dishes (see D-051). This clarifies D-011: a reviewed reference recipe counts as trusted data, while a free-form AI estimate is still labelled as an estimate.

## D-047 — Nutrition-label photos are R1
- Date / Source: 2026-10-10 · round-02 R2-10
- Decision: Photographing a nutrition label creates a saved personal food. Must-have in R1.

## D-048 — User-added foods
- Date / Source: 2026-10-10 · round-02 R2-11
- Decision: Private to the user in R1 and R2. In R3: shared, marked "user-added" until verified.

## D-049 — Offline details
- Date / Source: 2026-10-10 · round-02 R2-12
- Decision: AI messages sent while offline are queued and shown as "pending". Offline food search covers the user's history, personal foods and a set of common basic foods, not the whole database.

## D-050 — Meal slots
- Date / Source: 2026-10-10 · round-02 R2-13
- Decision: Customizable slots (rename, add, reorder). New entries go into a slot automatically based on the time, and the user can override. During Ramadan, slots switch to Iftar / Suhoor / Snacks.

## D-051 — Primary region: Palestine (West Bank)
- Date / Source: 2026-10-10 · round-02 R2-14
- Decision: The first users are in the West Bank. Food knowledge must cover **Palestinian/Levantine dishes**, products sold there, and local naming. Region-specific questions continue in round-03 (R3-5, R3-6, R3-8).

## D-052 — Ramadan mode (all features)
- Date / Source: 2026-10-10 · round-02 R2-17
- Decision: Automatic Ramadan detection (manual switch too), Iftar/Suhoor slots, separate Ramadan targets, reminders around suhoor/Fajr, relaxed weight expectations, Ramadan vs. normal comparison. **Suhoor counts toward the calendar day it's eaten on** (the fasting day).
- Note: Fajr-based reminders need prayer times for the user's location → R3-6.

## D-053 — Base targets
- Date / Source: 2026-10-10 · round-02 R2-18
- Decision: Start from a formula based on the user's stats. Switch to **adaptive** (learned from intake + weight trend) once there's enough data. The user can always override manually.

## D-054 — Any weigh-in cadence
- Date / Source: 2026-10-10 · round-02 R2-19
- Decision: Weekly, daily or irregular weigh-ins all work. Graphs show a smoothed trend plus the raw points. Adaptive targets state what data they need and how confident they are.

## D-055 — Paste import
- Date / Source: 2026-10-10 · round-02 R2-20
- Decision: Users paste free-form text (e.g. `oct 10 2025: 110k, oct 20 2025: 150kg...`) and the AI extracts dated entries for review before saving. Must tolerate typos and missing units ("110k"), and **flag implausible values** (e.g. +40 kg in 10 days) for confirmation instead of importing them silently.

## D-056 — Target flexibility
- Date / Source: 2026-10-10 · round-02 R2-21
- Decision: All of these are configurable: training/rest-day targets, per-weekday targets, weekly budget, automatic rebalancing, fixed protein. **Default: fixed daily protein target + weekly calorie budget.**

## D-057 — Workout features (R1)
- Date / Source: 2026-10-10 · round-02 R2-23
- Decision: Log by chat, log by form, routine templates (e.g. Push/Pull/Legs), "same as last time, but…", last session's numbers shown while logging, graph per exercise, PRs. Not in R1: notes, rest timer.

## D-058 — Workouts don't change food targets by default
- Date / Source: 2026-10-10 · round-02 R2-24 (owner delegated the decision to Claude)
- Decision: By default, logging a workout does **not** change that day's targets. Users who want training-day targets turn on **calorie shifting**: training days get a larger share of the *same weekly budget*. Training days come from the user's weekly plan (e.g. Sun/Tue/Thu/Sat), and logging a workout on an unplanned day reshuffles the rest of that week.
- Why: For fat loss and muscle retention, the evidence points to total weekly energy intake and adequate daily protein as what matters. Shifting calories toward training days is a matter of preference and adherence, not a physiological advantage. The owner logs workouts *after* the session, so switching targets at that point would arrive too late to help plan meals. A weekly plan does. This also stays consistent with D-021 (no adding exercise calories back) and D-056 (weekly budget).

## D-059 — Sign-in
- Date / Source: 2026-10-10 · round-02 R2-26
- Decision: Google, email, and Sign in with Apple (on iOS). Guest mode: you can try the app without an account, data stays on the device, and you're prompted to sign in to keep it safe.

## D-060 — Speed targets
- Date / Source: 2026-10-10 · round-02 R2-28
- Decision: Typed meal → numbers ≤ 5 s (9 out of 10 cases) · repeat meal ≤ 2 taps, no AI wait · open app → input ready ≤ 2 s · weigh-in ≤ 3 taps · widget/share-sheet entry in R2.

## D-061 — Name is open
- Date / Source: 2026-10-10 · round-02 R2-29
- Decision: "Fitness Buddy" is a working title. Suggestions in round-03 R3-10.

## D-062 — Buddy personality (provisional)
- Status: **Confirmed by D-069**
- Source: round-02 R2-6 (blank)
- Decision: Friendly and short. Replies in the user's language. Gives opinions only when asked.

## D-063 — Arabic details (provisional)
- Status: **Confirmed by D-069**. **Amended by D-080** (replies in the user's language move to R2)
- Source: round-02 R2-15 (blank)
- Decision: Understands any Arabic dialect (Palestinian/Levantine first), Arabizi/Franco ("akalt 2 ta3meya"), and mixed Arabic/English sentences. Full Arabic right-to-left interface in R2.

## D-064 — Halal (provisional)
- Status: **Confirmed by D-069**
- Source: round-02 R2-16 (blank)
- Decision: A "halal" setting (on for the owner) that (1) warns when a scanned product or dish likely contains non-halal ingredients (pork, gelatin of unknown source, alcohol) and (2) keeps suggestions and meal plans halal.

## D-065 — Progress photo backup (provisional)
- Status: **Confirmed by D-069**
- Source: round-02 R2-22 (blank)
- Decision: Photos stay on the device, with a manual "export my photos" option. Optional encrypted cloud backup: Later.

## D-066 — AI feature releases (provisional)
- Status: **Confirmed by D-069**
- Source: round-02 R2-25 (blank)
- Decision: R1: Q&A on own data, suggestions, weekly review by Buddy, workout logging by text. R2: recipe import from URL. Later: workout program generation, fridge-based meal plans, grocery lists.

## D-067 — Data export (provisional)
- Status: **Confirmed by D-069**
- Source: round-02 R2-27 (blank)
- Decision: In-app account deletion (required by stores) and full data export (CSV/JSON).

## D-068 — Steps (provisional)
- Status: **Confirmed by D-069**
- Source: round-02 §0d ("if steps are easily do-able, then let's add")
- Decision: Steps are read from Apple Health / Health Connect, shown **for information only** (they never change the food budget, consistent with D-021). Release: R2. Amends D-002 and D-009 for steps only.
- Why: Reading the phone's existing step count is cheap. Building our own step counter is not.

---

# Round 3 decisions

## D-069 — Provisional decisions confirmed
- Date / Source: 2026-10-10 · round-03 R3-1 (left blank, the second round with no objection)
- Decision: D-058 and D-062 to D-068 are treated as confirmed. The owner can override any of them at any time with a new decision.

## D-070 — Week start
- Date / Source: 2026-10-10 · round-03 R3-2 (blank, recommendation applied)
- Decision: User setting. Default **Saturday**.

## D-071 — Home screen emphasis
- Date / Source: 2026-10-10 · round-03 R3-3
- Decision: **Today's remaining calories** is the big number (it already includes weekly rebalancing), with a smaller "this week: X under/over" line.

## D-072 — Shared pots handled through language
- Date / Source: 2026-10-10 · round-03 R3-4
- Decision: No dedicated "my share" interface. The AI understands sharing from the message ("we were 6", "I had about a quarter") and reflects it in the proposal (D-079).

## D-073 — Label languages and product focus
- Date / Source: 2026-10-10 · round-03 R3-5
- Decision: Label-photo reading supports **Arabic and English**. The owner doesn't buy Israeli brands, so Hebrew labels aren't required. Product coverage focuses on Palestinian, Jordanian, Turkish and other imported products.

## D-074 — Location for prayer times
- Date / Source: 2026-10-10 · round-03 R3-6 (blank, recommendation applied)
- Decision: The user picks their city by default (no location permission needed). Automatic location is optional.

## D-075 — Must-cover dishes drafted by Claude
- Date / Source: 2026-10-10 · round-03 R3-7 ("just typical Palestinian")
- Decision: Claude drafts the must-cover list of typical Palestinian/Levantine foods (`11-foods-and-data-quality.md` §6). The owner may skim it, but it isn't blocking.

## D-076 — AI acceptance messages drafted by Claude
- Date / Source: 2026-10-10 · round-03 R3-8 ("I think you understand me")
- Decision: Claude writes the AI test message set in the owner's style: lowercase, short, typos, English/Arabic/Arabizi mixed (`40-acceptance-criteria.md`).

## D-077 — Occasional nudge to weigh
- Date / Source: 2026-10-10 · round-03 R3-9 (blank, recommendation applied)
- Decision: Estimates are accepted without complaint. The app nudges only occasionally, e.g. for foods you eat often, where weighing once would improve every later log.

## D-078 — Name
- Date / Source: 2026-10-10 · round-03 R3-10
- Decision: Keep **Fitness Buddy**. The assistant is called **Buddy**.

## D-079 — Confirm before logging
- Date / Source: 2026-10-10 · owner message after round 3 ("there should be some confirmation process that should be seamless and nice UI/UX, not auto log behind his eyes")
- Status: Accepted. **Supersedes D-014**, amends D-015.
- Decision: **Nothing the AI interprets reaches the diary until the user confirms it.** Every AI-produced change (new food entry, edit, move, delete, weigh-in, workout, recipe/batch, target change) appears as a **proposal card** showing exactly what will be logged. The user confirms with **one tap**, or adjusts it first, inline or with a follow-up message.
- Rule of thumb: **what the AI interprets is a proposal; what the user taps directly is an action.** Tapping a quick-add chip, choosing an amount after a barcode scan, or editing a number by hand applies immediately, with undo.
- Why: The owner wants to see and approve what gets logged. Trust (PR-3) matters more than saving one tap. Speed is kept by making confirmation a single tap on a card that appears right where the user is looking.
- Affects: D-060 (speed target becomes message → card ready ≤ 5 s, then 1 tap), PR-4, `10-ai-assistant.md` §4.

---

# Technical-planning decisions

## D-080 — Arabic scope trimmed for R1
- Date / Source: 2026-10-11 · owner message during technical planning ("if Arabic or other language support will cause us issues, we can move them to R2 or even R3")
- Status: Accepted. **Amends D-063**, FD-001, FD-020, WO-001, AI-141, AQ-11.
- Decision: R1 keeps the parts the owner uses daily, which are cheap because the AI model does the work:
  - Buddy **understands** English, Arabic, Arabizi and mixed messages (AI-010, LC-001).
  - Local portion words (LC-051) and Arabic label photos (FD-040).
  - Must-cover items have English, Arabic and Arabizi names (AT-003).

  Moved to **R2**, together with the Arabic interface (LC-003) for friends who prefer Arabic:
  - Buddy replying in the user's language and script (AI-141). In R1, Buddy replies in English (AI-143).
  - An Arabic name on every food (FD-001). In R1, only must-cover items and basics have one (FD-004).
  - Typo-tolerant Arabizi in the manual search box beyond the listed spellings (FD-020, FD-024).
  - Arabic names in the built-in exercise library (WO-001). Buddy still understands Arabic exercise names in R1.
  - The AQ-11 parity gate and an Arabic and Arabizi version of every test case. R1 reports scores per language, with no gate.
- Why: Understanding Arabic and Arabizi is mostly the AI model's job, so it costs little, and it's how the owner writes. The expensive parts are everything around it: translating every food and every reply template, writing three versions of the test set, and blocking R1 on a parity score. The owner reads English and the R1 interface is English, so none of that is needed until friends arrive.

## D-081 — Android-first R1, iPhone later
- Date / Source: 2026-10-11 · owner during technical planning ("We can use my android to test. Push iPhone stuff for later"), answering TQ-22
- Status: Accepted. Amends C-1 and AT-004 for R1.
- Decision: R1 is built, tested and distributed on **Android only** (the owner's Samsung A55, via Google Play internal testing). All iPhone work moves to **R2**: iOS builds and distribution (TestFlight), Sign in with Apple (AC-001), and the iPhone speed check in AT-004. The app stays a cross-platform Flutter app, and no Android-only shortcuts are allowed in shared code.
- Why: The owner uses Android and has no Mac. Nobody uses an iPhone in R1. Deferring iOS removes cloud-Mac setup, Apple fees and a second test target until friends need it.

## D-082 — Dark by default, in the Embrace palette
- Date / Source: 2026-10-29 · owner, after the design-canvas review ("The UI looks amazing"), answering TQ-23: "Well the new default will be the palette we decided, the minty stuff. OK anyways."
- Status: Accepted. Amends UX-040. **The default is superseded by D-083** (light, 2026-10-30); the palette part stands.
- Decision: The app opens in the **dark theme by default**, in the "Embrace" brand palette (dark "Deep Forest", teal and mint; light "Mint Cream"). Light and dark themes both stay, and Me › Settings › Theme still offers System / Light / Dark.
- Why: The owner prefers dark, and the approved Embrace identity is designed dark-first. Following the system stays available as a setting. Technical details: TD-098 (step A44).

## D-083 — Light by default
- Date / Source: 2026-10-30 · owner, after the first phone checks of the prod build ("rec for all")
- Status: Accepted. **Supersedes D-082's default** (the Embrace palette stays). Amends UX-040.
- Decision: The app opens in the **light theme** ("Mint Cream") by default. Dark and System stay as choices in Me › Settings › Theme.
- Why: On the phone the owner preferred light for daily use. Technical details: TD-107 (step A45).

## D-084 — Slim weight row on Today
- Date / Source: 2026-10-30 · owner phone feedback (option a)
- Status: Accepted. Amends HM-005.
- Decision: When there's a weigh-in today, Today shows weight as **one slim row**: weight · trend · ＋. Tapping the row opens the weight graph; ＋ logs a weigh-in. The full weight card shows only when there's **no weigh-in today**, to invite one.
- Why: Once you've weighed in, the card takes space that food logging needs. Step A45.

## D-085 — Workouts: muscle maps, no plan required, starter plans
- Date / Source: 2026-10-30 · owner workouts discussion ("I like muscle map… keep it simple… allow users without specific plans… some people like randomness. I trust your judgements")
- Status: Accepted. **Amends D-028, D-029**, WO-001, WO-003, WO-010, WO-021, WO-034, WO-041, WO-043, HM-006.
- Decision:
  - **Pictures:** every exercise, built-in and custom, shows a **muscle map**: front and back body, main muscles dark, secondary muscles lighter. We draw it ourselves from an MIT-licensed body outline. No photos or videos. (The free-exercise-db photos are scraped and must never ship.)
  - **No plan is ever required.** Training without a plan, or randomly, is a first-class way to use the app: log by picking exercises or by telling Buddy. Sessions are named from their muscles ("Chest & triceps") unless renamed. **Repeat** works on any past session, not only templates. The week view shows only the days you trained. **Never** a "missed day" message.
  - **Starter plans** are an optional gallery: Full body (3 days), Upper/Lower (4), Push/Pull/Legs (3–6), and Build my own. Picking one copies editable templates and weekdays.
  - **Logging after the session** is the main way. The form saves as you type.
  - **Working sets only:** no warm-up sets, no supersets or drop sets in R1. Weights in **kg**; lb typed to Buddy is converted.
  - **Today** shows a workout row only on planned days or after you logged one ("Push ✓ · 5 exercises · 1 PR"). Users with no plan see nothing until they log.
  - **Exercise page:** the main line is the heaviest set; estimated 1RM is a toggle.
  - **Calorie shifting** stays off by default (TG-043).
- Why: The owner wants simple and free-form training to feel normal, with a picture per exercise that works for custom ones too. A muscle map needs no photo licences and covers every exercise. The owner's own PPL routine is covered by the PPL starter plan or by just logging.

## D-086 — Shared dish portions default to one person
- Date / Source: 2026-10-30 · owner Q&A (option a; backlog #149)
- Status: Accepted. Amends AI-101 (adds AI-103), D-072.
- Decision: When a shared dish is logged without an amount ("had maqluba with the family"), Buddy assumes **one person's typical portion**, shown as an assumption with −/+ on the card. An explicit amount ("half the pot", "big plate", "we were 6") overrides it. Buddy asks only when it's truly ambiguous.
- Why: A sensible default with an easy fix is faster than a question every time, and keeps the "nothing logged without confirmation" rule. Step A49.

## D-087 — Acceptance by use; dish batches self-approved; A48 and A37b postponed
- Date / Source: 2026-10-30 · owner Q&A ("what about A37B and about local brands? Let's postpone that. This is not super important. And … anything related to dish batches, just auto approve yourself, and based on practice, once everything's ready, I will use the application myself, and if I find any issues, I will let you know.")
- Status: Accepted. Supersedes the owner-skim step for dish batches (D-075 "the owner may skim" stays true, but nothing waits on it). Amends TD-105 (waves).
- Decision:
  - **(a) Dish batches self-approved.** Dish batches (A17, A18, A19, A30, A32) need no owner skim. After an independent AI number check (a Codex task, never the authoring agent), the orchestrator marks the dishes `reviewed_by: ai-verified` and they ship in the pack. The owner's family recipes still override generic ones when they report them (TQ-08).
  - **(b) Acceptance by use.** Owner skims and device checks are optional. The owner accepts features by using the app and reports issues; steps don't wait for owner checks (device benchmarks such as backlog #219 become optional notes).
  - **(c) Postponed.** A48 (local brands) and A37b (workout logging by chat) leave the active phase-1 waves. A37b stays in phase 2. A48 moves to "later (postponed by owner)".
- Why: The owner is the only reviewer and wants to judge the finished app by living with it, not by reviewing data and checklists. Local brands and chat workout logging are not important for the first release.

## D-088 — First run on fresh installs; benefit-led sign-in; Me as grouped subpages
- Date / Source: 2026-10-31 · owner, UX overhaul review of the sketches ("I want us to do something EXCELLENT"; approved the first-run, sign-in and Me boards; "first-run flow only on fresh installs"; training "Not right now" → set up later in the Workouts tab)
- Status: Accepted. Amends UX-010, UX-060. Step A51.
- Decision:
  - **First run, fresh installs only.** On a phone with no profile and no logged data the app opens on a welcome screen: **Get started**, **Skip setup, I'll look around**, **Already have an account? Sign in**. Then one question per screen with a segmented progress bar: **goal** (lose / keep / gain / just see what I eat) → **about you** (sex, birth year, height, weight; metric or imperial) → **activity** → **training** (not right now / I mix it up / I want a plan) → **your plan** (daily calories and macros; "How is this worked out?" on demand; "Change the numbers") → **keep your data safe?** (Google / email / Not now). Every question can be skipped and answers survive Back. Nothing is saved until the plan is confirmed, as one undoable change. Skipped inputs or "just see what I eat" mean **no targets yet**; nothing is invented. "I want a plan" opens the starter plans afterwards. Phones that already have a profile or any data never see it.
  - The existing "Set up profile & targets" entry points open the same question screens, without the welcome and account steps. Week start and halal live in Preferences and Food & meals; the city is asked where prayer times need it (Ramadan).
  - **Sign-in:** a benefit-led header, Google's own "Continue with Google" button (shown only when Google sign-in is available), email with a 6-digit code entered in six boxes (paste fills them), a resend countdown, "Use a different email" and "Keep using without an account".
  - **Me:** an account card at the top (guest: "Data on this phone only, not backed up" + Sign in; signed in: the backup status), a compact targets summary, then grouped rows that open subpages: **Your plan** (Targets & goal, Food & meals, Workouts, Ramadan) and **App** (Preferences, Notifications, Account & data, Help & about). Rows show their current values; destructive actions sit apart at the bottom of Account & data. Every existing Me feature stays reachable.
- Why: The owner's critique of the first daily use: setup felt like a form and Me like a long list. Short, skippable, one-topic screens with the account offered last and optional follow the UX research (progressive disclosure, guest access prominent, no confirmshaming).

## D-089 — Workouts: easier tab, muscle maps in logging, popularity order, plans never assume exercises
- Date / Source: 2026-10-31 · owner UX critique and sketch review ("The workouts page is quite hard to use IMO"; "on logging, we should show the muscle map next to the exercise, it looks cool"; "sort the workouts by popularity"; "when a user selects a plan … we should ask them to select exercises, not assume them, we could have some defaults ofc if they want")
- Status: Accepted. Amends D-085, WO-001, WO-007, WO-023, WO-024, WO-034.
- Decision:
  - **Workouts tab:** this week's strip (trained days, today outlined, never "missed"), today's plan card with "Log <name>" and "Something else" (or one "Log a workout" card without a plan), recent sessions with a small muscle map and Repeat, and one "Your plan" row. The exercise library opens from a search icon; templates and the weekly plan live on the "Your plan" page. With no sessions and no plan, the tab is the setup point: "Log a workout" or "Choose a plan" (where the first run's "Not right now" lands).
  - **Logging:** every exercise card shows its muscle map next to the name, and the form's top shows the session's muscles ("Chest · Shoulders · Triceps") and progress ("1 of 5 exercises logged"). Set rows stay the main element, with last time's numbers per set.
  - **Popularity:** the built-in exercises carry a curated popularity rank. The picker shows "Your recent" (with the last result) and then "Most popular" before anything is typed, and search breaks ties by popularity.
  - **Plans never auto-assign exercises.** Picking a plan (Full body, Upper/Lower, Push/Pull/Legs, or Make my own; "No plan, I'll log as I go" is listed first) asks for the weekdays, then shows each workout day empty, with suggested exercises to add one by one or all at once. Nothing is saved until the user finishes, in one change with Undo.
- Why: The tab mixed every function on one long list; the sketches put today's action first. Muscle maps make the log form easier to scan, popular exercises are found faster, and a plan should reflect what the user actually does instead of our guess. Step A52.

## D-090 — Targets: one suggested number a day, changed per weekday; calculation on demand
- Date / Source: 2026-10-31 · owner UX critique ("Targets, showing how it's calculated should only appear on demand, also, it should be EASY to specify per day target, not complex, which means we can get rid of this high calorie days or whatever") and the sketch review ("We should not be this involved, we make a suggestion, then user can adapt as they need")
- Status: Accepted. **Amends D-058, TG-021, TG-040, TG-041, TG-042, TG-043, TG-044, WO-061.**
- Decision:
  - The app **suggests** one daily number (the calculated target, adapted after 2–3 weeks of weigh-ins). Each weekday can be given **its own number** ("Same every day | Different by day", tap a day, − / +, quick chips, type). A changed day keeps following the suggestion when it changes (stored relative to it).
  - The **week's total** is the sum of the seven days. Rebalancing (on by default) stays: over- or under-eating spreads over the rest of the week, each day within ±25 % of its own number and never below the safety floor.
  - "Higher-calorie days" with weights, taking calories "from other days", per-date one-off targets and training-day shifting are **removed**. Existing higher-calorie days become per-weekday numbers with the same daily values.
  - How the number is worked out (resting energy → × activity → goal → result) shows **only on demand**, with "Recalculate with today's weight" and "Set my own number instead". Rebalancing and the macro split move under "More options".
  - A day set below the safety floor shows the same warning and acknowledgement as an own target below the floor (SF-012).
- Why: Picking a number per day is simpler than weights and shares; the explanation is useful once, not every visit. Technical details: TD-112 (step A53).

## D-091 — Food names in the language you read
- Date / Source: 2026-10-31 · owner UX critique ("For foods, we show both Arabic and English names, we should have a setting, that defaults to system language(s) if possible, otherwise, default to English") and the sketch review
- Status: Accepted. **Amends LC-005**, adds LC-007.
- Decision:
  - Setting **Food names**: Match my phone (default) / English / Arabic / Both. "Match my phone" shows Arabic when the phone's language list prefers Arabic, else English. Both shows the English name with the Arabic one underneath. The app's own text stays English in R1 (D-080).
  - It applies wherever a food is listed: search results, recents, diary rows, quick add, saved meal items and your foods. If a food has no name in the chosen language, the other one shows. Names the user typed stay as typed.
  - The **food page** always shows both names and the food's other names ("Also called: …").
  - Search still understands English, Arabic and Arabizi. When the match came from the other language or an alias, the result says "Matched <name>".
- Why: A list in one language is easier to scan; the other names stay one tap away. Step A53.


## D-092 — Today summary card with slides
- Date: 2026-10-31
- Status: Accepted by the owner’s direct feature request and A56 build brief. Amends HM-005, HM-006, HM-009 and the Today presentation in D-084/D-085.
- Decision: Today’s top is a card with slides (Nutrition, Weight, Workout). Weight and workout are slides, not rows; the workout slide always shows (empty state “Log a workout”). Day swipe works below the card. A horizontal drag starting on the card changes slides. Buttons and the date picker continue changing days.
- Reason: keep Today’s essentials compact while preserving weight and workout entry points. Slide selection is session-only, shared across viewed days, with Nutrition first on cold start; no startup network or persisted setting.
