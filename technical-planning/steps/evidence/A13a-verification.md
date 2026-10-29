# A13a verification (2026-10-29)

Tier **Risky** (user-data write path, three new synced tables + migration v4 → v5, op family `targets`, three new sync entities, SF-012 acknowledgement; body data: sex, birth year, height, goals, target kcal). Built by Claude (flutter-engineer / dotnet-engineer agents, orchestrated). This file records the Phase D **security & privacy review** (Claude Opus `security-reviewer`, did not write the code) and the evidence it ran. Range reviewed: `origin/main` cd1d4e8 … `step/A13a-targets-storage` 9d72091 (11 commits, 65 files).

## Scope reviewed

- `packages/fb_domain/lib/src/targets/`: `target_records.dart` (wire codecs, `mayStayBelowFloor`, `toPlan`, `TargetSettingsRevision`), `target_rules.dart` (`TargetRules.wire` / `.input`, PA6), `target_ops.dart`, `target_events.dart`, `target_outcomes.dart`, `targets_timeline.dart` (read projection), `goals.dart` / `target_settings.dart` / `target_calculator.dart` diffs (conflict sets, `floor`).
- `apps/mobile/lib/core/db/` (`tables/target_tables.dart`, `targets.drift`, `sync_triggers.drift`, `migrations/from_4_to_5.dart`, `app_database.dart`), `core/export/export_registry.dart`, `app/app_scope.dart`.
- `apps/mobile/lib/features/targets/` (`data/targets_op_handler.dart`, `target_mappers.dart`, `targets_repository.dart`; `application/targets_actions.dart`, `targets_providers.dart`, `setup_input.dart`, `body_weight.dart`).
- Contract: `contracts/openapi/sync-entities.json` (`profile`, `goalPhase`, `targetSettings` v1), fixtures, `contracts/README.md` "Targets semantic rules", regenerated `backend/.../Schemas/entities.json`; `technical-planning/steps/B19-body-targets-sync.md` (outline).

## Write-path properties → tests

| Property | Evidence |
|---|---|
| Only `ChangeSetApplier` writes the three tables | `WriteGuard` + `app_check` single-writer rule (OK, 283 files); grep: the only writes are `RowOp`s planned in `TargetsOpHandler`; the repository reads via `readSnapshot` |
| Wire rules always, input rules on changed fields only (PA6), new-conflict-only rejection (PA2), PA9 row ops, every rejection writes nothing (rows + outbox), exact undo | `targets_op_handler_test.dart` (14 tests: `PutProfile create over a live row → VersionConflict …`, `PA9 …`, `TG-012 a phase write that creates a new overlap → phaseOverlap …`, `an existing synced overlap still allows …`, three `PA6 …`, `D15 the wire rules always apply …`, `every targets op and its undo restore the exact prior state, outbox …`, `a change set mixing settings and targets ops is atomic …`) |
| SF-012: below-floor / above-1%-loss manual target needs acknowledgement, nothing written without it; forced fixed below the floor; PA7 refusals | `targets_actions_test.dart`: `SF-012 setManualTarget below the floor without acknowledgement → NeedsAcknowledgement …`, `SF-011 SF-012 a manual target implying more than 1%/week loss needs …`, `PA7 SF-012 switching an acknowledged below-floor manual target to weekly budget is refused, nothing written (also rebalancing and shifting)` |
| Read projection is the last guard (below-floor manual shown only if acknowledged + fixed, else raised + `manualNeedsReview`; generated raised) | `targets_timeline_test.dart` (SF-010 / SF-012 tests and the 1,000-run property "never below the floor unless manual, acknowledged and fixed") |
| Tolerant decode of synced rows (skip + count, never thrown or logged) | `targets_repository_test.dart`: `tolerant decode: an unknown enum or broken pair in a synced row skips that row and counts it; an out-of-range shift weight reads as 1.0; no exception, no values logged` |
| Content-free `toString` (PA14) | fb_domain `target_ops_test.dart` `toString of every targets op, record and command outcome …`; app `PA14 toString of the targets inputs, patches, previews and outcomes …` |
| Contract ↔ tables ↔ Dart (PA8, D3) | `targets_contract_test.dart`: `PA8 for each of profile, goalPhase and targetSettings the v1 …`, `D3 the contract vocabularies and bounds equal the Dart ones` |
| Migration v1–v4 → v5 additive, data kept | `target_tables_migration_test.dart`: `migration v4 → v5 keeps every row and adds profile, goal_phases and target_settings with their indexes and outbox triggers`, `migration v1/v2/v3 → v5` (data integrity); `check-frozen-migrations.sh` OK |
| Export covers the three tables, live rows only | `export_test.dart` (registry ↔ `docs/export-format.md`), `export_snapshot.dart` `WHERE deleted_at IS NULL` |

