# A12 — Targets engine

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A06 | M | Codex (TD-078) | ✅ Done |

_Old ID: S19 (renumbered by TD-063, 2026-10-16)._

**Goal.** All target math as pure, property-tested domain code: initial targets, goals and phases, the weekly budget with rebalancing and safety limits, macros and fiber, calorie shifting. The UI (A13) and adaptive targets (A38) build on it.

**Spec:** TG-001, TG-002, TG-010, TG-011, TG-012, TG-013, TG-020, TG-040, TG-041, TG-042, TG-043 (engine), TG-044, TG-050–055, TG-060 (data hook), SF-010, SF-011, SF-012 (rule), WO-060, D-056, D-058 · **Decisions:** TD-009

## Scope
- **Profile & goal model:** sex, birth year, height, current weight, activity level (4 levels), goal type (lose/maintain/gain). Goal expression in any form: target + date, target + rate, rate only, **monthly target**. Conversion to a weekly rate and back for display (TG-011).
- **Phases** (TG-012): start/end dates, a name, history kept.
- **Initial target:** Mifflin-St Jeor × activity factor, ± the energy for the goal rate (≈ 7,700 kcal/kg), with a plain-language **explanation object** (TG-021 renders it).
- **Safety:** the calorie floor = max(estimated resting energy, 1,200 / 1,500 kcal by sex) (SF-010). Max loss rate 1% of body weight per week, capped with a warning (SF-011, TG-013). Manual override allowed with an acknowledgement flag (SF-012).
- **Weekly budget** (TG-040) and **rebalancing** (TG-041): day target = (budget − eaten earlier this week) ÷ days left, limited to ±25% of base and never below the floor. The carry-over shown as "this week: X over/under" (TG-042). **Fixed mode** (TG-044).
- **Calorie shifting** (TG-043): weighted days from the weekly plan or chosen weekdays, sharing the **same** weekly budget. An unplanned workout redistributes the rest of the week (the workout plan input is wired in A36).
- **Macros & fiber** (TG-050–055): protein g/kg of goal (or current) weight, fat % with a g/kg floor, carbs = rest, fiber 14 g/1,000 kcal, user overrides in g or %, "calories + protein only" mode. Daily targets for P/F/fiber. Only calories/carbs flex weekly.
- **Versioned `target_settings`** (effective-from dates). **Past targets are recomputed**, not stored (G10).
- **Ramadan variant** stored as data (behaviour in A41).
- **Defaults table** (`spec/13` §8) in one config object.

## Out of scope
- Screens (A13). Adaptive expenditure (A38). Ramadan behaviour (A41).

## Fixed by the plan
- Exercise calories never added (TG-036, WO-060). Floors respected by every generator (SF-010).

## Decide in the low-level plan
- How a "day" with no logging is treated in rebalancing (unknown, not zero, per TG-032 spirit).
- The rounding of displayed targets.

## Exit criteria
- [x] **Property tests:** generated day targets never below the floor. The weekly sum is preserved by rebalancing and shifting (within the limits). The ±25% bound holds. Shifting never changes the weekly total.
- [x] Unit tests reproduce worked examples for each goal expression (incl. "−2 kg this month").
- [x] `fb_domain` coverage stays ≥ 95%.

## Read first
`spec/13-targets-and-goals.md` · `spec/21-safety-and-wellbeing.md` §2

## Owner involvement
Confirm the defaults table still matches your intent (`spec/13` §8).

---

## Low-level plan
**Tier:** Normal (pure, local deterministic calculation; no persistence, user-data writes, telemetry, network or secrets). **Expected size:** M, four WPs. Independent plan/code review; Claude app-architecture review before merge (TD-078).

