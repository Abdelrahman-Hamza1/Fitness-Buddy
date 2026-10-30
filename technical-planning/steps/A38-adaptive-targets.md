# A38 — Adaptive targets & weekly check-in

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A16, A23a (proposal storage) | M | Claude | ✅ Closed, awaiting review/merge |

_2026-10-30 (TD-105): depends on A23a (durable proposals, done) instead of all of A23; the check-in proposal needs proposal storage, not the Buddy message queue (A23b, phase 2)._

_Old ID: S43 (renumbered by TD-063, 2026-10-16)._

**Goal.** Targets that learn from reality: estimate actual expenditure from logged intake and the trend weight, say how confident that is, and propose a change each week, never silently.

**Spec:** TG-030, TG-031, TG-032, TG-033, TG-034, TG-035, TG-036, TG-037, IN-005, AI-056, DY-004 (suggestion), SF-010 · **Decisions:** TD-009

## Scope
- **`AdaptiveExpenditure`** in `fb_domain`: expenditure = intake − energy of the trend change over the window. Readiness rules (TG-031: ≥ 14 days logged, ≥ 10 complete, ≥ 3 weigh-ins over ≥ 10 days). Incomplete days excluded, missing days unknown (not zero, TG-032). **Confidence** low/medium/high from data quantity and consistency (TG-033). Ramadan weeks with lower weight confidence (TG-037, wired fully in A41).
- **Progress messaging:** "2 more weigh-ins until your targets can adapt" (TG-031).
- **Weekly check-in** (TG-034): at week start, if the recommended target differs by > 50 kcal/day → a **target-change proposal** (AI-056), capped at ±150 kcal/day (TG-035), floors respected (SF-010). A setting for ask (default) vs apply automatically.
- **Expenditure chart** (IN-005) with confidence.
- **Incomplete-day suggestion** (DY-004): days < 50% of target with < 2 meals → a proposal to mark the day incomplete (never automatic).
- The check-in proposal is attached to the weekly review in A39. Until then, it's shown on Progress.

## Out of scope
- The review narrative (A39).

## Fixed by the plan
- Exercise calories are never added (TG-036). Changes are proposals unless the user chose automatic.

## Decide in the low-level plan
- The estimation method details (window length, weighting, outlier handling) with test scenarios.

## Exit criteria
- [x] Domain tests with synthetic histories: correct expenditure within tolerance, readiness thresholds, confidence levels, caps and floors.
- [x] Property: a check-in never proposes beyond ±150 kcal/day or below the floor.
- [x] The incomplete-day suggestion triggers only on the rule (test).

## Read first
`spec/13-targets-and-goals.md` §4

## Owner involvement
None (your real data validates it over the following weeks).

---

## Low-level plan
_Claude, 2026-10-30. Tier **Risky** (writes user targets from a system-made proposal). One engineer, one combined Codex review (code + security/data)._

