# S04 — Backend persistence, outbox & jobs

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P0 Foundations | S03 | M | ⬜ Not started |

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
- [ ] `make up` brings up api + worker + Postgres. `migrate` runs from an empty database, and runs again with no changes.
- [ ] Integration tests (Testcontainers): an outbox event is delivered once even if the worker crashes mid-dispatch (handler effect happens exactly once). A failing job retries with backoff and dead-letters after N attempts. A scheduled job fires on schedule (fake clock).
- [ ] RLS test: user A's query without a user filter returns none of B's rows.
- [ ] Idempotency tests: replay returns the same response. Same key + different body → `409`.
- [ ] `/health/ready` reports the database as down when Postgres is stopped.

## Read first
`04-backend.md` §3.3–3.4, §6–7 · `05-data-and-sync.md` §4

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
