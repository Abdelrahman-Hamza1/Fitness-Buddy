# A14 verification (2026-10-29)

Tier **Risky** (body weight is sensitive user data; a new synced table `weigh_ins`, migration v5, the `weighIn` op family and handler, local-only extra columns, export; `PROCESS.md` Part C). Built by Claude (TD-085). This is the Phase D `security-reviewer` evidence for the whole step: `git diff origin/main...HEAD` on `step/A14-weigh-ins-trend` at `6b50d0d` (main `8eb1b81`; WP1 `b41a30b`, WP2 `7f5d0f1`, WP3 `0cca575`, WP4a `9a16e24`, WP4b `c8676b8`, WP5 `6b50d0d`), lane 3. Executed checks are kept apart from inspection-only claims.

## Scope

- **Write path:** `features/body/data/weigh_in_op_handler.dart` (registered in `app/app_scope.dart`), `weigh_in_mappers.dart`, `core/db/tables/body_tables.dart`, `core/db/body.drift`, `core/db/sync_triggers.drift` (3 triggers), `core/db/migrations/from_4_to_5.dart`, `app_database.dart` (schema v5, `syncedTables`).
- **Domain:** `packages/fb_domain/lib/src/body/` (`weigh_in.dart`, `weigh_in_ops.dart`, `weigh_in_check.dart`, `weigh_in_cadence.dart`, `trend_weight.dart`).
- **Read path / UI:** `weigh_in_repository.dart`, `weight_providers.dart`, `weight_card_state.dart`, `weigh_in_actions.dart`, `weigh_in_form.dart`, `weight_tip.dart` + `data/weight_tip_store.dart` (`shared_preferences`), `presentation/weigh_in_sheet.dart`, `weight_card.dart`, `weight_text.dart`, `today/presentation/day_page.dart`, ARB block.
- **Export:** `core/export/export_registry.dart`, `core/db/export_snapshot.dart`, `docs/export-format.md`.
- **Not changed:** `contracts/`, `fb_api_client`, router, `core/api`, backend, Sentry/`PiiScrubber`, dependencies (`pubspec.lock` untouched).

## Properties → evidence