### Design
- **D1 — Pure boundary.** Add `fb_domain/src/targets/` models and calculators, exported from the existing barrel; no Flutter/dependencies/I/O. A13 owns persistence adapters, commands through ChangeSetApplier, providers and all copy. Here `TargetSettings` is an immutable effective-dated domain version, with historical selection/recomputation; no derived daily values stored. Preserve the existing A01/A06 write path.
- **D2 — Profile / goals.** Canonical kg/cm inputs reuse existing unit conversions. Formula sex male/female (R1), age = evaluation year minus birth year (birth year is all TG-001 stores). Four named activity levels map to centralized factors 1.2/1.375/1.55/1.725. Goal expressions carry signed kg change: target+date, target+positive weekly speed, signed weekly rate, signed monthly kg over the actual named calendar month (including leap February). Reject contradictory direction/zero-duration inputs. Return requested/effective signed rate, target/date references and warnings; cap generated loss at 1% current kg/week. Phases have inclusive start/end and preserved names; reads resolve conflicting dates/overlaps; strict checks apply to local writes (PA6).
- **D3 — Target safety / explanations.** Mifflin 10*kg + 6.25*cm - 5*age + (5 male/-161 female). Floor max(resting, sex minimum). Energy = expenditure + signed weekly kg *7700/7. Generated calories clamp to floor; explicit manual below-floor overrides require an acknowledgement. Explanations are typed numeric fields and warning codes, never user-facing strings. Keep full precision; existing DisplayRounding handles display. Acknowledgement never permits a generator/rebalancer below the floor.
- **D4 — Weekly allocation.** Saturday by default via WeekCalendar. Accept a complete 7-day dated input, each past day's intake known-complete or unknown/incomplete. Reserve its planned allocation for unknown days (never zero), expose unknown dates; known days consume actual kcal. Allocate remaining budget by positive weekday weights with iterative capped proportional allocation, within max(floor, .75*base) and 1.25*base. Infeasible remainder becomes signed carry (positive = over, negative = under), preserving consumed/reserved + future targets = weekly budget + carry. Unplanned workouts change only remaining weights, never calories added. Fixed mode ignores intake/shifting and returns base daily calories; rebalancing-off weekly mode keeps planned targets. Floors may prevent preservation: explicit residual instead of unsafe targets. No rounding before sum/allocation.
- **D5 — Macros.** Resolve daily protein, fat and fiber against base calories and goal/current kg once; only carbohydrate remainder changes with each day's calories. Default 1.8g/kg protein, max(30% kcal/9,.6g/kg) fat,14g/1000kcal fiber. User overrides in grams or energy percent (fiber grams only: fiber has no meaningful energy percent); protein-only mode omits fat/carbs targets. Detect infeasible macro energy and expose a warning/residual, never negative carbs or silently rescale explicit overrides. Optional carb override is a fixed base gram target that adjusts by daily calorie delta/4; over-budget/under-budget mismatch is surfaced. Fat minimum remains enforced. Ramadan is a separate optional settings variant selected explicitly; A41 controls dates/behaviour.
- **D6 — Defaults/history.** One immutable defaults config holds spec13§8 numeric values (including future adaptive thresholds), activity factors and safety constants. Effective-date selection tolerates same-date/revision rows with deterministic ties (PA6), and returns null before history starts; historical requests use their own date/profile inputs. No clock reads. Existing spec defaults unchanged; owner skim collected, not merge-blocking (PROCESS A6).

### Plan review amendments (fresh GPT-6.1 Sol, 2026-10-21)
- **PA1 (major):** Manual below-floor output is explicitly marked manual and acknowledged; it is never fed to the weekly generator. WeeklyBudget rejects base < floor, even in its fixed projection mode, so bounds never invert. A13 displays an acknowledged manual fixed target directly; it cannot silently rebalance that override. Test floor >1.25*manual base.
- **PA2 (major):** Expose requested, rate-capped and calorie-implied achievable rates separately. Floor-clamped generated calories determine achievable rate and projected completion; no-progress goals have no completion date. Manual calories also expose their implied rate and warnings. Projection rounds required days upward using LocalDate arithmetic.
- **PA3:** Weighted allocation uses bounded monotonic multiplier search (80 bisections over normalized weights), clamping each day to floor/bounds. This avoids incorrectly freezing both lower/upper extremes at once; residual identity tolerance1e-7 for ordinary inputs. Tests cover simultaneous bound saturation, extreme ratios and infeasible carry.
- **PA4:** Fixed P/F can exceed a low shifted day's calories: retain them, set carbs zero and expose energy deficit. Target weight equal to current is valid only for maintenance, rate zero and no completion projection. Tests cover both.
- **PA5:** Historical settings selection is per requested date, including a midweek revision. One WeeklyBudget projection has a single selected base/settings version; the caller recomputes each historical day's projection with the version effective on that day, reserving unknown earlier days at that projection's planned allocation. No retroactive writes.

