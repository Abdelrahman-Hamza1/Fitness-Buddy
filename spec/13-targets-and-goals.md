# 13 — Targets & Goals

_Status: **Draft v1** · 2026-10-10 · Main decisions: D-020, D-021, D-027, D-034, D-052 to D-054, D-056, D-058, D-070._

Numeric defaults below are **starting values** based on common evidence-based practice. They're listed in one place (§8) so they can be reviewed together.

## 1. Profile

- **TG-001** `[R1]` Needed for targets: sex (for formulas; "prefer not to say" uses an average of the two formulas, R2), birth year, height, current weight, activity level (4 plain-language levels), goal.
- **TG-002** `[R1]` Units follow the unit setting (D-006). Inputs accept either system.

## 2. Goals (D-027)

- **TG-010** `[R1]` Goal type: **lose**, **maintain**, or **gain**.
- **TG-011** `[R1]` The user expresses the goal in whichever way suits them: a target weight + date, a target weight + weekly rate, a weekly rate alone, or a **monthly target** ("−2 kg this month", the owner's style). The app converts it into a weekly rate and shows the others for reference ("≈ −0.46 kg/week, goal reached around March 2027").
- **TG-012** `[R1]` Goal **phases**: each goal has a start and end date and is kept in history (e.g. "Cut, Jan–Apr 2026"). Charts can be filtered or shaded by phase (`16`).
- **TG-013** `[R1]` Rates beyond the safety limits trigger a warning, and the app never generates them itself (`21-safety-and-wellbeing.md`).

## 3. Initial targets (D-053)

- **TG-020** `[R1]` Initial expenditure estimate = Mifflin-St Jeor resting energy × activity factor. The calorie target = expenditure − (or +) the energy for the goal rate (≈ 7,700 kcal per kg per week ÷ 7 per day).
- **TG-021** `[R1]` The user sees how the number was calculated in plain language, and can override any target manually at any time (manual override is always available, D-053).

## 4. Adaptive targets (D-053, D-054)

- **TG-030** `[R1]` Once there's enough data, the app estimates **actual expenditure** from logged intake and the change in **trend weight** over the same period, and recalculates targets weekly.
- **TG-031** `[R1]` "Enough data" = at least **14 days** of logging, of which at least **10 complete** (not marked incomplete, DY-004), plus at least **3 weigh-ins spread over ≥ 10 days**. With weekly weigh-ins this usually takes 3–4 weeks. The app says so plainly and shows progress ("2 more weigh-ins until your targets can adapt").
- **TG-032** `[R1]` Incomplete days are left out of the calculation, and missing days are treated as unknown, never as zero.
- **TG-033** `[R1]` Each estimate shows a **confidence** level (low / medium / high) based on how much data there is and how consistent it is. Fewer weigh-ins mean lower confidence (D-054).
- **TG-034** `[R1]` **Weekly check-in**: at the start of each week (D-070), if the recommended target differs from the current one by more than **50 kcal/day**, Buddy proposes the change inside the weekly review. It's a proposal (D-079): the user accepts, adjusts or keeps the current target. A setting can switch this to "apply automatically" (default: **ask**).
- **TG-035** `[R1]` Weekly changes are limited to **±150 kcal/day** per check-in to avoid jumps from noisy data.
- **TG-036** `[R1]` Exercise calories are **never** added to the food budget (D-021). Expenditure is learned from real results instead.
- **TG-037** `[R1]` Ramadan weeks are included, but with lower weight confidence, because weight fluctuates more while fasting (D-052).

## 5. Weekly budget & daily targets (D-056, D-058)

- **TG-040** `[R1]` **Default model: weekly calorie budget + fixed daily protein.** Weekly budget = daily calorie target × 7. The week starts on the user's chosen day (default Saturday, D-070).
- **TG-041** `[R1]` **Rebalancing** (on by default): each day's calorie target = (weekly budget − calories eaten earlier this week) ÷ days left, so going over on Monday lowers the remaining days a little, and under-eating raises them.
- **TG-042** `[R1]` Rebalancing limits: no day's target goes below the safety floor (`21`), and no day moves more than **±25%** from the base daily target. Any surplus or deficit beyond that carries as a visible "this week: X over/under" figure instead of being forced into the remaining days.
- **TG-043** `[R1]` **Calorie shifting** (optional, off by default, D-058): the user assigns a weight to particular days, either planned training days (from the weekly workout plan, `15`) or specific weekdays (e.g. Friday higher). Those days get a larger share of the **same** weekly budget. Logging a workout on an unplanned day redistributes the rest of that week.
- **TG-044** `[R1]` Simple fixed mode is also available: the same target every day, no weekly logic.
- **TG-045** `[R1]` The home screen shows today's remaining calories big and the weekly position small (D-071).

## 6. Macros & fiber

- **TG-050** `[R1]` **Protein**: a fixed daily gram target. Default **1.8 g per kg of goal weight** (or current weight if there's no target weight), adjustable.
- **TG-051** `[R1]` **Fat**: default 30% of calories, never below **0.6 g per kg** of goal/current weight.
- **TG-052** `[R1]` **Carbs**: the remaining calories.
- **TG-053** `[R1]` **Fiber**: default **14 g per 1,000 kcal** of the target.
- **TG-054** `[R1]` The user can set any macro in grams or %, or choose "calories + protein only" (carbs/fat shown but without targets).
- **TG-055** `[R1]` Protein, fat and fiber are **daily** targets. Only calories (and therefore carbs) flex across the week.

## 7. Ramadan targets (D-052)

- **TG-060** `[R1]` During Ramadan, a separate target setting applies: by default, the same goal and weekly budget. The user can choose "maintain during Ramadan" with one tap at the start of Ramadan (offered as a proposal in the first Ramadan weekly review).
- **TG-061** `[R1]` Normal targets resume automatically after Ramadan.

## 8. Defaults summary (for review)

| Default | Value | Ref |
|---|---|---|
| Energy per kg of body weight change | ≈ 7,700 kcal | TG-020 |
| Adaptive data threshold | 14 days, ≥ 10 complete, ≥ 3 weigh-ins over ≥ 10 days | TG-031 |
| Check-in threshold to propose change | > 50 kcal/day | TG-034 |
| Max change per check-in | ±150 kcal/day | TG-035 |
| Rebalancing daily limit | ±25% of base target | TG-042 |
| Protein | 1.8 g/kg goal (or current) weight | TG-050 |
| Fat | 30% of calories, ≥ 0.6 g/kg | TG-051 |
| Fiber | 14 g / 1,000 kcal | TG-053 |
| Safety floor and max rate | see `21-safety-and-wellbeing.md` | TG-013 |

## Open questions

None currently.