| Property | Evidence |
|---|---|
| **Only `ChangeSetApplier` writes** (TD-011, rule 2) | Inspection: the only `weigh_ins` writers are `InsertRow`/`UpdateRow`/`TombstoneRow` plans in `WeighInOpHandler` (grep of `lib/` for `weighIns`/`weigh_ins`); the repository is read-only; `WriteGuard` rejects unauthorised writes (A01). The handler re-validates every draft inside the transaction (`_columns`: bounds, note, `time`, `future`), so a caller that skips `WeighInActions._refusal` (A29 proposals, tests) still can't store an out-of-range value. Executed: handler tests `an invalid draft is rejected (invalidDraft)`, `a negative measured time is rejected (time)`, `a measured time more than 5 minutes ahead is rejected (future)` |
| **Optimistic concurrency / stale UI lists** | Executed: `UpdateWeighIn with a stale version is rejected and writes nothing`, `WB-003 ChooseTrendWeighIn rejects a day whose weigh-ins changed since they were shown` (exact membership at shown versions, `InvalidOp('sourceChanged')`), actions `a day that changed since it was shown is refused as changed`, `a weigh-in changed meanwhile is refused as changed; a deleted one …`. Domain: `ChooseTrendWeighIn` rejects empty lists, duplicate IDs and a `chosen` outside the list (`weigh_in_ops.dart:384-408`) |
| **Undo for every direct action** (rule 8, UX-030) | Executed: `UX-030 undo of CreateWeighIn leaves no live weigh-in (a tombstone)`, `UX-030 DeleteWeighIn tombstones the row and undo revives it`, `ChooseTrendWeighIn … undo restores them`, actions `logging pushes an undo entry labelled with the typed value`, `edit mode deletes with undo`. `weigh_ins_no_delete` trigger forbids hard deletes |
| **No user content in logs / crash reports / `toString`** (rule 6, `09` §4) | Inspection: `features/body` and `fb_domain/src/body` contain no `print`/`debugPrint`/`log`/Sentry/analytics call (grep). Every new type's `toString` omits kg, input value and note: `WeighIn` (`id@vN`), `WeighInDraft`, `WeighInInput` (unit only), all four ops (ID/version/count), `WeighInCheckResult`s, `TrendPoint`/`WeightAsOf`/`WeightTrend` (dates and counts only), `WeighInFormState`, `WeighInSubmission`, `WeighInTrendPick`, `WeightCardState`, `WeighInMappingError` (fixed text; the mapper swallows `ArgumentError`/`FormatException`, which quote stored text). `UndoLabel.toString` is the key only and the undo stack is in-memory, never logged (`undo_stack.dart:14,43`). Sentry: `PiiScrubber` drops exception values, messages, breadcrumb messages/data and Flutter error contexts (unchanged); the sheet opens with `showFbStatefulSheet` (no route, so no route arguments in navigation breadcrumbs). Executed: domain test `weigh-in toString carries no value and no note` |
| **Intentional value display** | The undo snackbar (`weighInSaved`/`weighInUpdated`, built from the submitted draft in `weigh_in_sheet.dart:163-179`), the card rows and their semantics labels carry the user's own weight on their own screen; nothing else does (no notification, no event payload — `ChangeSetApplied` carries entity names only) |
| **`shared_preferences` holds no weight data** | Inspection: `PreferencesWeightTipStore` writes only `{"shownOn": "YYYY-MM-DD", "dismissed": bool}` under `fb.weight_cadence_tip.v1` (`weight_tip_store.dart:141-147`); unreadable values fall back to `initial`. Executed: `weight_tip_store_test.dart` |
| **Hostile / garbled synced rows** | Tolerant decode: `WeighInRepository` drops rows `weighInOf` can't read (unknown unit, malformed date, bad UUID/version, `measured_at_utc` beyond `DateTime`'s range) instead of failing the list; `TrendWeight.compute` skips non-finite / non-positive kg (`trend_weight.dart:277`); `WeighInCheck` ignores such references (`weigh_in_check.dart:125`); the form prefill refuses non-finite/non-positive values. Executed: `watchOne … unreadable synced rows are left out of the lists`, `synced rows with non-positive or non-finite kg are skipped`. Exceptions: findings 1–2 |
| **CHECKs vs wire (D7 tripwire)** | Inspection: local CHECKs `measured_at_utc ≥ 0`, `kg ≥ 0`, `input_value ≥ 0`, `input_unit IN ('kg','lb')`, `tz_offset_min −720…840` are no stricter than `contracts/openapi/sync-entities.json` `weighIn` v1 (`kg` 0…1e12, `measuredAtUtc` 0…2^53, `note` ≤ 4096, `localDate` date) — the local-only columns have no wire counterpart yet. Executed: `weigh_in_migration_test.dart` tripwire (wire fields ⊆ columns; columns − wire − sync columns = exactly the four local-only columns, failure message names the catch-up). The v2 fields (`tzOffsetMin`, `inputValue`, `inputUnit`, `preferredForDay`) and the v1→v2 upgrader are recorded in the card (D7/PA4) and the tripwire message; the backlog item and the B19/A34 scope line are close-time orchestrator items (finding 4) |
| **Export includes weigh-ins** (AC-030, intentional) | `ExportTableSpec('weighIn', 'weigh-ins', …)` exports every content column incl. `note`, live rows only (`deleted_at IS NULL`); CSV text cells keep the existing formula protection (`csv_codec.dart`). Executed: `AC-030` export tests (every synced table has a spec; every column exported or excluded) and the file-count tests now derived from `exportRegistryV1.length` |
| **Neutral copy** (SF-020-22, PR-12, D13) | Inspection of every `weight*`/`weighIn*` ARB string: factual only ("Trend", "change", "weigh-in", signed numbers with U+2212); no colour or icon by direction. Executed: `D13 weight copy is neutral: no praise or blame words` (real assertions over 11 strings × 10 words; it doesn't cover the card strings: finding 3) |
| **No network on these paths** (rule 3) | Inspection: `features/body` imports no `core/api`, `http` or `dio`; `app_check` rule 3 enforces it (executed in the full run: `app-check: OK`). The trend is computed locally; the sheet has no route |

## Commands run (this review, lane 3, `6b50d0d`)

| Command | Result |
|---|---|
| `heavy.sh flutter test test/features/body test/drift/user/weigh_in_migration_test.dart test/core/export test/features/today/presentation/today_weight_test.dart` (in `apps/mobile`) | **113/113 passed**: handler (12), repository (2), providers (2), actions (11), form, tip store, sheet + goldens, card + goldens, weight text (incl. D13), migration v4→v5 + D7 tripwire, export (AC-030, formula guard, docs/registry parity), host 3-tap and past-day journeys |
| `heavy.sh dart test test/body` (in `packages/fb_domain`) | **44/44 passed** (incl. glados properties, `toString` content-free, non-finite/non-positive kg skipped) |
| `heavy.sh make check-dart gen-check test-dart` (orchestrator's lane-3 run at `6b50d0d`, clean tree; log read by this review) | **exit 0**: format/analyze clean, `app-check: OK` (no `core/api` in `features/body`), frozen-migrations OK, `gen-check: OK`; mobile 1541 passed (2 skipped), fb_domain coverage **100.0 %** (4909/4909), all other packages green |
| `dart run` scratch probe (`(x * 10).round()` for `1e300`, `Infinity`; `1e306 * 1000`; `1e21.toStringAsFixed(1)`) | `1e300` clamps; `Infinity` throws `UnsupportedError`; `1e306 * 1000 = Infinity`; `"1e+21"` (findings 1, 5) |
| grep `features/body`, `fb_domain/src/body` for `print`/`log`/Sentry/analytics/`http`/`Uri` | none |

Not run by this review: the Patrol journey (`[it]` on the close commit) and CI; they're close gates for the orchestrator.

## Findings

No blocker, no major.

1. **minor (hostile sync, latent until A34): an absurd-but-finite synced `kg` can throw while building the weight card or the sheet.** `weight_text.dart:13` computes `kg * 1000 / unit.grams`; for `kg` above ~1.8e305 the product is `Infinity`, and `signedWeightNumber` (`weight_text.dart:47`) calls `.round()`, which throws `UnsupportedError` on `Infinity` (checked: `(double.infinity * 10).round()` throws; `1e300.round()` clamps). The trend only drops non-finite / non-positive kg, so such a row reaches `weightRateText` (card, `weight_card.dart:83`) and `weightDiffText` (the large-change confirm in the sheet). In release the card is replaced by an error box on every day page after that date, which also hides row 2 (the only edit entry before A15). **Not reachable today:** only the handler writes (20–500 kg), and the wire caps `kg` at 1e12, so A34's decoder must enforce the schema maximum. **Fix (cheap, any time before A34):** treat kg outside a sane read range (e.g. `0 < kg ≤ 1e6`, or the wire's 1e12) as unreadable in `TrendWeight.compute`/`WeighInCheck`, and make `signedWeightNumber` return the plain number for non-finite input; add a test with `kg: 1e306`.
2. **minor (hostile sync): an unreadable live row blocks the trend choice for its day.** `WeighInOpHandler._choose` (`weigh_in_op_handler.dart:86-97`) compares the op's list with *every* live row of the day, but the UI only lists rows `weighInOf` can read (`weigh_in_repository.dart:80-86`). A wire-valid row the domain can't read (e.g. `measuredAtUtc` between 8.64e15 and 2^53, beyond `DateTime`'s range) on that day makes every `ChooseTrendWeighIn` fail as `sourceChanged`, so logging with "Use this weigh-in for the trend" on that day always shows "This weigh-in changed since you opened it". Logging without the switch still works; no lockout. **Fix:** in `_choose`, build the membership set only from rows `weighInOf` accepts (and leave unreadable rows' flags untouched), or tombstone-proof them in A34's decoder.
3. **minor (test gap): the D13 neutral-copy test misses the card strings.** `weight_text_test.dart:54-82` checks 11 sheet/snackbar strings but not `weightCardSparse`, `weightCardStale`, `weightCardTip`, `weightCardEmpty`, `weightCardTrendFrom`, `weightCardRateLater`, `weightCardLast`, `weighInNoteHint`, `weighInSameDay`. All are neutral today (inspected), but a future edit wouldn't be caught. **Fix:** iterate every `weight*`/`weighIn*` key of `app_en.arb` instead of a hand list.
4. **minor (doc, close item): the deferred `weighIn` v2 is recorded only in the card and the tripwire message, and both still say "after B18 merges, before A34 Phase B".** B18 is on `main` (`8eb1b81`) and the orchestrator now plans v2 in B19. **Fix at close:** add the backlog item, a line in B19's (and A34's) Scope listing the four fields with their constraints (`tzOffsetMin` integer −720…840, `inputValue` number ≥ 0, `inputUnit` enum `kg|lb`, `preferredForDay` boolean) and the D7 upgrader, and update the tripwire reason (`weigh_in_migration_test.dart:205-210`) to name B19.
5. **minor (cosmetic, hostile sync): the pad prefill can show exponent text.** `WeighInFormState._bufferText` (`weigh_in_form.dart:344-349`) guards `digits > maxDigits` with `indexOf('.')`, but `toStringAsFixed` returns `"1e+21"` (no point) for values ≥ 1e21, so a synced `input_value` of 1e21 prefills "1e+21" (Save stays off as out of range; one backspace gives "1e+2" = 100). **Fix:** return `null` when `value >= 10^maxDigits` before formatting.
6. **nit (residual, cross-cutting): tombstones keep `kg` and `note`.** `DeleteWeighIn` (and undo of a log) tombstones the row with its content, which undo needs. It stays in the local DB indefinitely (export excludes it) and A34 will push the full tombstone; B18 finding 5 set a scrubbing rule for chat tombstones. **Decide in B19/A34:** whether weigh-in tombstones scrub `note` (and `kg`) once the undo window has passed, consistently with A23.

