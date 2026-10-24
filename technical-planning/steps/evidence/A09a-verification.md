# A09a verification (2026-10-24)

Tier **Risky** (user-data write path and a sync contract, `PROCESS.md` A.2). Built by Codex (WP1–WP3 and the security fix round) and Claude flutter-engineer (WP4–WP5, review fix round). This file records the write-path evidence, the reviews and the device run.

## Write-path properties → tests

| Property | Tests (spec IDs first) |
|---|---|
| Only `ChangeSetApplier` writes; every op has an exact inverse (A01 D3 state comparison incl. outbox) | `apps/mobile/test/features/foods/data/personal_food_ops_test.dart`: `FD-070 CreatePersonalFood inserts one row …`, `FD-073 UpdatePersonalFood changes only the food: entries …`, `FD-073 UpdatePersonalFood with the same draft writes …`, `FD-073 DeletePersonalFood tombstones the food; entries keep …`, `DY-031 DeleteSavedMeal tombstones the meal and its live …` |
| **Exit criterion:** merging keeps every logged snapshot | `FD-073 merging B into A: every live diary entry and saved …` (+ Undo), `FD-073 an entry relinked by a merge and edited before Undo …`, `FD-073 a saved item relinked by a merge and changed before …` (atomic Undo rejects), `FD-073 merge rejects (nothing written): the same food, a …`, `a change set whose second op fails (RelinkFoodRefs rejects …` |
| Relink scope (personal → live personal only; untouched: other kinds, tombstones, `edited_by_user` rows stay relinked but unchanged) | `RelinkFoodRefs touches only live rows with that kind and …`, `FD-073 RelinkFoodRefs requires a live personal destination`; fb_domain `FD-073 RelinkFoodRefs rejects non-personal and identical refs` |
| Guarded repeat logs write exactly what the user saw, or nothing (D19) | `FD-073 RequirePersonalFood with LogEntries: the food …`, `FD-073 the survivor of a merge shown before the merge → …`, `DY-031 LogSavedMeal rejects with nothing written when, …`, `DY-031 LogSavedMeal rejects a same-count item replacement`, `DY-031 LogSavedMeal on a meal whose live items are all gone …`, `DY-031 LogSavedMeal keeps explicit instants and rejects …`; application `LogFood refuses a guard for a different logged food ref` |
| Bounds (§3.0) and wire validation separate from app-only sanity; sanity warns but stays saveable | fb_domain `packages/fb_domain/test/food/personal_food_test.dart`: `FD-070 each §3.0 bound accepts its limit and rejects just …`, `FD-070 NaN, ±infinity and 1e308 are rejected for every …`, `FD-070 personal foods obey 05 §5.5 wire representability …`, `FD-071 wire validation excludes app-only sanity`, `FD-001 Gtin accepts valid GTIN-8/12/13/14 and rejects a …`; SQL: `FD-070 SQL checks reject half entry servings and negative values` |
| One unreadable stored row never hides the others; unknown extras/state survive a rewrite; no values escape in errors | `FD-071 corrupt personal rows do not hide readable rows`, `malformed stored JSON in a personal food row surfaces a …`; fb_domain `toString of every personalFood op, LogSavedMeal, …` |
| Saved-meal rename/delete | `DY-031 RenameSavedMeal trims to 1–60 characters; a stale …`, fb_domain `DY-031 RenameSavedMeal rejects NUL without content` |
| Migration v1/v2/v3 → v4 (additive, `(food_kind, food_id)` partial indexes) | `apps/mobile/test/drift/user/personal_food_migration_test.dart`: `migration v3 → v4 keeps every row and adds personal_foods …`, `migration v2 → v4`, `migration v1 → v4` |
| Merge cost | `A09 perf merge relinking 1,000 entries and 50 saved items …` |
| Contract `personalFood` v1 | `contracts/openapi/sync-entities.json`, fixture in `contracts/testdata/sync/entity-payloads.json` validated by `make check-contract`; semantic rules for the server in B17 |

Gates on every WP commit: `make gen-app catalog-pack check-dart test-dart trace`, plus `make gen-check` and `make test-dotnet` (orchestrator, Docker). `fb_domain` line coverage 100% (2,304/2,304 at the security round).

## Security review (Claude security-reviewer, separate from the Codex builder; `PROCESS.md` Part B)

- **Round 1** (WP1–WP2): approve with findings, no blockers. Major: one bad stored row (app-only sanity, unknown extras key or state) broke the whole list. Minors: `RelinkFoodRefs` scope, a value-leak path in `planLogSavedMeal` mapping. Nits: survivor aliases, NUL in `RenameSavedMeal`, missing `(food_kind, food_id)` indexes, test gaps. All fixed in 4ff340e (Codex). Also: B17 now names UTF-16 lengths, Dart `trim()` parity, duplicate-key rejection and no sync sanity rule; backlog #98 (A34 version-only guards).
- **Re-check:** approve. Nits moved to the backlog at close (#99–#102).
- Privacy check: pass (no log, print or telemetry added; no values in `toString` or errors).

## Code and UX reviews (UI, WP3–WP5)

- Codex code review (b6c00d9): changes required, no blockers: (1) new-food forms shared state across tabs, (2) Reload changed the meaning of typed per-serving numbers, (3) duplicate Save and a pending outcome that popped the form, (4) the search round trip lacked a fixed clock, past day and explicit meal.
- ux-reviewer: 3 majors (form order with "More details", merge confirm with both foods, stale-banner Reload) and 10 minors/nits.
- Fix round 1: e4154ae, 079223c, 8a43fa1 (verified item by item by an Opus flutter-engineer). Codex re-check (8a43fa1): **approve**, no new findings.
- Creation Undo is skipped in the search → food sheet flow (the sheet would cover it; the user is about to log the food anyway).

## Device

CI `android-it`: Patrol `OF-01 FD-070 FD-021 create a personal food offline and log it from search` (WP5) plus the A08 journeys on the shared `patrol_test/support/patrol_support.dart`. Green on 6c48f25 (15 tests, 5 min 11 s, first attempt, job 120606125322). On 8a43fa1 (review fix round, no device-test, Android or start-up change) the emulator started no test within the 15-minute attempt and the retry ran 0 tests in 11 s: no test output, so an infrastructure failure, not a test result. The first merge attempt (squash 3b6a0eb) then ran all 15 tests: 14 passed and `app_test` UX-010 failed, still expecting the Me screen's old empty-state text that UX item 9 removed (the host shell test had been updated, the Patrol test not). Fixed to `Your foods`, like the host test; the merge commit's green `android-it` is the gate (`merge-step.sh` moves `main` only on a green `ci`).

## Also fixed

- A08a's date-picker golden rang the real today and would have failed on `main` from 2026-10-24; `currentDate` is now pinned.
- Golden failure images committed by WP4 were removed; `**/test/**/failures/` is now ignored.