### D1 Estimator (`fb_domain/src/targets/adaptive_expenditure.dart`)
- **Window:** the 28 days ending on `end` (the check-in uses the day before the week starts, so the estimate is stable all week; Progress shows the one ending yesterday).
- **Readiness (TG-031)** inside the window: logged days (≥ 1 live entry) ≥ 14, complete days ≥ 10, weigh-in days (`DayChoice`, readable rows) ≥ 3 spanning ≥ 10 days. Thresholds from `TargetDefaults.adaptive*` (A12). `AdaptiveReadiness` exposes what is still missing (messaging).
- **Complete day** (amended in review round 1): logged and not marked incomplete, exactly TG-031. Days that only look incomplete (DY-004) are suggested to the user, never left out by the estimate. Missing days are unknown, never zero (TG-032). Intake anomalies (amended in review round 2): logged intake is never clipped. A day above both median + 3 robust spreads (spread ≥ 15 % of the median) and 2.5 × the median, not confirmed by the user, is flagged: it still counts at its real value, keeps confidence at most medium, and holds an automatic change (the card names the days; "They're right" confirms them, or the user fixes the entry). The intake error never drops below a quarter of the sampling variance at full logging.
- **Intake** = mean of complete days. Its uncertainty = SD/√n × √(1 − n/28) (finite-population: nothing to infer when every day is logged).
- **Weight change** = slope of a weighted least-squares line through the weigh-in days (kg/day), not the EWMA trend's endpoints: the A14 trend lags a steady change (a weekly weigh-in moves it halfway), which would under-read a 0.5 kg/week loss for weeks. Weights 1, or 0.5 for a Ramadan day (TG-037 hook: `isRamadan` predicate, default none; A41a wires it). **Outliers:** with ≥ 4 weigh-ins, the single largest residual beyond max(1.5 kg, 1.5 % of mean weight) is dropped once and the line refitted, if readiness still holds.
- **Data estimate** = intake − slope × 7,700 kcal/kg. **σ_data** = √((7,700 · SE_slope)² + SE_intake²), SE_slope = max(residual SD, 0.5 kg) / √Σw(x − x̄)².
- **Confidence (TG-033)** from σ_data: high ≤ 100, medium ≤ 200, else low. Typical: daily weigh-ins + full logging → high; weekly weigh-ins → medium; 3 weigh-ins over 10 days → low.
- **Weighting:** the shown estimate blends the data with the formula expenditure (Mifflin × activity at the trend weight, TG-020) by inverse variance, prior σ 250 kcal. Low-confidence data moves it ~15 %, high-confidence ~90 %. Band = ± posterior σ.
- Pure, deterministic; tests with synthetic histories (S1–S10 below).

### D2 Check-in rule (`adaptive_check_in.dart`)
- Recommended = `TargetCalculator.calculate(..., expenditureKcal: estimate)` (new optional override of resting × activity): the goal rate in effect (maintain in a gap; SF-011 cap) and the SF-010 floor; exercise is never added (TG-036).
- Current = today's version base raised to the floor (`toPlan`). Skip when: not ready, no profile/version, goal can't be resolved, an acknowledged below-floor manual target, or |recommended − current| ≤ 50 (TG-034).
- Proposed = max(current + clamp(diff, ±150) rounded toward zero to 10 kcal, floor) (TG-035, SF-010). Property: |proposed − current| ≤ 150 and proposed ≥ floor.
- A manual target still gets a proposal (ask) but is never changed automatically.

### D3 Storage: no schema change, no new sync entity
- The check-in is a `proposals` row, kind `targetChange` (open vocabulary, already synced; the server admits any kind), no message refs, draft JSON `{weekStart, versionId, versionRevision, fromKcal, toKcal, recommendedKcal, expenditureKcal, confidence, fromManual, fromAcknowledged}`. One per week: a row for the week's start (any status) means done. Older pending ones are discarded in the same change set.
- Accept/adjust = one change set `PutTargetSettings` (D5 revision rule, `manual: false`) + `ResolveProposal(confirmed, unchanged|adjusted)`, `Origin.proposal`, with Undo. Keep = resolve discarded, with Undo. Stale (targets changed since) → only Keep.
- **Automatic** (setting `targets.checkInMode` = ask (default) | auto, synced settings key): the row is created, then applied by a second change set through the applier; Progress shows "Targets updated … Change back" (a direct revision back, with Undo) while the base is still the applied one.
- **DY-004:** suggestion rows kind `dayIncomplete` are written only when answered: Mark incomplete = Create + Resolve(confirmed) + `MarkDay` in one change set; "It was complete" = Create + Resolve(discarded). Both with Undo. Never automatic.
- Buddy's restore reads only `foodLog` pending rows (else these rows would show as broken chat cards).
- `DailyTotals`/`DayLog` gain a meal count (`COUNT(DISTINCT slot_id)`, same index).

### D4 App (`features/adaptive/`, new feature; Progress imports its barrel)
- Providers: the window's intake days, weigh-ins, the check-in proposals, the current estimate + readiness, the weekly history (last 12 week starts), the check-in card view, the incomplete-day suggestion (last 14 days, candidates first, then the day's target via `dayTargetsProvider`).
- `WeeklyCheckIn.run()` after the first frame (bootstrap, local only) and when Progress opens; serialized, idempotent per week.
- Progress order: week header → check-in card (pending / auto-applied) → incomplete-day card → … → exercises → **Expenditure** card: readiness message ("2 more weigh-ins until your targets can adapt") or the chart (`FbTimeSeriesChart` line + band) with confidence and the ask/auto switch.
- Me › Targets: a non-manual base that differs from the formula reads "Adjusted to your results"; "Recalculate with your current weight" isn't offered for it (it would throw the learning away).