## Privacy check

**Pass.** No weight value or note reaches logs, Sentry events/breadcrumbs, analytics, domain events or `toString` (inspection of every new type and call site; `PiiScrubber` unchanged and allow-list based; executed `toString` test). The `shared_preferences` tip store holds a date and a boolean only. No AI path, no network call, no identity involved. Values appear only where the user sees their own data (card, sheet, undo snackbar, accessibility labels) and in the user-initiated export (AC-030, intentional, live rows only, CSV formula protection).

## Residual risks for the owner

- Sync-time robustness (findings 1, 2, 5) depends on A34's decoder enforcing the wire schema (kg ≤ 1e12, a readable `measuredAtUtc`). None is reachable before A34; fixing 1 and 2 in the app is cheap and recommended before then.
- Deleted weigh-ins keep their value and note in the local tombstone (and, after A34, on the server until compaction): a policy decision for B19/A34 (finding 6), not a leak.
- Weight is in the Android backup scope like the rest of the profile DB (pre-existing A11 decision, unchanged here).

## Verdict

**Approve with findings.** No blocker or major. The write path is single-writer, validated inside the transaction, version-checked and undoable; no weight value or note leaks to logs, crash reports, events or preferences; export and neutral copy are as intended. Findings 1–5 are minor (1, 2, 5 latent until A34 sync; 3 a test gap; 4 close-time records). Recommended: fix 1–3 in this step or an early follow-up (small, app-only), file 4 at close, and carry 6 into B19/A34 planning. No owner decision is needed.

