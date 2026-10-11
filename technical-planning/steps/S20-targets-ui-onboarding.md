# S20 — Goals & targets UI, R1 onboarding

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P2 Targets & weight | S18, S19 | M | ⬜ Not started |

**Goal.** The user sets up a profile and goal in under two minutes, understands their targets, can override them safely, and the Today screen shows the real numbers: remaining calories, the weekly position and macros.

**Spec:** UX-060, TG-001, TG-002, TG-010, TG-011, TG-012, TG-013, TG-021, TG-044, TG-045, TG-054, HM-001, HM-002, HM-003, SF-010–012 (UI), SF-021 · **Decisions:** —

## Scope
- **R1 onboarding** (UX-060): profile (TG-001), goal in any expression (TG-010/011), units, halal, week start, city. Under 2 minutes, skippable fields where sensible, an offline-first first run.
- **Profile & goal screens** in Me: edit any field. **Phase history** list (TG-012), start a new phase.
- **Targets screen:** today's and the weekly numbers, the **plain-language explanation** (TG-021), mode (weekly budget / fixed), rebalancing on/off, shifting setup (weekdays now, workout plan in S41), macro settings (TG-054).
- **Manual override** with a clear warning screen and explicit acknowledgement when below safety limits (SF-012). Warnings for aggressive rates (TG-013).
- **Today wired:** the big **remaining kcal** + progress bar (HM-001, neutral "X over"), the **"This week: X under/over"** line (HM-002, TG-045), macro progress P/C/F + fiber (HM-003).

## Out of scope
- Adaptive targets and the check-in (S43). Ramadan targets (S46). R2 guided onboarding (UX-061).

## Fixed by the plan
- Numbers come only from the S19 engine. Over-target is neutral, never alarm red (SF-021).

## Decide in the low-level plan
- The onboarding step order and which fields are required for a first target.

## Exit criteria
- [ ] Onboarding completed in < 2 minutes on the A55 (timed by the owner).
- [ ] Today's remaining kcal, weekly line and macros match the engine for scripted scenarios (widget + integration tests).
- [ ] An override below the floor requires the acknowledgement. The warning copy contains no moral words (SF-020 check).
- [ ] Goldens for onboarding, targets and Today with real numbers (light/dark, scale 2.0).

## Read first
`spec/13-targets-and-goals.md` · `spec/16-insights-and-home.md` §1 · `spec/30-ux-principles.md` §7

## Owner involvement
Go through onboarding with your real data. Check the explanation reads well.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
