# B19 verification (2026-10-29)

Tier **Risky** (sync admission of untrusted body/targets input, RLS on a shared natural row ID, account erasure, telemetry; `PROCESS.md` Part C). Built by Claude (TD-085). This is the `security-reviewer` evidence for the whole step: `git diff c420081..HEAD` on `step/B19-body-targets-sync` at `1e36fa3` (WP1 `f35ffa4` contract, WP2 `2076475` corpus, WP3 `37b75e1` validator, WP4 `f8b36f0` persistence/erasure/privacy). The reviewer did not write the code. Executed checks are kept apart from inspection-only claims.

## Scope

- **Production code:** `backend/src/Modules/UserData/Infrastructure/TargetsPayloadValidator.cs` (new, 103 lines), one hook line in `SyncPayloads.cs:28`, and the regenerated embedded `Schemas/entities.json` (adds `weighIn` v2 only; equal to `contracts/openapi/sync-entities.json`, checked by `DeepEquals` of the `entities` objects). No endpoint, migration, grant, `infra/`, `openapi.yaml`, `fb_api_client` or `apps/mobile/lib` change; no new package (`git diff --name-only`). One Dart `lib/` line: `TargetWireRules.maxPercent = 100` replaces a literal.
- **Unchanged and relied on:** `PostgresSyncStore` (push/pull/history, receipts, LWW), `SyncRetentionJob` (compaction/fences), `UserDataErasure`, forced RLS policies on `documents`/`row_history`/`version_receipts`.
- **Tests reviewed:** `UserData.Tests/BodyTargetsPayloadTests.cs` + `BodyTargetsCases.cs` + `SyncTestIds.cs`; `Persistence.Tests/BodyTargetsSyncTests.cs` (7 facts/theories), `SyncHttpSupport.cs` (helpers moved from B18), the `PersonalFoodHttp` `SchemaVersion`/`id` parameters, `IdentityPrivacyTests.B19_body_and_targets_values_never_reach_errors_logs_or_telemetry`; the corpus `contracts/testdata/sync/body-targets-validation-vectors.json` (389 payloads) and its generator; docs (`contracts/README.md`, `contracts/testdata/README.md`, `backend/README.md`, `05` §5.5).

## Properties → evidence

