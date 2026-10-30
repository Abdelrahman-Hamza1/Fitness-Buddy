# A45 — UX polish

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A15b ✅, A44 ✅ | M | Claude | ⬜ Not started |

_New step (owner phone feedback, 2026-10-30). Phase 1, wave 1 (TD-105). Tier: Normal._

**Goal.** Fix what the owner felt on the phone in the first prod build: chip rows that jump, an abrupt range switch, a weight card that takes too much room, tabs that keep stale screens, and a dark default the owner no longer wants.

**Spec:** UX-040 (light default, D-083), HM-005 (slim weight row, D-084), UX-010 (tabs) · **Decisions:** D-083, D-084, TD-107, TD-104 (lean tests)

## Scope
- **Steady chips:** fixed-width chips on the weight graph range row and every other chip/button row (the weigh-in sheet included), so a selected chip never resizes its row. Audit every chip row in the app.
- **Range switch:** a short transition when the weight graph range changes, instead of an instant jump.
- **Light by default** (D-083, TD-107): the stored theme default, the pre-read first frame and the Android window/splash become light; System/Light/Dark stay.
- **Slim weight row on Today** (D-084): with a weigh-in today, one row "weight · trend · ＋" (row opens the graph, ＋ logs a weigh-in); the full card only when there is no weigh-in today.
- **Tabs:** switching away from a tab resets it to its root screen; tapping the current tab again scrolls it to the top.

## Out of scope
- New screens or features. Workout row on Today (A37a).

## Exit criteria
- [ ] No chip row in the app changes width when a chip is selected (checked on every chip row; one widget test for the shared chip).
- [ ] A fresh install opens in light, first frame and splash included; a stored Dark still applies.
- [ ] Today shows the slim row after a weigh-in and the full card before (widget test).
- [ ] Tab reset and re-tap scroll-to-top work (widget test).
- [ ] Owner phone check on the A55 (collected, non-blocking).

## Read first
`spec/16-insights-and-home.md` §1 · `spec/30-ux-principles.md` UX-040 · A44 card (theme, splash) · A15 card (graph range row)

## Owner involvement
A short phone check after merge.

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._
