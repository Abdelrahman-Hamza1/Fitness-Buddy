# B21 verification (2026-10-30)

- **CI:** evidence comes from the merge run (TD-108); no branch push.
- **Commits:** 2e59f08 (WP1 contract), 394c689 (WP2 fb_domain, corpus, parity), e3c5d03 (WP3 validator), 022e5d8 (WP4 persistence, revival, erasure, privacy), 6aea537 (outcome draft).
- **Codex combined review (read-only, fresh task: correctness, architecture, security/data integrity):** **APPROVE, 0 blocker, 0 major, 0 minor.** Confirmed W1–W5 parity, schema and table alignment, validator dispatch and failure codes, LWW, tombstones and R14 revival, RLS and auth, erasure and privacy, test coverage, the embedded registry equal to the contract, and existing entity schemas unchanged. No fix-check was needed.
- **Migration / deploy hold:** no EF migration, no data change, no deploy hold (D12: registry and validator ship in one merge).

## Exit criteria

| Exit criterion | Evidence |
|---|---|
| Contract conformance green; the Dart client regenerated | `make gen` (no client diff: no OpenAPI change), `make check-sync-schemas`, `make check-dotnet`; CI `contract` job on the merge run. Tripwire `B21 workout fixtures map 1:1 to the table columns both ways; every content column is on the wire` (`workout_contract_test.dart`). `Embedded_schema_vocabularies_and_bounds_equal_contract_and_corpus` (`WorkoutPayloadTests`): embedded registry = contract |
| Admission tests reject rule-breaking rows | `WorkoutPayloadTests`: `Wire_rules_accept_valid_and_reject_each_violation` (W1–W5), `Payload_matrix_matches_admission_for_live_and_tombstone` (corpus + schema matrix, live and tombstone), `Nested_json_fields_reject_non_arrays_non_strings_and_ill_formed_utf16`, `Not_wire_rules_are_admitted`, `Workout_validator_fails_closed_for_unregistered_versions_and_other_entities`, `Fail_closed_validators_cover_exactly_their_registry_versions`, `Readme_workout_rules_equal_corpus_rules_and_each_has_accept_and_reject_cases`. `WorkoutSyncTests`: `Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions` (ordered `invalidPayload`, invalid versions never stored) |
| Deletion erases every workout row | `WorkoutSyncTests.Delete_account_erases_workout_live_history_fences_and_receipts_and_preserves_second_owner` (real `DELETE /v1/me`; zero-row inventory for all 7 entities: live, history, fences, receipts; second owner untouched) |
| Security review recorded (Risky) | Codex combined review above: APPROVE, no findings. RLS and auth: `Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned` (x7), `Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401`. Privacy: `B21_workout_names_and_values_never_reach_errors_logs_or_telemetry` (`IdentityPrivacyTests`; canaries for exercise, alias, session and template names, Arabic name, a `kg` value; accepted, W1/W3/W4/schema-invalid and guest legs) |
| (plan) LWW and tombstones | `Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable` (x7), `Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection` (x7) |
| (plan) R14 revival accepted | `Revived_children_are_newer_live_versions_before_and_after_compaction` (sessionExercise, workoutSet); `Aggregate_children_are_admitted_in_any_order_and_across_aggregates` (no cascade) |
| (plan) app parity | fb_domain: `B21 generated vectors match committed bytes`, `B21 untagged cases have serverAccepts equal to WorkoutWireRules...`, `B21 workout fixtures satisfy every wire rule`, property `WO-004 any SetValues that issueFor accepts...`, `WO-003 WO-020 valid drafts satisfy W1, W2, W4...`. App: `B21 every server-accepted corpus payload stores in the real tables`, `WO-003 WO-010 WO-020 WO-021 corpus payloads read through WorkoutRepository as declared`, `WO-003 WO-010 WO-020 drafts written by the real column writers equal accepted corpus payloads`, `WO-021 WorkoutWireRules.planDayIds equal planDayId for all seven weekdays`. The C# server agreed with all 321 corpus declarations, live and as tombstones, on the first run |

## Metrics
- **Tests:** 28 named tests (5 fb_domain, 5 app, 9 C# pure, 8 Testcontainers, 1 privacy); `WorkoutPayloadTests` 630 cases, `WorkoutSyncTests` 27 cases, corpus 321 cases.
- **Review:** 1 combined Codex round, APPROVE, 0/0/0.
- **Size:** planned M–L (~2.3 sessions); one merge, no split.
