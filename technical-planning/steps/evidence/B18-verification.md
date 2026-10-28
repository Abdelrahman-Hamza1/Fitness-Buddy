# B18 verification (2026-10-29)

Tier **Risky** (sync admission of chat and proposal content, privacy, erasure; `PROCESS.md` Part C). Built by Claude (TD-085). This is the WP5 `security-reviewer` evidence for the whole step: `git diff 11c4740...HEAD` on `step/B18-chat-proposal-sync` at `1e668a9` (contract `cd1d4e8`, already on `main` as `B18 (contract)`; WP2 `b3530ed`, WP3 `ef93480`, WP4 `1e668a9`). The WP1 schema pass happened before the contract merge, and its findings were applied. Executed checks are kept apart from inspection-only claims.

## Scope

- **Production code:** the only `backend/src` change is the regenerated embedded registry `Modules/UserData/Infrastructure/Schemas/entities.json`. There's no C# source, endpoint, migration, grant, `openapi.yaml`, `fb_api_client` or `apps/` change, and no new dependency (`git diff --name-only`). Admission, storage, RLS, retention and erasure are the existing entity-agnostic B05/B06/B17 code.
- **Tests reviewed:** `Persistence.Tests/ChatProposalSyncTests.cs` (15), the new `IdentityPrivacyTests.B18_authorized_pull_returns_content_while_errors_logs_and_telemetry_omit_it` plus the `SinkCapture` extraction, the `PersonalFoodHttp` `entity` parameter, `UserData.Tests/ChatProposalPayloadTests.cs` + `ChatProposalCases.cs` (550), and the contract, corpus and docs (`contracts/README.md` §chatMessage and proposal admission, `05` §2.3/§5.5, A22/A23/A34 handoffs).

## Properties → tests

| Property | Tests / evidence |
|---|---|
| `09.4-no-user-content`: no message text or proposal content in error responses or diagnostic sinks; owner reads return it exactly | `B18_authorized_pull_returns_content_while_errors_logs_and_telemetry_omit_it`: 9 canaries (EN, Arabic, Arabizi text; budget key; interpretation EN + Arabic; draft; kind; language), sent as unescaped UTF-8 like Dart `jsonEncode`. Paths: accepted push, invalid `role`/`status`, `text` 8193 and `draftJson` 32769, unpaired surrogate (top-level text + nested `draftJson` key), fixed 400, guest 403, real-Kestrel 413, injected 500 (push and item history), `DELETE /v1/me`. Each response body is checked for the raw and JSON-escaped form. All sinks are checked at the end: logs through the production scrubbing decorator (incl. scopes and structured state), activities (all sources, incl. Npgsql), every metric type, serialized Sentry envelopes, `identity.audit` (owner credentials) and the Postgres container log. Positive control: owner pull and item history `DeepEquals` the sent payload, and `text` is byte-exact. The capture's own detection is proven by `Privacy_capture_detects_numeric_measurements_scopes_and_unformatted_structured_fields` |
| Per-row rejections are content-free | `Batched_matrix_…`: every ack item has exactly `entity, hlc, id, reason, status`; no `synthetic`/`Json` text; invalid ids absent from `documents`/`row_history`/`version_receipts` (privileged count) |
| D7: ill-formed UTF-16 never 500s, is never stored, and never logged | `Ill_formed_utf16_never_500s_or_reaches_postgres_logs`: ≥ 20 cases (chatMessage, proposal, `weighIn.note`; top level, nested values and keys; live + tombstone), one batch + each row alone → 200/`invalidPayload`; 0 documents; canary absent from ack and Postgres log |
| `04.6-rls`: cross-user isolation | `Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned` (Theory over both entities): live, item history and compacted fence invisible to B; B's same `(entity,id)` is independent. Direct app-role RLS proof stays in the existing generic suites (entity-agnostic policies) |
| `04.6-authz`: guest 403, unauthenticated 401 | `Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401` (Theory): push, pull, item history |
| AC-031: erasure | `Delete_account_erases_chat_and_proposal_live_history_fences_and_receipts_and_preserves_second_owner`: real `DELETE /v1/me` → 204, token revoked (401). Privileged per-entity inventory before (2 documents incl. 1 fence, ≥ 1 history, 4 receipts per entity) and after (all 0, plus all-entity 0 for the user). Second owner intact (`1,0,1` per entity, payloads exact). `UserDataErasure` deletes from all three userdata content tables |
| AC-012 + tombstone scrubbing | `Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection` (Theory): the scrubbed tombstone payloads from A23's handoff (`chat-tombstone-scrubbed`, `proposal-tombstone-scrubbed`) are admitted; compaction by acceptance time; history physically 1→0 (privileged count); empty fence payload; stale resurrection blocked; explicit restore works. `Lww_…` covers immutable replay (`versionConflict`) |
| D14: max-size rows fit one push | `Maximum_size_rows_fit_one_push_and_round_trip` through real Kestrel: proposal body ∈ [196 608, 262 143] bytes accepted and round-tripped; the same row `\u`-escaped is > 262 144 |
| Admission = schema + generic representability; constants = corpus | `ChatProposalPayloadTests` (550): live + tombstone matrix, 32768/32769 and 8192/8193 incl. straddling surrogate pairs, closed codes, null refs, no attachments, `codecVersion` bounds, bounded hostile JSON, embedded registry = contract = corpus |

