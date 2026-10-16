# S04 — Backend persistence, outbox & jobs

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S03 | M | ✅ Done |

**Goal.** Postgres becomes usable by any module in a safe, uniform way: per-module schemas and migrations, row-level security as a second wall, a transactional outbox, a job queue with schedules, and idempotent POSTs. All proven against a real Postgres in tests.

**Spec:** MN-005 (idempotency), AC-012 (purge jobs later rely on this) · **Decisions:** TD-022, TD-025

## Scope
- **Npgsql + EF Core 10:** one `DbContext` per module, each with its own schema. A shared convention for UUIDv7 keys, timestamps (UTC `timestamptz`) and snake_case naming.
- **Migrations:** EF migrations per module, with raw SQL support for extensions (`pg_trgm`), RLS policies and indexes. The **`migrate` role** applies all modules' migrations under a Postgres advisory lock.
- **Database roles:** `fb_app` (application, RLS enforced), `fb_migrator` (schema owner). Connection strings per role.
- **RLS helper:** set `app.user_id` with `SET LOCAL` per transaction/command for user-scoped work. A sample policy plus tests proving that a query **without** `WHERE user_id` still can't see another user's rows. Safe with connection pooling.
- **Transactional outbox:** an `ops.outbox` table, written in the same transaction as the business change. A dispatcher in the `worker` role. Handlers registered per event type, idempotent (processed-message tracking), with retry and backoff.
- **Job queue:** `ops.jobs` with `FOR UPDATE SKIP LOCKED` claiming, retries with backoff, a dead-letter state, and **cron-style schedules** (for the purge and cleanup jobs that later steps add).
- **Idempotency middleware:** `Idempotency-Key` on unsafe POSTs. Stores status + body for 24 h. Replays them. Returns `409` on the same key with a different payload.
- **Health:** `/health/ready` checks the database.
- **Local dev:** Postgres 18 in `infra/compose`, with seed users/roles. `make up` runs api + worker + postgres.
- **Test base:** a Testcontainers Postgres 18 fixture shared by all integration tests (migrations applied once per test run, isolated data per test).