## Commands run (this review)

| Command | Result |
|---|---|
| `git fetch origin`; `git diff origin/main...HEAD` | 11 commits, 65 files reviewed |
| `dart test test/targets` (packages/fb_domain) | **67 passed** |
| `tools/scripts/heavy.sh flutter test test/features/targets test/drift/user/target_tables_migration_test.dart test/core/export test/core/db` (apps/mobile) | **125 passed** |
| `tools/scripts/heavy.sh make check-sync-schemas check-contract` | OK (bundle, lint, self-test, breaking: none vs cd1d4e8, conformance OK) |
| `tools/scripts/check-frozen-migrations.sh` | OK, no shipped migration or dump changed |
| `dart run tools/app_check/bin/app_check.dart apps/mobile` | OK |
| grep of the diff for `print`/`debugPrint`/`log(`/Sentry/breadcrumbs and value-bearing `toString` | none added; every new type's `toString` is content-free |
| Scratch probes (outside the repo, path dependency on `fb_domain`): 20,000 random **wire-valid** hostile rows into `TargetsTimeline.day` / `explain`; targeted cases; acknowledgement-scope scenario | `explain` never throws; `day` throws for extreme basis weight / height (finding 2); scenario for finding 1 reproduced |

Not re-run here (orchestrator gates, Progress log 2026-10-28/29): full `make test-dart`, `make test-dotnet`, `make gen-check`, `make trace`.

## Findings

No blocker, no major.

