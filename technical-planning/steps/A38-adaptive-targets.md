# A38 — Adaptive targets & weekly check-in

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A16, A23 | M | Claude | ⬜ Not started |

_Old ID: S43 (renumbered by TD-063, 2026-10-16)._

**Goal.** Targets that learn from reality: estimate actual expenditure from logged intake and the trend weight, say how confident that is, and propose a change each week, never silently.

**Spec:** TG-030, TG-031, TG-032, TG-033, TG-034, TG-035, TG-036, TG-037, IN-005, AI-056, DY-004 (suggestion), SF-010 · **Decisions:** TD-009

## Scope
- **`AdaptiveExpenditure`** in `fb_domain`: expenditure = intake − energy of the trend change over the window. Readiness rules (TG-031: ≥ 14 days logged, ≥ 10 complete, ≥ 3 weigh-ins over ≥ 10 days). Incomplete days excluded, missing days unknown (not zero, TG-032). **Confidence** low/medium/high from data quantity and consistency (TG-033). Ramadan weeks with lower weight confidence (TG-037, wired fully in A41).
- **Progress messaging:** "2 more weigh-ins until your targets can adapt" (TG-031).
- **Weekly check-in** (TG-034): at week start, if the recommended target differs by > 50 kcal/day → a **target-change proposal** (AI-056), capped at ±150 kcal/day (TG-035), floors respected (SF-010). A setting for ask (default) vs apply automatically.
- **Expenditure chart** (IN-005) with confidence.
- **Incomplete-day suggestion** (DY-004): days < 50% of target with < 2 meals → a proposal to mark the day incomplete (never automatic).
- The check-in proposal is attached to the weekly review in A39. Until then, it's shown on Progress.

## Out of scope
- The review narrative (A39).

## Fixed by the plan
- Exercise calories are never added (TG-036). Changes are proposals unless the user chose automatic.

## Decide in the low-level plan
- The estimation method details (window length, weighting, outlier handling) with test scenarios.

## Exit criteria
- [ ] Domain tests with synthetic histories: correct expenditure within tolerance, readiness thresholds, confidence levels, caps and floors.
- [ ] Property: a check-in never proposes beyond ±150 kcal/day or below the floor.
- [ ] The incomplete-day suggestion triggers only on the rule (test).

## Read first
`spec/13-targets-and-goals.md` §4

## Owner involvement
None (your real data validates it over the following weeks).

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