- **PA6 (Claude app-review major, 2026-10-21):** Treat histories as tolerant read projections over current per-ID LWW rows (exclude tombstones). Settings carry stable UUIDv7 IDs and sort by effective date, domain revision, ID; latest wins. Goal phases also carry stable UUIDv7 IDs/revisions; same-start winners use revision then ID, and later starts truncate earlier projected ends without mutating stored rows or reviving a superseded phase. Keep original phase records for history. Separate `validateForWrite` checks guard proposed local timelines through A13's single writer, never synced reads. Global uniqueness of revision integers is not required. All four minors and two nits resolved: transient never-persisted floors documented, shared technical bounds/validator, monthly rate conversion, codec/write-path note, fixed projection/protein-only residual docs.

### Files
`packages/fb_domain/lib/src/targets/{target_profile,goals,target_calculator,weekly_budget,macros,target_settings}.dart`, barrel, focused `test/targets/`, domain README and this card/board. No API/migration/generation changes.

### Tests
- TG-001/002/010–013/020, SF-010/011/012: both formulas, canonical units, all four expressions incl −2kg February/leap month, direction/invalid finite inputs, capped loss, floor and manual acknowledgement, typed explanations/phases.
- TG-040–044, WO-060: worked equal/weighted allocation, all weekdays, unknown/incomplete vs explicit zero, rest-of-week workout change, impossible budget carry, fixed/rebalance-off. Glados >=1000 runs/property: finite floor/bounds, feasible weekly preservation and shifting invariance, residual identity, no exercise calories.
- TG-050–055: default/overrides/protein-only, fixed P/F/fiber across changing daily calories, impossible macros.
- TG-060/G10: settings history/duplicates/earlier revisions/Ramadan variant, immutable collections. Coverage >=95%, determinism/dependency/structure checks unchanged.

### Work packages
1. **WP1:** profile, goal expressions/phases, safety/initial target and tests.
2. **WP2:** weekly allocation, unknown-day/carry rules and properties.
3. **WP3:** macros, effective-dated settings/Ramadan hooks and history tests; README seam examples.
4. **WP4:** full `make check test`, independent whole-diff review + exit evidence; push **ready for app review**, then fix Claude blockers/majors and merge only after its required review. If Claude unavailable, leave clean/pushed on main with review handoff instead of bypassing it.

### Risks
Unknown intake cannot be recovered from absent logs; reserve planned calories and report uncertainty. Floor/bounds/explicit macro overrides can make budgets infeasible: expose residuals. Arithmetic guards reject nonfinite/nonpositive inputs without echoing private values. No medical advice or new default policy: implement given spec. A13 must persist versions through the sole writer; no storage belongs in this pure package.

## Progress log
- 2026-10-21 — Orient: clean latest main e088ac4, both main CI runs green. Read TD-078 and app rules. Selected A12 under board §7 rule 4 to unblock A13; B08 remains the next backend step. No paid calls. Plan independently reviewed; two majors and four clarifications resolved in PA1–PA5. Self-approved within PROCESS A6; implementation starting.

- 2026-10-21 — WP1 complete: canonical profile, four goal expressions, phases, Mifflin/explanation and safety/manual rules; 8 focused tests pass. Full `make check test` green (330 backend tests; domain coverage 99.2%). Independent plan reviewer approved PA1–PA5, no outstanding majors. No paid calls.

