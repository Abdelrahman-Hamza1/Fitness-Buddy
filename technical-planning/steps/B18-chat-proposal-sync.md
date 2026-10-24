# B18 — chatMessage & proposal sync entities (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | A21 (WP4 codec shape and size budget) | M | Codex | ⬜ Not started |

_New step (orchestrator, 2026-10-24, A21 plan review PA1): the persistence of chat messages and pending proposals moved out of A21 to A22 (`chat_messages`) and A23 (`proposals`), and both sync like any row (G3). Like B17 for `personalFood`, the server side is its own step. The app builds against its **contract commit first**._

**Goal.** The server stores, validates, serves and erases the `chatMessage` and `proposal` sync entities exactly as the contract says, so A34 can upload them and A23's pending cards survive a reinstall.

**Spec:** AI-045 (pending cards survive), AC-010, AC-012 (offline changes sync; row-level last-write-wins + history, `05` §5), AC-031 (deletion covers them), AC-040 (privacy: no user content in logs) · **Decisions:** TD-031, TD-049, TD-061, TD-080 (entity-specific semantic admission), TD-083 (proposal persistence belongs to A23)

## Scope
- **Contract commit first:** consume **A21 WP4’s codec shape and size budget**, then define `chatMessage` v1 / `proposal` v1 in `contracts/openapi/sync-entities.json`, fixtures in `contracts/testdata/sync/entity-payloads.json`, regenerated embedded `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json` and the `contracts/README.md` admission pointer. Order: **A21 WP4 → B18 contract commit → A22 → A23**. Both app steps build against the contract; breaking changes require owner approval.
- **Envelope/schema admission only (PA16):** validate required/optional fields and types, identity/reference field shapes, integer `codecVersion`, closed role/status/outcome vocabularies and JSON strings bounded to **32768 UTF-16 units**. Message role/status follows A22’s contract; proposal status is `pending / confirmed / discarded / superseded` (`05` §2.3), outcome is `unchanged / adjusted chips / discarded` (nullable before resolution). Pin omitted/null/wrong-type/boundary cases. If exporter needs entity-specific admission, keep it limited to these envelope/vocabulary/size rules; B17-style corpus/byte-equality/app mapper parity tests pin the same boundary semantics.
- **`chatMessage` shape:** text/role/status plus `codecVersion` and a bounded JSON budget field on the **assistant** message row. That row stores the shared question-budget payload once; user rows need no budget. `chat_messages` **attachment refs (local paths) are excluded from the sync entity**, as images are not synced (`05` §2.3).
- **`proposal` shape:** one card/row, kind/status/outcome/resolution metadata, immutable `originMessageId`, current `budgetMessageId`, `codecVersion`, bounded `interpretation` and `draft` JSON strings. Interpretation contains only that card’s normalized intents; compact draft carries per-card state and owned question IDs, **no duplicated message budget**. Payload strings are opaque bounded JSON: no validation of engine dimensions, nutrient facts, issued-ID counts/ownership or relationships between rows.
- **No cross-row validator:** B18 never loads sibling cards/messages to admit a row and never enforces message/card consistency. A21 `restore(message, cards by budgetMessageId)` produces `budgetConflict` / `sessionIncomplete`; A23 handles recovery through versioned applier transactions. B18 does not upgrade its opaque JSON to a version-specific engine semantic validator.
- **Behaviour:** prove new entities on generic owner-authorized pull/history, LWW/history, tombstones/compaction fences, guest 403 and RLS paths; B05 already supplies this storage machinery.
- **Erasure:** account deletion removes both entities, history and fences.
- **Privacy:** no message text or proposal content in **error responses**, logs or telemetry (B17 canary pattern). Owner-authorized pull/history intentionally returns the stored content exactly; do not mistake that for an error-response leak.
- Fresh independent code review and a separate Codex security review (`PROCESS.md` Part C).

## Out of scope
- The app tables, ops and UI (A22, A23). Uploading (A34). Cross-row consistency, question-budget/engine validation (A21 restore). Local attachment paths/images and their transfer.

## Exit criteria
- [ ] Validator and corpus tests: every envelope/vocabulary/size rule accepts its limit and rejects just past it (32768/32769 UTF-16 units, including supplementary characters); the constants equal the corpus; the app corpus test passes in both directions.
- [ ] Persistence tests (Testcontainers): accepted push, each invalid envelope/vocabulary/size case → `invalidPayload` with no content in error responses or telemetry; authorized pull/history round-trip content, tombstone, cross-user isolation, guest 403. Opaque engine-JSON and cross-row inconsistencies remain admitted if envelope-valid, for A21 restore to diagnose.
- [ ] Account deletion test includes both entities, history and fences.
- [ ] `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet` green; CI green.
- [ ] Fresh security review: no open blocker or major.

## Read first
`05-data-and-sync.md` §2.3, §5.5 · the B17 card and its Outcome (the pattern) · A21's card (session codec) and A23's card · TD-080

## Owner involvement
None.

---

## Low-level plan
_Full plan written in Phase B by Codex; binding scope amendments PA16–PA18/PA24/PA25 accepted by the orchestrator at A21 re-check `bd430bf` (2026-10-24)._

**Planning constraints:** consume A21 WP4 projections first; contract-only handoff precedes A22. Restrict pure validators/corpus to envelope, closed role/status/outcome values, codecVersion integer and bounded opaque JSON fields; no cross-row DB queries or engine vocabulary/nutrition validation. Add explicit tests in the full plan: `B18 JSON string limit counts UTF-16 units including supplementary characters`; `B18 opaque interpretation draft and budget JSON round trip without engine validation`; `B18 row admission does not require related message or card rows`; `B18 proposal status accepts pending confirmed discarded superseded`; `B18 chatMessage excludes local attachment paths`; `B18 authorized pull returns content while errors logs and telemetry omit it`. Test missing/unknown/wrong-type closed fields via the shared corpus, preserve generic RLS/erasure/history behavior, and retain Docker-free pure tests separate from Claude’s Testcontainers/conformance runs. Size remains M; no server cross-row validator is planned.

## Progress log
- 2026-10-24 · A21 re-check `bd430bf` findings PA16–PA18/PA24/PA25 applied: dependency on A21 WP4 shape/size; bounded opaque engine JSON with envelope/vocabulary admission only; assistant-row budget and origin/current proposal binding; 32768 UTF-16 units; authorized reads retain content, errors/logs/telemetry do not; attachment paths excluded. Planning only.

## Outcome
_Written in Phase E._
