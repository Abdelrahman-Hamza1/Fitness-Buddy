# B05 verification

Local implementation and independent review gates passed on2026-10-18. The exact-squash `ci`
check remains mandatory through `merge-step.sh` before main moves.

## Scope and trust boundary

Production bearer-authenticated sync, closed entity/schema registry, dataset discovery/binding,
immutable version receipts,30-day history and tombstone payload compaction retaining deletion
fences. Registered users only; missing/revoked credentials401, guests403. Forced RLS and a live
Identity check run inside the same user-locked transaction as reads/writes. No application
cross-user cleanup capability, migrator credential, phone bypass or provider proof bypass.

## Independent review

Fresh GPT-6.1 Sol whole-diff code review and a separate fresh security review found four majors:
legacy JSONB numeric fingerprint failures, insufficient scheduled-retention failure/continuation
coverage, dynamic-path telemetry leakage and cleanup privilege expansion. Fixed all four and
received approval on scoped recheck, including the final harness changes. Replaced elevated
cleanup enumeration with user-owned recurring Ops schedules, seeded only by migration-role code.
Fixed the remaining cheap minor (quadratic trailing-zero normalization) with linear trimming and
1e100000 canonical equivalence coverage. No unresolved blocker or major.

## Exit evidence

| Exit criterion | Concrete evidence |
|---|---|
| LWW/history/deletes/clocks/paging/isolation | Retained B01 independent SQL tests plus `ProductionSyncTests`: all eight entities; mixed invalid neighbours; dataset discovery/mismatch no-write/no-ack; ahead cursor; exact immutable replay; changed same-version rejection after retention; compacted fence and strictly newer restore; revocation while waiting for the user lock; host401/403/null-batch400; user A cannot access B documents/history/receipts |
| Production convergence |7 Dart simulator tests, including1,000 independent fake seeds, reset/clock correction with concurrent edits, faults, shared vectors, batching and malformed acknowledgements/cursors;50 real randomized authenticated Production-image scenarios plus dropped-body/replay/crash cases |
| Retention with fake clock | `SyncRetentionTests`: idle-user recurring scheduling, failed transaction rollback/retry, next scheduled sweep,1001-row legacy backfill/continuation and no application-executable UserData SECURITY DEFINER functions; `SyncUpgradeTests` upgrades actual pre-B05 schema/data with1e100/1e-100, seeds schedules, backfills receipts, purges history and compacts fences |
|10,000-change load | Real bearer-authenticated Docker-loopback Production image, byte/row-bounded batches, independent SQL count, fresh-device pull; measurements below |
| JSONB/input privacy | Raw JSON duplicate keys, NUL, extreme/underflow numeric values rejected before SQL; strict schema vocabulary exporter/freshness check; Identity privacy integration captures successful/invalid sync, throwing item-history and unmatched paths through logs, Activities, Meter, serialized Sentry and PostgreSQL canaries |

## Measurements and image checks

Image: `sha256:70d8f836e23809eb1ada55ef2f866f38cf0675e980c473cde710b47ae2639413`.
Synthetic isolated Docker loopback; raised per-IP/user load quotas, no owner account or tailnet load.
Fresh pull includes previous scenario rows as well as the10,000 benchmark rows. These are laptop
measurements, not default-throttled service throughput or actual phone/Wi-Fi timings.

-10,000-row batched push9473ms; fresh pull543ms.
- Client HTTP round-trip p95 (includes authentication/server/loopback): push30.48ms/1052requests,
  pull6.15ms/4730requests, history16.98ms/301requests.
- Server handler p95 (excludes outer authentication/serialization): push26.57ms, pull1.99ms,
  history5.16ms.
-15,003 receipt rows;4,767,744 relation bytes (indexes included).
- Faithful custom dump transferred counts and epoch; explicit migrate `--Sync:RotateDataset=true`
  rotated only the scratch restored database before traffic.
- Baseline image smoke: UID1654, config200, repeat migration0, worker0, DB-down readiness503 with
  liveness200, graceful stop1second/exit0. Engine180,552,307bytes; gzip archive74,384,625bytes.
- Private overlay smoke: UID1000, protected mounts, local email/refresh/reuse/logout, private
  gateway/HSTS, backup-role RLS dump and22-table scratch restore (21 module tables plus synthetic
  smoke fixture), two protected rows/sum33 preserved, restart/worker and development-volume isolation.

## Final gates and follow-ups

`make check test`:298 backend tests passed, zero failures/skips; all10 Dart workspace packages
passed (existing app skip unchanged). Focused final Dart analyzer passed. Backend format/build,
contract conformance, production sync harness, baseline image smoke, private server smoke and
`make gen-check` passed after review fixes. The merge script verifies CI on the actual squash.

B06 erases receipts, fences and user-owned Ops schedules. A34 implements real SQLite outbox,
process-death, single-writer clock recovery/UI, dataset merge and phone/Wi-Fi acceptance. B14
repeats production load and preserves the restore-epoch procedure. No live owner database reset,
real Google or paid OpenAI call, app implementation or new security trade-off was performed.
