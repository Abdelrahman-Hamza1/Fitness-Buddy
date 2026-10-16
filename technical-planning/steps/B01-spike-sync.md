# B01 — Spike: sync

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | S04 ✅, S08 ✅ | M | Codex | ⬜ Not started |

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
- [ ] The convergence simulation passes ≥ 1,000 randomised runs against the fake, and ≥ 50 against the real API.
- [ ] Fault-injection tests pass (no loss, no duplicates).
- [ ] 5,000-row push + fresh-device pull timings are recorded (target: a few seconds on Wi-Fi).
- [ ] **TD-006 and TD-031 decided** (confirmed, or switch to PowerSync with the reasons). `05` §5 is updated with any protocol changes.

## Read first
`05-data-and-sync.md` §4–5 · `04-backend.md` §7

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Outcome
_Written in Phase E._