## Verifier (2026-10-29, lane 3, `8ac581c`)

Fresh `verifier` run on `step/A14-weigh-ins-trend` at `8ac581c` (after the review fixes `4f4aa7e`, `8ac581c`), clean tree. `git fetch origin`: `main` is still `8eb1b81` (= merge base), so no rebase is needed.

### Commands

| Command | Result |
|---|---|
| `heavy.sh make check-dart` | exit 0: format and analyze clean, `app-check: OK` (290 lib files, 16 patrol files), frozen-migrations self-test and check OK |
| `heavy.sh make gen-check` | exit 0: `gen-check: OK`, `git status --porcelain` empty afterwards (no diff) |
| `heavy.sh make test-dart` | exit 0: mobile **1554 passed, 2 skipped**; fb_domain **522**, coverage **100.0 % (4910/4910)**; fb_text 56 (100 %); fb_api_client 16, fb_design_system 194, app_check 79, catalog 139, trace 33, buddy_eval 11, sync_sim 8 (10 packages passed) |
| `heavy.sh flutter test test/features/body test/features/today/presentation/today_weight_test.dart test/drift/user/weigh_in_migration_test.dart` | **106/106 passed** (targeted re-run) |
| `heavy.sh dart test test/body` (fb_domain) | **44/44 passed** (glados properties at 1,000 runs each, `propertyRunCount`) |
| `make trace` | exit 0; R1 151/319 covered. All 9 card spec IDs are in "R1 covered": WB-001, WB-003, WB-004, WB-005, WB-010, WB-011, WB-012, HM-005, UX-005 |
| `git fetch origin main && tools/scripts/check-frozen-migrations.sh` | OK, no shipped migration or dump changed (v5 is new) |
| `make check-sync-schemas` | exit 0 |
| `git diff --stat origin/main...HEAD -- contracts packages/fb_api_client backend apps/mobile/lib/app/router` | empty (D14: no contract, client, backend or router change) |