| Property | Evidence |
|---|---|
| **Input handling: no exception escapes admission** | Validator runs only after `Representable` + schema `Matches` (`SyncPayloads.cs:21`), inside the `try` whose filter catches `JsonException`/`InvalidOperationException`/`FormatException`/`ArgumentException` (`:39`). Every `GetProperty` target is required by the schema, and `Matches` enforces member count = property count with duplicates already rejected, so all members exist with their declared type; `GetDecimal` follows the representability pass; `GetBoolean` only on non-null booleans; `DateOnly.ParseExact` only on schema-validated `format: date` strings (and `FormatException` is caught anyway). No allocation per field, no regex, no I/O: O(1) work after the bounded generic pass (inspection). |
| Numbers: NaN/±Infinity/overflow/underflow/too many digits rejected; `-0.0` | `Numbers_reject_nan_infinity_overflow_and_unrepresentable` (`"NaN"`, `"Infinity"`, `1e400`, `1e-400`, `1e-29`, 31-digit, 2^96); wire-rule theory: `heightCm`/`targetKg`/`baseKcal` `-0.0` rejected (decimal `> 0`), maintain `kgPerWeek` `-0.0`/`0e5` accepted (decimal `== 0`), `1e-28` positive accepted; decimal-precision asymmetry cases (`100.0000000000000001` %) rejected by the server's decimal compare |
| Fail-closed by schema version | `Versions = {1}`; `Matches` returns false for any other version (`TargetsPayloadValidator.cs:39`) even if the registry gained one. `Registry_versions_equal_validator_versions_and_personalFood_stays_v1`, `Targets_validator_fails_closed_for_unregistered_versions` |
| v1/v2 confusion (`weighIn`) | Schema selected by the change's `schemaVersion`; v1 payload as 2 and v2 payload as 1 → `invalidPayload`, 3 → `unsupported`; same `(entity,id,hlc)` re-sent at another version → `versionConflict` (fingerprint includes `schemaVersion`). `WeighIn_v1_and_v2_are_each_admitted_only_by_their_own_schema`, `WeighIn_v1_and_v2_coexist_in_pull_history_and_lww` |
| TD-080 exactness / TD-089 no cross-row | `Readme_targets_rules_equal_corpus_rules_and_each_has_accept_and_reject_cases`, `Payload_matrix_matches_admission_for_live_and_tombstone`, `App_only_plausibility_outliers_are_admitted`, `Cross_row_conflicts_are_not_validated`, `Cross_row_overlapping_phases_and_same_date_settings_are_admitted_and_pulled`. The validator reads only the one `SyncVersion` (no store access) |
| **Shared profile natural ID: no cross-user collision** | Every key that holds or references a version includes `user_id`: PKs `documents(user_id,entity,id)`, `row_history`/`version_receipts(user_id,entity,id,hlc)`; every statement in `PostgresSyncStore` (receipt lookup, duplicate check, archive, upsert `ON CONFLICT(user_id,entity,id)`, page), `SyncRetentionJob` (receipt backfill, history expiry, compaction subqueries correlate `r.user_id=d.user_id`) and `UserDataErasure` filters by `user_id=$1`; forced RLS `user_isolation` on all three tables. No other module touches `userdata.*` (grep). Test: `Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned` (profile uses the one natural ID for both owners): B can't see A's live/history/fence; B's push of the same ID is accepted as B's own row and A's fence stays; raw `fb_app` session with `app.user_id=B` counts 0 of A's rows in all three tables. Test-only aging/inventory use the migrator connection and filter by `user_id` |
| Guest 403 / unauthenticated 401 | `Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401` (push of all five pairs, pull, profile and goalPhase item history) |
| **Erasure (AC-031)** | `Delete_account_erases_body_and_targets_live_history_fences_and_receipts_and_preserves_second_owner`: real `DELETE /v1/me` → 204, token revoked → 401; privileged per-entity inventory before `{1,1,2, 2,2,4, 2,2,4, 4,4,8}` (documents/history/receipts for profile, goalPhase, targetSettings, weighIn incl. 2 v1 + 2 v2 documents and history rows, 5 compacted fences) and after all zero, plus all-entity zero for the user; second owner (same profile natural ID) intact `{1,0,1, 1,0,1, 1,0,1, 2,0,2}` with exact payloads |
| **No user content in responses/logs/telemetry (rule 6, `09.4`)** | `B19_body_and_targets_values_never_reach_errors_logs_or_telemetry`: 8 canaries (phase name, Arabic weigh-in note, distinctive height/weight/input/kcal/target/protein numbers) on accepted push, validator-invalid (acknowledgement, expression fields), schema-invalid (extra member, unknown `inputUnit`), guest 403 and `DELETE /v1/me`; ack bodies checked; all sinks checked (logs incl. scopes/state through the scrubbing decorator, activities, metrics, Sentry envelopes, `identity.audit`, Postgres log). Positive control: owner pull + item history `DeepEquals`. Per-row results have exactly `entity,hlc,id,reason,status` (`Batched_matrix_…`), invalid `(entity,id,hlc)` absent from all three tables (privileged count). `SyncTelemetry` records only operation/counts/duration (no entity, no values) |
| Omitted privacy legs are sound | 400 (body binding), 413 (Kestrel), 500 (store failure with content in the exception) and 401 happen before or outside entity-specific code, and B17/B18's facts cover them with content-carrying canaries (`IdentityPrivacyTests.cs:160`, B18 fact incl. `FailingWithContent`). B19 adds no entity-specific exception path (see row 1), so no new 500 source exists |
| Hygiene | No secrets (pattern grep over the diff); corpus content is synthetic (`Synthetic goal`, `Synthetic note`, `بعد العيد`, `origin: synthetic`, control-char/surrogate probes), 0 e-mail addresses; test e-mails `@example.invalid`; no grant/migration/infra change; privileged connections only in test aging (`SyncHttpSupport.AgeAndCleanup`, `HistoryCount`) and inventories; `git diff --check` clean |

## Commands run (this review, lane 3, `1e36fa3`)

