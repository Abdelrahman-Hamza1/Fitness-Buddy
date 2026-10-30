# A46 — Test diet

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App (and CI) | — | M | Claude | ⬜ Not started |

_New step (owner, 2026-10-30, TD-104). Phase 1, wave 1 (TD-105). Tier: Normal. A one-time cut; the test rules for new steps are in `PROCESS.md`._

**Goal.** Make the test suite small, fast and trusted: keep the tests that guard logic and risk, delete the ones that guard pixels and copy, and take the emulator off the merge path for good.

**Spec:** — (process) · **Decisions:** TD-104, TD-086, TD-060

## Scope
- **Goldens:** 138 → about 15 key screens (Today, food search, proposal card, weight graph, Progress, settings…); delete the rest and their images.
- **Patrol:** 21 files → about 5 journeys: offline launch, log food, weigh-in, sign-in, and a workout once A37a exists.
- Delete the 8 skipped tests.
- Cut tests that assert copy or layout, and duplicates across levels (a widget test repeating a unit test).
- **Keep:** calculations, migrations and data safety, security/sign-in, backend API tests.
- **CI:** remove the `[it]` trigger from `android-it` in `.github/workflows/ci.yml`; it runs nightly and on manual runs only. Update `run-step` and any doc that still mentions `[it]`.
- **Measure** before and after: test count and lines per area, and CI wall time.

## Out of scope
- New tests. Fixing product bugs the cut reveals (backlog).

## Exit criteria
- [ ] Goldens ≤ about 15, Patrol ≤ about 5 journeys, no skipped tests.
- [ ] CI is green; the next nightly emulator run is green.
- [ ] `android-it` has no push trigger; the `ci` gate still accepts its skip.
- [ ] Outcome lists before/after test counts, lines and CI time.

## Read first
`PROCESS.md` owner rules (2026-10-30) · TD-104 · `technical-planning/10-engineering-practices.md` §7 · `.github/workflows/ci.yml`

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._
