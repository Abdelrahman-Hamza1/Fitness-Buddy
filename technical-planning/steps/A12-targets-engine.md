# A12 — Targets engine

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A06 | M | Codex (TD-078) | ⬜ Not started |

_Old ID: S19 (renumbered by TD-063, 2026-10-16)._

**Goal.** All target math as pure, property-tested domain code: initial targets, goals and phases, the weekly budget with rebalancing and safety limits, macros and fiber, calorie shifting. The UI (A13) and adaptive targets (A38) build on it.

**Spec:** TG-001, TG-002, TG-010, TG-011, TG-012, TG-013, TG-020, TG-040, TG-041, TG-042, TG-043 (engine), TG-044, TG-050–055, TG-060 (data hook), SF-010, SF-011, SF-012 (rule), WO-060, D-056, D-058 · **Decisions:** TD-009

## Scope
- **Profile & goal model:** sex, birth year, height, current weight, activity level (4 levels), goal type (lose/maintain/gain). Goal expression in any form: target + date, target + rate, rate only, **monthly target**. Conversion to a weekly rate and back for display (TG-011).
- **Phases** (TG-012): start/end dates, a name, history kept.
- **Initial target:** Mifflin-St Jeor × activity factor, ± the energy for the goal rate (≈ 7,700 kcal/kg), with a plain-language **explanation object** (TG-021 renders it).
- **Safety:** the calorie floor = max(estimated resting energy, 1,200 / 1,500 kcal by sex) (SF-010). Max loss rate 1% of body weight per week, capped with a warning (SF-011, TG-013). Manual override allowed with an acknowledgement flag (SF-012).
- **Weekly budget** (TG-040) and **rebalancing** (TG-041): day target = (budget − eaten earlier this week) ÷ days left, limited to ±25% of base and never below the floor. The carry-over shown as "this week: X over/under" (TG-042). **Fixed mode** (TG-044).
- **Calorie shifting** (TG-043): weighted days from the weekly plan or chosen weekdays, sharing the **same** weekly budget. An unplanned workout redistributes the rest of the week (the workout plan input is wired in A36).
- **Macros & fiber** (TG-050–055): protein g/kg of goal (or current) weight, fat % with a g/kg floor, carbs = rest, fiber 14 g/1,000 kcal, user overrides in g or %, "calories + protein only" mode. Daily targets for P/F/fiber. Only calories/carbs flex weekly.
- **Versioned `target_settings`** (effective-from dates). **Past targets are recomputed**, not stored (G10).
- **Ramadan variant** stored as data (behaviour in A41).
- **Defaults table** (`spec/13` §8) in one config object.

## Out of scope
- Screens (A13). Adaptive expenditure (A38). Ramadan behaviour (A41).

## Fixed by the plan
- Exercise calories never added (TG-036, WO-060). Floors respected by every generator (SF-010).

## Decide in the low-level plan
- How a "day" with no logging is treated in rebalancing (unknown, not zero, per TG-032 spirit).
- The rounding of displayed targets.

## Exit criteria
- [ ] **Property tests:** generated day targets never below the floor. The weekly sum is preserved by rebalancing and shifting (within the limits). The ±25% bound holds. Shifting never changes the weekly total.
- [ ] Unit tests reproduce worked examples for each goal expression (incl. "−2 kg this month").
- [ ] `fb_domain` coverage stays ≥ 95%.

## Read first
`spec/13-targets-and-goals.md` · `spec/21-safety-and-wellbeing.md` §2

## Owner involvement
Confirm the defaults table still matches your intent (`spec/13` §8).

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