| Command | Result |
|---|---|
| `heavy.sh dotnet build tests/Persistence.Tests -c Release` · `tests/UserData.Tests -c Release` | 0 warnings, 0 errors |
| `heavy.sh dotnet test --project tests/UserData.Tests -c Release --no-build --filter-class *BodyTargetsPayloadTests` | **784/784 passed** |
| `heavy.sh dotnet test --project tests/Persistence.Tests -c Release --no-build --filter-class *BodyTargetsSyncTests *IdentityPrivacyTests *ChatProposalSyncTests *PersonalFoodSyncTests *ProductionSyncTests` | **55/55 passed** (Testcontainers Postgres) incl. B17/B18 regressions after the helper move |
| registry vs contract (`entities` `DeepEquals`, python) | equal |
| `git diff --check c420081..HEAD` | clean |
| `dotnet build-server shutdown` | done |

These runs finished before the owner's 2026-10-29 "no local tests" rule reached this review; nothing was run after it. Not run: full `make test-dotnet`, `make check-sync-schemas`, `make contract-conformance`. CI is the gate.

## Findings

No blocker, no major.

1. **minor (defensive): `KeyNotFoundException` isn't in the admission catch filter** (`SyncPayloads.cs:39`; `TargetsPayloadValidator.cs:43–92` uses `GetProperty`). Unreachable today: the schema requires every member, and fail-closed dispatch means a future version never reaches these reads. If the invariant ever broke (e.g. a hand-edited registry), one row would turn the whole push into a 500 and block the device's queue (privacy-safe: the 500 path is scrubbed). **Fix (optional):** add `KeyNotFoundException` to the filter, or use `TryGetProperty` and return false.
2. **minor (residual privacy, doc): unscrubbable targets tombstones keep health data server-side.** Tombstones carry the full payload; a targets tombstone must stay wire-valid, so `heightCm`, `birthYear`, `sex`, `baseKcal`, `basisWeightKg` and goal weights stay until compaction (30 days after acceptance) and displaced versions stay in history for 30 days. Unscrubbed `weighIn` tombstones keep `kg` and the free-text `note` likewise. Documented in `contracts/README.md` (D11) and owned by A34 (#136). **Fix:** make sure the privacy-policy backlog line (B18 item 5) names body and target data too, and that A34 scrubs `weighIn` tombstones (`kg` 0, `inputValue` 0, `note` null).
3. **nit: the B19 privacy fact has no `profile` validator-invalid leg** (`IdentityPrivacyTests.cs:~317`). `heightCm` 0 / a wrong row ID go through the same `Matches → bool → bare invalidPayload` path as the two covered legs, so the risk is negligible. Optional: add one profile row with `heightCm: 0` carrying the height canary.
4. **nit (integrity, documented): an old client's `weighIn` v1 can replace a v2 by LWW** and drop `tzOffsetMin`/`inputValue`/`inputUnit`/`preferredForDay`. Owner-only writes, recoverable from history for 30 days, and stated in D6 and `contracts/README.md`. Not a security issue; A34 should upload v2 only (already planned).

Pre-existing residuals from B18 (no pull-page byte budget, no per-account quota) are unchanged; B19 rows are small.

## Privacy check

**Pass.** Rejections return only `invalidPayload` with `entity,hlc,id,reason,status`; values never reach responses, logs, scopes, spans, metrics, Sentry, audit or the Postgres log on the entity-dependent legs (executed, 55/55), and the entity-independent legs remain covered by B17/B18. No AI path or identity is involved. No new log statement in the diff.

## Residual risks for the owner

- Deleted body/target values can remain on the server for up to about 30 days as a tombstone plus 30 days in history (finding 2). The privacy policy (AC-044, R3) should say so.
- Account erasure is immediate for live data; backups keep it until rotation (pre-existing AC-031 "within 30 days", unchanged).

## Verdict

**Approve with findings.** 0 blocker, 0 major. Finding 1 is a cheap optional hardening; finding 2 belongs in the A34 handoff and the privacy-policy backlog.

## CI

_Placeholder: CI run on the exact merge commit (`merge-step.sh B19 …`) to be added at merge._
