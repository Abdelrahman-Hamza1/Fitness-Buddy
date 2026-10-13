# S26 — Sync backend

| Phase | Depends on | Size | Status |
|---|---|---|---|
| P3 Accounts, sync & prod | S12, S24 | M | ⬜ Not started |

**Goal.** The production UserData module: validated document storage, push/pull with last-write-wins and history, and the cleanup jobs, secured per user.

**Spec:** AC-010, AC-011, AC-012 (server side), G6, G7 · **Decisions:** TD-006, TD-031, TD-025

## Scope
- **Schema `userdata`** (from the S12 prototype, hardened): `documents` (PK user+entity+id, `server_seq` from a sequence, index `(user_id, server_seq)`), `row_history` (30-day retention), **RLS** on both.
- **Entity registry:** the list of synced entities and their JSON schemas per `schemaVersion`, sourced from the contract (`contracts/openapi/` sync components). Unknown entities or invalid payloads → per-change `invalid` results.
- **`POST /v1/sync/push`:** ≤ 500 changes, per-change result (`accepted` / `stale` / `invalid`), HLC comparison, a **future-clock clamp**, a history copy when a version from another device is replaced (and on delete), idempotent replays, the returned max `server_seq`.
- **`GET /v1/sync/pull`:** cursor paging (≤ 500), stable under concurrent pushes, returning tombstones.
- **`GET /v1/sync/history/{entity}/{id}`:** earlier versions within 30 days (G7).
- **Policies:** registered users only (anonymous → `403`), per-user rate limits, payload size limits.
- **Jobs:** purge `row_history` > 30 days, compact tombstones > 30 days (scheduled in the worker).
- **Metrics:** pushes/pulls, changes per request, stale/invalid counts, latency.

## Out of scope
- The app's engine and UI (S27). Account deletion (S28).

## Fixed by the plan
- Document storage, not mirrored tables (TD-031, as confirmed by S12). Server-assigned `server_seq` ordering for pulls.

## Decide in the low-level plan
- How entity JSON schemas flow from the contract into the backend at build time.
- Partition readiness (keep the schema partition-friendly by `user_id`, no partitioning yet).

## Notes from earlier steps
- **From S08:** reconcile the client's max forward drift (24 h default) with the server clamp ("a few minutes", `05` §5.2). Compare HLCs with `COLLATE "C"` (TD-049).

## Exit criteria
- [ ] Integration tests: LWW for concurrent edits from two devices, history captured, a tombstone beats an older update, a future-dated HLC is clamped, invalid payloads are rejected per change, pagination is complete under concurrent pushes, anonymous → `403`, **user A can't read B's documents even with a crafted request**.
- [ ] The convergence simulation from S12 passes against the production module.
- [ ] Purge and compaction jobs tested with a fake clock.
- [ ] Load test: 10,000-change push + pull on staging, timings recorded.

## Read first
`05-data-and-sync.md` §4–5 · `04-backend.md` §6–7 · S12 Outcome

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
