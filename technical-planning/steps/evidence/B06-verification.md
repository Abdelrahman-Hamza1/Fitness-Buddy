# B06 verification

Local implementation and two independent review gates passed on2026-10-20. The exact-squash
`ci` check remains mandatory through `merge-step.sh` before main moves.

## Scope and trust boundary

Bearer-authenticated `DELETE /v1/me` supports guests and registered accounts. No body, target user,
completion mapping or generic cached response. A204 follows one durable transaction covering all
installed module erasers, session revocation and Ops purge. Known participant failure rolls back
and permits retry; old access/refresh credentials fail after commit. A lost204 followed by401 is
an uncertain app outcome, not a general proof of deletion (A35).

Module-owned SQL and narrow Identity capabilities preserve forced RLS. Shared installation keys,
dataset metadata, abuse IP buckets and other accounts remain. No provider, owner account, real-data
reset or paid AI call was used. The generated Dart client is the only app-area change.

## Independent review

One fresh GPT-6.1 Sol whole-diff review and a separate fresh GPT-6.1 Sol security review found no
blockers or majors. The security minor was fixed and rechecked: real-table inventory now recursively
follows foreign keys into user-owned tables, regardless of column spelling. The code review minor
is backlog#80: fixed first-page queue discovery can delay later owners while the first32 candidates
are busy; safe lock ordering and erasure remain intact. No remaining security finding.

## Exit evidence

| Criterion | Evidence |
|---|---|
| Complete erasure | `AccountDeletionTests`: real schema inventory and all owner/session rows absent, including Identity credentials/audit/challenges, UserData documents/history/receipts/fences and Ops schedules/jobs/replays/envelopes/markers; shared keys and second user preserved; foreign linked challenge preserved |
| Atomic retry | Failed participant restores data/session and known recovery generation; retry succeeds; missing eraser fails before effects; handler secret preparation stays outside transaction |
| Concurrent lifecycle | Refresh/sync queued behind deletion cannot recreate data; actual authenticated cached replay cannot return old bytes; real worker claim waits/finishes before deletion, orphan work causes no effects; HTTP shared lease and DELETE exclusive transaction do not self-deadlock |
| Connection uncertainty | Real backend connection termination before commit rolls back data and leaves recovery fail-closed; client cancellation after real commit leaves old credentials rejected and readiness healthy |
| Privacy | Identity privacy test includes successful DELETE and subsequent401 through captured logs, Activities, Meter, serialized Sentry and PostgreSQL canaries |
| Recovery admission | Missing/corrupt/non-private/symlink state refused; explicit first initialization and matching repeat only; file/DB mismatch blocks readiness and online traffic while liveness/config remain available |
| Local email residual | Atomic private delivery publication; recorded expiry rather than mtime; startup pruning before traffic, unsafe/unwritable cleanup refused; expiry is10min plus next≤1min running sweep, no physical wall-clock guarantee while stopped |
| Production image | Synthetic registered sync/history→DELETE; old access/refresh/email rejected; second user intact; backup lock blocks deletion, stale/digest backup refused, matching post-delete scratch restore passes; manual mismatch503 and read-only recovery rollback |
| Contract | Contract-only commit precedes implementation; regenerated client; full check includes contract lint/self-tests, breaking-change check and server conformance |

Provider sign-in, linking and email-consume versus deletion were checked by review of their lock
order and post-wait revalidation; those particular races do not have separate B06 adversarial tests.
Existing Identity concurrency tests and B06 refresh/sync/replay/worker race tests pass.

## Measurements and final local gates

- `make check test`:319 backend tests, zero failed/skipped; app and10 Dart packages passed.
- `make gen-check` and final C# whitespace verification passed without generated drift.
- Operator unit tests:31 passed, including same-second backup selection by modification time.
- Current image: `sha256:cbfeefed216fa9375c2c5165f8c23fbeb69c4df46a669ec4f70d24fc03448ec0`.
  UID1654; repeat migration0, worker0, config200, DB-down ready503/live200, graceful stop0s/exit0;
  engine180,683,681bytes, gzip archive74,426,294bytes.
- Synthetic Production-image deletion:30,004 UserData rows,364ms HTTP including deliberate backup
  recovery-lock wait. SQL expanded shapes first created by actual sync; this measures erasure,
  not API ingestion, and is a laptop loopback observation rather than a throughput guarantee.
- Same-image sync regression:50 real randomized runs and existing dropped-body/replay/crash faults;
  10,000-row push8929ms/fresh pull590ms; HTTP p95 pull6.77ms, push29.39ms, history18.79ms;
  server handler p95 pull1.97ms, push24.84ms, history5.30ms;15,003 receipts/4,751,360bytes.
  Faithful dump counts/epoch and explicit scratch epoch rotation passed.
- Private overlay scratch restore:25 tables including synthetic fixture, both protected rows/sum33,
  ACLs preserved, matching generation, scratch-only dataset rotation.

## Recovery limits and handoff

The protected opaque generation is outside restorable dumps/key bundles and durably written before
erasure. Known savepoint rollback can reconcile while holding the exclusive lock; ambiguous crashes
may overblock and must never guess an older marker. Older dumps retain their ordinary expiry but
cannot reopen traffic. No destructive live restore/reset command was added. B14 must provide an
equivalent durable production mechanism before deployment; do not roll back to a pre-B06 binary
after enabling deletion. A35 owns confirmation, local wipe and uncertain-result UX; A34 owns phone
sync. Owner phone Google/reboot/off-laptop-backup checks remain backlog#76/#78/#79.
