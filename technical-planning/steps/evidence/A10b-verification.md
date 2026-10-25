# A10b verification (2026-10-25)

Tier **Risky** (user-data write path, `PROCESS.md` A.2). Branch `step/A10b-meal-slots`, reviewed implementation HEAD `a34aea4`. Codex built WP5 and completed WP6/WP7 after the earlier UI agent was cut off, including both review-fix rounds. This close-out inspected the committed tests and the card's recorded gate results; it did not rerun code tests, Gradle or the full Dart suite. Counts below are separate, overlapping runs, not an aggregate.

## Full checks

| Command / scope | Evidence | Status |
|---|---|---|
| WP5 security-fix gates | Card Progress log: `make gen-app` (no generated diff), `make check-dart`, domain `test/diary` 80 passed; app diary + foods 696 passed; core change/undo 53 passed | ✅ recorded, not rerun |
| Final WP6/WP7 review-fix gates | Card Progress log: `make check-dart`; app diary + foods + settings 788 passed; DS reorderable-list and all sheet tests/goldens 18 passed; no generated inputs or golden updates | ✅ recorded, not rerun |
| WP6 initial UI/golden verification | 60 focused app tests, 7 DS tests and six golden matrix comparisons; recovery logs separately recorded 114 app and 9 DS tests/goldens. These counts overlap the later runs | ✅ recorded, not summed |
| Domain properties / coverage | WP5: 1,000 property runs; full domain run 462 passed / 1 existing quick-add timing miss, isolated retry passed; `fb_domain lib/` 4,528/4,528 lines. Security fix: slot rules 15/15 and slot ops 95/95 lines | ✅ recorded; full coverage not remeasured after fixes |
| Earlier focused timing failures | Initial WP5 app diary/foods: 684 passed / 7 existing timing misses (day-view, merge, five search timings); each passed its isolated serial retry (search file 7 passed) | ✅ retries recorded; host timings are load-sensitive |
| `make trace`, `git diff --check` | Passed in both final fix rounds; trace retains the pre-existing ZZ-060 scanner-fixture warning | ✅ recorded |
| Full `make test-dart` / full-suite CI | Intentionally not run for this close-out; merge-commit CI is the full-suite gate | pending CI |
| `make build-it` | WP7 log: three attempts failed during Gradle initialization (`The settings are not yet available for build.`), before Dart/APK compilation; Patrol discovered a 13-test bundle | ⚠️ compilation unverified; orchestrator/CI must compile |

## Exit criteria

| Criterion (A10b) | Evidence | Status |
|---|---|---|
| 1. Imperial display, stored values unchanged | A10a; see `A10a-verification.md` | ✅ A10a |
| 2. Slot customisation and auto-assignment use the new windows (integration test) | `apps/mobile/test/features/diary/application/slot_integration_test.dart`: `DY-010 exit 2 host journey…` adds Pre-workout 17:00–18:00, renames Snacks, changes Breakfast's window, reorders, logs automatically at 17:30/10:30, removes/moves and undoes. `presentation/slots/slot_journey_test.dart`: `DY-010 DY-011 exit 2 Today follows the host slot journey and shows storage totals after every change`. PA4 proves existing entries/groups byte-identical after window/reorder changes; overnight overlap and exclusive ends have separate tests. Domain `slot_assigner_test.dart` pins shortest window, tie order, inactive/mode filtering and boundaries | ✅ host integration; Patrol pending |
| 3. Week start changes `WeekCalendar` | A10a evidence | ✅ A10a |
| 4. Settings and slot editor goldens | A10a settings matrices; A10b `presentation/slots/meal_slots_golden_test.dart`: Meal times, edit sheet, remove sheet (light/dark × 1.0/2.0); DS `reorderable_list_golden_test.dart`, `sheet_actions_golden_test.dart`; updated Me Settings matrix. Six matrices inspected in WP6 | ✅ host goldens |
| Owner: set real settings; feedback | Meal times on the A55, including text scale and TalkBack Move up/Move down; proposed backlog line in card Progress log | pending owner; not claimed |

## Write-path properties → tests → status

All data tests below are in `apps/mobile/test/features/diary/data/meal_slot_ops_test.dart` unless stated otherwise.

