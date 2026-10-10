# 00 — Vision & Scope

_Status: **Draft v2** · 2026-10-10 · Based on D-001 to D-079._

## 1. The problem

People who want to lose fat (or gain muscle) know they should track what they eat. Most stop, and the owner of this project did too: **they stopped using MyFitnessPal and Cronometer because of the inconvenience**, not because of a lack of features (D-039). The specific problems:

- Logging one meal takes many taps: search, pick from duplicate or wrong entries, set a serving, repeat for every ingredient.
- Home-cooked and family-cooked food, which is most of what people in the Middle East eat, is a nightmare to log.
- Local dishes and local products are poorly covered, and local restaurants publish no nutrition data (D-046).
- Screens are cluttered and dated. Ads are everywhere. Core features sit behind paywalls.
- Fixing a logged item is painful.
- Weight lives in a phone note with no graph and no trend (D-024).
- Nutrition, weight and training are spread over separate apps.

## 2. The vision

> **Tell it what you ate, the way you'd tell a friend, and trust the number you get back.**

Fitness Buddy (D-078) is a mobile app for iOS and Android focused on **nutrition and weight**. An AI assistant ("Buddy") turns plain English or Arabic messages, photos, barcodes and labels into a food diary. The numbers come from trusted food data, not AI guesses (D-011). When a detail changes the result a lot, it asks one quick question. **Nothing is logged until you've seen it and tapped to confirm** (D-079). It remembers your habits, your foods and your portions. Weight, simple strength workouts and a weekly view of progress live in the same place. The whole thing is clean, fast and ad-free.

## 3. Who it's for

| Stage | Users | Release |
|---|---|---|
| 1 | **The owner**: cutting, trains strength 3–4×/week (PPL), eats home-cooked and out, Middle Eastern (Palestinian) food, lives in the West Bank, owns a kitchen scale but often doesn't use it, weighs in weekly, writes in English and Arabic, fasts in Ramadan, eats halal | **R1** |
| 2 | Friends: similar region and culture, mixed goals, not necessarily technical, some may not train | **R2** |
| 3 | Public (if worthwhile): App Store / Play Store, mainly Arabic-speaking and Middle Eastern users first | **R3** |

Data, privacy and safety are designed as if stage 3 were already here (D-001).

Personas and daily journeys: `01-personas-and-journeys.md` (planned).

## 4. Success criteria

| ID | Criterion | How we know |
|---|---|---|
| SC-1 | **The owner uses it daily instead of everything else**: no MyFitnessPal/Cronometer, no weight note | Self-reported after 4 weeks of R1 |
| SC-2 | **Logging a typical meal is effortless** | Speed targets in D-060 / D-079 met: message → proposal card ≤ 5 s → 1 tap to confirm; repeat meals in ≤ 2 taps |
| SC-3 | **The numbers can be trusted** | AI logging passes the acceptance set (R3-8) within the accuracy targets in `40-acceptance-criteria.md` |
| SC-4 | **Every number shows where it came from** | Each logged item shows its source (database, label, reference recipe, estimate) |
| SC-5 | **Weekly progress is obvious at a glance** | Weekly summary + weight trend visible within 1 tap of opening the app |
| SC-6 | **Nothing is lost** | Switching or reinstalling a phone keeps all data, except device-only photos (D-065) |

## 5. Product principles

These come straight from what made the owner quit other apps (D-039). When two options compete, the one that follows these wins.

| ID | Principle | Means in practice |
|---|---|---|
| PR-1 | **Convenience first** | The fewest possible steps for every common action. Typing a sentence beats filling a form. |
| PR-2 | **Ask, don't guess, but rarely** | At most 1–2 quick-tap questions per log, only when the answer changes the result a lot. Otherwise use your defaults and show the assumption (D-012). |
| PR-3 | **Trustworthy and transparent** | Numbers come from trusted data. Estimates are always marked, with a range on tap (D-011, D-045). |
| PR-4 | **You see it before it's logged** | The AI proposes and you confirm with one tap. Adjusting the proposal (or anything already logged) takes one sentence or one tap (D-079, D-015). |
| PR-5 | **One choice, not twenty** | Never make the user pick between duplicate search results. Pick the best match and let them change it. |
| PR-6 | **The week matters more than the day** | Weekly budget, weekly summary. A day over isn't a failure (D-044, D-056). |
| PR-7 | **Clean, not empty** | Uncluttered screens that still show the key numbers. Light and dark themes (D-035). |
| PR-8 | **No ads, no nagging, no games** | No ads ever (D-041). Moderate, configurable reminders (D-032). No streaks, badges or social (D-033). |
| PR-9 | **Local by default** | Palestinian/Levantine food, Arabic and Arabizi, halal and Ramadan are first-class, not add-ons (D-022, D-051). |
| PR-10 | **No bloat** | Features earn their place. Water, sleep, habits, supplements and fasting timers are out (D-002). |
| PR-11 | **Your data is yours** | Synced to your account, exportable, deletable (D-008, D-067). |
| PR-12 | **Kind language** | No "good/bad food" judgements. Guardrails against unsafe goals (D-034). |