### Exit criteria

| Criterion | Status | Evidence |
|---|---|---|
| A weigh-in is logged in 3 taps from Today (integration test counts taps) | ✅ host · ⚠️ device | Host `WB-001 UX-005 a weigh-in is logged in 3 taps from Today` (`today_weight_test.dart`) counts the taps that aren't digits: card + Save = 2 (prefilled, row stored for today, card updated), card + Save + "Save 101.0 kg" confirm = 3; it passed. **Remaining gate:** Patrol `A14 weigh-in from Today in three taps` (`patrol_test/weigh_in_test.dart`, offline, asserts `taps == 2`, `2`, `3` and the stored rows) runs on the emulator in CI on the `[it]` close commit |
| Trend properties: min/max, converges to a constant, single outlier moves it partly | ✅ | `trend_weight_test.dart` glados properties (1,000 runs each): `the trend stays within the min and max of the inputs so far` (running min/max per point), `a constant series gives that constant exactly`, `from a trend T₀ ≠ c … ≤ (1 − α(1))ⁿ·\|T₀ − c\|` (PA12), `one outlier … moves the trend by α(gap) of its distance, never more than 75 %`, plus order and duplicate invariance. Scenarios: weekly, daily noise, 3-week gap, single outlier, 90-day gap |
| Implausible-value tests (3 % rule, unit mix-up) | ✅ | Domain `weigh_in_check_test.dart`: `>3 %` (97 → 100), exactly 3 % (99.91 / 94.09 pass, 99.92 asks), 7-day window, backfill, 214 kg ↔ lb both ways, unit before large change, first weigh-in, edit without itself. Sheet: `WB-005 an implausible change shows the in-sheet confirm…`, `WB-005 Did you mean lb: Save as lb stores 214 lb / 97.07 kg` |
| Goldens for the weight card and pad | ✅ | `weigh_in_sheet_golden_test.dart` (prefilled, large change, unit, same day, edit) and `weight_card_golden_test.dart` (empty, one, trend + rate + sparse + tip, stale, past day), light/dark × 1.0/2.0, all pass; 10 PNGs under `test/features/body/presentation/goldens/ci/`; Today goldens regenerated |