1. **minor: a rate-only acknowledgement later counts as a below-floor acknowledgement.** `packages/fb_domain/lib/src/targets/target_records.dart:518` (`mayStayBelowFloor = manual && acknowledged && fixed`) with `apps/mobile/lib/features/targets/application/targets_actions.dart:373` (`acknowledged: warnings.isNotEmpty`). Path: `setManualTarget(1600, acknowledged: true)` where only `manualLossRateExceeded` applies (female, 170 cm, 80 kg, high activity: floor 1,522) → `setMode(fixed)` (allowed) → `saveProfile(sex: male)` (manual: no recompute) or, after A14, a rising trend weight → floor 1,688; probe: `TargetsTimeline.day` shows 1,600, `raisedToFloor false`, `issues {}`. The user never saw the below-floor warning (SF-012). Fix (pick one, A13a or before A13c's warning UI): (a) `saveProfile`/projection re-check: when the current version is an acknowledged manual target and the new floor rises above its base, return `TargetsNeedsAcknowledgement` from `saveProfile` and flag `manualNeedsReview` in `TargetsTimeline.day` when the base is below the floor at the version's basis weight/effective date only because the floor rose; or (b) store what was acknowledged (contract change). Leaving it as is is a safety trade-off → owner decision.
2. **minor: `TargetsTimeline.day` throws on wire-valid but implausible synced numbers.** `packages/fb_domain/lib/src/targets/targets_timeline.dart:208` (`version.toPlan(floor)`) and `:233` (`plan.day`) aren't inside `_tryEngine`, so `basisWeightKg` ≥ ~1e5 or `heightCm` ~1e6 (floor > `TargetLimits.maxNumber`) throws `ArgumentError`, contrary to the doc ("null … when the profile can't be evaluated"). `dayTargetsProvider` then errors (no app crash; Today's error banner in A13b), and until A14's trend is wired no command repairs it (`recalculate`/`useCalculatedTarget` → `goalNeedsUpdate`/`invalid`; other revisions copy the basis weight; the PA6 rule doesn't re-check a copied value). Not reachable locally (input 20–500 kg); sync is off until A34 and B19 admits these values (plausibility is app-only). Fix: wrap both calls in `_tryEngine` (return null), and in `TargetsActions._weight` treat a basis weight outside `TargetRules.input.weight` as unusable so `recalculate` can repair from a weigh-in/typed weight; add a `basisWeightKg: 1e5` test.
3. **minor: an unreadable live profile row has no recovery path.** `targets_actions.dart:386` + `targets_op_handler.dart:62`. A synced profile with an unknown code (newer app, D17 "row skipped") or wire-invalid value makes `data.profile` null, so Today/Me offer setup, but `completeSetup` returns `alreadySetUp` (settings exist) or `changed` (VersionConflict on the live row) and `saveProfile` returns `removed`. No crash or data loss. Fix (A13b): expose "profile present but unreadable" in `TargetsData` (`skippedRows` doesn't say which) and show "Update the app" instead of the setup row; don't overwrite the newer row.
4. **minor (defence in depth, forward): the handler accepts `acknowledged: true` from any origin.** `targets_op_handler.dart:123–163`. SF-012 is enforced only in `TargetsActions.setManualTarget`; any future change-set builder (A38 check-in proposals write versions "with a proposal origin", §7 forward notes) could write an acknowledged below-floor fixed version that the projection honours. Fix: in `_settings`, reject (`InvalidOp('invalid')`) a record whose `acknowledged` is true when the row it revises/supersedes wasn't acknowledged, unless `context.origin is OriginDirect`; one handler test. At minimum, record the rule on A38's card.
5. **minor (docs): the B19 card's wire-rule list differs from `TargetRules.wire` and the README.** `technical-planning/steps/B19-body-targets-sync.md:15` adds "direction consistent with `goalType`" (not a Dart wire rule: the app reads a direction mismatch as `goalNeedsUpdate`, and `saveGoal` on a non-active phase doesn't resolve it, so a server enforcing it could reject app-written rows) and leaves out the positivity rules (`heightCm`, `targetKg`, `baseKcal`, `basisWeightKg` > 0) and percent ≤ 100 that the README lists. Fix: B19's Scope references the README list verbatim and drops "direction".
6. **nit (docs, contract README):** the README's wire-rule list matches `TargetRules.wire` (positivity incl. the `targetRate` positive speed, expression fields, maintain, phase dates, macro pairs + percent ≤ 100, acknowledged ⇒ manual). Add: (a) row IDs: the app skips `goalPhase`/`targetSettings` rows whose ID isn't UUIDv7 and reads only the profile ID `naturalId('profile','self')`. Make it a B19 wire rule or note "ignored by the app"; (b) `month` "the month's first day, as the app writes it" is a convention the Dart rules don't enforce, so say so; (c) for A34: the server admits whole-number `1990.0` as an integer but `TargetRules.wire` needs a Dart `int`, so the downloader must convert `num → int` (the B18 note) or the row is skipped.
7. **nit:** drift-generated `ProfileRow` / `GoalPhaseRow` / `TargetSettingsRow` (and companions) have value-bearing `toString`s. Nothing logs them today (grep), same as the existing tables; the table header says "never log row values".

## Privacy check: **pass**

- Logs/telemetry: no `print`, `debugPrint`, logger, Sentry or breadcrumb call added. Rejections are codes (`InvalidOp('invalid' | 'phaseOverlap' | 'duplicateDate')`, `VersionConflict` with entity/ID/versions); engine `ArgumentError`s have constant messages; `PiiScrubber` replaces exception messages anyway.
- `toString`: every new record, op, event, outcome, input, patch, preview and wrapper is content-free (`ProfileRecord`, `Versioned(v3)`, `TargetsOp.putProfile(update)`, `TargetsChanged(goals)`, `TargetsNeedsAcknowledgement(manualBelowFloor)`, `GoalInput(lose)`). Pinned by the PA14 tests.
- Undo labels: key + `kcal` arg (the recomputed target the snack bar shows, intended); `UndoLabel.toString` shows the key only.
- Export: `profile`, `goal-phases`, `target-settings` with every content column, live rows only: intentional (AC-030), documented in `docs/export-format.md`. Nothing else is added to the export.
- AI context: not touched by A13a; no body data reaches any model.
- Contract minimality: birth **year** only (no date of birth), canonical values + input units (TD-017), no weight on `profile` (TD-090), no IDs or identity beyond the envelope; fixtures are synthetic.

## Residual risks for the owner

- **Finding 1 needs a decision through the orchestrator:** fix (recommended, small) or accept. Accepting is a safety trade-off (SF-012) and so an owner item.
- Server admission of the targets wire rules is B19 (TD-080). Until then nothing uploads (A34 depends on B19), so the hostile-row cases (findings 2, 3) aren't reachable in R1 today.
- Tombstoned profile/phase/settings rows keep their content columns locally (A01 undo design, all synced tables); erasure is the account/profile deletion path (B06, AC-031).

## Verdict

**Approve with findings.** No blocker or major. Findings 1–4 are minor and should be fixed in A13a or tracked on A13b/A13c/A38 by the orchestrator. Finding 5 updates the B19 card before its Phase B; 6–7 are nits.

## Verifier (2026-10-29)

Claude Opus `verifier` (didn't write or review the code). Branch `step/A13a-targets-storage` at `56e7b38`, rebased on `origin/main` `8eb1b81` (includes B18). Started from a clean `git status`; the tree was still clean after every generator ran. Pinned toolchains (Flutter 3.47.7, `~/.dotnet`); heavy commands went through `tools/scripts/heavy.sh`.

### Full checks

| Command | Result |
|---|---|
| `heavy.sh make check` | OK: format, `dart analyze --fatal-infos` no issues, app-check OK (283 files), frozen-migrations self-test + check OK, `check-dotnet` 0 warnings, contract bundle/lint/self-test/breaking (none)/conformance OK, APK hardening self-test 26/26 |
| `heavy.sh make gen-check` | OK (API client + app gen + `check-sync-schemas`), **no diff** |
| `heavy.sh make db-migrations` | 0 outputs, 0 files changed: the committed v5 dump and steps match the code |
| `heavy.sh make test-dart` (full) | mobile **1,502 passed, 2 skipped, 1 failed**: `day_view_perf_test` P1 cold p95 **10.70 ms** (budget < 10) under full-suite load. The runner stops at the first failing member, so the other members were run separately (next two rows) |
| `DART_TEST_SHARD=app:perf heavy.sh make test-dart` (perf alone, the way CI runs it, backlog #116) | **16/16 passed**: P1 4.80 ms, P2 9.57 ms, P3 5.46 ms; Today W1 44.7 / 40.7 / 35.2 ms. A13a doesn't touch the diary day-view query, so the full-run miss is load noise |
| `DART_TEST_SHARD=packages heavy.sh make test-dart` | 9 packages passed: fb_api_client 16, fb_design_system 194, **fb_domain 515 (coverage 100.0%, 5,159/5,159 lines; gate 95%)**, fb_text 56 (100%), app_check 79, catalog 139, trace 33, buddy_eval 11, sync_sim 8 |
| Focused, expanded reporter: `flutter test test/features/targets test/drift/user/target_tables_migration_test.dart test/core/export test/core/db`; `dart test test/targets` (fb_domain) | **128 passed**; **68 passed** |
| `heavy.sh make test-dotnet` | **1,397 / 1,397 passed** (7 modules incl. Persistence/Testcontainers); catalog pack + client smoke OK. The test bins carry the new `entity-payloads.json` / `sync-entities.json`, so B18's registry-derived tests (`ChatProposalPayloadTests.Utf16Cases`, `ProductionSyncTests.Every_current_entity_round_trips…`) admit `profile`, `goalPhase`, `targetSettings` alongside `chatMessage` / `proposal` |
| `make trace` | R1 319 total, 145 covered; 2 warnings (`TD-017` used as a test-name ID in `target_records_test.dart`; the existing `ZZ-060` self-test) |
| `git fetch origin main && tools/scripts/check-frozen-migrations.sh` | OK, no shipped migration or dump changed (v5 is new; A14 isn't on `main`, so no renumber) |

### A13a exits (card §8: the engine half of exit 2, the write half of exit 3)

| Criterion | Evidence | |
|---|---|---|
| Exit 2 (engine half): Today's numbers match the engine | fb_domain `targets_timeline_test.dart`: `TG-040 TG-041 TargetsTimeline equals TargetPlan.day for a Saturday-start week…`, TG-032, D6, HM-002, TG-044, PA1, SF-010, SF-012, PA3 ×3, A12 PA5 midweek revision, TG-050, TG-021/PA13; properties at 1,000 runs (`propertyRuns`): `TargetsTimeline.day equals TargetPlan.day … never below the floor unless manual, acknowledged and fixed`, `week position plus the reserved unknown days equals accountedPastKcal minus the planned past allocation`. App `HM-001 dayTargetsProvider follows a new entry, an incomplete mark, a week-start change and midnight` (asserts kcal and week position/uncounted days after each change) | ✅ (widget/host/Patrol half is A13b) |
| Exit 3 (write half): a below-floor override needs the acknowledgement | `SF-012 setManualTarget below the floor without acknowledgement → NeedsAcknowledgement…`: `expectNoWrite` compares every synced table + `sync_outbox` + `sync_state` and the undo stack before/after; with acknowledgement → `(1500, manual, acknowledged, fixed)`. `SF-011 SF-012 … more than 1%/week loss …` (mode kept, not stored as acknowledged); `SF-012 a rate-only acknowledgement is not stored…` (review fix); `PA7 SF-012 … refused, nothing written (also rebalancing and shifting)`; handler `SF-012 a newly acknowledged manual value is rejected unless the origin is direct` (review fix) | ✅ (warning UI + SF-020 guard are A13b/A13c) |
| Exits 1 and 4 (A55 timing, goldens) | Not A13a (A13b/A13c) | n/a |

### Work-package done-whens

| WP | Done when | |
|---|---|---|
| WP1 | Own commit `bc28a0a` (contract files + PA8 test only); `check-sync-schemas` OK; embedded `entities.json` fresh with 14 entities (B18's + the 3); `check-contract` OK; `test-dotnet` green; negative monthly (`entity-payloads.json` goalPhase `monthKg -2`) and negative weekly / maintain = weekly 0 (`targets-payload-variants.json`, checked by `targets_contract_test.dart`) | ✅ |
| WP2 | `check-dart` OK; fb_domain 515 tests, 100% coverage; property tests at 1,000 runs; TD-089/TD-090 Proposed in `12`; README points to the contract rule list | ✅ |
| WP3 | Separate commit `5445f64`; dumps committed and reproducible (`db-migrations` no diff); migration v4→v5 and v1/v2/v3→v5 with data integrity; handler tests (exact undo incl. outbox, rejections write nothing, PA2/PA6/PA9, atomic mixed change set); tolerant decode; export covers every synced table (`AC-030 every synced table has an export spec`) | ✅ |
| WP4 | `gen-check`/`check-dart` OK; 30+ application tests green; `make trace` lists A13a's IDs; full `test-dart` run; write-path section above | ✅ |
| WP4 A14 seam (D8, D10 `CreateWeighIn`) | A14 isn't on `main`: `bodyWeightProvider` returns null (test `D8 bodyWeightProvider returns null until A14's trend is wired`) and `completeSetup` doesn't add the weigh-in. Planned fallback (card D8/§7): **A13b WP6 wires both** | ⚠️ deferred by plan, tracked on A13b |

### Definition of Done (`10` §9)

1 spec IDs ✅ (deviation `goalUnresolvable` recorded in the Progress log as accepted) · 2 domain + handler tests ✅ · 3 UI n/a (no UI) · 4 offline ✅ (no network in any command; local writes only) · 5 change sets + undo ✅ (`UX-030 every command records one undo entry`) · 6 ARB n/a (no UI strings; app-check OK) · 7 API ✅ (additive sync entities, breaking: none, conformance OK, no OpenAPI path or client change) · 8 traceability ✅ (24/24 A13a IDs covered), CI on the merge commit pending · 9 perf ✅ (no hot path wired yet; perf shard green alone) · 10 docs: contract README, `docs/export-format.md`, fb_domain README, TDs, B19 card ✅; **card Outcome, board status and `05` §2.2 (profile row with TD-089/TD-090) are still to do at the close** (Phase E)

### Traceability

A13a spec IDs (TG-001, TG-002, TG-010–013, TG-020, TG-021, TG-032, TG-040–044, TG-050–055, SF-010–012, UX-030): **24/24 covered** in `make trace`. TG-020, TG-042, TG-051–053 and TG-055 are covered by A12's engine tests; A13a reaches them through the projection (TG-050/TG-054 tests).

### Verdict

**PASS.** Remaining: CI green on the merge commit; the Phase E close docs (Outcome, board, `05` §2.2). Nits: the `TD-017` trace warning (a TD isn't a spec ID; use `// covers:` or drop the prefix); the full-suite perf miss is load noise (passes alone, CI runs the perf shard alone).