## Commands run (this review, lane 2, `1e668a9`, clean tree)

| Command | Result |
|---|---|
| `heavy.sh dotnet build tests/Persistence.Tests -c Release` | 0 warnings, 0 errors |
| `heavy.sh dotnet test --project tests/Persistence.Tests -c Release --no-build --filter-class *ChatProposalSyncTests --filter-class *IdentityPrivacyTests --filter-class *PersonalFoodSyncTests` | **24/24 passed** (15 B18 + 3 privacy incl. the B18 fact, the existing identity/B17 fact and the positive control + 6 B17 regression after the helper change), Testcontainers Postgres 18.6 |
| `heavy.sh dotnet test --project tests/UserData.Tests --no-build --filter-class *ChatProposalPayloadTests` (Debug build newer than HEAD) | **550/550 passed** |
| `make check-sync-schemas` | exit 0 (embedded registry = contract) |
| `git diff --check 11c4740...HEAD` | clean |
| `dotnet build-server shutdown` | done |

Not run by this review: full `make test-dotnet`, `make contract-conformance` and CI. These are WP5/merge gates for the orchestrator (`merge-step.sh`).

## Findings

No blocker, no major.

1. **minor: the B18 500 leg doesn't carry B18 content into the exception** (`IdentityPrivacyTests.cs:253`, `FailingHistory` at `:398`). The injected store throws a fixed `CANARY-PATH-PRIVATE`, which isn't in the B18 canary list (`:174`). So this leg proves the 500 response and sinks add no payload content. It doesn't prove that an exception *carrying* chat text would be scrubbed. That's covered transitively: the identity/B17 test uses the same `FailingHistory`, lists `CANARY-PATH-PRIVATE`, and asserts it absent from every sink (`:159`). Optional fix: add `CANARY-PATH-PRIVATE` to the B18 list, or throw with the pushed `text` in the message.
2. **minor (pre-existing pattern): Postgres-log assertions are config-bound** (`ChatProposalSyncTests.cs:356`, `IdentityPrivacyTests.cs:377`). `PostgresFixture.cs:18` runs Postgres with `log_min_messages=fatal`, `log_min_error_statement=panic` and zero parameter logging, identical to `infra/compose/docker-compose.yml:22` and `infra/phone-server/compose.yml:21`. The checks can only fail if logging is reconfigured, and the fixture duplicates the compose command rather than reading it. The behavioural protection for D7 is "200 + `invalidPayload` before any SQL", which is asserted. Backlog: a drift check that the fixture, `image-smoke.sh` and compose Postgres commands are equal.
3. **minor (backlog recommendation, prior finding confirmed): no server byte budget on pull/history pages** (`SyncEndpoints.cs:57` caps only `limit ≤ 500`). The response uses the default `System.Text.Json` encoder, which escapes non-ASCII as `\uXXXX` (by inspection: `ApiRole.cs:23` sets no encoder). A maximum proposal row is therefore about 393 KB on the wire, and a 500-row page is about 190 MB, materialized server-side. One authenticated account can fill its own dataset (100 req/min) and then drive memory pressure on the VM, and the phone would get the same page. Pre-existing for every entity (any row can be up to the push cap), but B18 makes large rows routine. **Fix (backlog, before R3/public):** stop a page once it holds about 2–4 MiB of payload, always returning at least one row. This is non-breaking because `05` §5 already says "keep pulling until an empty page". A34 must end a pull on an empty page, never on `changes < limit` (the test helper `ChatProposalSyncTests.cs:443` uses `< 500`, which is fine for a test but not a pattern to copy). The A34 handoff "500 × ~197 KB" (`A34-sync-engine-app.md:56`) understates the wire size by about 2× because of server-side escaping.
4. **minor (A34 risk to record): D14 has about 64 KB of headroom, and only for unescaped bodies.** The maximum proposal is about 197 KB against 262 144. Control characters in `kind`/`origin` (6 bytes each when escaped) add at most about 1 KB, so it still fits, though the test uses BMP text only. A `\u`-escaping encoder (or a future v2 field) turns the row into a **whole-batch 413**, which names no row. The A34 handoff (`:53`) and `contracts/README.md:112` cover the encoding. **Add to A34's handoff:** batch by encoded body bytes, not only the 500-change count; send a near-cap row alone; on 413, split the batch and park a single unpushable row (backlog #111 semantics) so it never blocks the queue or retries endlessly; don't assume pulled rows are as small as pushed ones.
5. **minor (doc): the tombstone scrubbing rule lives only in A23's card** (`A23-message-lifecycle.md:69`). The server stores full-payload tombstones as the live document until compaction (30 days after acceptance) and keeps displaced versions in history for 30 days, so an unscrubbed tombstone keeps cleared chat text on the server for up to about 60 days in the worst chain. The contract authority (`contracts/README.md` §chatMessage and proposal admission) and the A34 handoff don't state the rule. **Fix:** add one line to both. Make sure the planned privacy-policy backlog item ("cleared chats can remain in server history up to 30 days", card §8 A23 handoff) is actually filed at close. AC-033 doesn't promise immediate server erasure, so this isn't a spec conflict.
6. **minor (residual, pre-existing): no per-account storage quota.** About 100 × 256 KiB ≈ 25 MB/min of accepted rows per account is possible. Acceptable for R1/R2 (owner and friends). Backlog it for R3 together with item 3.
7. **nit:** the B18 privacy fact doesn't check the 401 (unauthenticated) response body. Auth rejects before the body is read and the status is covered by the guest/unauth theory, so the risk is negligible.