### Tests
fb_domain: S1 steady loss, daily weigh-ins → expenditure within 50 kcal, high · S2 weekly weigh-ins → medium · S3 3 weigh-ins/10 days → low · S4 readiness boundaries (13/14 logged, 9/10 complete, 2/3 weigh-ins, 9/10 span) · S5 missing days don't count as zero · S6 incomplete and likely-incomplete days excluded, confirmed ones kept · S7 outlier dropped · S8 Ramadan down-weighting widens σ · S9 blend moves toward data with confidence · check-in: threshold, cap, floor, manual, skip reasons · **property** (seeded random): never beyond ±150 or below the floor · DY-004 rule only on the rule · draft JSON round trip.
App: check-in run creates one row per week (idempotent), auto applies through the applier and Change back restores; accept/keep/stale; incomplete-day accept/dismiss; restore ignores non-foodLog rows; Progress shows readiness/chart/card.

### Work packages
WP1 domain + tests · WP2 data (meal count, proposal reads, restore filter, setting) · WP3 check-in service + actions + tests · WP4 Progress/Targets UI + ARB + widget tests · WP5 cross-check, docs, outcome.

## Outcome
_Claude, 2026-10-31 (the orchestrator adds the Codex review, CI and merge)._

**Built.** WP1 `fb_domain`: `AdaptiveExpenditure` (28-day window, WLS weight line, outlier drop, finite-population intake error, inverse-variance blend with the formula, confidence from σ), `IncompleteDayRule`, `AdaptiveCheckIn` (threshold 50, cap ±150 rounded toward the base to 10 kcal, SF-010 floor, skips), `TargetChangeDraft`/`DayIncompleteDraft`, `TargetCalculator.calculate(expenditureKcal:)`. WP2: `DailyTotals.mealCount` (`COUNT(DISTINCT slot_id)`), `ProposalRepository.watchKind/byKind` (+ `kind` on `pending`/`resolved`), Buddy restore ignores non-`foodLog` rows without message refs, setting `targets.checkInMode` (ask | automatic), `weighInsReader`. WP3–4: new feature `features/adaptive/` (actions, providers, Progress cards), bootstrap + Progress run the check-in (local, idempotent per week, re-run on a day change), Me › Targets "Adjusted to your results" (and no "Recalculate" for an adjusted base), 37 ARB strings, Progress golden regenerated (the new card's top edge).

**Decisions in the plan (D1–D4)** as written; changes while building:
- "Adjusted" is not inferred from the formula mismatch (a goal phase that starts after its version made the golden fixture look adjusted): the resolved check-in draft records `appliedVersionId`/`appliedRevision`, and Targets reads the confirmed rows.
- The check-in skips a week whose targets the user already changed (version effective after the window end): the user's own change wins.
- Adjust steps are 50 kcal within [max(base − 150, floor), base + 150]; the handler-side check re-validates.
- Automatic changes record no undo entry (not a direct action); Progress shows "Your target changed … Change back" (a direct revision with Undo) until OK or the end of the week.

**Data/schema.** No drift schema change, no migration, no new sync entity: the check-in and the answered suggestions are `proposals` rows (kinds `targetChange`, `dayIncomplete`, open vocabulary already synced and admitted by the server); the setting is one more synced settings key (no server allowlist).

**Tests.** fb_domain: `adaptive_expenditure_test` (19: S1–S9 synthetic histories, readiness boundaries 13/14, 9/10, 2/3, span 9/10, window, day choice, missing ≠ zero, incomplete and likely-incomplete days, outlier, Ramadan, DY-004 rule), `adaptive_check_in_test` (12 incl. two properties: `propose` and `decide` never beyond ±150 or below the floor, also at `PROPERTY_RUNS=1000`), calculator override test. App: `adaptive_actions_test` (13: propose once, accept + Undo, adjusted/out of range, keep, stale, automatic + Change back, manual never automatic, not ready / own change, new week discards the old one, DY-004 accept/dismiss/rule, expenditure view), `adaptive_cards_test` (3), restorer orphan test, meal-count assertion, bootstrap test override.

**Local checks.** Single files only via `heavy.sh` (all green); `dart analyze --fatal-infos apps packages tools` clean; `dart format` clean; `make app-check` OK; `make gen-app` no diff.

**Review round 1** (Codex, CHANGES-REQUIRED: 5 major, 3 minor; all fixed, 2026-10-31):
- (1) Automatic apply rechecks inside the applier transaction: new no-write ops `ExpectCurrentSettings` (targets: the version in effect is still the captured ID/revision, generated) and `SettingsOp.expect` (the setting is still automatic); a refusal leaves the proposal pending. Fresh reads before planning. Interleaving tests (synced manual target; setting turned off).
- (2) Acceptance derives the base from the live version and today's floor; the draft's `fromKcal` must equal it (else stale), the delta is checked against it; kind and codec must be `targetChange` v1. The same in-transaction version check. Test with a forged persisted draft.
- (3) Readiness/complete days exactly TG-031 (D1 amended above). Test: 9 normal + 5 light unmarked days are ready.
- (4) Intake anomalies capped, uncertainty kept at full logging (D1 above). Tests S10 (one 20,000 kcal day: no high confidence, no change), S11, S12; S1 tolerance now 50 kcal.
- (5) The latest unseen automatic change keeps its card past the week and restarts while its version is current. Test with a 9-day rollover and OK.
- (6) Change back and the note match `appliedVersionId`/`appliedRevision`; Change back also rechecks in the transaction. Test with a same-calorie revision.
- (7) Opening Progress (and resume) invalidates the check-in provider after the first frame, so a skipped run retries; the weekly idempotency is unchanged. Provider rerun test.
- (8) The automatic switch reports through `reportSettingsOutcome` (Undo, failure text); two ARB strings.
- Not done: an index on `proposals.kind` (a schema change; rows grow about one a week), backlog #235.

**Review round 2** (Codex fix-check: 1–4, 6, 8 fixed; one new major, two leftover minors; all fixed, 2026-10-31):
- (new major) Genuine high-intake days were capped: intake is now the real logged average; error-like days are flagged (rule above) and recorded on the check-in (`anomalyDates`). The automatic setting holds the change while an anomaly is unresolved or confidence is low (`CheckInHold`, shown on the card: "Not applied automatically: …"); "They're right" (`confirmDays`, Undo) confirms the days. Tests: S10 (one 20,000 kcal day) and S13 (weekly 4,000 kcal days: nothing flagged, the real average, no proposal at 2,300), each at full and partial logging; app: anomaly hold + confirm, low-confidence hold.
- (5) The unseen automatic change has its own provider (`appliedCheckInCard`) and card, shown above any newer proposal. Test: an applied change, then a pending one next week, both shown.
- (7) The router reports a switch to a tab (`tabActivationProvider`); Progress reruns the check-in on its own tab. Test: Today → no rerun, back to Progress → rerun.

**Open items.** Backlog #230–#235. Codex fix-check by the orchestrator.

## Progress log
- 2026-10-30/31: plan, WP1–WP4, close-out (commits 18d50b8d…7b35b9f5); orchestrator merged origin/main (912c6c06).
- 2026-10-31: review round 1 fixed in 838f4be8 (domain 3, 4) and 34076a7a (app 1, 2, 5–8). Local: fb_domain adaptive tests 34 ✓, `adaptive_actions_test` 19 ✓, cards 3 ✓, progress screen/golden, targets handler, settings store/actions/ops, bootstrap, app tabs/shell/router ✓; analyze, format, app-check, gen-app clean.
- 2026-10-31: review round 2 fixed in 0bd50fd0 (domain) and 36d06810 (app). Local: fb_domain adaptive tests 37 ✓, `adaptive_actions_test` 22 ✓, cards 4 ✓, progress screen/golden/navigation, app tabs/router/shell ✓; analyze, format, app-check, gen-app clean.