- 2026-10-21 — WP2 complete: bounded weighted weekly allocation, known/unknown intake reservations, fixed/rebalance-off modes and signed carry. Eight focused tests pass, including three Glados properties ×1000 cases. Full `make check test` green (10 Dart packages; domain 99.3%; 330 backend tests). WP3 will expose rest-of-week weight updates through the settings seam without changing unknown past-day reservations.

- 2026-10-21 — WP3 complete: base-resolved macro targets/overrides, explicit macro energy mismatches, immutable effective-dated settings/history and Ramadan data hook. Added remainingWeights input for unplanned workouts, preserving earlier unknown reservations. All 28 focused targets tests pass; full `make check test` green: 234 domain tests, 100% domain line coverage (1573/1573), 10 Dart packages, 330 backend tests. Root analysis/app_check/frozen migrations/contracts/hardening green; no app screens/copy/writes/API changes.
- 2026-10-21 — WP4 independent review: fresh GPT-6.1 Sol whole-step review, no blockers/majors; one minor (manual output incorrectly inherited generated-floor warning) fixed with TG-021 regression. Tier Normal: no persistence/write/network/telemetry/security exposure; separate Risky security review not triggered. Plan reviewer separately approved PA1–PA5. No milestone verifier (A12 is not a milestone).
- 2026-10-21 — **ready for app review** on `step/A12-targets-engine` (TD-078). Implementation and local verification complete; pushed branch is for Claude's short app-architecture review. Read via `git diff origin/main...origin/step/A12-targets-engine` / `git show`, without checkout/worktree. Focus: pure fb_domain seam, A13 integration boundary, manual fixed exception, unknown-day reservation, per-date historical revision semantics. Claude should append its findings to this Progress log; Codex fixes blockers/majors before the required merge script. No merge or step closure claimed before that review and green CI. Owner default skim collected as backlog #81, nonblocking per PROCESS A6.