## Privacy check

**Pass.** Error responses are content-free on every leg (accepted, invalid vocabulary, over-limit, ill-formed UTF-16, 400, 403, 413, 500 push/history, deletion), and the canaries are absent from logs, scopes, spans, metrics, Sentry, audit and the Postgres log (executed, 24/24). Owner pull/history returns content exactly, which is intentional and asserted. No identity is involved. No AI path changed. Attachments and local paths are excluded by `additionalProperties: false` (pure tests).

## Residual risks for the owner

- Pull pages have no byte cap, and accounts have no storage quota (items 3 and 6): availability risk from a misbehaving or malicious *authenticated* account. Low for R1/R2. Fix before R3 (backlog).
- Cleared chat content can remain server-side for up to 30 days in history (longer if tombstones aren't scrubbed). The privacy policy must say so (AC-044, R3).
- Account erasure covers live data immediately. Backups keep it until rotation (pre-existing B06/AC-031 "within 30 days" topic, unchanged).

## Verdict

**Approve with findings.** No blocker or major, and no production C# change. Items 3–5 should be recorded at WP5 close: the backlog entry for the page byte budget and quota, plus the A34 handoff lines and the `contracts/README.md` scrubbing line.

## Verifier (2026-10-29, lane 2, `b1e6e39`, clean tree, origin/main `cd1d4e8`)

Fresh `verifier` pass against every exit criterion on the card and the Definition of Done (`10` §9). Everything below was executed by this pass on the exact branch head (security review + review-fix commit `b1e6e39` included). Pinned toolchains (`~/.dotnet`, Flutter 3.47.7); heavy commands under `tools/scripts/heavy.sh`.

### Commands run

| Command | Result |
|---|---|
| `heavy.sh make check` (check-dart, check-dotnet, check-contract incl. conformance, apk-hardening-selftest) | exit 0: format 0 changed, `dart analyze --fatal-infos` no issues, app-check OK, frozen migrations OK, `dotnet format` clean, Release build 0 warnings / 0 errors, contract bundle/lint/selftest OK, `contract-breaking` no breaking changes, `contract-conformance` OK, APK hardening 26 cases |
| `make check-sync-schemas` | exit 0 (embedded registry = contract) |
| `heavy.sh make test-dotnet` | **1381/1381 passed**, 0 skipped (all 7 test modules; Persistence.Tests via Testcontainers) |
| `dotnet test --project tests/Persistence.Tests --no-build --filter-class *ChatProposalSyncTests --filter-class *IdentityPrivacyTests` | **18/18** (15 B18 + 3 privacy incl. the B18 fact) |
| `dotnet test --project tests/UserData.Tests --no-build --filter-class *ChatProposalPayloadTests` | **550/550** |
| `DART_TEST_SHARD=packages heavy.sh make test-dart` | 9 packages passed; fb_domain **478** tests, coverage **100.0 %** (4563/4563, min 95 %) |
| `dart test` the three fb_domain B18 files (corpus vectors, sync codes, codec) | all passed; the 14 named B18/AI-045 tests listed in card §5 all present and green, incl. `B18 generated vectors match committed bytes` (drift gate) |
| `heavy.sh make contract-conformance` (standalone) | OK, server API matches the contract |
| `make trace` | exit 0; R1 319 total / 141 covered; AI-045, AC-010, AC-012, AC-031 list the B18 test files; 1 pre-existing warning (ZZ-060 in trace's own self-test) |
| `git diff --name-only origin/main...HEAD -- backend/src contracts/openapi contracts/openapi.yaml packages/fb_api_client apps` | empty: **no production C#**, contract, client or app change on the branch (registry regen shipped with `B18 (contract)`) |
| `git diff --check origin/main...HEAD` · `git status` after all runs | clean · clean |

### Exit criteria

| Criterion | Verdict | Evidence |
|---|---|---|
| Validator + corpus: every rule at limit/limit+1 (32768/32769 incl. supplementary); constants = corpus; fb_domain corpus both directions | ✅ | `Payload_matrix_matches_admission_for_live_and_tombstone` (corpus 232 + schema-derived matrix, live + tombstone), `B18_json_string_limit_counts_utf16_units…` (all three JSON fields 32768/32769, text 8192/8193, pair ending at / straddling the limit, all-pairs), corpus cases for language 16/17, kind 32/33, origin 128/129, codecVersion bounds; `Embedded_schema_bounds_and_vocabularies_equal_Dart_corpus` (embedded = contract DeepEquals; bounds and enums = corpus); `Corpus_declarations_agree_with_admission_and_asymmetry_lists`. Dart: drift byte-equality, app→server (`AI-045 codec projections…`, 11 real codec cards), server→app (`AI-045 codec rows restore…`, closed codes decode / unknown → null, opaque JSON → fixed issue, never throws), asymmetry list. Mapper-level parity is A22/A23's (D10 rewrite) |
| Persistence (Testcontainers): accepted push, invalid → `invalidPayload` content-free, pull/history round trip, tombstone, isolation, guest 403; opaque/cross-row inconsistencies admitted | ✅ | `Batched_matrix_…` (ordered acks with exactly `entity,hlc,id,reason,status`; invalid ids absent from documents/history/receipts; accepted rows pulled exactly), `B18_opaque_…_round_trip…` (HTTP), `B18_row_admission_does_not_require_related…` (HTTP), `Pending_proposal_and_assistant_message_survive_fresh_device_pull`, `Maximum_size_rows_fit_one_push_and_round_trip`, `Lww_…`/`Tombstones_…`/`Another_owner_…`/`Guests_get_403_…` theories over both entities, `Ill_formed_utf16_never_500s_or_reaches_postgres_logs`, and `B18_authorized_pull_returns_content_while_errors_logs_and_telemetry_omit_it` (500 leg now throws with the pushed content) |
| Account deletion covers both entities, history and fences | ✅ | `Delete_account_erases_chat_and_proposal_live_history_fences_and_receipts_and_preserves_second_owner`: inventory `{2,2,4}` per entity before, all zero after (plus all-entity zero), token revoked, second owner `{1,0,1}` intact |
| `check-sync-schemas`, `contract-conformance`, `test-dotnet` green; CI green | ✅ local · ⏳ CI | Local: all three green (above). **Remaining gate:** CI on the exact merge commit via `merge-step.sh B18 …` |
| Fresh security review: no open blocker or major | ✅ | Security section above: approve, 0 blocker / 0 major. Findings 1 (500 leg content) and 5 (scrubbing line in `contracts/README.md`) are fixed in `b1e6e39`; 3/4 recorded in the A34 handoff |

### Definition of Done (`10` §9)

1 spec IDs ✅ (AI-045, AC-010, AC-012, AC-031, rule `09.4-no-user-content`) · 2 tests incl. edge cases ✅ · 3 UI n/a · 4 offline n/a (server) · 5 change sets n/a (no app writes) · 6 ARB n/a · 7 API: contract first (`B18 (contract)` on main), no client/path change, conformance green, no breaking change ✅ · 8 trace tags ✅, CI ⏳ merge commit, eval n/a · 9 perf: no hot path; `Near_limit_opaque_json_completes_with_bounded_work` green ✅ · 10 docs: card handoffs, `contracts/README.md`, A23/A34 cards ✅; **open for close (Phase E):** card **Outcome** (incl. the D10 deviation), board status, `backend/README.md` §Document sync still mentions only B17 (plan §3.5 WP5), backlog items (page byte budget + per-account quota, privacy-policy history note, A23 nested-limit precheck)

### Traceability

Spec IDs of this step covered by tests: **4/4** (AI-045, AC-010, AC-012, AC-031) + rule `09.4-no-user-content` (`IdentityPrivacyTests`). Missing: none.

### Verdict

**PASS** for the exit criteria executable before merge. Remaining gates: the close docs listed under DoD 10, then CI green on the exact merge commit.
