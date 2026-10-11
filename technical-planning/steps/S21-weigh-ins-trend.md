# S21 — Weigh-ins & trend

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P2 Targets & weight | S16 | M | ⬜ Not started |

**Goal.** Logging a weigh-in in three taps, and a smoothed trend weight that behaves sensibly with weekly or irregular weigh-ins. This is the core of "replace the weight note" (D-024).

**Spec:** WB-001, WB-003, WB-004, WB-005, WB-010, WB-011, WB-012, HM-005, UX-005 · **Decisions:** TD-009

## Scope
- **Table** `weigh_ins` (value in kg + original input value/unit, measured_at, local_date, note).
- **3-tap pad** (WB-001): the weight card on Today → number pad prefilled with the last value → save (a direct action with undo). Date/time defaults to now, editable. Optional note.
- **Several per day** allowed. The earliest is used for the trend unless the user picks otherwise (WB-003).
- **Implausible check** (WB-005): > 3% change within 7 days, or a likely unit mix-up (e.g. 214 vs 97 → "did you mean lb?") → confirm before saving.
- **Trend algorithm** (WB-010): handles irregular gaps, and a single weigh-in moves the trend only partly. Weekly rate from the trend.
- **Weight card** on Today (HM-005, WB-011): "Trend 97.6 kg · −0.4 kg/week", the latest raw value smaller, tap → pad or graph (S22).
- **Honesty message** (WB-012) about low weigh-in frequency, at most once a month.

## Out of scope
- The graph and stats (S22). Weigh-ins by chat and paste import (S39).

## Fixed by the plan
- The trend is derived (computed), not stored (`05` §2.2).

## Decide in the low-level plan
- **The trend algorithm** (e.g. time-aware exponential smoothing with a half-life in days, or a local regression), with a short justification and test scenarios: weekly weigh-ins, daily noise, a 3-week gap, a single outlier.

## Exit criteria
- [ ] A weigh-in is logged in 3 taps from Today (integration test counts taps).
- [ ] Trend property tests: stays within the min/max of inputs. Converges to a constant series. A single outlier moves it only partly.
- [ ] Implausible-value tests (3% rule, unit mix-up).
- [ ] Goldens for the weight card and pad.

## Read first
`spec/14-weight-and-body.md` §1–2

## Owner involvement
Log your weigh-ins. Feedback on how the trend feels.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
