# B01 — Spike: sync

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | S04 ✅, S08 ✅ | M | Codex | ✅ Done |

_Old ID: S12 (renumbered by TD-063, 2026-10-16)._

**Goal.** Prove that the custom delta sync (TD-006) with document storage on the server (TD-031) converges reliably, before the app's data model grows around it. Otherwise, switch to PowerSync now, while it's cheap.

**Spec:** AC-010, AC-011, AC-012 (feasibility), OF-03 (simulated) · **Decisions:** TD-006, TD-031

## Scope
- **Backend prototype** (UserData module, minimal): `userdata.documents` + `row_history`, a global `server_seq`, `push` (HLC compare, history copy when another device's version is replaced, future-clock clamp) and `pull` (cursor paging). Two sample entities. Contract entries marked experimental.
- **Post the protocol first:** the wire protocol (batches, cursor, HLC, results) goes in this card's Progress log and `05` §5 at the start, so A01's outbox follows it.
- **Prototype client in `tools/sync_sim/` (Codex's, kept, not throwaway):** a `SyncEngine` behind the interface from `05` §5 over a simulated outbox shaped like `05` §3: push batches, pull and apply with LWW, advance the cursor. The convergence simulation is reused by B05 and A34. The production engine is A34's; the real outbox is A01's. Any protocol change goes in this card's Progress log and in `05` §5 so A01/A34 follow it.
- **Convergence simulation** (property-based, Dart): N simulated devices perform random creates/updates/deletes offline, then sync in random orders and interleavings, (a) against an in-memory fake implementing the server rules and (b) against the real API in Docker. Assert convergence, no silent loss (every replaced version exists in history), tombstones win correctly.
- **Fault injection basics:** a dropped connection mid-push, a duplicated push, a crash between push and acknowledgement.
- **Throughput:** pushing 5,000 rows and pulling them on a fresh device, timed.
- **PowerSync comparison note:** a short evaluation of what PowerSync would change (drift integration, self-hosting against our Postgres, guest mode), to make the decision explicit.

## Out of scope
- Production hardening, payload schema validation, history UI, scheduling (B05/A34).

## Fixed by the plan
- Single-owner, row-level LWW + 30-day history (AC-012). HLC ordering (`05` §5.2).

## Decide in the low-level plan
- HLC encoding on the wire and in Postgres (sortable text vs composite columns).
- Pull page size and cursor semantics under concurrent pushes.

## Notes from earlier steps
- **From S08:** HLC text format and receive result (`ok`/`driftRejected`) are in `fb_domain` (TD-049). Add `contracts/testdata/sync/hlc_cases.yaml` so C# matches.

## Exit criteria
- [x] The convergence simulation passes ≥ 1,000 randomised runs against the fake, and ≥ 50 against the real API.
- [x] Fault-injection tests pass (no loss, no duplicates).
- [x] 5,000-row push + fresh-device pull timings are recorded (target: a few seconds on Wi-Fi).
- [x] **TD-006 and TD-031 decided** (confirmed, or switch to PowerSync with the reasons). `05` §5 is updated with any protocol changes.

## Read first
`05-data-and-sync.md` §4–5 · `04-backend.md` §7

## Owner involvement
None.

---

## Low-level plan
### Design and decisions

Self-reviewed against `03`, `04` §3/6/7, `05` §5, `09` §4, `10` and TD-049/062–066. Plan approved under TD-037: no owner item or new dependency. This is an experimental feasibility spike, not production sync.

- **D1 · Wire first.** Experimental `/v1/sync/push`, `/pull` and `/history`; two synthetic entities (`diaryEntry`, `weighIn`), schema version 1, object payload. HLC is exactly TD-049's sortable text. Batch/page maximum 500, default page 100. Sequence cursors are decimal strings (avoid JavaScript integer rounding); push acknowledgements never advance a pull cursor. See `05` §5.4 for the complete handoff to A01/A34.
- **D2 · Commit order.** Each push transaction takes a per-user advisory transaction lock **before** allocating global sequence values (sequences use `CACHE 1`). Pull uses ascending `server_seq > cursor`, returns the last delivered sequence (unchanged on an empty page); updates during paging move forward and are eventually delivered. A sequence gap is harmless. Tests hold a transaction open to prove a later same-user push cannot overtake it. No offset or global high-watermark cursor.
- **D3 · Recovery.** Archive a distinct version when displaced **and when an offline incoming version loses** to another device. Same-HLC retries are no-ops; reuse with different contents is invalid. This catches loss that a winner-only convergence test misses. History is immutable/deduplicated by row + HLC; all user-owned tables have forced RLS. Retention scheduling remains B05.
- **D4 · Clock bound.** The spike clamps *admission*: over five minutes ahead returns per-change `invalid` / `clockDrift` plus server time; no silent HLC rewriting and no acknowledgement/deletion of that pending change. It tests this explicitly. This refines the card's shorthand “future-clock clamp”; canonical rewrite/re-stamping is deferred to B05's clock policy (TD-049), because rewriting without persistent receipt mapping makes retries and concurrent local edits unsafe. HLC library's 24-hour receive default is unchanged.
- **D5 · Isolated access.** Before B04 authentication, normal API runs return 501 for these routes. Only the dedicated `SyncSpike` environment with an explicit enabled flag, a 32-byte random test key and a configured synthetic user can open the prototype. The key is checked in constant time; no request-supplied user id, no test bypass for production authentication. The Docker harness binds to loopback and uses an ephemeral database. The module's application port and storage remain reusable for B05; the access gate is removed/replaced then.
- **D6 · Durable client work.** `tools/sync_sim/` is a pub workspace member using existing `fb_domain`, `dio`/generated `fb_api_client` and `test`/`yaml` dependencies, no new libraries. The simulated persistent store holds rows, outbox versions and cursor separately from the engine. Snapshot a batch, acknowledge only those exact HLCs, merge pulls by LWW, and persist application + cursor together. Restart the engine over the same store for crash tests. Real SQLite and production scheduling belong to A01/A34.

### Work packages and files

1. **WP0 — Plan/protocol:** this card, own board row, `05` §5.4; publish before implementation.
2. **WP1 — Contract:** `contracts/openapi/modules/userdata.yaml`, root registration, bundled contract and generated client; shared HLC vectors in `contracts/testdata/sync/hlc_cases.yaml`. Own commit before server code, Progress log naming the handoff. No early main contract merge is needed for this spike.
3. **WP2 — Server and focused tests:** new `backend/src/Modules/UserData/` (Domain HLC/rules, Application port/handler, Infrastructure context/migration/repository, Api DTOs/endpoints), module registration/project references/Docker restore list. Existing persistence test assembly covers real Postgres RLS, rollback/retries, clock boundary, history and cursor concurrency; contract/runtime tests cover the disabled gate and wire JSON.
4. **WP3 — Client simulation:** `tools/sync_sim/`, workspace manifest/lockfile; fake and real transports behind the same interface, seeded randomized scenarios, HLC vector parity, retry/drop/crash/tombstone assertions. `make sync-spike` and `tools/scripts/sync-spike.sh` run the built API image + pinned Postgres with temporary data; CI image job runs the real harness. Record 1,000 fake runs, 50 real runs and 5,000-row timing.
5. **WP4 — Decide and close:** dated primary-source PowerSync research in `technical-planning/research-notes.md`, decide pending TD-006/031 using measurements, update backend guide/`05`, independent whole-diff architecture/correctness/security review, fix and re-review majors, formal evidence, Outcome/board/backlog, full gates and CI-verified squash.

### Verification and risks

| Requirement/rule | Evidence planned |
|---|---|
| AC-010/011; OF-03 feasibility | Randomized multi-device create/update/delete, fresh-device restore and convergence, both transports |
| AC-012 | Every cross-device losing version in history, latest HLC wins including tombstones, retries/crashes preserve confirmed data |
| TD-049 (`05.5-hlc`) | Shared valid/invalid/order vectors in Dart and C# |
| `04.6-rls`, `09.4-no-user-content` | App-role forced RLS and anonymous isolation, no payload logging, production gate closed |
| `05.5-cursors` | Concurrent transaction/sequence ordering, paging while rows change, empty pages and push-cursor independence |
| Throughput | 5,000 small synthetic rows, push then fresh pull, environment and wall times recorded (loopback is not Wi-Fi) |

Main risks: false confidence from a matching fake (mitigate real container + independent SQL/RLS tests); out-of-order sequence commits (D2); losing stale offline writes (D3); future HLCs and clock recovery (D4); prototype accidentally exposed (D5). Dataset-id recovery remains proposed TD-066/B05, with a follow-up rather than implicitly changing an accepted decision.

## Outcome
**Custom sync and document storage confirmed:** TD-006 and TD-031 are now Accepted. The evidence is [B01-verification.md](evidence/B01-verification.md). Production sync remains B05/A34, after identity B04.

Built the UserData module and schema with forced RLS; immutable HLC-based retries, LWW documents/tombstones, recoverable incoming losers and displaced versions, per-user commit-ordered sequence allocation and paged document/history cursors. Published the experimental contract before code and regenerated the Dart client. Normal API runs keep these endpoints closed (501); the ephemeral harness has a dedicated environment/key/fixed synthetic principal.

Kept `tools/sync_sim/` for reuse: generated API models, shared fb_domain HLC, independent fake, simulated durable store/outbox, full-version oracle, concurrency, retries, connection loss, restart and cursor-commit faults. `make sync-spike` and the CI image job run the shipped image against pinned Postgres. Final measurements: **1,000 fake runs, 50 real runs**, **5,000 rows push 2,818 ms / fresh pull 144 ms**. Single laptop Docker-loopback run; the fresh pull also contains prior scenario rows. This is not a Wi-Fi/phone measurement.

**Deviations and reasons:** future-clock admission is rejected and retained pending instead of silently rewriting an immutable HLC (D4; B05 decides recovery). Same-device losers are retained too, so a reused HLC cannot change meaning after replacement. The simulator uses checkpointed in-memory state instead of production drift; actual phone persistence is A01/A34 scope. No dataset-id/retention/auth/schema-hardening completion is claimed. No new paid service, dependency or TD number was needed.

**Review:** one independent whole-diff architecture/correctness/security round (`b01_independent_review`, 9422c34..c1a4d2a): zero blockers/majors, one minor (null change element returned 500), one nit (stale protocol reference/overview). Both fixed, with a 400/no-partial-write regression and local checks under TD-054. No open review findings. Formal verification followed review.

**Metrics:** planned M, actual M; five WPs (WP0–WP4); one review round; **+18 .NET cases** (207 total, including six new module architecture cases) and **five Dart simulator tests**. Full `make check test`, `make gen-check`, image smoke and final real harness pass. Follow-ups #54–57 cover production clock/retention/reset/schema rules and real-phone integration, all in their existing B05/A34 scope. Source-backed PowerSync comparison is in `technical-planning/research-notes.md` (2026-10-16).

## Progress log

- 2026-10-16 · Orient → Plan/WP0: clean `main` at 9422c34; read AGENTS Start here, board §4–8, dependencies S04/S08 and required design docs. B01 ready independently of A01. Self-reviewed/approved plan under TD-037. Protocol posted in `05` §5.4 before code: fixed-width HLC, immutable version identity, per-change results, string cursors, no push-to-pull cursor jump; future-clock admission bound explained in D4. No owner input needed.

- 2026-10-16 · WP1 contract handoff: added experimental UserData push/pull/history and DTOs, immutable HLC retry identity, required nullable fields and string sequence cursors; generated Dart client with `make gen`. Shared HLC parse/order vectors published. These routes are unavailable in ordinary runs; server implementation follows in its own commit.

- 2026-10-16 · WP1 amendment: declare the existing pipeline’s X-Request-Id header on experimental 401/501 responses; no wire behavior change. WP2 preliminary checks: 204 .NET tests pass, including real Postgres sync/RLS/cursor tests; conformance caught these missing contract declarations and cursor parameter metadata, being corrected before the WP2 commit.

- 2026-10-16 · WP2 complete: UserData module, schema-local migration, forced RLS on documents/history, per-user pre-allocation transaction lock, immutable retries/version conflicts, stale and displaced version archive (including same-device versions), tombstones and paged cursors. SyncSpike environment/key/fixed synthetic principal gate tested closed in Production/Development. `make check test` green: 204 .NET tests, existing Dart suites and contract gates. No new dependency.

- 2026-10-16 · WP3 complete → Review: reusable `tools/sync_sim` engine/store/transport port, 1,000 fake randomized runs, full-payload version recovery, faults and byte/row/cursor guards. Real Docker API passes 50 seeded runs plus actual partial-body TCP drop and retry/crash/concurrent-edit cases; initial 5,000 rows push 3,096 ms / fresh pull 174 ms (loopback, not Wi-Fi). `make sync-spike` and CI image integration added. `make check test` green (five sync_sim tests); extra UTC-offset and forced-RLS write tests bring .NET total to 206, `make check-dotnet test-dotnet` green. Sequences explicitly CACHE 1. Protocol handoff section numbered `05` §5.4. Primary-source PowerSync/sequence research recorded. Independent whole-diff architecture/correctness/security review next, before formal verification.

- 2026-10-16 · Review round 1 complete: independent reviewer `b01_independent_review` inspected all changes from 9422c34 to c1a4d2a, including architecture and auth/RLS/secrets/logging/exposure security pass. Zero blockers/majors, one minor (null array element yields 500) and one nit (stale protocol references/overview). Both are being fixed; TD-054 requires local verification, not a new review round for minor/nit fixes. Contract description references corrected to `05` §5.4 and regenerated before the server fix commit. Reviewer also confirmed benchmark fresh pull includes prior scenario rows.

- 2026-10-16 · Review fixes → Verify: null push-array elements now return RFC 9457 validation 400 before mapping/database work; regression checks `[null]` and `[valid,null]` leave the user dataset empty. Updated `05` §5.2 overview to match §5.4 (serverTime acknowledgements, immutable outbox versions, archived losers). Both review findings fixed; local diff checked under TD-054, no re-review required for minor/nit findings. Post-review `make check test` passes: 207 .NET cases and all Dart suites including five sync_sim cases/1,000 seeds. Generated-code/image/final real-harness verification continues before close.

- 2026-10-16 · WP4/Verify → Close: post-review `make check test` (207 .NET, five sync_sim tests/1,000 seeds), `make gen-check`, `make image-smoke` and real Docker harness all pass. Final 50 real seeds and faults pass; 5,000-row push 2,818 ms / fresh pull 144 ms, including prior scenario rows (loopback only). Evidence written, all exits ticked, TD-006/031 confirmed, current docs/board updated and #54–57 recorded. Self-accepted under TD-037; CI-verified squash/fast-forward is the final gate before handoff. Branch pushed before that wait.