### UX review M1 (confirmed by tests)

- **The pinned action becomes the confirm, with no duplicate Save:** `WB-005 an implausible change…` asserts `button('Save')` findsNothing, `button('Save 100.0 kg')` findsOneWidget and no `FbButton` inside the `FbInlineBanner`. The unit test asserts "Keep kg" and "Save as 214.0 lb" with no plain Save. The `weigh_in_sheet_large_change` golden shows the banner as a message only, with two pinned answers.
- **A double tap stores nothing:** `M1 an implausible value and a double tap on Save store nothing` (the 2nd tap before the next frame, then a tap on "Save 100.0 kg" inside 300 ms → 1 row only, confirm still shown). `M1 a likely unit mix-up and a double tap on Save never store 214 kg` ("Keep kg", which would save 214 kg, and "Save as" inside the guard → nothing; after the guard "Save as 214.0 lb" stores 214 lb, never 214 kg). `a double tap on Save logs once`. Code: `weigh_in_sheet.dart` `_save` returns early while `!_confirmArmed` for confirm answers **and** for a Save that reaches an open confirmation. The guard is `Timer(300 ms)`, armed when the confirmation appears.

### TD-088 vs code

TD-088 (Proposed) says the rate is "hidden when the last weigh-in is 28 or more days old". `WeightTrend.asOf` uses `daysUntil(date) >= config.staleAfterDays` (28), and `fb_domain` README says "No rate when `date − D ≥ 28`". Test `WB-012 asOf(date): no weekly rate when the last weigh-in day is 28 or more days before the date` pins day +27 (rate) and day +28 (stale, no rate). **Match.**

### DoD (`10` §9)

1. Spec IDs implemented, deviations recorded: ✅ (WP4a deviations in the Progress log, TD-088 Proposed).
2. Domain and handler edge cases tested: ✅ (fb_domain 100 %; handler: stale version, identical draft, future, negative time, invalid draft, membership incl. unreadable rows).
3. UI states, light/dark, text scale 2.0, goldens: ✅ (`UX-050` empty, `UX-051` skeleton + Try again for the card and the sheet, golden matrix).
4. Offline: ✅ (`app-check` rule 3: no `core/api` in `features/body`; grep empty).
5. Writes through change sets with undo: ✅ (handler + actions undo tests).
6. Strings in ARB, no left/right: ✅ (`app-check: OK`; neutral-copy test iterates every `weight*`/`weighIn*` key).
7. API changes: n/a (no contract diff); migration v4→v5 with test + tripwire (names B19): ✅.
8. Traceability tags 9/9: ✅. CI on the branch: ⚠️ the `ci` run with `[it]` on the close commit is the remaining gate.
9. Performance: ⚠️ the card is on every day page (hot path). `today_perf_test` only changed labels; the device numbers come from the `[it]`/nightly emulator run.
10. Docs: ✅ README "Weight trend", TD-088 row, `docs/export-format.md`. **Close items (orchestrator, Phase E):** card Outcome, TD-088 → Accepted at merge, B19 Scope line, backlog `FbUnitOption.semanticLabel`, status board.

### Nits (no action required)

- `weigh_in_sheet_golden_test.dart:63-64` comment "a confirmation adds a Save above the pinned one" predates M1 (the answers now replace it).
- `weigh_in_sheet_test.dart:438` comment "Keep kg after the guard" is followed by a tap on "Save as 214.0 lb".

### Verdict

**PASS pending the `[it]` CI run:** every exit criterion is met on the host. The remaining gate is Patrol `A14 weigh-in from Today in three taps` (and the shifted Today journeys, D15) on the emulator via the `[it]` close commit.
