# A16 — Progress tab v1

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A13, A15 | M | Claude | ⬜ Not started |

_Old ID: S23 (renumbered by TD-063, 2026-10-16)._

**Goal.** The Progress tab with calories, macros, weight, measurements and goal progress, all filterable by goal phase, so weekly progress is obvious at a glance (SC-5).

**Spec:** IN-002, IN-003, IN-004, IN-006 (measurements; exercise entry in A37), IN-007, IN-009, IN-020, IN-021, DY-004 (manual incomplete marking in the UI), SC-5 · **Decisions:** —

## Scope
- **Progress tab layout:** a current-week header (the weekly summary card arrives in A39), then chart sections.
- **Calories chart** (IN-002): daily intake vs daily target, by week or month. **Incomplete days** marked differently.
- **Macros chart** (IN-003): P/C/F/fiber per day vs targets.
- **Weight** (IN-004): the A15 graph embedded, plus a link to the full view.
- **Measurements** entry points (IN-006).
- **Goal progress** (IN-007): the current phase, progress toward the target weight, this month vs the monthly target.
- **Phase filter** (IN-009) on every chart.
- **Mark a day incomplete** from the diary day menu and the chart (DY-004 manual). The suggestion comes in A38.
- Check IN-020/021: no streaks, scores or micronutrient dashboards.

## Out of scope
- The weekly summary + review (A39). The expenditure chart (A38). Exercise progress (A37). The Ramadan comparison (A41).

## Fixed by the plan
- Past targets are recomputed from current data (G10), so charts reflect corrected history.

## Decide in the low-level plan
- Aggregation queries vs the in-memory domain for month views (measure first, `03` §4).

## Exit criteria
- [ ] With one year of seeded data, each chart renders in < 300 ms on the A55 (measured).
- [ ] The phase filter changes every chart (widget tests).
- [ ] An incomplete day is visibly distinct in the calories chart (golden).
- [ ] The owner can answer "how did this week go?" in one tap from Today (SC-5, the review card comes in A39).

## Read first
`spec/16-insights-and-home.md` §2–3

## Owner involvement
Review with your real data.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
