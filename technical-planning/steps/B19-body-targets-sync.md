# B19 — Body & targets sync entities (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B05 ✅, **B18**, **A13a** (contract), **A14** | M | Claude | ⬜ Not started |

_New step (orchestrator, 2026-10-28, A13 plan review PA12; outline card, the Low-level plan is written in Phase B). The app sides are A13a (targets entities) and A14 (weigh-ins); the upload is A34's. **Tier: Risky** (user-data admission, untrusted input, account erasure)._

**Goal.** The server admits, stores, serves and erases the body and targets sync entities exactly as the contract and their wire rules say, so A34 can upload profile, goal phases, target settings and weigh-ins.

**Spec:** TG-001, TG-012, TG-040 (data that syncs), WB-001, WB-003 (weigh-ins), AC-010 (data syncs to the account), AC-012 (offline changes sync; row-level last-write-wins + history, `05` §5), AC-031 (deletion covers them) · **Decisions:** TD-031, TD-049, TD-080, TD-089 (Proposed), TD-090 (Proposed)

## Scope
- **Starts from A13a WP1's contract commit** on `main`: `profile`, `goalPhase`, `targetSettings` v1 in `contracts/openapi/sync-entities.json`, fixtures in `contracts/testdata/sync/entity-payloads.json`, the regenerated embedded `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json`, and the "targets semantic rules" section in `contracts/README.md`. B19 doesn't change those three v1 schemas; a needed change goes back to the app track as a contract commit first (breaking → owner).
- **Semantic admission of the targets wire rules (TD-080), exactly A13 PA6's `TargetRules.wire` and nothing more** (app-only plausibility ranges are not sync rules). The rules are listed once, in `contracts/README.md` § "Targets semantic rules", the single source; B19 admits exactly that list (and the row-id rule there). Invalid rows return `invalidPayload` with no value in the response or telemetry.
- **`weighIn` v2 (A14 D7/PA4, deferred to here):** a new contract version (own commit first): the v1 fields + `tzOffsetMin` (integer −720…840), `inputValue` (number ≥ 0), `inputUnit` (enum `kg` | `lb`), `preferredForDay` (boolean); **v1 stays untouched** and accepted. Registry, fixture, regenerated export, and admission of both versions.
- **Shared corpus and app parity (TD-080):** a Dart-generated vector corpus in `contracts/testdata/sync/` for the targets wire rules and `weighIn` v2, with a byte-equality drift test (`fb_domain` generator) and an app mapper test proving the actual A13a/A14 decoders and writers round-trip the vectors; C# tests read the same corpus.
- **Conformance:** push accepts a valid document of each entity from its owner; each wire rule and each schema rule (unknown enum, extra or missing field, over-long string) has a rejection case.
- **Behaviour:** pull, LWW with history (`row_history`, 30 days), tombstones and compaction fences, guest 403, RLS (another user can't read them), item history `GET /v1/sync/history/{entity}/{id}`: the existing generic paths, proven for these entities. Concurrent target-settings or phase rows that conflict across rows are **not** rejected (cross-row selection is the app's read projection, A12 PA6 / TD-089).
- **Erasure:** B06's account deletion removes these documents, history and fences.
- **Telemetry:** metrics and logs carry no body values, names, weights or kcal (the B05 canary pattern).
- A fresh Opus **security review** of the diff (authorization/RLS, input handling, logging), findings fixed and recorded in `evidence/B19-verification.md`.

## Out of scope
- The app's tables, ops and UI (A13a–c, A14). Uploading from the app (A34). Plausibility ranges (app-only, A13 D15).

## Fixed by the plan
- One JSON document per row in `userdata.documents` (TD-031); the contract is the payload authority, with no runtime schema fetching (`05` §5.5). Wire rules equal A13's `TargetRules.wire` (A13 PA6).

## Decide in the low-level plan
- Where the targets validators plug in (the B17 entity-specific hook after schema validation) and how their constants are shared with the corpus.
- How `weighIn` v1 and v2 coexist in admission and pull (schemaVersion per change).

## Exit criteria
- [ ] Validator tests: every wire rule in `contracts/README.md` § "Targets semantic rules" accepts a valid case and rejects each violation (NaN/infinity/overflow included), equal to the corpus.
- [ ] `weighIn` v2: valid and invalid cases (tz offset bounds, unit enum, negative input value); v1 still accepted.
- [ ] Persistence tests (Testcontainers): accepted push, each invalid case → `invalidPayload` with no value in the response or telemetry, pull, history, tombstone, cross-user isolation (RLS), guest 403.
- [ ] Account deletion test includes the four entities' documents, history and fences.
- [ ] `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet` green; CI green.
- [ ] Security review: no open blocker or major.

## Read first
`05-data-and-sync.md` §5.5 · `04-backend.md` §4.2, §7 · the A13 card's D2, D3, D15 and PA6 · the A14 card's D6/D7 and PA4 · B17's card and Outcome (the hook and corpus pattern)

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B._

## Progress log
- 2026-10-28 · Outline card created from the A13 plan review (PA12); board rows added.

## Outcome
_Written in Phase E._