- 2026-10-21 — **Claude app review (TD-078, Sonnet, read-only on 6952538; CI green): 0 blockers, 1 major, 4 minors, 2 nits.** Seam is clean: pure/deterministic/immutable, no strings or AI numbers, spec rules (Mifflin, 7,700 kcal/kg, floor, 1%/week cap, ack'd manual override, ±25% rebalance, shared shifting budget, base-resolved P/F/fiber with only carbs flexing) match; property tests meaningful.
  - **Major (fix before merge):** `TargetSettingsHistory` (`target_settings.dart` ~163–178) and `GoalHistory` (`goals.dart` ~187–203) throw on duplicate dates/revisions and overlapping phases. Synced data will produce these (two devices, or two edits on the same day, each creating a row; caller-supplied `version` ints collide), so building the history from `user.db` would crash A13's Targets/Today providers. Fix: give `TargetSettings` a stable `id` (UUIDv7, like `GoalPhase.id`); construct histories tolerantly with a deterministic order (`effectiveFrom`, then a tiebreak the row carries, e.g. `version` then `id`; the later one wins for a date) and a deterministic overlap rule for phases (e.g. a later-starting phase ends the earlier one at its start − 1 day). Keep strict validation as a separate write-time check A13 can call. Add tests for same-date, same-version and overlapping-phase inputs.
  - Minor: `TargetPlan.floorKcal` is derived (weight/age), so a stored value goes stale. Take it as a `day()` argument from `TargetCalculator`, or state in the README that it's recomputed, never persisted.
  - Minor: duplicated weight bounds `.001..1000` (`target_profile.dart`, `weekly_budget.dart`) and bare `1e6`/`80` literals: one shared validator/defaults.
  - Minor: TG-011 "back for display" (monthly kg) isn't exposed; add a small helper or note that A13 derives it.
  - Minor: add one README line on persistence: enums by `name`, `GoalExpression` by a kind tag + fields, `MacroOverride` shape.
  - Nits: `WeeklyBudget.calculate(fixed:)` looks unused (`TargetPlan.day` skips the budget in fixed mode); document protein-only `energyDeficitKcal`/null `energyDifferenceKcal` in `macros.dart`.
  - After the major is fixed with tests and CI is green, merge without another Claude round; minors at Codex's judgement (fix if cheap, else `backlog.md`).

- 2026-10-21 — Resumed from clean latest main; fetched Claude's card-only review commit 9f76904 and continued the A12 branch. Implemented PA6 and all cheap minors/nits. Focused 31 tests pass, including 24 order permutations each for settings and phases, read-vs-write validation, no resurrection and monthly display round trips. Fresh independent GPT-6.1 Sol scoped recheck: 0 blockers/majors; confirms app-review major resolved. Full checks passed; no another Claude round required per its explicit handoff. No provider calls, storage writes or sync engine changes.

- 2026-10-21 — Review resolution verified: full `make check test` green (237 domain tests, 100% line coverage 1606/1606, all 10 Dart packages, 330 backend tests); 31 focused targets tests pass. Fresh independent recheck confirms Claude's major resolved with 0 blockers/majors. All four app-review minors and two nits addressed. Close-out prepared; merge only through `merge-step.sh A12 "Targets engine" step/A12-targets-engine`, whose squash-commit `ci` gate must pass before main moves.

## Outcome

**Built:** pure profile/goal/phase and initial-target math; requested/capped/achievable rate explanations, safety floors/caps and acknowledged manual fixed exception; bounded weekly rebalancing/shifting, uncertainty reservations and explicit carry; fixed daily P/F/fiber with flexible carbs, overrides and energy-conflict reporting; effective-dated settings/history and Ramadan data hook. Public seam and A13 integration: `packages/fb_domain/README.md`.

**Conflict handling:** history reads accept concurrent effective dates, revisions and overlapping phases. Stable UUIDv7 IDs break ties deterministically after date/revision; later phase starts truncate earlier projected ends without rewriting stored rows or reviving superseded phases. Raw records remain available. Local-write validation is separate and never used to reject synced reads. Future A13 adapters supply current per-ID LWW rows, excluding tombstones.

**Validation:** full `make check test` green; **237 domain tests and 100% line coverage (1606/1606)**, including 31 focused targets tests, all 24 input-order permutations for each conflict history and three 1,000-case Glados properties. All 10 Dart packages and 330 backend tests pass. Determinism/dependency/barrel/app_check/frozen migration/contract/hardening checks pass. Local final evidence: `~/.local/state/a12-review-fixes.log`, `a12-revision-targets.log`; merge CI evidence is the required `ci` check on the script's squash commit ([A12 merge runs](https://github.com/Abdelrahman-Hamza1/Fitness-Buddy/actions?query=branch%3Amerge%2FA12)).

**Reviews:** independent plan review's two majors resolved/rechecked in PA1–PA5. Initial independent code review's minor warning bug fixed with regression. Claude's app review found one major, four minors, two nits: all addressed in PA6. A fresh independent GPT-6.1 Sol recheck found no blockers/majors and confirmed the conflict fix. Claude explicitly waived another Claude round after fixes/tests/green CI. No separate security review triggered: this Normal pure-calculation step introduces no persistence, sync engine, auth, network or logging changes.

**Deviations/clarifications:** A12 supplies domain settings/history; A13 owns codecs, tables, contract sync payloads, commands through ChangeSetApplier and UI. Floors are transient, recomputed from the applicable profile/weight/date and never persisted. Shared technical limits and monthly-display conversion are centralized. Unplanned-workout weights affect only remaining allocation. Fiber overrides use grams; P/F/C allow grams or base-energy percentages. No new dependencies, UI/copy, writes, generated code, provider calls, TD or spec change; spec defaults unchanged.

**Follow-ups:** A13 integration and owner defaults skim (backlog #81); A36 workout-plan inputs, A38 adaptation, A41 Ramadan activation. B08 remains next backend step.

**Size:** M, four implementation/verification WPs plus the app-review correction checkpoint. Closure and board prepared for the CI-gated squash merge; no additional owner gate.
