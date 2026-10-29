# A14 — Weigh-ins & trend

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A08 | L (re-estimated in the plan) | Claude | ✅ Done |

_Old ID: S21 (renumbered by TD-063, 2026-10-16)._

**Goal.** Logging a weigh-in in three taps, and a smoothed trend weight that behaves sensibly with weekly or irregular weigh-ins. This is the core of "replace the weight note" (D-024).

**Spec:** WB-001, WB-003, WB-004, WB-005, WB-010, WB-011, WB-012, HM-005, UX-005 · **Decisions:** TD-009

## Scope
- **Table** `weigh_ins` (value in kg + original input value/unit, measured_at, local_date, note).
- **3-tap pad** (WB-001): the weight card on Today → number pad prefilled with the last value → save (a direct action with undo). Date/time defaults to now, editable. Optional note.
- **Several per day** allowed. The earliest is used for the trend unless the user picks otherwise (WB-003).
- **Implausible check** (WB-005): > 3% change within 7 days, or a likely unit mix-up (e.g. 214 vs 97 → "did you mean lb?") → confirm before saving.
- **Trend algorithm** (WB-010): handles irregular gaps, and a single weigh-in moves the trend only partly. Weekly rate from the trend.
- **Weight card** on Today (HM-005, WB-011): "Trend 97.6 kg · −0.4 kg/week", the latest raw value smaller, tap → pad or graph (A15).
- **Honesty message** (WB-012) about low weigh-in frequency, at most once a month.

## Out of scope
- The graph and stats (A15). Weigh-ins by chat and paste import (A29).

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
_Written in Phase B (2026-10-28) by the step-planner in lane 3 (`~/work/fitness_buddy_3`, branch `step/A14-weigh-ins-trend` from `main` 11c4740; TD-087). A13 (lane 1) is planned and built in parallel: §9 lists the shared files and the schema-version protocol. **Revised after the architect plan review (approve with required changes, PA1–PA12, PA3 option a; list after §2). Plan approved by the orchestrator (TD-037, no owner items).**_

**Tier: Risky** (`PROCESS.md` A2: user-data write path). A new synced table and migration, a new op family and handler, undoable direct actions. Reviews: `architect` (own plan review), `code-reviewer`, `security-reviewer` (+ `evidence/A14-verification.md`), `ux-reviewer` (real screens and weight copy), `verifier`.

### 1. Summary
After A14 the owner logs a weigh-in from Today in 2 taps (3 with an implausible-value confirm): tap the weight card, the pad opens prefilled with the last value, type, Save. Undo is available. Weigh-ins are stored in a new synced table `weigh_ins` (kg + the value and unit as typed, time, local date, note, a per-day trend choice). A pure `TrendWeight` in `fb_domain` turns them into a time-aware smoothed trend and a weekly rate. The weight card on every day page shows the trend as of that date ("Trend 97.6 kg · −0.4 kg/week") and the latest raw weigh-in smaller; on today's page it adds an honest note when weigh-ins are sparse (WB-012). The trend is also the app's **current weight**: targets (A13) read it through the `features/body` barrel (PA1). Nothing is stored that can be derived. No contract, router or API change.

