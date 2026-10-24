# B18 — chatMessage & proposal sync entities (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B05 ✅, **A21** (the versioned proposal session codec) | M | Codex | ⬜ Not started |

_New step (orchestrator, 2026-10-24, A21 plan review PA1): the persistence of chat messages and pending proposals moved out of A21 to A22 (`chat_messages`) and A23 (`proposals`), and both sync like any row (G3). Like B17 for `personalFood`, the server side is its own step. The app builds against its **contract commit first**._

**Goal.** The server stores, validates, serves and erases the `chatMessage` and `proposal` sync entities exactly as the contract says, so A34 can upload them and A23's pending cards survive a reinstall.

**Spec:** AI-045 (pending cards survive), AC-010, AC-012 (offline changes sync; row-level last-write-wins + history, `05` §5), AC-031 (deletion covers them), AI-150 (privacy: no user content in logs) · **Decisions:** TD-031, TD-049, TD-061, TD-080 (entity-specific semantic admission), TD-083 (proposal persistence belongs to A23)

## Scope
- **Contract commit first** (in this step's own commit, with A21's codec shape as input): `chatMessage` v1 and `proposal` v1 in `contracts/openapi/sync-entities.json`, fixtures in `contracts/testdata/sync/entity-payloads.json`, the regenerated embedded `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json`, the `contracts/README.md` pointer to the semantic rules. A22 and A23 align their payloads with it. Breaking changes go to the owner.
- **Bounds:** every JSON string field ≤ 32 KiB (the sync limit); A21's compact per-card projection (A21 `encodeCard`) is what fits, not the 512 KiB local input.
- **Semantic admission** per TD-080: a hand-written validator for the rules the exporter can't express (lengths in UTF-16 units, closed vocabularies for message role/status and proposal lifecycle, duplicate JSON keys, ill-formed UTF-16, per-card/message consistency), pinned to a shared corpus generated from the Dart reference with a byte-equality drift test, plus the app-side corpus test (the B17 pattern).
- **Behaviour** (generic paths proven for the new entities): pull, LWW with history, tombstones and compaction fences, guest 403, RLS, history endpoint.
- **Erasure:** account deletion removes both entities, history and fences.
- **Privacy:** no message text, no proposal content in responses, logs or telemetry (the B05/B17 canary pattern).
- A fresh Codex security review (Part C) of the diff.

## Out of scope
- The app tables, ops and UI (A22, A23). Uploading (A34).

## Exit criteria
- [ ] Validator and corpus tests: every rule accepts its limit and rejects just past it; the constants equal the corpus; the app corpus test passes in both directions.
- [ ] Persistence tests (Testcontainers): accepted push, each invalid case → `invalidPayload` with no value in the response or telemetry, pull, history, tombstone, cross-user isolation, guest 403.
- [ ] Account deletion test includes both entities, history and fences.
- [ ] `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet` green; CI green.
- [ ] Fresh security review: no open blocker or major.

## Read first
`05-data-and-sync.md` §2.3, §5.5 · the B17 card and its Outcome (the pattern) · A21's card (session codec) and A23's card · TD-080

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B by Codex._

## Progress log
_One dated line per event, newest last (process §8a)._

## Outcome
_Written in Phase E._
