# A42 — Performance, accessibility & offline acceptance

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A41 | M | Claude | ⬜ Not started |

_Old ID: S48 (renumbered by TD-063, 2026-10-16)._

**Goal.** Measure and fix what users feel: startup, smoothness, speed targets, accessibility and offline behaviour, on the reference device.

**Spec:** AT-004, AT-005, UX-001–007, UX-070, UX-071, OF-01, OF-02, OF-03, SC-2 · **Decisions:** TD-034 (Android-only R1)

## Scope
- **Speed targets** (UX-001–007) measured on the **Samsung A55** (the iPhone pass is R2, D-081): cold start → input bar, repeat meal taps, weigh-in taps, barcode → logged taps, Buddy round trip, no blocking spinners.
- Profiling and fixes: startup work, jank on Today/Progress/charts, DB query plans, image handling, app size.
- **Accessibility:** text scale 1.5/2.0 on every screen, contrast (AA) re-verified, colour never the only signal, tap target sizes.
- **Offline scenarios** OF-01–03 as automated E2E tests on a device/emulator, and once manually on the A55.
- Crash-free sessions over the dogfood period from Sentry (> 99.5%).

## Out of scope
- Screen-reader labels (R2, UX-072).

## Fixed by the plan
- Budgets in `09` §6.

## Decide in the low-level plan
- The measurement method per target (integration test timeline vs manual stopwatch protocol).

## Exit criteria
- [ ] Every UX-001–007 target met and recorded with the method.
- [ ] OF-01, OF-02, OF-03 pass (AT-005).
- [ ] All screens usable at text scale 2.0. The contrast test is green.
- [ ] Crash-free sessions > 99.5%.

## Read first
`09-cross-cutting.md` §6–7 · `spec/30-ux-principles.md` §1, §8 · `spec/40-acceptance-criteria.md` §4

## Owner involvement
Confirm it feels fast on your phone.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