## 6. Scope by module

Releases: **R1** = owner · **R2** = friends · **R3** = public · **Later** = not planned. Detailed requirements live in the module files.

### In scope

| Module | R1 | R2 | R3 | Later | Spec file |
|---|---|---|---|---|---|
| **AI logging**: text (EN/AR/Arabizi/mixed), clarifying questions, corrections by chat, memory | Text, photo + text, clarify, correct, memory | | | Voice | `10-ai-assistant.md` |
| **AI assistant extras** | Q&A on own data, suggestions, weekly review | Recipe from URL | | Program generation, fridge meal plans, grocery list | `10-ai-assistant.md` |
| **Foods**: database, barcode, label photo, personal foods, local dishes | All, plus private user-added foods | | Shared user-added foods (marked until verified) | | `11-foods-and-data-quality.md` |
| **Diary**: meal slots, batch cooking, family-cooked dishes, recipes, time handling | All except recipe library | Recipe library | | | `12-diary-meals-recipes.md` |
| **Targets & goals**: formula → adaptive, weekly budget, shifting, protein, goals incl. monthly | All | | | | `13-targets-and-goals.md` |
| **Weight & body**: weigh-ins, trend graph, paste import, measurements | Weight, trend, import, measurements | | | | `14-weight-and-body.md` |
| **Progress photos** (device-only) | | ✓ | | Encrypted backup | `14-weight-and-body.md` |
| **Workouts**: chat/form logging, PPL templates, last session, graphs, PRs, manual cardio | All | Hide module | | Notes, rest timer, programs | `15-workouts.md` |
| **Home & insights**: dashboard, weekly summary, charts | All | | | | `16-insights-and-home.md` |
| **Notifications** (configurable) | Core reminders | | | | `17-notifications.md` |
| **Localization & culture**: units, Arabic input, halal, Ramadan | Input, halal, Ramadan | Arabic RTL interface | | | `18-localization-and-culture.md` |
| **Accounts & data**: sign-in, sync, guest mode, offline, export, deletion | All | | | | `20-accounts-and-data.md` |
| **Steps** (read-only, info only) | | ✓ | | | `16-insights-and-home.md` |
| **Quick entry**: widget, share sheet | | ✓ | | | `30-ux-principles.md` |
| **Safety**: guardrails, disclaimers, age gate | Basic | Full | ✓ | | `21-safety-and-wellbeing.md` |
| **Monetization**: AI limits, paid tier | Free | Free | Free + paid tier | | `02-monetization.md` |

Recipe library and progress photos are R2: both are wanted, but neither is needed to replace the owner's current apps.

### Out of scope (non-goals)

| ID | Not doing | Why |
|---|---|---|
| NG-1 | Water, sleep, habit, supplement tracking, fasting timers | Bloat; inconvenient to use (D-002) |
| NG-2 | Streaks, badges, leaderboards, friends, social feed | Not wanted (D-033) |
| NG-3 | Ads | Main complaint about competitors (D-041) |
| NG-4 | Tablet, smartwatch and web apps | Phones only (D-004) |
| NG-5 | Wearable/scale integrations, GPS cardio tracking | Not needed (D-009, D-030); steps are the only exception (D-068, R2) |
| NG-6 | Adding exercise calories to the food budget | Wearables overestimate burn (D-021) |
| NG-7 | Advanced training features (RPE, periodization, rest timers) | Simple logging was requested (D-028) |
| NG-8 | Importers for other apps' export files | Paste-text import covers it (D-055) |
| NG-9 | Medical advice or clinical nutrition | Not a medical product (D-034) |
| NG-10 | Technical design inside `spec/` | Planned separately (D-005) |

## 7. Constraints

- **C-1** Flutter, iOS + Android phones (D-004).
- **C-2** Solo developer: scope must stay realistic per release.
- **C-3** AI must be cheap and good enough. Cloud AI is acceptable (D-018). The free tier must be affordable to run (D-041).
- **C-4** Store rules: in-app account deletion, Sign in with Apple when Google sign-in is offered (D-059, D-067).
- **C-5** Food data licensing must allow the planned use (see `research/domain-pitfalls.md` P7). This is checked in technical planning.

## 8. Open items

None at the vision level. Module-level open questions are listed at the end of each module file.