### 2. Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **Trend algorithm (card item): time-aware exponential smoothing over one weigh-in per day.** Sort the day choices (D3) by `local_date`. `T₁ = w₁`. For each next weigh-in, `Δd` = whole days since the previous one (≥ 1, from local dates), `α = min(1 − 2^(−Δd / 7), 0.75)`, `Tₙ = Tₙ₋₁ + α·(wₙ − Tₙ₋₁)`. **Half-life 7 days, cap 0.75.** So a daily weigh-in counts 9.4 %, a weekly one 50 %, and after a gap of 14 days or more (the card's 3-week gap included) one weigh-in counts 75 %, never all of it. Between and after weigh-ins the trend holds its last value (a step function, `trendOn(date)`). The constants live in one `TrendWeightConfig` value; the trend is derived (`05` §2.2), so tuning them after the owner's feedback needs no migration. Rows with a non-finite or non-positive `kg` (possible only via sync) are skipped | EWMA is a convex combination, so the trend can't leave the min/max of its inputs (exit criterion, by induction), and a constant series stays constant. The time-aware α handles any cadence (WB-004, D-054) with no resampling. The cap is what makes "a single weigh-in moves the trend only partly" (WB-010) hold after long gaps too. A local regression was rejected: its fitted level can leave the input range (it fails the exit criterion), and it extrapolates badly at the end of the data. Holt (level + slope) was rejected: with weekly data it overshoots, and it's harder to explain. Half-life 7 d = the familiar "10 % a day" smoothing (Hacker's Diet style), and weekly weigh-ins count half, which is easy to explain |
| D2 | **Weekly rate (WB-011), as of an evaluation date `E` (today, or the page's date, PA3).** Let `D` = the last day choice on or before `E`. **No rate when `E − D ≥ 28` days (stale, PA2; outside "the last 4 weeks", code review 2026-10-29)**: the card shows the trend + "from {date}" only. Otherwise rate (kg/week) = `(T(D) − T(D − 28)) / 4`, where `T(D − 28)` is the step value on that date. If the first weigh-in is later than `D − 28`, use the available span `s = D − first` days: `(T(D) − T₁)·7 / s`, but only when `s ≥ 14` days **and** there are ≥ 2 day choices. Otherwise there is no rate yet (the card says so). Display: 1 decimal in the body unit, with a sign (U+2212 minus), "0.0" below 0.05 | One readable formula ("4-week trend change ÷ 4"). In steady state an EWMA's slope equals the true slope, so the rate isn't biased by the trend's lag. The 14-day minimum keeps a 1-week-old rate from claiming precision, and the 28-day staleness rule keeps an old rate from looking current. The same `T(date)` serves A15 (WB-023) and A38 (TG-030) |
| D3 | **Several per day (WB-003).** The **day choice** is the live weigh-in of that `local_date` with `preferred_for_day = true` (several, after a sync: the earliest of those), otherwise the earliest by `measured_at_utc`; ties break by `id`. A new op `ChooseTrendWeighIn(day, chosen: VersionedId?, dayWeighIns: List<VersionedId>)` sets the flag on `chosen` and clears it on every other row of that day. `chosen = null` means "back to the earliest" and clears every flag. The op must list **exactly** the day's live rows at the versions shown (the A08b source-version rule): any difference → `Rejected`. An `UpdateWeighIn` that moves a preferred row to another day clears its flag | "Unless the user picks otherwise" needs stored state that syncs (one column). Exact membership means the user's choice applies only to the day they saw |
| D4 | **Implausible values (WB-005), pure `WeighInCheck`.** Results: `Plausible` · `LikelyOtherUnit(suggestedUnit, suggestedKg, reference)` · `LargeChange(reference, diffKg)`. **Unit mix-up** is checked first, against the nearest weigh-in in time (an earlier one first, else the next later one; any distance): the typed number read in the *other* unit lands within ±5 % of the reference, **and** read in the typed unit it differs by > 25 %. Example: 214 "kg" after 97 kg → "214 lb (97.1 kg)?". **Large change**: the nearest earlier weigh-in at most 7 days back by local date (else the nearest later one within 7 days, for a backfill); `|new − ref| / ref > 3 %` strictly (with a 1e-9 tolerance: 97.0 → 99.91 is 3.0 %, no confirm). An edit is checked without itself. The first weigh-in gets only the hard bounds (D6) | Exactly the spec's two examples, with thresholds the tests pin. Unit-first means a 214-after-97 slip gets a helpful "lb?" rather than a "large change" |
| D5 | **Write path: new op family `weighIn` (`fb_domain`), `WeighInOpHandler` (app).** Ops: `CreateWeighIn(id, WeighInDraft)`, `UpdateWeighIn(id, expectedVersion, WeighInDraft)` (an identical draft writes nothing), `DeleteWeighIn(VersionedId)` (tombstone), `ChooseTrendWeighIn` (D3). The handler validates the draft (D6) inside the transaction, rejects a `measured_at` more than 5 min after `ApplyContext.nowUtc` (`InvalidOp('future')`), and reads once per op (A01 follow-up). Every UI write is a direct action: the caller pushes the inverse to `UndoStack` (5 s snackbar, UX-030); delete is a single row, so undo, not a confirm. **No custom domain events**: `ChangeSetApplied(entities: {'weighIn'})` already tells later subscribers (A38, A40), and the read model is reactive through drift watches (`03` §2 rule 3) | TD-011 (only `ChangeSetApplier` writes), the same shape as A06/A09 ops, so A15 (edit from a graph point) and A29 (chat proposals) reuse them unchanged. No speculative events |
| D6 | **Validation (local writes only).** `WeighInDraft {time: EntryTime, input: WeighInInput(value, unit ∈ {kg, lb}), note?}`. `kg = StoragePrecision.round(value × unit factor)` (214 lb → 97.07 kg, shown back as 214.0 lb). Hard bounds **20–500 kg** after conversion (44.1–1,102.3 lb); pad max 4 digits + 1 decimal. Note: trimmed, empty → null, ≤ 200 characters, no `\p{Cc}` control characters; `\p{Cf}` is **allowed** (emoji ZWJ sequences, RLM/LRM in mixed Arabic/English notes; PA8). `measured_at_utc ≥ 0` (PA9: the handler rejects `< 0` with `InvalidOp('time')`). The DB CHECKs are only as strict as the wire (D7) (`kg >= 0`, `input_value >= 0`, `measured_at_utc >= 0`, unit enum, tz range), because local-write rules never reject synced reads (the A12 convention). `toString()` of every weigh-in type shows no value and no note | Plausible human range plus room for the units. One storage rounding (fb_domain README). The privacy rule: no user content in logs |
| D7 | **Table and wire compatibility.** `weigh_ins` (DataClassName `WeighInRow`, entity `weighIn`), `SyncColumns` +: `measured_at_utc` INT NOT NULL CHECK ≥ 0 (UTC ms, PA9) · `tz_offset_min` INT NOT NULL CHECK −720…840 · `local_date` TEXT NOT NULL (`YYYY-MM-DD`, from the stored offset, DY-002 style) · `kg` REAL NOT NULL CHECK ≥ 0 · `input_value` REAL NOT NULL CHECK ≥ 0 · `input_unit` TEXT NOT NULL CHECK IN ('kg','lb') · `note` TEXT NULL · `preferred_for_day` BOOL NOT NULL DEFAULT 0. Partial index `ix_weigh_ins_live (local_date, measured_at_utc) WHERE deleted_at IS NULL` in a new `core/db/body.drift`. Three outbox triggers. **The existing `weighIn` v1 wire fields map 1:1 by snake_case** (`measuredAtUtc`, `localDate`, `kg`, `note`; a test proves it the way `personal_food_migration_test` does). **No contract change in A14.** **The target wire shape is `weighIn` v2 (PA4; additive, v1 is not edited):** v1's fields + `tzOffsetMin` (integer −720…840), `inputValue` (number ≥ 0), `inputUnit` (enum `kg`\|`lb`), `preferredForDay` (boolean). **v1→v2 upgrader (for A34):** `inputValue = kg`, `inputUnit = 'kg'`, `preferredForDay = false`, `tzOffsetMin` = the offset implied by `localDate` and `measuredAtUtc` (minutes between UTC midnight of `localDate` and the UTC time, adjusted to the nearest offset whose local date is `localDate`, clamped to −720…840). It ships in a **contract catch-up commit after B18 merges, before A34's Phase B** (backlog item added at A14 close, plus a line in A34's Scope: "weighIn v2 must exist before upload; A14 backlog #…"). The tripwire test (§5.3) fails with a message naming that backlog item if the local column set and the documented four drift apart | TD-017 (Accepted) requires the original input and the tz offset, so the local row keeps them. Changing `sync-entities.json` now would collide with lane 2 (B18) for no benefit before A34 uploads anything. A v2 (not edited v1) keeps the B01/B05 fixtures and validators valid. The local row stays a superset of the wire shape |
| D8 | **The pad (WB-001, UX-005, UX-022).** `WeighInSheet` (an `FbSheet` on the root navigator, the A08b rule, with pinned actions). Top: the value, large, plus **kg / lb chips** (default from `unitSystemProvider`; switching relabels the typed number and doesn't convert it, because it fixes what the number meant: TG-002, LC-011). Then a **date/time chip** ("Today, 07:42": now by default, or **the page's date at now's wall-clock time when opened from a past day page** (PA3), never in the future; `showFbDatePicker` from 1970-01-01 (PA9) up to today, then `showFbTimePicker`; a future time can't be saved) and an **"Add a note" chip** (`FbTextField`, ≤ 200). Then `FbNumberPad` (`maxDigits: 4, maxDecimals: 1`), **prefilled with the latest weigh-in** in the shown unit (the typed value when the units match, else converted to 1 decimal). The first digit replaces the prefill (the `EntryAmountSheet` pattern). **Save** is pinned and always visible; the pad's Done closes the pad (like the diary's amount sheets; UX review m3, 2026-10-29), and focusing the note closes it too. Out of range → Save disabled + a hint. Implausible → an **inline `FbInlineBanner` in the sheet** (not a dialog, message only) whose answers replace the pinned actions: large change → "Save 100.0 kg" / "Edit". Unit → "Save as 214.0 lb" / "Keep kg". The saving answers ignore taps for 300 ms after the banner appears (a blind double tap on Save answers nothing; UX review M1). **Same day** (another live weigh-in on the chosen date): an info line "Also on this day: 97.2 kg at 06:50 · used for the trend" and an `FbSwitchRow` "Use this weigh-in for the trend" (off; on → the change set is `[CreateWeighIn, ChooseTrendWeighIn]`, atomic, where `ChooseTrendWeighIn` lists the new row as `VersionedId(newId, 1)`: it sees the create's write in the same transaction, PA6). **Edit mode hides the trend switch once the chosen date differs from the stored date** (the move clears the flag, D3; PA6). **Taps:** card (1) → type → Save (2) [→ confirm (3)]. With the same value as last time it's 2 taps and no typing | Spec's tap path. In-sheet confirm keeps it within 3 taps and follows UX-022. Save stays pinned, so Done never costs a tap on the path |
| D9 | **Weight card on every day page, "as of" that date (HM-005, HM-009, WB-011; PA3 option a).** `WeightCard(date:, isToday:)` in `features/body/presentation`, right after the day's numbers in the page's ordered header list (§3.5: numbers → to-confirm (A22) → weight → workout hint (A37) → diary). It shows `trendOn(date)`, the rate as of `date` (D2 incl. the staleness rule) and the latest raw weigh-in on or before `date`. One `FbCard`, two rows: **row 1** (tap → log sheet with the date preset to the page date, D8; trailing add icon): "Weight", "Trend 97.6 kg" (title style: the main number, smaller than the day's kcal), "−0.4 kg/week" on its own line (body style; UX review m4), and **on today's page only**, once there is a weekly rate, the honesty line and tip (D10; UX review M2). **Row 2** (tap → the same sheet in **edit mode** for that latest weigh-in; trailing edit icon): "Last weigh-in 97.4 kg · Fri", smaller. Edit mode: value/unit/time/note, the trend switch (hidden after a date change, D8), Save (`UpdateWeighIn`) and a secondary "Delete weigh-in" (`DeleteWeighIn`), both with undo. States: loading → `FbSkeleton.card` (UX-051) · empty (no weigh-in on or before the date) → "Log your first weigh-in" with no history, "No weigh-ins by this day. Tap to add one." on a past day before the first (row 1 only, UX-050; UX review M3, n2) · one weigh-in → trend = it, "Weekly rate after 2 weeks of weigh-ins" · stale (≥ 28 days) → "Trend 97.6 kg · from {date}", no rate (PA2), and the last weigh-in row without its date · error → inline banner with Try again. Graph navigation is added by A15 | HM-009 ("the same layout shows past days") holds, and a past page logs to that day in the same 2–3 taps. Editing the latest weigh-in covers the realistic mistake (a typo noticed after the 5 s undo) before A15's graph-point editing. The ops exist anyway (D5) |
| D10 | **Honesty (WB-012).** Pure `WeighInCadence.of(dayChoices, today)`: day choices in the last 28 days. **1–7** → the quiet line "{n} weigh-ins in 4 weeks · trend updates slowly" (UX review m1) (always shown while it applies: it's information, not a nag). **0 with history** → no line (the stale trend row already says "from {date}"; code review 2026-10-29 dropped "No weigh-ins in the last 4 weeks…"). **≥ 8** → nothing. Line and suggestion show **on today's page only** (PA3). **The suggestion** "Weighing in 2–3 times a week makes the trend steadier." + "Got it" appears only with a 1–7 cadence, **at most once per 30 days**. It stays for the day it first appears until dismissed, then disappears. Pure rule `CadenceTipRule.shouldShow(state, today, cadence)`. State `{shownOn, dismissed}` lives in **`shared_preferences`** (new `PreferenceKeys.weightCadenceTip` = `'fb.weight_cadence_tip.v1'` (PA10), read/written by `features/body/data/weight_tip_store.dart`): a display preference, not user data, so it stays out of the write path and sync. The controller records `shownOn` after the first frame that shows it, never inside `build` | The spec's "at most once a month" grammatically governs the suggestion, and the honesty statement itself is just the truth about the data. The owner (weekly) sees one calm line. `ux-reviewer` judges whether the always-on line feels like clutter (fallback: show it only on the sheet) |
| D11 | **Schema version: A14 takes v5** (v4 → v5: `createTable(weighIns)`, `createIndex(ixWeighInsLive)`, three triggers, nothing else). **Renumbering if A13 merges first with its own v5** (mechanical, Sonnet chore OK): rebase onto main; keep A13's `from_4_to_5.dart`, `drift_schema_v5.json` and `schema_v5.dart` untouched (frozen once on main); drop A14's own v5 dump and generated schema; rename A14's step to `migrations/from_5_to_6.dart` (`from5To6(Migrator m, Schema6 schema)`), set `schemaVersion => 6`, add `from5To6:` to `stepByStep`, union the `tables:` / `syncedTables` / `include:` lists, run `make db-migrations` (v6 dump + steps + generated test schemas), set the two constants at the top of `weigh_in_migration_test.dart` (`_from = 5`, `_to = 6`) and its `schema_vN` imports, then `make gen-check check-dart test-dart`. **Also on rebase (PA7):** union the blocks in `export_registry.dart`, the `export_snapshot.dart` order map, `sync_triggers.drift` and `app_scope.dart`; `git fetch origin main` before `tools/scripts/check-frozen-migrations.sh`; run `make goldens` and review the diffs. If A14 merges first, A13 does the same. Whichever lane merges second renumbers. Never both in one version | A self-contained migration and a test parameterised by two constants make the renumber a 10-minute chore. The frozen-migration check compares with the merge base, so an unmerged v5 can still be replaced |
| D12 | **Seams for later steps (no speculative API).** `body.dart` barrel exports `weighInsProvider` (live, ordered), `weightTrendProvider` (`WeightTrend`: day-choice points with raw + trend, `latest`, `trendOn(date)`, `asOf(date)` → `{trendKg, weeklyRateKg, lastWeighIn}`), **`currentWeightKgProvider`** (`Stream<double?>` = `weightTrendProvider.latest?.trendKg`), `showWeighInSheet(context, {LocalDate? date, WeighIn? edit})` and `WeightCard`. `fb_domain` README gains a "Weight trend" section (algorithm, constants, day choice, rate; `trendOn` holds the last value between weigh-ins; A38 windows should align with weigh-in days; A29 reuses `WeighInCheck` for chat and import rows). **Current weight (PA1, orchestrator decision binding both lanes): the current weight is the latest weigh-in trend.** No weight column on the profile. A13's onboarding sends its current-weight field as `CreateWeighIn` (origin `direct`) in the same change set as its profile/goal ops. Targets read weight only through the `features/body` barrel: `currentWeightKgProvider` and `weightTrendProvider`'s `trendOn(date)`. With no weigh-ins the targets surface shows an empty state; there is no profile fallback. **A14 merges before A13 wires its weight**; A13 builds against these fixed names and overrides the providers in its tests. The providers land in WP3 (PA5), so if A14 slips, **A14a (WP1–WP3, providers included) closes early** | A15 needs exactly these (WB-020/022). One source of "current weight", so targets and the weight card never disagree |
| D13 | **Copy and neutral language (PR-12, SF-020–022).** Only factual words: "weigh-in", "trend", "change". No praise or blame ("great", "oops", "too much", "gained"), no red/green or warning icons for direction or size of change, rate sign shown as plain numbers. Every string in ARB (§3.6). Weights format through one helper `weight_text.dart` (kg/lb, 1 decimal, signed rate, `intl` NumberFormat) | `CLAUDE.md` rule 8, the spec's kind-language rules |
| D14 | **No router, contract or API change; offline by construction.** The sheet opens with `showFbSheet` (no route; A40 adds the `/body/weigh-in` deep link later). `features/body` imports no `core/api` (app_check rule 3) | Local-first (rule 3); keeps shared files minimal |
| D15 | **Patrol changes → `[it]` on the close commit** (TD-086): a new `patrol_test/weigh_in_test.dart`, and the card shifts every day page's content, which can affect the existing journeys (`quick_add_test`, `food_search_add_test`, `meal_slots_test`, `today_diary_test`, `today_perf_test`, `app_test`; PA7). The engineer greps `patrol_test/` for Today-page finders/scroll assumptions (memory rule "UI copy → Patrol check") | Device truth for the 3-tap criterion; catches layout shifts |

**⚠️ OWNER items: none.** No spec change (D9 now follows HM-009 literally; D10's reading of WB-012 is an interpretation within WB-012; `ux-reviewer` checks it). No Accepted-TD change (TD-017 is honoured by D7), no vendor or cost, no security trade-off, no milestone cut. **TD:** D1/D2 are recorded by WP2 as **TD-088, Proposed** (Accepted at A14's merge). TD numbers are assigned by the orchestrator in merge order (PA7). **Backlog items to add at close:** (1) "`weighIn` v2 contract catch-up commit after B18 merges, before A34 Phase B (A14 D7/PA4)", named by the tripwire test; (2) the matching line in A34's Scope.

**Plan-review amendments (architect, 2026-10-28: approve with required changes; all applied above).**

| # | Amendment | Where |
|---|---|---|
| PA1 | Current weight = latest weigh-in trend; no profile weight column; A13 onboarding writes `CreateWeighIn` in its change set; targets read `currentWeightKgProvider` / `trendOn(date)` via the barrel; empty state without weigh-ins; A14 merges before A13 wires weight; fallback A14a | D12, §3.3, WP3, risk 7 |
| PA2 | No weekly rate when the last weigh-in day is ≥ 28 days before the evaluation date (code review: was > 28); stale card shows trend + "from {date}" | D2, D9, §5.2, §5.5 |
| PA3 (a) | Card on every day page as of that date; honesty line/tip only today; row 1 presets the page date (time = now's wall-clock, never future) | D8, D9, D10, §3.5, §5.5 |
| PA4 | `weighIn` v2 (additive) + v1→v2 upgrader defined; catch-up commit after B18, before A34 Phase B; tripwire test names the backlog item | D7, §5.3, risk 3 |
| PA5 | WPs re-cut: providers in WP3, WP4a/WP4b, tip store in WP5; ~2.7 sessions | §4, §8 |
| PA6 | Edit mode hides the trend switch after a date change; new row listed at version 1 in `[CreateWeighIn, ChooseTrendWeighIn]` | D8, §5.4 |
| PA7 | TD numbers by merge order; Patrol grep list extended; rebase union list, `git fetch` before the frozen check, `make goldens` | D11, D15, §9 |
| PA8 | Note rejects only `\p{Cc}`, allows `\p{Cf}` | D6, §5.1 |
| PA9 | `measured_at_utc ≥ 0` CHECK, `InvalidOp('time')`, date picker from 1970-01-01 | D6, D7, D8, §5.3 |
| PA10 | `PreferenceKeys.weightCadenceTip = 'fb.weight_cadence_tip.v1'` | D10 |
| PA11 | Undo test renamed (tombstone, trend as before) | §5.3 |
| PA12 | Convergence property starts from T₀ ≠ c | §5.2 |
| Suggestions | Ordered header list in `day_page.dart`; README notes; 90-day-gap scenario; TD-088 row in WP2 | §3.5, D12, §5.2, WP2 |

### 3. Design

**3.1 `fb_domain` — `packages/fb_domain/lib/src/body/` (pure, exported, 100 % coverage)**
```
weigh_in.dart         WeighInInput {value, unit: MassUnit (kilogram|pound only)} · kg rounding (D6)
                      WeighInBounds {minKg 20, maxKg 500, noteMax 200} · WeighInDraft {time: EntryTime, input, note?}
                      .validate() → WeighInIssue? (outOfRange | noteTooLong | noteInvalid | unit)
                      WeighIn {id, version, time: EntryTime, localDate, kg, input, note?, preferredForDay}
                      DayChoice.of(Iterable<WeighIn>) → List<WeighIn> (one per local_date, D3, sorted)
weigh_in_ops.dart     sealed WeighInOp (family 'weighIn'): CreateWeighIn · UpdateWeighIn · DeleteWeighIn · ChooseTrendWeighIn (D3/D5)
trend_weight.dart     TrendWeightConfig {halfLifeDays 7, maxAlpha .75, rateWindowDays 28, minRateSpanDays 14}
                      TrendWeight(config).compute(Iterable<WeighIn>) → WeightTrend {points: List<TrendPoint>, latest?,
                      trendOn(LocalDate) → double?, asOf(LocalDate) → WeightAsOf {trendKg?, weeklyRateKg? (D2 incl. PA2
                      staleness), lastWeighIn?}}; TrendPoint {localDate, weighInId, rawKg, trendKg}
weigh_in_check.dart   WeighInCheck.check({candidate: WeighInDraft, others: Iterable<WeighIn>}) → sealed WeighInCheckResult (D4)
weigh_in_cadence.dart WeighInCadence.of(points, today) {countLast28, lastDate, kind: none|frequent|sparse|stale}
                      CadenceTipState {shownOn?, dismissed} · CadenceTipRule.shouldShow(state, today, cadence) (D10)
```
Reuses `EntryTime` (`time/local_time.dart`), `MassUnit`, `StoragePrecision`, `VersionedId`/`checkUuid`/`checkRowVersion` (`diary/diary_ops.dart`). The barrel `fb_domain.dart` adds the five `src/body/*` exports (alphabetically first). No `DateTime.now()` (determinism test).

**3.2 Data — `apps/mobile/lib/core/db/` and `features/body/data/`**
```
core/db/tables/body_tables.dart       WeighIns table (D7) + `const weighInEntity = 'weighIn'`
core/db/body.drift                    ix_weigh_ins_live
core/db/sync_triggers.drift           + import 'tables/body_tables.dart' + weigh_ins_outbox_ai / _au / _no_delete
core/db/app_database.dart             tables += WeighIns · include += 'body.drift' · syncedTables += weighIn · schemaVersion 5 · from4To5
core/db/migrations/from_4_to_5.dart   createTable + createIndex + 3 triggers (D11)
core/export/export_registry.dart      ExportTableSpec('weighIn', 'weigh-ins', 'weigh_ins', [...all content columns]) (AC-030 tests require it)
core/db/export_snapshot.dart          weighIn order: 'local_date, measured_at_utc, id'
core/storage/preferences.dart         PreferenceKeys.weightCadenceTip = 'fb.weight_cadence_tip.v1' (WP5)
features/body/data/weigh_in_mappers.dart     row ↔ WeighIn; draft → WeighInsCompanion (D6 rounding, local_date from stored offset)
features/body/data/weigh_in_op_handler.dart  WeighInOpHandler (D3/D5/D6), registered in app/app_scope.dart
features/body/data/weigh_in_repository.dart  @riverpod: watchLive() (ordered local_date, measured_at_utc, id; live only), watchOne(id)
features/body/data/weight_tip_store.dart     read/write CadenceTipState in shared_preferences (D10; WP5)
```
Respects `03`: only `ChangeSetApplier` writes user data (rules 10–13 / `WriteGuard`). The tip store writes preferences, not the DB. Repositories expose reads only.

**3.3 Application — `features/body/application/`**
```
weight_providers.dart   (WP3) weighInsProvider (stream) · weightTrendProvider (TrendWeight over it; memoised) ·
                        currentWeightKgProvider (Stream<double?> = latest?.trendKg; PA1 seam for A13 targets)
                        (WP5) weightCardProvider(LocalDate date, {isToday}) → WeightCardState {asOf, latest raw?, cadence?, showTip, units}
weigh_in_form.dart      immutable WeighInFormState + pure reducer: buffer, unit, time, note, useForTrend, editTarget,
                        derived kg, validation issue, WeighInCheckResult (from weighInsProvider minus itself), sameDay list
weigh_in_actions.dart   WeighInActions (keepAlive): log / update / delete / chooseForTrend → builds ChangeSets, applies,
                        pushes UndoEntry (labels weighInLogged / weighInUpdated / weighInDeleted / weighInTrendChosen),
                        returns typed WeighInActionOutcome (done(undoId) | unchanged | failed(changed|removed|invalid|future)),
                        ignores a duplicate pending submit (A10b lesson)
weight_tip.dart         WeightTipController: shouldShow from CadenceTipRule; markShown after the first frame; dismiss()
```

**3.4 Presentation — `features/body/presentation/`**: `weight_card.dart` (D9), `weigh_in_sheet.dart` (+ `weigh_in_sheet_parts.dart` if over ~300 lines) (D8), `weight_text.dart` (D13). Directional layout only (`EdgeInsetsDirectional`, `AlignmentDirectional`), DS components only (`FbCard`, `FbListRow`, `FbNumberPad`, `FbChoiceChip`, `FbSwitchRow`, `FbInlineBanner`, `FbTextField`, `FbSkeleton`, `showFbSheet`, `showFbDatePicker`/`showFbTimePicker`, `showFbUndoSnackBar` helper from `core/undo`). Semantics: row 1 "Weight trend 97.6 kilograms, minus 0.4 per week. Log a weigh-in"; row 2 "Last weigh-in 97.4 kilograms, Friday. Edit". Tap targets ≥ 48 dp. No new DS component is expected; if one is needed, it gets its matrix golden (TD-076).

**3.5 Today integration**: `features/today/presentation/day_page.dart` renders the `NumbersRow` item as a small **ordered header list**: `TodayNumbers` → [A22 to-confirm strip] → `WeightCard(date: date, isToday: isToday)` → [A37 workout hint], so later steps add one entry rather than nesting widgets (`DayRows` in `features/diary` is untouched). `today` imports only `features/body/body.dart`. `body` never imports `today` (it gets the date and `isToday` as parameters).

**3.6 ARB keys (new, inserted as one block right after `weightLog`/`@weightLog` in `app_en.arb`, not at the end of the file, to keep the merge with A13 clean)**: `weightValue` ("{value} {unit}"), `weightUnitKg`/`weightUnitLb`, `weightCardTrend` ("Trend {weight}"), `weightCardRate` ("{rate} {unit}/week"), `weightCardRateLater` ("Weekly rate after 2 weeks of weigh-ins"), `weightCardTrendFrom` ("Trend {weight} · from {date}", PA2), `weightCardLast` ("Last weigh-in {weight} · {when}"), `weightCardEmpty`, `weightCardSparse` (ICU plural on {count}), `weightCardStale`, `weightCardTip`, `weightCardTipDismiss` ("Got it"), `weightCardLoadFailed`, `weightCardLogSemantics`, `weightCardEditSemantics`, `weighInSheetTitle` ("Log weigh-in"), `weighInEditTitle`, `weighInSave`, `weighInDelete`, `weighInAddNote`, `weighInNoteLabel`, `weighInNoteHint` ("e.g. after Eid"), `weighInOutOfRange` ("Enter a weight between {min} and {max}"), `weighInConfirmChange` ("That's {diff} from your weigh-in {when} ({weight}). Save it?"), `weighInConfirmSave` ("Save"), `weighInConfirmEdit` ("Edit"), `weighInConfirmUnit` ("Did you mean {value} {unit} ({converted})?"), `weighInSaveAsUnit` ("Save as {unit}"), `weighInKeepUnit` ("Keep {unit}"), `weighInSameDay` ("Also on this day: {weight} at {time}"), `weighInUsedForTrend` ("used for the trend"), `weighInUseForTrend` ("Use this weigh-in for the trend"), `weighInFuture`, `weighInSaved` ("Weigh-in saved: {weight}"), `weighInUpdated`, `weighInDeleted`, `weighInTrendChosen`, `weighInChanged`, `weighInRemoved`. The existing mockup keys (`weightTitle`, …) stay. `weightTitle` ("Weight") is reused for the card title.

### 4. Work packages
All WPs go to `flutter-engineer` (Opus), one brief each, in order. Heavy commands run as `flock ~/.cache/fb-heavy.lock <cmd>`. Each ends with `make gen-check check-dart` + the named tests green, then a commit by explicit paths. The full `make test-dart` runs at WP5 and at close.

- **WP1 — Weigh-in domain** (`fb_domain/src/body/weigh_in.dart`, `weigh_in_ops.dart`, `weigh_in_check.dart`, `weigh_in_cadence.dart`, barrel, tests in `packages/fb_domain/test/body/`). D3–D6, D10 rules. Done when the §5.1 tests (except trend) pass and `fb_domain` coverage stays 100 %. Commit `feat(body): weigh-in domain, ops and checks`.
- **WP2 — TrendWeight** (`trend_weight.dart` incl. `asOf`, `test/body/trend_weight_test.dart` with glados properties + the card's four scenarios + the 90-day-gap scenario, README "Weight trend" section with the D12 notes, and the TD row below in `technical-planning/12-decisions-and-questions.md`). D1, D2. Done when the §5.2 tests pass, coverage 100 %, `make test-dart` for `fb_domain`. Commit `feat(body): trend weight and weekly rate`. TD row (verbatim): `| TD-088 | **Trend weight:** time-aware smoothed average over one weigh-in per local day (earliest, or the user's per-day choice); a new weigh-in counts α = min(1 − 2^(−Δdays/7), 0.75); the trend holds between weigh-ins; weekly rate = 4-week trend change ÷ 4 (or the available span ≥ 14 days), hidden when the last weigh-in is over 28 days old; derived, never stored; constants in fb_domain TrendWeightConfig | Proposed | WB-010/011/012, D-054; a single weigh-in moves the trend only partly at any cadence; easy to explain; retuning needs no migration | Local regression (level can leave the input range); Holt level+slope (overshoots on weekly data); fixed daily smoothing with interpolation | A14 plan D1/D2, fb_domain README "Weight trend" |` (Accepted at A14's merge).
- **WP3 — Table, migration, handler, repository, providers** (§3.2 files except the tip store; `app_scope.dart` registration; export spec + snapshot order; the export test seed sets `input_unit` to `kg`; `features/body/application/weight_providers.dart` with `weighInsProvider`, `weightTrendProvider`, `currentWeightKgProvider` + the `body.dart` barrel exports (PA1/PA5); `test/drift/user/weigh_in_migration_test.dart`; `test/features/body/data/*`, provider tests). `make db-migrations`, then `make gen-app`. Done when §5.3 passes, plus the existing `AC-012 … outbox triggers` and `AC-030 …` export tests. Commit `feat(body): weigh_ins table (schema v5), write path and trend providers`. Progress-log line naming schema v5 and the provider names (for the lane-1 rebase and A13's build).
- **WP4a — Actions, form, text, copy** (`weigh_in_actions.dart`, `weigh_in_form.dart` pure reducer, `weight_text.dart`, the ARB block; unit tests without widgets). D5, D8 rules, D13. Done when the §5.4 non-widget tests pass. Commit `feat(body): weigh-in actions, form state and copy`.
- **WP4b — The weigh-in sheet** (`weigh_in_sheet.dart` (+ parts), log and edit modes, §5.4 widget tests and sheet goldens). D8. Done when the §5.4 widget tests and goldens pass. Commit `feat(body): weigh-in pad with checks, trend choice and undo`.
- **WP5 — Weight card, honesty, Today** (`weight_card.dart`, `weightCardProvider`, `WeightTipController`, `weight_tip_store.dart` + the `PreferenceKeys` key, the `day_page.dart` header list, `fakeToday` override in `test/features/today/presentation/support/today_support.dart`, card goldens (incl. past day) + regenerated Today goldens (`make goldens`, review the diffs), host 3-tap and past-day journeys, `patrol_test/weigh_in_test.dart`, grep/fix of the existing Patrol journeys (D15), `make build-it` compiles). D9, D10, D15. Done when §5.5 passes and full `make test-dart` is green. Commit `feat(today): weight card with trend and honesty line`. The close commit carries `[it]`.

### 5. Test list (names as written; spec ID first, `10` §5)

**5.1 Domain, weigh-ins** (`packages/fb_domain/test/body/`)
- `WB-003 a weigh-in keeps value, unit, time, local date and note`
- `WB-003 lb input is stored as kg rounded once (214 lb → 97.07 kg, shown back as 214.0 lb)`
- `WeighInDraft rejects values outside 20–500 kg, non-finite values and units other than kg/lb`
- `WeighInDraft note is trimmed, empty becomes null, at most 200 characters, no control characters`
- `a note with an emoji ZWJ sequence or RLM is accepted` (PA8)
- `weigh-in toString carries no value and no note` (rule `09.4-logging`)
- `WB-003 several weigh-ins on one day: the earliest is the day choice`
- `WB-003 a preferred weigh-in wins over the earliest; two preferred after a sync: the earliest preferred`
- `WB-003 equal times break ties by id`
- `weigh-in ops: value equality, uuid and version checks; ChooseTrendWeighIn rejects a chosen id outside dayWeighIns`
- `WB-005 a change over 3 % within 7 days asks for confirmation (97.0 → 100.0)`
- `WB-005 exactly 3 % does not ask (97.0 → 99.91)`
- `WB-005 the reference is the nearest earlier weigh-in within 7 days; 8 days back means no 3 % check`
- `WB-005 a backfilled weigh-in is checked against the next one within 7 days`
- `WB-005 214 kg after 97 kg suggests lb (97.07 kg); 97 lb after 214 lb suggests kg`
- `WB-005 a unit mix-up is reported before a large change`
- `WB-005 the first weigh-in is only checked against the bounds`
- `WB-005 an edit is checked against its neighbours, not itself`
- `WB-012 1–7 weigh-in days in 28 is sparse, 8+ is frequent, none with history is stale`
- `WB-012 the suggestion shows at most once in 30 days and stays hidden after Got it`
- `WB-012 on the day it first shows, the suggestion stays until dismissed`

**5.2 Domain, trend** (`trend_weight_test.dart`)
- `WB-010 property: the trend stays within the min and max of the inputs so far` (glados, 1,000 cases: random dates, gaps 1–60 d, 20–500 kg)
- `WB-010 property: a constant series gives that constant exactly`
- `WB-010 property: from a trend T₀ ≠ c, after n daily weigh-ins of c, |Tₙ − c| ≤ (1 − α(1))ⁿ · |T₀ − c|` (PA12)
- `WB-010 property: one outlier in a constant series moves the trend by α(gap) of its distance, never more than 75 %`
- `WB-010 property: input order and repeated rows don't change the result`
- `WB-004 weekly weigh-ins each move the trend halfway`
- `WB-004 scenario: weekly weigh-ins losing 0.5 kg/week with alternating ±0.8 kg noise give a rate within 0.15 of −0.5 after 8 weeks and smaller week-to-week steps than the raw values` (deterministic noise, no seeds)
- `WB-010 scenario: daily alternating ±1 kg noise around 80 kg keeps the trend within 80 ± 0.5 after 21 days`
- `WB-004 scenario: after a 3-week gap the next weigh-in moves the trend 75 %, then weekly ones 50 %`
- `WB-010 scenario: a single +3 kg outlier among daily weigh-ins moves the trend 0.28 kg and decays back`
- `WB-004 scenario: after a 90-day gap a weigh-in 6 kg higher moves the trend 4.5 kg (75 %); before it, the rate as of a date in the gap is hidden (stale)`
- `WB-011 weekly rate: the 28-day trend change ÷ 4; a shorter history uses its span; under 14 days or 1 day choice: no rate`
- `WB-011 lb inputs give the same trend and rate as the equivalent kg inputs (within storage rounding)`
- `WB-022 trendOn(date) is the trend of the last day choice on or before the date, null before the first`
- `WB-012 asOf(date): no weekly rate when the last weigh-in day is more than 28 days before the date` (PA2)
- `synced rows with non-positive or non-finite kg are skipped`
- `one weigh-in: the trend equals it and there is no rate`

**5.3 Data** (`apps/mobile/test/features/body/data/`, `test/drift/user/`)
- `WB-001 CreateWeighIn writes kg, input, time, local date and note, and one outbox row`
- `UX-030 undo of CreateWeighIn leaves no live weigh-in (a tombstone) and the trend as before` (PA11)
- `UpdateWeighIn with a stale version is rejected and writes nothing`
- `UpdateWeighIn with an identical draft writes nothing`
- `UX-030 DeleteWeighIn tombstones the row and undo revives it`
- `WB-003 ChooseTrendWeighIn sets the chosen flag, clears the others, and undo restores them`
- `WB-003 ChooseTrendWeighIn rejects a day whose weigh-ins changed since they were shown`
- `WB-003 logging and choosing for the trend in one change set is atomic`
- `moving a preferred weigh-in to another day clears its preference`
- `a measured time more than 5 minutes ahead is rejected (future)`
- `a negative measured time is rejected (time)` (PA9)
- `an invalid draft is rejected (invalidDraft)`
- `watchLive emits live weigh-ins ordered by date, time and id, and updates after an apply`
- `migration v4→v5 keeps every v4 row and adds weigh_ins with its index and three triggers` (+ the generated schema validation)
- `the weighIn wire fixture fields map to weigh_ins columns by snake_case; the extra local columns are the documented four` (tripwire: its failure message names the backlog item "weighIn v2 contract catch-up", PA4)
- `PA1 currentWeightKgProvider is the latest trend and null without weigh-ins; it updates after a weigh-in is logged`
- existing `AC-012 every synced table has insert/update/no-delete outbox triggers` and `AC-030 every synced table has an export spec` / `AC-030 every column is exported or excluded with a reason` (now covering weigh_ins)

**5.4 Application and sheet** (`apps/mobile/test/features/body/`)
- `WB-001 the pad opens prefilled with the latest weigh-in in the shown unit; the first digit replaces it`
- `TG-002 the pad accepts kg or lb whatever the setting; switching relabels the typed number`
- `UX-030 logging pushes an undo entry and shows Weigh-in saved with Undo`
- `WB-005 an implausible change shows the in-sheet confirm; Save saves, Edit returns to the pad`
- `WB-005 Did you mean lb: Save as lb stores 214 lb / 97.07 kg`
- `WB-003 a second weigh-in on a day shows the earlier one and the use-for-trend switch`
- `WB-003 date and time default to now, can be changed, and a future time can't be saved`
- `editing a weigh-in's date hides the use-for-trend switch and clears its preference` (PA6)
- `out-of-range values disable Save and show the range hint`
- `edit mode saves changes and deletes with undo; a weigh-in changed meanwhile shows the changed message`
- `a double tap on Save logs once`
- Goldens `weigh-in sheet: prefilled · large-change confirm · unit confirm · same day · edit` (light/dark × 1.0/2.0)

**5.5 Card and Today**
- `HM-005 WB-011 the card shows the trend and weekly rate, and the latest raw weigh-in smaller`
- `UX-050 with no weigh-ins the card invites the first one`
- `WB-011 with one weigh-in the card says the rate comes after 2 weeks`
- `WB-012 sparse weigh-ins show the honesty line; the suggestion appears at most once a month`
- `LC-010 the imperial setting shows lb for the trend, rate and last weigh-in`
- `UX-051 loading shows a skeleton; an error shows Try again`
- `HM-009 a past day shows the trend as of that day and logs to that day` (PA3)
- `WB-012 the honesty line and suggestion show on today's page only`
- `WB-012 with no weigh-ins in the last 4 weeks the card shows no weekly rate` (PA2)
- `WB-001 UX-005 a weigh-in is logged in 3 taps from Today` (host journey; counts non-digit taps: card + Save = 2, + confirm = 3; checks the stored row and the updated card)
- Goldens `weight card: empty · one weigh-in · trend + rate + sparse line + suggestion · stale · past day` (light/dark × 1.0/2.0) and the regenerated Today goldens
- Patrol `A14 weigh-in from Today in three taps` (offline, device)

### 6. Exit-criteria mapping
| Exit criterion | Demonstrated by |
|---|---|
| Weigh-in in 3 taps from Today (integration test counts taps) | `WB-001 UX-005 a weigh-in is logged in 3 taps from Today` (host) + Patrol `A14 weigh-in from Today in three taps` (`[it]` run on the close commit). The A55 timing goes to A42 |
| Trend properties (min/max, constant convergence, outlier partial) | §5.2 glados properties 1–4 (+ scenarios for weekly, daily noise, 3-week gap, single outlier, the card's decide-item) |
| Implausible-value tests (3 % rule, unit mix-up) | §5.1 `WB-005 …` domain tests + §5.4 sheet confirm tests |
| Goldens for the weight card and pad | §5.4 sheet goldens, §5.5 card goldens incl. `weight card: past day` (light/dark × 1.0/2.0) |

### 7. Risks & unknowns
1. **Schema version collision with A13** → D11 protocol. The orchestrator tells the second lane to merge. Mechanical, ~10 min.
2. **Shared Today files and goldens with A13** (`day_page.dart`, `today_support.dart`, Today golden PNGs) → small hunks. Goldens are regenerated (`make goldens`) after the rebase, never merged by hand.
3. **Wire schema lacks four local columns** → D7/PA4: `weighIn` v2 + upgrader in a contract catch-up commit after B18 merges, before A34 Phase B; the tripwire test names the backlog item. No upload exists before A34, so there's no data risk.
4. **Trend feel** (half-life 7 d, cap 0.75) → owner feedback while dogfooding. Constants in one value, derived, so a retune needs no migration (a one-line change + test update).
5. **Patrol shifts** from the card on every day page → D15 grep + the `[it]` run. A no-output `android-it` run isn't automatically an infra flake (memory).
6. **Honesty line feels naggy, or the card crowds past days** → `ux-reviewer` checks. Fallbacks (line only on the sheet; a compact past-day card) need no owner gate.
7. **A13 current-weight seam (PA1, binding)** → A14 publishes `currentWeightKgProvider` and `weightTrendProvider` in WP3 and **merges before A13 wires its weight**; A13 builds against those names with test overrides. If A14 slips, close **A14a** (WP1–WP3) early so A13 isn't blocked.
8. **What `ux-reviewer` should check:** neutral copy (no moral, praise or blame words, no red/green for change), trend as the main number but smaller than the kcal number, the honesty line's tone and frequency, confirm-banner wording, tap targets and semantics of the two card rows, the past-day card (as-of wording, logging to that day), text scale 2.0 (card + sheet with pinned Save), directional layout, the empty/loading/error states, edit/delete discoverability.

### 8. Size
**L, ~2.7 sessions** (the card said M: the write path, migration, edit mode, past-day card and two goldened surfaces add up): WP1 0.4 · WP2 0.4 · WP3 0.5 · WP4a 0.3 · WP4b 0.5 · WP5 0.6. No split proposed. Fallback seam (PA1): if A14 slips, close **A14a** (WP1–WP3: domain, trend, write path and the providers A13 needs) early, and **A14b** (WP4a–WP5: pad, card, honesty, goldens, Patrol). The orchestrator decides that under `13` §9.

### 9. Shared files (for rebase sequencing with lane 1 = A13)
| File | A14 change | Collision risk |
|---|---|---|
| `apps/mobile/lib/core/db/app_database.dart` (+ generated `.g.dart`, `app_database.steps.dart`) | tables, include, syncedTables, `schemaVersion 5`, `from4To5` | **High**: D11 |
| `apps/mobile/lib/core/db/sync_triggers.drift` | import + weigh_ins trigger block appended | Medium: keep both blocks |
| `apps/mobile/drift_schemas/user/drift_schema_v5.json`, `test/drift/user/generated/schema.dart` + `schema_v5.dart` | new (generated) | **High**: D11 (regenerate) |
| `apps/mobile/lib/core/export/export_registry.dart`, `core/db/export_snapshot.dart`, `test/core/export/export_test.dart` (seed) | weighIn spec, order, seed unit | Medium: adjacent specs |
| `apps/mobile/lib/app/app_scope.dart` | `WeighInOpHandler(db)` + body barrel import | Low: adjacent lines |
| `apps/mobile/lib/l10n/app_en.arb` (+ `l10n/gen/*`) | one block after `weightLog` | Low/medium: regenerate gen |
| `apps/mobile/lib/features/today/presentation/day_page.dart` | `NumbersRow` item → ordered header list (§3.5) | Medium: A13 wires targets here |
| `apps/mobile/test/features/today/presentation/support/today_support.dart` | `fakeToday` weight overrides | Medium |
| Today golden PNGs (`test/features/today/presentation/goldens/ci/`) | regenerated | **High**: regenerate after rebase |
| `packages/fb_domain/lib/fb_domain.dart`, `packages/fb_domain/README.md` | body exports (top), "Weight trend" section | Low |
| `apps/mobile/lib/core/storage/preferences.dart` | one key | Low |
| `technical-planning/12-decisions-and-questions.md` | TD-088 row (WP2); numbers assigned by the orchestrator in merge order (PA7) | Low/medium: renumber if A13 takes 088 first |
| `technical-planning/steps/README.md`, `steps/backlog.md`, `A34-sync-engine-app.md` Scope line, `05-data-and-sync.md` §2.2 | orchestrator at close | Low |
New, A14-only: `packages/fb_domain/lib/src/body/*`, `packages/fb_domain/test/body/*`, `apps/mobile/lib/core/db/tables/body_tables.dart`, `core/db/body.drift`, `core/db/migrations/from_4_to_5.dart`, `apps/mobile/lib/features/body/**`, `apps/mobile/test/features/body/**`, `test/drift/user/weigh_in_migration_test.dart`, `patrol_test/weigh_in_test.dart`. Not touched: router, `core/navigation`, `contracts/`, `fb_api_client`, backend.

## Progress log
- 2026-10-28 · Low-level plan written (step-planner).
- 2026-10-28 · Architect plan review: approve with required changes PA1–PA12 (PA3 option a), applied. Plan approved by the orchestrator (TD-037, no owner items).
- 2026-10-28 · WP1 committed (4c0199a): `fb_domain/src/body/` weigh-in model + draft (D6, PA8, PA9), `DayChoice` (D3), `WeighInOp` family (D5), `WeighInCheck` (D4), cadence + tip rules (D10); fb_domain 489 tests, coverage 100.0 %.
- 2026-10-28 · WP2 committed (0b80fd9): `TrendWeight` / `WeightTrend` (`trendOn`, `asOf` with the PA2 stale rule), `TrendWeightConfig`, glados properties + scenarios (incl. 90-day gap), README "Weight trend", TD-088 (Proposed); fb_domain 508 tests, coverage 100.0 %. Next: WP3.
- 2026-10-28 · WP3 committed (9ecdc57): **schema v5** (`weigh_ins`, `ix_weigh_ins_live`, 3 triggers, `migrations/from_4_to_5.dart`, `drift_schema_v5.json`), `WeighInOpHandler`, `WeighInRepository`, export spec; providers in the `features/body/body.dart` barrel: **`weighInsProvider`, `weightTrendProvider` (`Stream<WeightTrend>`), `currentWeightKgProvider` (`Stream<double?>`)** for A13. Renumber if A13 merges first: D11. Next: WP4a.
- 2026-10-28 · WP4a committed (e046314): `features/body/application/weigh_in_actions.dart` (`WeighInActions` keepAlive notifier: `log` / `update` / `delete`, one change set each through the applier, undo labels `weighInLogged` / `weighInUpdated` / `weighInDeleted` / `weighInTrendChosen`, typed outcomes Done / Unchanged / Pending / Failed(changed|removed|invalid|future), duplicate submit → Pending), `weigh_in_form.dart` (pure `WeighInFormState`: prefill + first digit replaces, kg/lb relabel, same-day list and trend switch default (PA6: hidden after an edit's date move), implausible confirm, Save issues incl. future and pre-1970), `presentation/weight_text.dart` (1 decimal, kg/lb, signed U+2212 rate), A14 ARB block after `weightLog`. Deviations: no standalone `chooseForTrend` (the choice rides with log/update; an identical draft + changed choice = `weighInTrendChosen`); `weighInUsedForTrend` fragment → two full sentences `weighInSameDay` / `weighInSameDayUsed`; extra keys for semantics, the When chip, note issues, pre-1970 and refusals; card keys (`weightCard*` except `weightCardRate`) come with WP5. Next: WP4b.
- 2026-10-28 · WP4b committed (504a9ae): `presentation/weigh_in_sheet.dart` (`WeighInSheet` log + edit modes on `FbSheet` with pinned Save (+ Delete in edit), pad prefilled (first digit replaces), kg/lb `FbUnitPicker`, When chip (page date at now's clock time per PA3, date picker 1970-01-01…today then time; future → Save off + hint), note chip/field (≤ 200 code points, issues under the field), same-day lines + trend switch (hidden after an edit's date move), in-sheet confirm banner (Save/Edit; Save as {lb}/Keep kg), undo snackbars, load error with Try again) and `showWeighInSheet(context, {date, edit})` in the `body.dart` barrel for A13c/WP5. 13 widget tests + 5 goldens (prefilled, large change, unit, same day, edit; light/dark × 1.0/2.0). ARB +2 (`weighInLoadFailed`, `weighInTryAgain`). Next: WP5.
- 2026-10-29 · WP5 committed: `presentation/weight_card.dart` (`WeightCard(date:, isToday:)`: row 1 trend as of the day + rate (PA2 stale → "from {date}", no rate; < 14 days → "Weekly rate after 2 weeks"), today only the sparse/stale honesty line and the monthly tip with Got it; row 2 the latest raw weigh-in on or before the day (from the weigh-ins list) → edit sheet), `application/weight_card_state.dart` (`weightCardProvider`, synchronous `AsyncValue` over the shared weigh-in/trend streams, so a swiped-to page shows no skeleton), `application/weight_tip.dart` (`WeightTipController`) + `data/weight_tip_store.dart` (`PreferenceKeys.weightCadenceTip = 'fb.weight_cadence_tip.v1'`), `day_page.dart` ordered header (numbers → [A22] → weight → [A37]). `WeighInRepository.watchLive` now re-reads on drift table updates (the diary's pattern) instead of `.watch()`, whose close timer was left pending in every Today widget test. Tests: card widget tests, tip store, host 3-tap + past-day journeys (`today_weight_test.dart`), card goldens (5), Today/quick-add/app-shell goldens regenerated with `make goldens`; `patrol_test/weigh_in_test.dart` (compiles; `[it]` on the close commit validates it); `showsLoadedDay` (Patrol support) no longer requires a mounted meal header (the header can fill a compact viewport). Next: close.
- 2026-10-29 · Phase D review findings applied (2 commits). **Code/security:** stale when the last weigh-in is ≥ 28 days old (TD-088 row text updated), stale honesty line and `weightCardStale` dropped; kg read bound `WeighInBounds.isReadableKg` (finite, > 0, ≤ 1e6) in `TrendWeight`, `WeighInCheck`, the repository decode and the sheet/card; `ChooseTrendWeighIn` membership from readable rows only; untouched edit prefill saves the stored input exactly; pad limits passed explicitly; `_bufferText` refuses ≥ 10⁴; trend properties generate same-day pairs; `watchOne` / `weightTextIn` removed; tripwire names B19; neutral-copy test covers every `weight*`/`weighIn*` key. **UX:** confirm answers replace the pinned actions ("Save 100.0 kg" / "Edit", "Save as 214.0 lb" / "Keep kg") with a 300 ms double-tap guard; pad Done and note focus close the pad; range hint only when more digits can't help, whole-number bounds; card: "Trend 97.6 kg" title + rate line, cadence line/tip only once a rate exists, past-day empty copy, stale row without a second date, full-unit semantics; changed-weigh-in banner with Reload (log mode: its own retry message); copy n2/n3, m1. Goldens regenerated (`make goldens`). Gates: gen-check OK, check-dart OK, test-dart green (mobile 1554, fb_domain 522 at 100 % coverage). Backlog note: `FbUnitOption.semanticLabel` (m5). B19 Scope line in the close notes below (B19 card not on this branch).
- 2026-10-29 · Rebased onto main 6151d38 (A13a merged at v5). Per D11/PA7 **weigh_ins is now schema v6**: `migrations/from_5_to_6.dart` (`from5To6`, body unchanged), `drift_schema_v6.json` + `schema_v6.dart` generated, A13a's v5 files byte-identical to main; `weigh_in_migration_test` runs v5→v6 and seeds the targets tables too; export count is twelve CSVs.
- 2026-10-29 · Verifier PASS (`1088502`); rebased onto A13a and renumbered to v6 (`423e647`); Outcome, board, TD-088 Accepted, backlog #135/#136; merging via `merge-step.sh` with `[it]` (Patrol changed).

## Outcome
**Built by Claude (TD-085) in lane 3 (TD-087), merged 2026-10-29. Actual size L (planned M on the card; the plan said L): WP1 domain, WP2 trend, WP3 data + providers, WP4a actions/form, WP4b sheet, WP5 Today card, plus one review-fix round and the v5→v6 renumber after A13a.**
- **Built:** fb_domain weigh-in model/ops/checks (bounds, implausible change, unit mix-up, cadence) and `TrendWeight` (TD-088); `weigh_ins` table (schema **v6**, after A13a's v5), triggers, CHECKs, export, `WeighInOpHandler`, repository, `weighInsProvider` / `weightTrendProvider` / `currentWeightKgProvider` (the fixed names A13b wires into targets); the weigh-in sheet (pad, kg/lb, date/time, note, confirms, same-day trend choice, edit/delete, undo) and the weight card on every day page "as of" that date with honesty line and monthly tip on today; Patrol `A14 weigh-in from Today in three taps`.
- **Deviations:** no separate `chooseForTrend` (the trend choice rides with log/update in one change set); `WeighInRepository.watchLive` re-reads on table updates (drift `.watch()` left close timers); Patrol `showsLoadedDay` loosened to the day's number; stale rule is ≥ 28 days (TD-088 text updated); the stale honesty line was dropped (the trend row says "from {date}"); the pad's Done closes the pad; unreadable synced rows (kg not finite, ≤ 0 or > 1e6) are dropped from the list.
- **Reviews:** architect PA1–PA12; code review (0 blocker/major, 3 minors + nits, fixed); security review (0 blocker/major, 6 minors: 4 fixed, 2 recorded); UX review (1 major blocker fixed: during a confirm the pinned action *is* the confirm and a double tap can't store 214 kg; M2 first-day clutter and M3 past-day copy fixed; minors fixed); verifier PASS. Evidence: `evidence/A14-verification.md`.
- **Metrics:** mobile tests 1,468 → 1,614 on the merged tree; fb_domain 100 % coverage; 9/9 spec IDs traced. Full-suite `day_view_perf_test` missed once under parallel load (P2 35 ms vs 25 ms), passes alone (~9 ms): backlog #116 noise.
- **TDs:** TD-088 (trend weight) Accepted.
- **Follow-ups:** `weighIn` v2 contract + admission is in B19's Scope (the four local columns + v1→v2 upgrader); backlog #135 (unit chip semantics), #136 (weigh-in tombstone scrubbing); A13b WP6 wires `bodyWeightProvider` and the first weigh-in in setup.
- **Owner checks on the A55 (not blocking):** 2-tap weigh-in + Undo; the unit mix-up confirm; the weekly card with the one-line cadence note; the monthly tip.

_Close notes from Phase D (2026-10-29), for the orchestrator:_ applied above (B19 Scope already carries `weighIn` v2; backlog #135).