| Property | Evidence | Status |
|---|---|---|
| Every slot op + undo restores the exact content state, with explicit versions/outbox checks | `UX-030 every slot op + undo restores the exact state` covers Add, Update and Reorder; `UX-030 undo of a removal restores the slot and every moved entry and group exactly` covers Remove. `DiaryHarness.state()` compares A01 D3 live content (not sync metadata). `undoWithOutbox` separately preserves the entire pre-undo outbox prefix, checks exact appended row identities/count, version = post-apply version + 1, `undo:<changeSetId>` origin, matching HLC and tombstone flag. Undo is a new synced write: versions/outbox are verified, not reset to their pre-apply values | ✅ |
| Every tested rejection writes nothing | `refuses` compares complete meal-slot, entry, group and outbox rows including versions before/after each rejected op. Covers limits, bad names, missing/duplicate/inactive/wrong-mode sources, last slot, missing/invalid target, stale versions and PA1 below. Constructor validation rejects before apply. Same-value Update/Reorder assert empty inverse and unchanged outbox. Rejected undo compares those tables plus `sync_state` | ✅ |
| PA1 exact membership and observed versions, not counts | Same-count replacement → `sourceChanged`; group-only rename → `VersionConflict`, group arrival/departure → `sourceChanged`; observed entry edited → `VersionConflict`, deleted → `sourceChanged`; entry arriving after sheet opened → `sourceChanged`. Destination renamed/re-windowed/reordered → `VersionConflict`, deactivated → `badTarget`; source stale-version test. Successful removal moves exactly the observed rows and keeps dates, instants, offsets and group membership | ✅ |
| Undo guard 1: group membership | `DY-010 UX-030 undo removal rejects new group member atomically` → `sourceChanged` even when group version is unchanged | ✅ |
| Undo guard 2: live slot references | `… undo addition rejects entry arrival atomically` and `… empty group arrival atomically` → `slotInUse` | ✅ |
| Undo guard 3: combined active-slot limit | `… undo removal rejects ninth active slot atomically` and `… undo multiple removals checks combined active count atomically` → `tooManySlots`; projected count spans the entire inverse | ✅ |
| Undo rejection is atomic through both paths | `refusesUndo` checks direct applier revert and `UndoStack`, exact rows/outbox/versions/sync state unchanged; stack returns conflict then unknown (existing consume-on-rejection policy). Editing a moved entry before removal Undo also rejects atomically | ✅ |
| PA3 captured meal choices remain safe | Data test: LogEntries, MoveEntries, UpdateDiaryEntry(slot), CopyMeal reject `inactiveSlot` without writes. `food_slot_changes_test.dart` covers live labels, explicit clearing, typed input and replace-mode exemption; `slot_consumers_test.dart` and `food_sheet_slots_test.dart` cover live move/copy/food sheets and dedicated localized feedback | ✅ |
| Validation / privacy | Domain `meal_slot_ops_test.dart`: normalized names reject remaining Unicode Cc/Cf through Add/Rename; op text excludes names. No contract or migration change | ✅ |

## Reviews and UI safeguards

- Plan review PA1–PA6 accepted and resolved; PA1/PA3/PA4 are covered above. PA2 display, PA5 theme measurement and PA6 settings/loading states belong to A10a (see its evidence). Re-check R1-1/R1-2 pins replace-mode exemption and explicit nullable clearing.
- Separate Codex security session on WP5: **3 major + 1 minor fixed** in `f2a5829`: three inverse guards (including combined active count) and Unicode-control name validation. Regressions observed failing before fixes; card records the final passing gates.
- Codex code + UX review of WP6/WP7: **2 major + 1 minor fixed** in `a34aea4`: synchronous single-submit guard; feedback/Undo survives back, barrier and drag dismissal; disabled reorder rows retain labels without move semantics. Tests cover queued Add/Save, pending save and historical-removal dismissal with Undo, disabled semantics and scroll position across pending-mode changes.
- `meal_slots_screen_test.dart` covers stale/reload, live removal counts, changed destination, duplicate labels, eighth/last-slot limits, accessible Move up/Move down with Undo and scale 2.0. This is host accessibility evidence, not an A55 TalkBack run.

## Performance and device checks (not run here; not claimed)

| Item | Evidence / status |
|---|---|
| Removal benchmark, host only | 1,500 entries + 100 groups across 365 days; 3 warm-ups + 20 measured runs. Initial WP5 apply p95 **143.735 ms**, undo **130.935 ms**; security-fix rerun apply **154.281 ms**, undo **162.522 ms**; both <500 ms each. No device measurement |
| Patrol `A10 meal slots journey add window remove` | `apps/mobile/patrol_test/meal_slots_test.dart`; compilation gate `make build-it`, execution gate CI `android-it`. Neither successful compilation nor execution is claimed here; recorded local compilation attempts failed before compilation |
| A55 owner check | **pending**: real Meal times, persistence, text scale, TalkBack Move up/Move down, add/window/remove/move/Undo and responsiveness |

## Remaining gates / known issues

Merge-commit CI must pass the full suite and `android-it`; the orchestrator must obtain successful APK compilation. Host timing passes do not establish A55 responsiveness. Large removal must remain atomic; if device latency exceeds about one second, consider a progress line. A34 owns concurrent remote writes into inactive slots / group repair (existing backlog #63); A41 owns Ramadan editing. No owner/device item is marked complete.
