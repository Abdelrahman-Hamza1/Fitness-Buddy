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
The plan is the read-only audit of 2026-10-30 (lead overrides included); its decisions are copied here in short.

**Before (main fe4f671):** apps/mobile/test 287 files / 63,648 lines; patrol_test 26 files / 5,036 lines (21 journey files); fb_domain 95 / 22,301; fb_text 11 / 1,307; fb_api_client 5 / 437; fb_design_system 70 / 6,426 (40 golden files); tools 34 / 6,552; backend tests 82 files / 11,501 lines; golden PNGs 138 (62 golden test files); 26 of the last ~80 CI runs failed.

**Work packages (one commit each):**
- WP0 docs: TD-104 amended (supersedes S06 D17 / A02 D7-D9, S08 D14, DoD item 3, `09` goldens lines), `10` §4/§7/§9, backlog #116/#199 closed.
- WP2 Patrol + CI: `android-it` on schedule and manual only; `app:perf` shard and host-timing gates dropped; property runs 100 on push and PR, 1,000 nightly (`PROPERTY_RUNS`); migration matrix 45 → 9; docs-only fast path; 15 Patrol files deleted, Buddy J1 kept.
- WP1 goldens: 138 → 15 PNGs (the kept PNG files stay byte-identical, nothing is regenerated), `alchemist` removed from `fb_design_system`.
- WP4 packages + tools: equality/boilerplate trims, perf test and test-of-test-fakes removed, DS non-golden trims (the three single tests kept for SF-041, LC-040 and UX-020/021/026).
- WP5 .NET: `BuddyLiveTests` + budget helper deleted, per-entity sync copies deduplicated, p95 assert dropped.
- WP3 app tests: DELETE/TRIM lists of the audit; unused helpers swept at the end.
- WP6 close: numbers, lost spec IDs, `make progress`.

**Rules held:** no local test runs (CI is the evidence); keep calculations, migrations, session/security, sync and backend API tests; `fb_domain` and `fb_text` coverage stays at or above 95%.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).
- 2026-10-30: WP0 docs done (TD-104 amended, engineering docs aligned).
- 2026-10-30: WP2 (CI, Patrol, perf, migration matrix), WP1 (goldens), WP4 (packages, tools), WP5 (.NET) and WP3 (app tests) committed and pushed; waiting for CI.

## Outcome
**Built.** All work packages of the plan; CI on the branch is the evidence (no local test runs, owner rule).

**Measurements** (Dart test code without generated files; `wc -l`):

| Area | Before (files / lines) | After (files / lines) |
|---|---|---|
| apps/mobile/test | 287 / 63,648 | 247 / 48,284 |
| apps/mobile/patrol_test | 26 / 5,036 (21 journey files) | 9 / 1,417 (5 journeys + the Keystore probe) |
| packages/fb_domain/test | 95 / 22,301 | 93 / 21,851 |
| packages/fb_text/test | 11 / 1,307 | 11 / 1,246 |
| packages/fb_api_client/test | 5 / 437 | 3 / 268 |
| packages/fb_design_system/test | 70 / 6,426 (40 golden files) | 26 / 2,460 (no goldens, no alchemist) |
| tools/*/test | 34 / 6,552 | 34 / 6,224 |
| **All Dart tests** | **528 / 105,707** | **423 / 81,750 (-23%)** |
| backend tests (.NET) | 82 / 11,501 | 80 / 10,925 |
| Golden PNGs / golden test files | 138 / 62 | 15 / 14 |
| Host timing gates, perf shard | 11 + `app:perf` | 0 |
| Migration matrix (`migration_test.dart`) | 45 migrations | 9 |
| Property runs on push and PR | 1,000 | 100 (1,000 nightly and manual) |

CI wall time before and after is read from the CI runs of this branch and of the first merge after it (not recorded here).

**Spec IDs that lost their last automated test** (the rule is checked by hand or is a design detail): AQ-12 (the never-run live Buddy .NET test; evidence stays in `evidence/B08-verification.md`), UX-024 and UX-025 (change highlight, confirm haptic and count-up animation: manual checks), UX-012 and UX-023 (chat sheet height with the numbers visible, composer focus: layout detail), LC-005 (bilingual name display in the food sheet and Today details: manual check). TG-045 moved to the HM-002 view test, UX-041 to a `covers` note on the Today full-day golden. Performance (AT-004) is a release-checklist item on the A55 (`make cold-start`).

**Deviations from the audit.** The 15 kept golden tests keep their full light/dark and x1/x2 matrices, so no PNG was regenerated (the audit would have trimmed every kept PNG to one cell and needed a local golden run). Not done, left as small follow-ups: collapsing parameterized loops in `diary_edit_commands_test`, the `determinism_test` self-test shrink, the privacy `toString` rewrites, the partial equality-test trims (`diary_entry_test`, `trend_weight_test`, `*_ops_test`), the `proposal_codec_test` merges, the app_check/tools message-wording cuts, `export_service_test` merge, the `BuddyApiTests` 8-host theory, and compiling `public_eval` once. `patrol_support.dart` keeps `hitsTarget` and `screenSummary` (the audit called them dead, but `tapExactly` uses them).

**Follow-ups.** Read the `-- coverage fb_domain` / `fb_text` lines of the `packages` shard (equality tests were cut; if below 95%, restore the equality test of the class that lost coverage). Re-measure the shard balance (split `packages` if it is the long pole). One manual `android-it` dispatch (or the first nightly) must be green with the 6 Patrol files. No new TDs (TD-104 was amended).