## Out of scope
- Module-specific tables (each module's own step). Backups (S29).

## Fixed by the plan
- Postgres is the only stateful dependency: no Redis, no broker (TD-025).
- Each module owns its schema, and no cross-schema access from another module's code (`04` §3.3).
- Expand → migrate → contract discipline for every migration (`04` §6).

## Decide in the low-level plan
- An in-house queue + scheduler (~a few hundred lines) vs **Hangfire** with Postgres storage. Default: in-house. Switch only if the plan finds a concrete gap.
- How EF migrations per module are discovered and ordered by the `migrate` role.
- How the RLS user context flows from the request into EF/Dapper commands (interceptor vs explicit unit of work).

## Exit criteria
- [x] `make up` brings up api + worker + Postgres. `migrate` runs from an empty database, and runs again with no changes.
- [x] Integration tests (Testcontainers): an outbox event is delivered once even if the worker crashes mid-dispatch (handler effect happens exactly once). A failing job retries with backoff and dead-letters after N attempts. A scheduled job fires on schedule (fake clock).
- [x] RLS test: user A's query without a user filter returns none of B's rows.
- [x] Idempotency tests: replay returns the same response. Same key + different body → `409`.
- [x] `/health/ready` reports the database as down when Postgres is stopped.

## Read first
`04-backend.md` §3.3–3.4, §6–7 · `05-data-and-sync.md` §4

## Owner involvement
None.

---

## Low-level plan
_2026-10-16 · Codex · self-reviewed against 03/04/05/09/10 and TD-022/025/058/061. Delegated gate TD-037: no OWNER item._

### Design
1. **Explicit transaction/session boundary.** BuildingBlocks owns a pooled Npgsql data source, `DatabaseSession` (one connection + transaction), shared EF conventions and a module migration registry. User work sets `app.user_id` with parameterized transaction-local `set_config`; the user comes from `ICurrentUser`, never an HTTP body. Contexts attach to that same transaction. No automatic command interceptor or session-level identity survives pooling. User-owned policies use both USING and WITH CHECK and fail closed without identity.
2. **Migration isolation.** Each module registers an ordered factory for its own context and schema-local history table. The migrate process alone reads its migrator connection string and holds one session advisory lock across all context migrations. API/worker receive only fb_app credentials. Bootstrap provisions non-superuser, non-BYPASSRLS roles; fb_app cannot own/create schemas or inherit fb_migrator. No business tables are invented in Account; a test-only module demonstrates the conventions/RLS and migrations.
3. **In-house queue.** `ops` is BuildingBlocks-owned infrastructure, not a product module. EF migration creates outbox, processed_messages, jobs, schedules and idempotency tables. Outbox inserts share the business transaction. Worker claims with FOR UPDATE SKIP LOCKED and holds the transaction through database-only handlers and acknowledgement. Effect + processed marker + acknowledgement commit together. A process death rolls all three back. This proves exactly-once **database effects**, not exactly-once network delivery; future external adapters must use stable idempotency keys. Savepoints preserve claims while failed effects roll back; capped exponential retries end in dead-letter state.
4. **Scheduling.** Cronos parses five-field cron expressions in UTC; schedules persist next_due. Scheduler atomically inserts one uniquely keyed job and advances next_due. Missed ticks coalesce into one run on restart (no unbounded catch-up). TimeProvider drives retries, schedules and expiry. Queue payloads and response bodies stay in the database, never logs or traces.
5. **Idempotency.** Reusable HTTP middleware for endpoint metadata `RequireIdempotency`, ready for future unsafe POSTs (there are no product POST routes yet). Require a bounded Idempotency-Key; namespace by trusted user + operation, hash keys and payload fingerprint. Database lock serializes concurrent same-key calls. Execute the handler and save status/body in the same DatabaseSession transaction; rollback on failures/cancellation, expire after 24 h. Reject a changed fingerprint with 409. Anonymous operations fail closed until S24 supplies an explicit trusted scope policy. Replay safe headers only; transport correlation stays current. No existing public API change, so no generated-client change.
6. **Privacy.** EF sensitive/detailed logging stays off; driver parameter/error detail logging off; database commands are not instrumented or logged. Fixed-code worker logs only IDs/type/attempt. Canary tests trigger database failures containing synthetic content and inspect emitted logs.
7. **Local runtime.** Digest-pinned Postgres 18.6, private Docker network, persistent volume, local-only bootstrap passwords, no published DB port. Compose healthy database → one-shot migrate → api + worker. Readiness executes a bounded database probe; liveness remains independent. Image smoke now supplies a real database and runs migrations twice.

### Files and dependencies
- `backend/src/BuildingBlocks/Persistence/`, `Messaging/`, `Jobs/`, `Web/Idempotency/`: sessions, conventions, migration registry/runner, ops context/migration, queue, scheduler, HTTP boundary.
- `backend/src/Host/`: role wiring, ready health check, persistence configuration; existing S03 tests adapt where database readiness/migrate behavior changed.
- `backend/tests/Persistence.Tests/`: one assembly-shared Testcontainers Postgres fixture, test-only module, isolated test data, real-role security/crash/retry/concurrency cases.
- `infra/compose/`: role bootstrap and compose services; `Makefile`, `tools/scripts/image-smoke.sh`, CI dotnet/image jobs as needed; backend/root README and relevant backend planning sections.
- Central pins: EF Core/Relational 10.0.12 + Npgsql EF 10.0.3 (MIT, approved stack); Testcontainers.PostgreSql 4.16.0 (MIT, real engine tests); Cronos 0.13.0 (MIT, avoids maintaining cron parsing). All versions exceed the seven-day cooldown. No Hangfire: the database-transaction handler contract meets this card without its wider runtime/storage surface.

### Work packages and test mapping
- [x] **WP1 — persistence and migration base:** roles/bootstrap, sessions + EF conventions, migration registration/lock, ops tables, Testcontainers base. Tests: empty/repeated/multi-context/concurrent migrations; schema history ownership; UTC/snake_case/UUIDv7 conventions; RLS A/B reads, insert/update/delete denial, missing context, pooled connection reuse, rollback. Traits `04.3.3-module-schemas`, `04.6-rls`, `04.6-migrations`.
- [x] **WP2 — outbox and jobs:** atomic publisher, idempotent dispatcher, worker loop, retries/dead letters, persistent cron + cleanup. Tests: business/outbox rollback, crash after effect before ack, restart after commit, competing workers, failed-effect rollback, backoff and dead-letter, fake-clock schedule/duplicate prevention. Traits `04.3.3-outbox`, `04.3.4-jobs`; AC-012 is foundation only, actual user-history purge arrives S26.
- [x] **WP3 — idempotent POST boundary:** bounded capture, transaction integration, replay/mismatch/expiry/concurrent requests, user+route isolation, missing/malformed key, rollback/cancellation and replay privacy/correlation tests. Trait Req MN-005 (server foundation; Buddy message integration later).
- [x] **WP4 — runtime and delivery:** api/worker/migrate, DB readiness, compose + image smoke, documentation. Tests: database unavailable → ready 503/live 200; empty/repeated migrate; hardened api/worker containers; startup/shutdown. Full `make check test`, conformance, gen-check, image-smoke, real `make up/down`.
- [x] **Review:** independent whole-diff reviewer with security pass; fix/re-review blockers and majors; log minors.
- [x] **Verify/close:** evidence per exit criterion, Outcome, board/docs/backlog, CI-verified squash merge (TD-036/039).

### Implementation amendments
- **A1 · Privacy:** Postgres server logs are part of the no-content boundary, not just .NET sinks. Compose/Testcontainers/image smoke suppress ordinary SQL statement errors and parameter logging, preserve terse FATAL/PANIC infrastructure failures, and test container logs with a canary. S05 carries the same policy.
- **A3 · Dependency cooldown:** newly introduced EF Core/Relational use 10.0.12; 10.0.13 was published October 13 and is still within seven days. Existing S03 runtime/ASP.NET security pins stay 10.0.13. Relational is pinned too so Npgsql does not select its older minimum transitively.
- **A2 · Driver/runtime:** Npgsql positional parameters cannot combine multiple SQL statements in one prepared command. Cleanup executes separate parameterized commands inside the same transaction. Password/SCRAM data sources disable unused GSS discovery in the chiseled image; an explicit GSS Require is rejected, TLS configuration stays intact.

### Risks and checks
- A single database transaction cannot make a remote HTTP side effect exactly once. Handler contract explicitly limits the guarantee and tests rollbacks with real Postgres.
- Holding locks during handlers requires bounded database-only handlers; external work must enqueue a separate idempotent operation. Cancellation must never count as a retry or swallow host shutdown.
- EF command diagnostics can leak text despite exception scrubbing; driver/EF logging is disabled at the source and tested with canaries.
- No real product user tables/auth exist yet. Test-only fixtures prove the foundations without inventing a product endpoint or misreporting AC-012 as fully implemented.
- Persistence is required at runtime; build-time OpenAPI generation stays side-effect-free and existing HTTP unit tests use explicit health replacements where appropriate.

## Progress log
- **2026-10-16 · Orient → Plan:** S03 is merged at 4f74286 and dependency/main CI is green. Read working agreement, board, dependency Outcome and required design/security/testing docs. Created `step/S04-backend-persistence`. No owner prerequisites; researched versions and transaction/RLS/cron APIs. Low-level plan written and self-reviewed; TD-037 gate approved with no OWNER item. Next: WP1.

- **2026-10-16 · Plan → Implement / WP1:** Added pooled explicit database sessions, principal-based user transactions, shared EF schema/column conventions, per-schema migration registry with an advisory lock, initial ops migration and separate non-privileged local roles. Assembly-shared digest-pinned Postgres 18.6 fixture proves repeated/concurrent migrations, role privileges, EF RLS reads/writes and pooled identity reset after commit/rollback. `make check test` passes (166 .NET tests, all Dart/contract checks); no API change. TD-062 records the transaction design. Next: WP2 outbox/jobs/schedules.

- **2026-10-16 · WP2:** Added transactional outbox/job writers carrying the trusted transaction identity, SKIP LOCKED processor, per-handler processed markers, savepoint rollback, capped retry/dead-letter policy, persistent UTC cron scheduling and infrastructure cleanup. Real Postgres connection termination after handler effect proves rollback/restart/exactly-once database effect; competing workers, failure backoff, cancellation and fake-clock coalescing pass. `make check test` passes (172 .NET tests); production worker wiring follows in WP4. Next: WP3 idempotency.

- **2026-10-16 · WP3:** Added metadata-driven idempotency middleware after client checks: authenticated user/route scope, hashed key/fingerprint, transaction advisory serialization, status/body + safe headers for 24 h, 409 mismatch, bounded request/response buffers and rollback on 5xx/exception. Replayed problems refresh traceId for the current request (TD-057); Set-Cookie is never replayed. Tests prove six concurrent retries produce one effect, isolation, expiry and buffer/failure boundaries. Disabled Npgsql command/batch/COPY/open tracing at its source to protect against broad future listeners. `make check test` passes (184 .NET tests); existing public API/client unchanged. Next: WP4 runtime, compose and delivery checks.

- **2026-10-16 · WP4 / Implement → Review:** Wired required api/worker database configuration, real migrate role, durable worker loop and database readiness. Compose runs private Postgres → migrate → api/worker with separate credentials and a persistent volume. Image smoke now uses real Postgres, repeats migrations, checks worker schedule/UID/shutdown, and stops DB to prove ready 503/live 200. Added database-log canary protection and S05 carry-forward notes; EF Core/Relational 10.0.12 respect cooldown. Full `make deps-dotnet check test` passes (189 .NET cases). Empty/repeated `make up` passed (two migration rows, worker schedule present), prior image smoke passed; final privacy-config image/compose rerun is underway. Next: independent whole-diff code/security review, then evidence/close.

- **2026-10-16 · Review → Verify:** Owner confirmed the account usage limit reset; independent reviewer restarted after its earlier attempt returned no review. Completed whole-diff review at 6c3c6bb: APPROVE, zero findings, security pass included. Final image/compose, `make gen-check` and all branch CI jobs passed. Evidence written in `evidence/S04-verification.md`. Backlog #1 rechecked against still-open upstream issue 13950; retained for dependency review/before S24.
- **2026-10-16 · Verify → Close:** All five exit criteria have evidence. Outcome/board/backend docs updated; TD-062 accepted. No OWNER item. Preparing the CI-verified squash merge; main changes only after the squash SHA is green.

## Outcome
**Built.** A runnable api/worker/Postgres stack with separate application/migrator roles, schema-owned EF migration registration/history and a shared advisory lock. Explicit connection/transaction sessions set trusted user identity locally and safely through pooling. Transactional outbox, per-handler processed markers, SKIP LOCKED jobs, capped retries/dead letters and persistent UTC cron run in the worker. Opted-in unsafe POSTs gain bounded, user/route-isolated 24-hour replay with payload conflicts and atomic database effects. Database readiness, hardened local compose and real-database image smoke complete the runtime.

**Verification.** All five exit criteria pass with [evidence](evidence/S04-verification.md). Full checks pass: **189 .NET cases**, Dart/app/tool checks/tests, architecture, contract/conformance and gen-check; zero new warnings. Empty/repeated compose and migrations, worker schedule/shutdown, real connection termination, RLS read/write/pooling, six-way request concurrency and fake-clock schedules/retries all pass. Full branch CI green, including Android/emulator. Independent whole-diff code/security review: **1 completed round, 0 blockers/majors/minors**, approved at 6c3c6bb. An initial quota-blocked attempt produced no review and was restarted after the owner's reset. Merge uses only the separately green squash SHA (TD-036/039).

**Deviations and constraints.** No Hangfire: a small database-only queue and Cronos meet this scope. Crash safety guarantees committed database effects, not remote calls; external handlers require stable adapter idempotency keys. Product modules still own future tables; a test-only module and synthetic principals prove RLS without inventing Identity/Account data. Idempotency has no product POST to change yet; future endpoints must add their contract before opting in, and S24 must define pre-auth scopes. Replayed problems refresh traceId for TD-057. The shared test database is paused for health failure/recovery (preserves its mapped port); the isolated image test stops Postgres. Postgres server logs are also inside the privacy boundary, with a tested statement-error/parameter policy carried to S05. New EF Core/Relational use 10.0.12 for the seven-day cooldown; existing ASP.NET/runtime security pins stay 10.0.13.

**Follow-ups.** Backlog #1 rechecked and retained: upstream Dependabot issue 13950 still leaves downstream CPM lock files stale; revisit at the next dependency review/before S24. Existing S03 #53 remains for S24. S05 provisions real credentials and preserves database-log privacy. AC-012 user-history purge and MN-005 allowance/Buddy integration remain later module steps. No new review finding or paid service.

**TDs.** TD-062 accepted: explicit shared database sessions, transaction-local identity, migration registration/lock and database-only atomic worker handlers. Existing Accepted TDs unchanged.

**Metrics.** Planned **M**, actual **L** because persistence, replay, privacy and process/container failure boundaries require a larger integration suite. **4 implementation WPs**, **29 new persistence tests** (net +28 vs S03, 189 total), **1 completed independent review round / 0 findings**. Image **164.43 MiB**, gzip image archive **68.76 MiB**, api/worker UID **1654**, migrate/repeat exit **0**, API shutdown **0 s / exit 0**. Lesson: driver privacy settings do not protect database server logs, and positional parameters require separate commands for multi-statement maintenance.
