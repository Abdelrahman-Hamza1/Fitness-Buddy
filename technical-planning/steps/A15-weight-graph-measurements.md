# A15 — Weight graph & measurements

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A12, A14 | L | Claude | ⬜ Not started |

_Old ID: S22 (renumbered by TD-063, 2026-10-16)._

**Goal.** The weight graph that replaces the owner's note, with all its overlays, plus body measurements and their graphs. The chart library is confirmed (TD-012) by a feasibility check at the start.

**Spec:** WB-020, WB-021 (goal line, projection cone, phase shading; Ramadan shading data arrives in A41), WB-022, WB-023, WB-040 (form), WB-041, WB-042 (manual body fat), WB-043 (setting), IN-004 · **Decisions:** TD-012

## Scope
- **Feasibility check first (≤ ½ session):** fl_chart with points + trend line + goal line + uncertainty cone + shaded bands + touch tooltips. If any part fails, `CustomPainter` for that layer. **Record TD-012.**
- **Chart widgets** in `fb_design_system` (the wrappers from A02): time-axis handling (chronological in any direction, LC-003-ready), ranges 1M/3M/6M/1Y/All, tooltips.
- **Weight graph** (WB-020–022): raw points + trend, goal weight line, projected path to the goal with a cone (from the trend rate + uncertainty), **shaded phases** (TG-012), a band API for Ramadan periods (fed in A41), tap a point → value, date, note, trend at that date.
- **Summary stats** (WB-023): change since phase start, this month vs the monthly target, average weekly rate.
- **Measurements:** built-in types (waist, chest, hips, arm, thigh, neck) + custom types, a form entry (chat in A29), a graph per type (trend smoothing only with ≥ 5 points), body fat % manual with its own graph (WB-042), and a measurement reminder on/off setting stored for A40 (WB-043).
- **The owner's weight history:** a simple multi-row manual entry (paste import comes with Buddy in A29).

## Out of scope
- Paste import (A29). Ramadan detection (A41). The Progress tab layout (A16).

## Fixed by the plan
- Charts are wrapped in design-system widgets. Screens never use the chart library directly.

## Decide in the low-level plan
- The projection cone method (e.g. a rate ± standard error over the last N weeks).
- Down-sampling for "All" ranges with years of data.

## Exit criteria
- [ ] **TD-012 recorded** with the feasibility result.
- [ ] The weight graph renders the owner's real history with every overlay. The owner signs off ("this replaces my note").
- [ ] Goldens for the graph in each range (light/dark). Tooltip interaction test.
- [ ] Measurements: add, edit, delete with undo. Graphs per type.
- [ ] Rendering 2 years of daily points stays smooth on the A55 (no frame > 16 ms during pan).

## Read first
`spec/14-weight-and-body.md` §3, §5 · `02-tech-stack.md` §1 (charts)

## Owner involvement
Enter your weight history (or hand it over for entry). Review the graph.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
