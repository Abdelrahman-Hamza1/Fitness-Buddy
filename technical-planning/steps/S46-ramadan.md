# S46 — Ramadan mode

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P7 Insights & time | S22, S43, S45 | L | ⬜ Not started |

**Goal.** Ramadan is first-class: detected automatically (proposed, not forced), with iftar/suhoor slots, Ramadan targets, prayer-time reminders, honest weight expectations and a Ramadan comparison.

**Spec:** LC-020, LC-030, LC-031, LC-032, LC-033, LC-034, DY-012, TG-037, TG-060, TG-061, NT-008, NT-009, NT-026, WB-021 (Ramadan shading), IN-008, AI-120 (Ramadan suggestions), T30, T31, T32, J9, J11 · **Decisions:** TD-013

## Scope
- **`RamadanCalendar`** (`fb_domain`): an Umm al-Qura Hijri package (chosen here) → Ramadan start/end per year + the user's ±1-day shift + a manual on/off (LC-030). The Hijri date shown alongside during Ramadan (LC-020).
- **Proposal to switch on** a few days before (LC-031). A proposal, never silent.
- **Prayer times** (LC-033, NT-026): `adhan_dart` from the chosen city's coordinates (or opt-in location), a calculation method setting with a regional default checked against a local timetable (G12).
- **Ramadan slots** (DY-012): Iftar / Suhoor / Snacks (customizable separately), windows from prayer times. **Suhoor counts toward the calendar day eaten** (T31, DY-001). Normal slots return afterwards.
- **Ramadan targets** (TG-060/061): a separate setting, "maintain during Ramadan" offered via the first Ramadan weekly review. Normal targets resume automatically.
- **Not-fasting days** (LC-034): mark a day, and normal slots and reminders apply.
- **Reminders:** suhoor (45 min before Fajr, allowed in quiet hours) and iftar log nudge (90 min after Maghrib), plugged into the S45 planner.
- **Weight:** shaded Ramadan periods on charts (WB-021), lower confidence in adaptive targets (TG-037).
- **Ramadan comparison** (IN-008): intake, trend and workouts during Ramadan vs the month before.
- **Suggestions** favour suhoor-appropriate options and iftar staples (AI-120 context).
- Eval: T30–T32 (+ AR/Arabizi).

## Out of scope
- —

## Fixed by the plan
- Day boundaries are calendar days, so no special day logic (`09` §2).

## Decide in the low-level plan
- The Hijri package and the default prayer calculation method for Palestine (verified against a local timetable).

## Exit criteria
- [ ] **J9, J11, T30–T32** pass (E2E with a fake clock across Ramadan start/end).
- [ ] Prayer times for the owner's city match a local timetable within ±2 minutes for 10 sampled days.
- [ ] Time-zone/DST and Ramadan boundary tests (incl. the ±1-day shift).
- [ ] Planner tests for the suhoor/iftar rules (quiet-hours exception).

## Read first
`spec/18-localization-and-culture.md` §3–4 · `09-cross-cutting.md` §2 · `spec/01-personas-and-journeys.md` J9, J11

## Owner involvement
Check the prayer times for your city. Review during the next real Ramadan.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
