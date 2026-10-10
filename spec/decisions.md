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
- Decision: Strength training (owner: PPL, 3–4×/week). Simple logging: exercise, sets × reps × weight, usually logged **after** the session. No RPE, tempo or periodization initially.
- Open: Rank and scope → round-02 R2-2, R2-23.

## D-029 — Exercise library stays simple
- Date / Source: 2026-10-10 · round-01 Q39
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
- Status: **Confirmed by D-069**
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
