# B01 verification — Sync spike

Verified 2026-10-16 by Codex after independent whole-diff architecture/correctness/security review of `9422c34..c1a4d2a`. Review fixes are in `182fd53` (references) and `3f10e5c` (null-envelope 400 + regression, protocol overview). One round, no blockers/majors; one minor and one nit both fixed and checked under TD-054. No re-review round required. Production completion is deliberately outside this feasibility spike.

## Exit criteria

| Criterion | Executed evidence | Result |
|---|---|---|
| ≥1,000 fake and ≥50 real randomized runs | `make check test` runs `1000 randomized multi-device runs converge with every version recoverable` over seeds 0–999. `make sync-spike` against the final shipped image prints 10/20/30/40/**50/50** real seeds passed. Each seed has 2–5 devices, 100 random offline writes/deletes, random sync ordering, concurrent final pushes and a fresh-device pull. Expected winners derive from local events, independently of both stores. Full payloads/metadata of every version must exist in current documents or deduplicated history; all devices agree with the expected winners. AC-010/011/012 feasibility; OF-03 simulated. | ✅ |
| Fault injection, no loss/duplicates | Same `runFaults` suite against fake and real: drop before send, response lost after server commit, engine crash before acknowledgement, newer local edit during an old acknowledgement, crash before atomic page/clock/cursor commit, duplicated push and invalid future version left pending. State crosses engine restarts through serialized checkpoint/restore. Real harness additionally cuts an actual TCP connection halfway through the declared JSON body, verifies no row appears, then retries the immutable version twice and gets one stored row. | ✅ |
| 5,000-row push + fresh pull timing | Final real harness: **push 2,818 ms; fresh pull 144 ms**. Independent SQL count confirms 5,000 benchmark documents. Small synthetic payloads, AMD64 laptop (~7 GiB RAM), hardened API container + Postgres 18.6 over Docker loopback. This is one run, not a latency percentile or phone/Wi-Fi test. Fresh pull includes prior scenario rows as well as the benchmark rows. Earlier run 3,096 / 174 ms. Wi-Fi/app integration remains #56, B05/A34. | ✅ |
| Decide TD-006/031 and update `05` §5 | Both pending decisions confirmed Accepted using the executed evidence; custom delta sync + versioned JSON documents remain the design. `05` §5.2/5.4 now define immutable per-version acknowledgement, string cursors, per-user commit ordering, archived stale losers and a bounded future-clock admission policy. Primary-source PowerSync comparison (Drift integration, self-hosted Postgres storage and disconnected guest use) recorded in research notes. | ✅ |

## Focused invariants and security evidence

- `Winners_losers_and_tombstones_survive_reversed_order_duplicates_and_conflicts`: latest HLC wins, tombstone survives stale replay, displaced and incoming stale versions are recovered, conflicting contents under a known HLC are invalid and do not duplicate history (AC-012).
- `Shared_hlc_vectors_and_future_admission_bound_are_exact`: shared YAML strict parse vectors, C# ordinal ordering and actual Postgres `COLLATE "C"` agree with Dart; exactly five minutes ahead accepted, one millisecond further invalid. Device suffix must match metadata. TD-049 library defaults unchanged.
- `Same_user_push_cannot_commit_past_an_uncommitted_sequence`: holds the first user's advisory transaction lock after sequence allocation; checks `pg_locks` to prove the second push is waiting, confirms pull cannot see the uncommitted row, commits, then sees both pages in order. Sequences explicitly use `CACHE 1`.
- `Rows_updated_while_paging_move_forward_and_are_delivered_again`: no skipped update; empty page preserves the last delivered cursor. Push never changes a client's pull cursor.
- `Both_document_and_history_tables_force_user_isolation_and_anonymous_reads_are_empty`, `Both_tables_reject_cross_user_inserts_with_check_and_force_rls`: real non-owner/non-BYPASSRLS fb_app role; unfiltered reads cannot cross users, anonymous context sees neither table, cross-user inserts fail and both ENABLE/FORCE flags are checked. Existing S04 pooling/identity/role tests remain green.
- `Tombstone_instants_accept_rfc3339_offsets_and_store_utc`: legal non-UTC RFC 3339 offsets normalize before Npgsql and round-trip as UTC.
- `Experimental_http_access_is_fail_closed`: Production/Development stay 501 even with enable/key options; disabled SyncSpike stays 501; properly configured synthetic environment can sync; wrong key gets 401. No request-supplied user identity. Independent review confirms constant-time key comparison, SQL parameterization, scrubbed diagnostics and loopback-only disposable harness exposure.
- `Null_change_elements_return_validation_400_without_applying_any_row`: `[null]` and `[valid,null]` return problem+json 400 with `changes` errors and leave no document. Fixes the reviewer's reproduced minor.
- Dart byte/row batch tests use Arabic UTF-8 payloads and 1,001 rows; malformed acknowledgements and skipping cursors leave durable state unchanged. Five simulator tests pass.

## Gates and image

- Post-review `make check test`: passed, **207 .NET cases**, no failures/skips/warnings/errors. All Dart/tool/app tests passed; the pre-existing local-live mobile test remains skipped by its normal configuration. Architecture tests include UserData's six layer/surface rules; contract bundle/lint/self-test/breaking/conformance and APK hardening self-test pass.
- `make gen-check`: passed, generated API client and app outputs match the committed index.
- `make image-smoke sync-spike SYNC_SPIKE_IMAGE=fitness-buddy-api:smoke SYNC_SPIKE_SKIP_BUILD=1`: passed on final local image **sha256:27fdf2b7d3df2ff4ae57131b1a5c11cabd1f1ffd88b35f662f53fe2f1a48cebc**. UID 1654, read-only/tmpfs/no capabilities; config 200, trace `e598d5742ad542ad219691324937988e`, migrate/repeat exit 0, worker exit 0, DB-down ready 503/live 200, API stop 0 s/exit 0. Image 172,528,178 bytes; gzip archive 72,147,001 bytes. Both scripts clean disposable containers/networks.
- `bash -n tools/scripts/sync-spike.sh` and `git diff --check`: passed. Final CI must pass on the exact `merge/B01` squash SHA before fast-forwarding main (TD-036/039); `tools/scripts/ci-status.sh` enforces that gate.

## Practical limits

This demonstrates convergence within one live dataset, not production AC-010/011/012 sign-off. No real auth, user payload schemas, retention scheduler, dataset reset recovery, production phone outbox or network measurements are claimed. `SyncSpike` is synthetic-only; normal runs keep routes unavailable. Drift/process death on the phone, clock repair, 30-day history/tombstone compaction and JSONB payload boundaries are retained as #54–57 for B05/A34. No paid service, production operation or secret was introduced.
