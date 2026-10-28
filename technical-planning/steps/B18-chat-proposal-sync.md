# B18 — chatMessage & proposal sync entities (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | A21 (WP4 codec shape and size budget) | M | Claude (TD-085) | 🟨 In progress |

_New step (orchestrator, 2026-10-24, A21 plan review PA1): the persistence of chat messages and pending proposals moved out of A21 to A22 (`chat_messages`) and A23 (`proposals`), and both sync like any row (G3). Like B17 for `personalFood`, the server side is its own step. The app builds against its **contract commit first**._

**Goal.** The server stores, validates, serves and erases the `chatMessage` and `proposal` sync entities exactly as the contract says, so A34 can upload them and A23's pending cards survive a reinstall.

**Spec:** AI-045 (pending cards survive), AC-010, AC-012 (offline changes sync; row-level last-write-wins + history, `05` §5), AC-031 (deletion covers them); rule `09.4-no-user-content` (privacy: no user content in error responses, logs or telemetry; CLAUDE.md rule 6) · **Decisions:** TD-031, TD-049, TD-061, TD-080 (entity-specific semantic admission), TD-083 (proposal persistence belongs to A23)

## Scope
- **Contract commit first:** consume **A21 WP4’s codec shape and size budget**, then define `chatMessage` v1 / `proposal` v1 in `contracts/openapi/sync-entities.json`, fixtures in `contracts/testdata/sync/entity-payloads.json`, regenerated embedded `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json` and the `contracts/README.md` admission pointer. Order: **A21 WP4 → B18 contract commit → A22 → A23**. Both app steps build against the contract; breaking changes require owner approval.
- **Envelope/schema admission only (PA16):** validate required/optional fields and types, identity/reference field shapes, integer `codecVersion`, closed role/status/outcome vocabularies and JSON strings bounded to **32768 UTF-16 units**. Message role/status follows A22’s contract; proposal status is `pending / confirmed / discarded / superseded` (`05` §2.3), outcome is `unchanged / adjusted chips / discarded` (nullable before resolution). Pin omitted/null/wrong-type/boundary cases. If exporter needs entity-specific admission, keep it limited to these envelope/vocabulary/size rules; B17-style corpus/byte-equality/app mapper parity tests pin the same boundary semantics.
- **`chatMessage` shape:** text/role/status plus `codecVersion` and a bounded JSON budget field on the **assistant** message row. That row stores the shared question-budget payload once; user rows need no budget. `chat_messages` **attachment refs (local paths) are excluded from the sync entity**, as images are not synced (`05` §2.3).
- **`proposal` shape:** one card/row, kind/status/outcome/resolution metadata, immutable `originMessageId`, current `budgetMessageId`, `codecVersion`, bounded `interpretation` and `draft` JSON strings. Interpretation contains only that card’s normalized intents; compact draft carries per-card state and owned question IDs, **no duplicated message budget**. Payload strings are opaque bounded JSON: no validation of engine dimensions, nutrient facts, issued-ID counts/ownership or relationships between rows.
- **No cross-row validator:** B18 never loads sibling cards/messages to admit a row and never enforces message/card consistency. A21 `restore(message, cards by budgetMessageId)` produces `budgetConflict` / `sessionIncomplete`; A23 handles recovery through versioned applier transactions. B18 does not upgrade its opaque JSON to a version-specific engine semantic validator.
- **Behaviour:** prove new entities on generic owner-authorized pull/history, LWW/history, tombstones/compaction fences, guest 403 and RLS paths; B05 already supplies this storage machinery.
- **Erasure:** account deletion removes both entities, history and fences.
- **Privacy:** no message text or proposal content in **error responses**, logs or telemetry (B17 canary pattern). Owner-authorized pull/history intentionally returns the stored content exactly; do not mistake that for an error-response leak.
- Fresh independent `code-reviewer` review, `security-reviewer` and `verifier` (Risky; `PROCESS.md` B).

## Out of scope
- The app tables, ops and UI (A22, A23). Uploading (A34). Cross-row consistency, question-budget/engine validation (A21 restore). Local attachment paths/images and their transfer.

## Exit criteria
- [ ] Validator and corpus tests: every envelope/vocabulary/size rule accepts its limit and rejects just past it (32768/32769 UTF-16 units, including supplementary characters); the constants equal the corpus; the `fb_domain` corpus test passes in both directions (codec projections/inverse + wire codes). Mapper-level parity is an A22/A23 exit criterion (D10, rewritten in WP1 with the orchestrator's approval, PA4).
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
_Binding scope amendments PA16–PA18/PA24/PA25 come from the A21 re-check `bd430bf` (2026-10-24). This full plan replaces the Codex placeholder that was never written (step-planner, Claude, 2026-10-28). The architect plan review's required changes PA1–PA9 are applied below._

**Tier: Risky** (sync admission of user data, privacy, erasure). **Size: M**, five ordered WPs, about two sessions. No migration, endpoint, OpenAPI path/schema change, generated-client change, new dependency, paid call or owner item, and **no production C# change** (PA2). Lane 2 (TD-087): `/home/abood/work/fitness_buddy_2`, branch `step/B18-chat-proposal-sync`; every heavy command (`make test-dotnet`, `make test-dart`, `make check-contract`, Testcontainers) runs as `flock ~/.cache/fb-heavy.lock <cmd>`.

### 1. Summary
After B18, `contracts/openapi/sync-entities.json` defines `chatMessage` v1 and `proposal` v1, and the server admits, stores, serves, versions and erases them through the existing B05 machinery. Admission is the schema (types, closed vocabularies, UTF-16 `maxLength`, integer `codecVersion`, UUID references) plus the existing generic representability pass (nested JSON, decimal numbers, unique keys, no U+0000, well-formed UTF-16). B18 pins all of it with tests. The three engine fields (`budgetJson`, `interpretationJson`, `draftJson`) are opaque, bounded JSON, and nothing loads sibling rows. `fb_domain` gains the canonical Dart wire codes and a pure codec inverse of `syncProjection`. A Dart-generated shared corpus built from the real A21 codec pins both sides. A22/A23 build against the contract merge `B18 (contract)`, and A34 uploads after the full merge.

### 2. Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **`chatMessage` v1 fields:** `createdAtMs`, `origin`, `editedByUser` (the shared trio, `05` §5.5), `role`, `text`, `status`, `language`, `replyToMessageId`, `codecVersion`, `budgetJson`. Every field is required (S02 D4). `language`, `replyToMessageId`, `codecVersion` and `budgetJson` are nullable. User rows send `null` for the budget pair; the assistant row carries the one shared budget (PA17). There is **no attachment field** (D8) | Role, text, status, `codecVersion` and one budget field come from A22's binding shape; `language` is in `05` §2.3. `replyToMessageId` links an assistant row to the user message it answers. A23 needs that link to make a crash-retried interpret response idempotent. Adding a field later means `schemaVersion` 2 plus an upgrader |
| D2 | **`proposal` v1 fields:** shared trio, `kind`, `status`, `outcome`, `resolvedAtMs`, `originMessageId`, `budgetMessageId`, `codecVersion`, `interpretationJson`, `draftJson`. `outcome`, `resolvedAtMs`, `originMessageId`, `budgetMessageId` and `interpretationJson` are nullable; `codecVersion` and `draftJson` are required non-null. **The two message refs and `interpretationJson` are null only for proposals not created from chat** (AI-056 weekly check-in target change, DY-004 incomplete day, WO-022 template update). `foodLog` codec rows always set them, and A21 restore requires them (TD-083). No budget copy (PA17) (PA1) | TD-083 / A23 scope: one row per card, immutable origin, current budget binding, resolution metadata (`05` §2.3: outcome, resolved_at). Non-chat proposals must sync under the same v1 without inventing message IDs. "Which chips changed" (`06` §5) stays derivable from the opaque draft's choices/edits |
| D3 | **Closed vs open vocabularies.** Closed (schema `enum`): `chatMessage.role` = `user`, `assistant`; `chatMessage.status` = `queued`, `pending_offline`, `processing`, `done`, `failed` (`05` §2.3); `proposal.status` = `pending`, `confirmed`, `discarded`, `superseded`; `proposal.outcome` = `unchanged`, `adjusted`, `discarded`, `null`. Open bounded strings: `kind` (≤ 32, e.g. `foodLog`), `language` (≤ 16) | PA16 closes exactly role/status/outcome. `kind` stays open so A25–A29 can add kinds without a server-first deploy. Engine `active` is **not** a wire code (`active ≡ pending`, A21 D9). "Adjusted chips" becomes `adjusted`. New **closed envelope codes** are server-first (TD-080). **Opaque engine JSON evolves by app-owned `codecVersion`**: restore rejects unknown versions, so TD-080's server-first rule for inner vocabularies doesn't apply to it (PA7) |
| D4 | **Opaque engine JSON uses the `...Json` convention:** `budgetJson`, `interpretationJson`, `draftJson`. They get the existing generic nested pass (well-formed JSON, depth ≤ 24, ≤ 128 members per object, ≤ 500 items per array, exactly decimal-representable numbers, unique keys, no U+0000, well-formed UTF-16, strings ≤ 32768). Any JSON root is admitted (`{}`, `[]`, `null`, scalars). There's no check of engine keys, versions, dimensions, nutrients, issued-ID counts or ownership | `05` §5.5 convention and PA16 ("opaque bounded JSON"). A21 `restore` diagnoses engine content. The coupling between the codec output and the generic nested limits is pinned by the corpus (WP2) and listed under Risks |
| D5 | **Bounds.** JSON fields `maxLength` **32768** UTF-16 units (= `ProposalDraftCodec.syncStringLimit`); `text` 8192; `language` 16; `kind` 32; `origin` 128 (existing); `codecVersion` integer **1…2147483647** (nullable on `chatMessage`, required on `proposal`); `resolvedAtMs` 0…2^53−1; references `format: uuid`, `maxLength` 36. `createdAtMs` is a bare `integer` like on the other nine entities (PA6) | 32768 is fixed by PA16 and A21. `text` 8192 is 8× the interpret input cap (1000), with room for Q&A replies; widening later is additive. `codecVersion` isn't pinned to `1`, so a future codec syncs and restore rejects it. The UUID *format* is the envelope check; UUIDv7 stays an A21 check |
| D6 | **No intra-row pairing rules and no cross-row lookups.** No role ↔ budget, `codecVersion` ↔ budget, status ↔ outcome/`resolvedAtMs`, and **no `kind` ↔ ref/interpretation nullability pairing** (PA1). Nothing checks that referenced messages or cards exist, and top-level `status`/IDs/`codecVersion` aren't compared with copies inside `draftJson` | PA16's list is exhaustive. Lifecycle semantics belong to A23's applier, and consistency to A21 `restore` (`sessionIncomplete` / `budgetConflict`) |
| D7 | **Well-formed UTF-16 is existing behaviour, pinned rather than added** (PA2). `System.Text.Json` `GetString()` / `JsonProperty.Name` throw on unpaired surrogates. `SyncPayloads.Representable` calls them for every string and for nested `...Json`, and `InvalidReason` catches the exception, so the result is already `invalidPayload` (verified on .NET 10.0.402). B18 adds **regression tests** for chatMessage, proposal and `weighIn.note`, top level and nested, including "never 500, never in Postgres logs". WP1 documents "well-formed UTF-16 (existing)" in the `contracts/README.md` generic rules and in `05` §5.5 | User-typed chat text is the likeliest place for a split surrogate pair; a regression would mean a 500 and possible text in the Postgres error log (rule 6) |
| D8 | **Attachments are excluded by construction:** there's no attachment/path property, and `additionalProperties: false` rejects `attachmentRefs`, `attachmentsJson` or any other extra field | `05` §2.3: images aren't synced; local paths are device-specific and private (PA24) |
| D9 | **Shared Dart contract surface and corpus** (TD-080 pattern, without a semantic validator). `fb_domain` gets three pieces. (1) `lib/src/proposals/proposal_sync_codes.dart`: enums `ChatMessageRole`, `ChatMessageStatus`, `ProposalStatus` (with `ofLifecycle`: active→pending, never superseded) and `ProposalOutcome`, each with `code`/`fromCode`, plus `ChatProposalSyncBounds` (JSON = `ProposalDraftCodec.syncStringLimit`, text, language, kind, codec range). (2) **The real codec inverse** (PA3), both pure, returning `ProposalResult<Map<String, Object?>>`: `ProposalDraftCodec.cardFromSync({required String? interpretationJson, required String draftJson})` and `ProposalDraftCodec.messageFromSync(String? budgetJson)`. Malformed, non-object or null input returns a fixed, content-free `ProposalIssue` and never throws. (3) `encodeCard`/`restore` use `ProposalStatus.ofLifecycle`, or a test pins `ProposalStatus.ofLifecycle(l).code == encodeCard(…)['status']` for every lifecycle. A Dart generator (`packages/fb_domain/tool/generate_chat_proposal_vectors.dart`) writes `contracts/testdata/sync/chat-proposal-validation-vectors.json` from the codes/bounds and from **real** `syncProjection` output. There is **no C# constants class**: the embedded registry is what the server enforces, and a pure test pins it to the corpus | One Dart source for the codes and the decode path that A22/A23 use (A23's mapper calls the inverse). Real codec output proves app→server; the inverse proves server→app. A third hand-copied list would just drift |
| D10 | **The "both directions" test lives in `fb_domain` for B18:** `packages/fb_domain/test/proposals/chat_proposal_sync_vectors_test.dart` (WP2). App→server: codec projections are declared `serverAccepts`, and C# asserts every declaration. Server→app: accepted closed codes decode to Dart enums and rejected unknown codes to `null`. Every accepted opaque field goes through `cardFromSync`/`messageFromSync`, and restore scenarios return `ok` or a fixed `ProposalIssue` and never throw. **WP1 rewrites B18's exit criterion** to "fb_domain corpus test passes in both directions (codec projections/inverse + wire codes); mapper-level parity is an A22/A23 exit criterion" (PA4). It adds that exit criterion to **A22** (`apps/mobile/test/features/buddy/data/chat_message_sync_vectors_test.dart`, `A22 chat message row mapper matches the sync corpus in both directions`) and **A23** (`apps/mobile/test/features/buddy/data/proposal_sync_vectors_test.dart`, `A23 proposal row mapper matches the sync corpus in both directions`). The Outcome records the deviation | The drift tables and mappers don't exist until A22/A23 (out of scope). The codec, its inverse and the wire codes are the app-side contract that exists today |
| D11 | **Contract handoff (TD-065), exact sequence** (PA5). After the WP1 code and security reviews: `git branch step/B18-contract <WP1-sha>`, then `tools/scripts/merge-step.sh "B18 (contract)" "chatMessage and proposal sync entities" step/B18-contract` (merge branch `merge/B18`; the script deletes it and it can be reused later). The squash also carries the plan commits, which is intended: the card reaches `main` for A22's planners. Then `git rebase --onto origin/main <WP1-sha> step/B18-chat-proposal-sync`. If another lane touched `fb_domain.dart` or the `Makefile` in the meantime, rebase the throwaway branch on `origin/main` first. No 501 stubs: there's no endpoint. Between the two merges the server admits both entities with the full generic rules | Lets A22 start in another lane. The only uploader is A34, which depends on the full B18 |
| D12 | **Test helpers.** Give `PersonalFoodHttp` an `entity` parameter (default `personalFood`; B17 call sites unchanged). Add `ChatProposalCases.cs` in `UserData.Tests`, compile-linked into `Persistence.Tests` like `PersonalFoodCases.cs`. Generic behaviours run as `[Theory]` over both entities | Reuse over copy; one matrix for the pure and HTTP tests |
| D13 | **Privacy proof** is a new `[Fact]` in `IdentityPrivacyTests` using the existing sink capture (logs + scopes, activities, every metric type, serialized Sentry, audit, Postgres logs). The capture setup is extracted into a private helper without changing the existing test's assertions | Named evidence; same sinks as B05/B17 |
| D14 | **Byte budget.** The largest valid proposal row (both JSON fields at 32768 units of BMP non-ASCII) is about 197 KB as UTF-8 with non-ASCII unescaped (Dart `jsonEncode`'s output). That fits the 256 KiB push cap; `\u`-escaping non-ASCII would not. `contracts/README.md` states this for A34. WP4 proves it with a hand-built UTF-8 body, not the default `JsonSerializer` encoder, which escapes non-ASCII | A permanently unpushable single row would block A34's queue |
| D15 | **Whole-number integers stay generic:** `codecVersion: 1.0` is admitted, as for every integer field (`Matches`), and is pinned as an accepted corpus case. App mappers (A22/A23/A34) must read integers as `num` → `int` | Consistent server semantics; the asymmetry is recorded |

No ⚠️ OWNER decision: everything is additive, and no Accepted TD changes. WP1 amends **TD-083 (Proposed)** (PA7) and corrects `05`'s stale "TD-080 Proposed" to Accepted. There's no security trade-off and **no TD candidate**.

### 3. Design

**3.1 Contract diff (`contracts/openapi/sync-entities.json`, both entities under `"1"`, `additionalProperties: false`, `required` = all properties):**

```jsonc
"chatMessage": { "1": { "type": "object", "properties": {
  "createdAtMs":      {"type": "integer"},
  "origin":           {"type": "string", "maxLength": 128},
  "editedByUser":     {"type": "boolean"},
  "role":             {"type": "string", "enum": ["user", "assistant"]},
  "text":             {"type": "string", "maxLength": 8192},
  "status":           {"type": "string", "enum": ["queued", "pending_offline", "processing", "done", "failed"]},
  "language":         {"type": ["string", "null"], "maxLength": 16},
  "replyToMessageId": {"type": ["string", "null"], "format": "uuid", "maxLength": 36},
  "codecVersion":     {"type": ["integer", "null"], "minimum": 1, "maximum": 2147483647},
  "budgetJson":       {"type": ["string", "null"], "maxLength": 32768} } } },
"proposal": { "1": { "type": "object", "properties": {
  "createdAtMs", "origin", "editedByUser": as above,
  "kind":               {"type": "string", "maxLength": 32},
  "status":             {"type": "string", "enum": ["pending", "confirmed", "discarded", "superseded"]},
  "outcome":            {"type": ["string", "null"], "enum": ["unchanged", "adjusted", "discarded", null]},
  "resolvedAtMs":       {"type": ["integer", "null"], "minimum": 0, "maximum": 9007199254740991},
  "originMessageId":    {"type": ["string", "null"], "format": "uuid", "maxLength": 36},
  "budgetMessageId":    {"type": ["string", "null"], "format": "uuid", "maxLength": 36},
  "codecVersion":       {"type": "integer", "minimum": 1, "maximum": 2147483647},
  "interpretationJson": {"type": ["string", "null"], "maxLength": 32768},
  "draftJson":          {"type": "string", "maxLength": 32768} } } }
```

The exporter's closed keyword set expresses all of this (`tools/scripts/export-sync-schemas.py`); there's no `minLength` and no `description`. `createdAtMs` copies whatever schema the other entities actually use (PA6: no new bounds). `contracts/openapi.yaml` and `packages/fb_api_client` don't change, because the sync envelope's `payload` is a generic object.

**3.2 Server admission: no production C# change** (PA2). `SyncPayloads.InvalidReason` already does everything B18 needs, in this order: deletion-instant precision → registry lookup (`unsupported`) → `Representable` (which rejects unpaired surrogates through `GetString()`/`Name` throwing, caught as `invalidPayload`) → `Matches` → entity hooks (mealSlot, personalFood) → nested `...Json` parse + `Representable`. Regenerating the embedded registry is the only backend file change. Storage, `PushForSessionAsync`, advisory lock, forced RLS, LWW/history, receipts, retention/compaction and `UserDataErasure` are entity-agnostic (B05/B06) and untouched. Module boundaries hold: UserData only, no new cross-module call, Postgres stays the only state.

**3.3 Dart surface** (`fb_domain`, WP1).
- `proposal_sync_codes.dart` (exported from `fb_domain.dart`): pure enums and constants, content-free `toString`, no I/O. `ChatProposalSyncBounds.json` references `ProposalDraftCodec.syncStringLimit`.
- In `proposal_codec.dart`: `cardFromSync` decodes `draftJson`, which must be an object. It adds `interpretation` from `interpretationJson`; null interpretation returns a fixed issue for restore, since `foodLog` restore requires it. `messageFromSync` decodes `budgetJson`, which must be a non-null object. Both bound input by `fitsSyncString` before decoding.
- `encodeCard` writes `status` through `ProposalStatus.ofLifecycle`, or a test pins the equality (D9).
- A22/A23 use the codes for their drift columns; A23's mapper uses the inverse.

**3.4 Corpus** (`contracts/testdata/sync/chat-proposal-validation-vectors.json`, synthetic only; format documented in `contracts/testdata/README.md`):
- `constants` (from `ChatProposalSyncBounds`) and `vocabularies` (from the four enums).
- `payloads`: `{id, entity, rawPayload (exact text), deleted, serverAccepts, source: codec|synthetic}`.
  - Codec cases, generated with A21's test fixture builders and a deterministic `SequenceIdGenerator`: six-item card, multi-card message (one assistant budget), follow-up M1→M2 carried card (`originMessageId ≠ budgetMessageId`), confirmed card, discarded card.
  - Every closed code, plus rejected unknowns (`system`, `sent`, `active`, `adjusted chips`, case variants).
  - **Accepted null cases (PA1):** a non-chat proposal (`kind` e.g. `targetChange`) with null `originMessageId`/`budgetMessageId`/`interpretationJson`. Also a `foodLog` row with null refs: accepted, because there's no kind pairing (D6).
  - Each bound at limit/limit+1: 32767/32768/32769 units for each JSON field, built as ASCII and with a supplementary character straddling the limit; text 8192/8193; language 16/17; kind 32/33; origin 128/129.
  - `codecVersion` cases: 1, 2, max, max+1, 0, −1, 1.5, `1.0` (accepted, D15), `"1"`, `null` (accepted on chatMessage, rejected on proposal). `draftJson: null` is rejected.
  - UUID shapes: uppercase, non-UUID, nil UUID (accepted).
  - Opaque-but-odd JSON: `{}`, `[]`, `null`, `1`, an unknown inner `codecVersion`, engine-invalid keys (all accepted). Malformed, depth-25, duplicate-key, unrepresentable-number and U+0000 cases (rejected).
  - Unpaired high/low surrogates in `text`, in a raw JSON field and inside nested escaped strings/keys: rejected by existing behaviour; Dart tolerates.
  - Attachment extra fields (rejected); full-payload tombstones of the main cases (same outcome); `{}` tombstone (rejected).
- `restoreScenarios`: `{id, messagePayloadId, cardPayloadIds, expect}`, all built through `cardFromSync`/`messageFromSync`:
  - codec message + cards → `ok`; follow-up M2 → `ok`;
  - missing card → `sessionIncomplete`; a card bound to another message, and a budget naming a foreign card → `budgetConflict`; `{}` budget → `sessionIncomplete`;
  - **a `foodLog` row with null refs/interpretation → the fixed issue** (PA1);
  - unknown inner version and non-object roots → the fixed issue, pinned as generated.
- `serverRejectsAppTolerates`: the exact list of server-rejected rows that Dart decodes (surrogates).

**3.5 Docs.**
- **WP1:**
  - `contracts/README.md` gets a section "chatMessage and proposal admission". It covers envelope-only admission; the generic rules, including **well-formed UTF-16 (existing)**; opaque JSON and the generic nested limits the codec must satisfy; closed envelope codes being server-first (TD-080) while engine JSON evolves by app-owned `codecVersion`; null refs for non-chat proposals; attachments excluded; no cross-row validation; the UTF-8 byte budget (D14); a corpus pointer.
  - `05`: §2.3 rows for `chat_messages`/`proposals`; the §5.5 entity list (+ `chatMessage`, `proposal` (B18)); "well-formed UTF-16 (existing)" in §5.5's representability list; "(proposed TD-080 remains Proposed)" corrected to TD-080 Accepted (owner, 2026-10-24).
  - `12-decisions-and-questions.md` TD-083 (Proposed) gets this sentence appended: "Proposal rows not created from chat (AI-056 target change, DY-004, WO-022) leave `originMessageId`/`budgetMessageId`/`interpretationJson` null. Opaque engine JSON evolves by `codecVersion` (app-owned; restore rejects unknown), so TD-080's server-first rule for inner vocabularies does not apply to it."
  - Card handoffs per §8, and the B18/A22/A23 exit-criterion edits per D10.
- **WP5:** `backend/README.md` §Document sync, `docs/runbooks/sync.md` if it lists rules, and the Outcome deviation note.

### 4. Work packages

| WP | By | Tasks · files | Done when |
|---|---|---|---|
| **WP1 · Contract handoff** (own commit `feat(contract): chatMessage and proposal sync entities`; merged as **`B18 (contract)`**) | **First** `dotnet-engineer` (contract JSON, export, fixtures, README, `05`, TD-083 note, card handoffs), **then** `flutter-engineer` on top (codes, codec inverse, lifecycle pin, contract-equality test) (PA8); one commit | **dotnet-engineer:**<br>• §3.1 schemas in `contracts/openapi/sync-entities.json`<br>• one valid fixture each in `contracts/testdata/sync/entity-payloads.json` (an assistant `chatMessage` with a small `budgetJson`; a pending `foodLog` `proposal`)<br>• regenerated `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json` (`make gen-sync-schemas`)<br>• the §3.5 WP1 doc edits in `contracts/README.md`, `05`, `12` (TD-083)<br>• the A22/A23/A34 card handoffs and the B18/A22/A23 exit-criterion edits (§8, D10)<br>**flutter-engineer:**<br>• `packages/fb_domain/lib/src/proposals/proposal_sync_codes.dart` + export<br>• `cardFromSync`/`messageFromSync` in `proposal_codec.dart`<br>• tests in `test/proposals/proposal_sync_codes_test.dart` and `proposal_codec_test.dart`<br>**Card:** Progress-log line.<br>**Must not contain:** any C# source or C# test change, the corpus/generator/Makefile target, `apps/mobile` changes, `openapi.yaml`/`fb_api_client` changes (none expected), or board/backlog edits | `make gen` leaves no diff beyond `entities.json`; `make gen-check`; `make check-sync-schemas`; `flock … make check-contract` (incl. conformance); `make check-dart`; focused fb_domain `dart test test/proposals/proposal_sync_codes_test.dart test/proposals/proposal_codec_test.dart`; `flock … make test-dart` (fb_domain ≥ 95 % `lib/` coverage gate); `flock … make test-dotnet` (the existing all-fixture `ProductionSyncTests` and `All_current_entity_fixtures_still_pass_schema_admission` now cover both entities); `git diff --check`. Then a fresh **`code-reviewer`** and a short **`security-reviewer`** pass on the WP1 diff (schema focus) (PA8), then D11's exact merge sequence with green CI |
| **WP2 · Shared corpus and Dart parity** | `flutter-engineer` | `packages/fb_domain/tool/generate_chat_proposal_vectors.dart` (in-memory `chatProposalVectors()` + CLI writer; may import `test/proposals/proposal_fixtures.dart` by relative path; copies no codec logic). `contracts/testdata/sync/chat-proposal-validation-vectors.json`. `packages/fb_domain/test/proposals/chat_proposal_sync_vectors_test.dart` (restore scenarios and the never-throws test go through `cardFromSync`/`messageFromSync`). Makefile `gen-chat-proposal-vectors` (manual; no `check`/CI dependency). `contracts/testdata/README.md` format note. **No `lib/` change expected.** Only if the corpus exposes a defect in the WP1 inverse/codes is it fixed in `lib/` here, under the coverage gate and stated in the Progress log | Byte-equality drift and both-direction tests pass with counted cases; `make check-dart`; `flock … make test-dart`; `git diff --check` |
| **WP3 · Pure admission tests** | `dotnet-engineer` | **No production C# change** (PA2). `backend/tests/UserData.Tests/ChatProposalCases.cs` (corpus cases + a schema-derived matrix: missing/`null`/wrong-type/extra per field, every case live and as a full tombstone) and `ChatProposalPayloadTests.cs`. Content link for the corpus in `FitnessBuddy.UserData.Tests.csproj`. If a test exposes an admission gap, stop and report to the orchestrator; don't patch admission silently | The whole Docker-free `UserData.Tests` passes (B17 suite unchanged); `make check-dotnet`; `make check-sync-schemas`; `git diff --check` |
| **WP4 · Persistence, erasure and privacy proof** | `dotnet-engineer` | `backend/tests/Persistence.Tests/ChatProposalSyncTests.cs`. The `entity` parameter on `PersonalFoodHttp`. Compile-link `ChatProposalCases.cs` and the corpus in `FitnessBuddy.Persistence.Tests.csproj`. The new privacy `[Fact]` and capture-helper extraction in `IdentityPrivacyTests.cs`. Only privileged (migrator) connections for inventory/aging; production grants unchanged | `make check-dotnet`; `flock … make test-dotnet` (new + all existing sync, retention, deletion and privacy tests); `flock … make contract-conformance`; `git diff --check` |
| **WP5 · Reviews and close** | orchestrator; fresh `code-reviewer`, `security-reviewer`, `verifier`; fixes by `dotnet-engineer`/`flutter-engineer` | Whole-diff reviews. The security reviewer writes `technical-planning/steps/evidence/B18-verification.md`. Docs per §3.5 WP5. Backlog candidates (§7). Board: B18 status/size at close. Outcome, including the D10 exit-criterion deviation | No open blocker or major; `make trace`; `flock … make check test`; CI green on the exact merge commit via `merge-step.sh B18 "chatMessage & proposal sync entities (server)" step/B18-chat-proposal-sync`. No `[it]` needed (no Android/Patrol change) |

### 5. Test list
Dart names start with the spec ID or `B18`. C# uses `[Trait("Req", …)]` or `[Trait("Rule", "B18.<slug>")]`, or the existing `05.5-…`, `04.6-…`, `09.4-no-user-content` rule tags.

| Test (file) | Proves |
|---|---|
| `B18 sync codes and bounds equal the sync-entities contract` (`proposal_sync_codes_test.dart`, WP1) | D3/D5/D9; AC-010 |
| `AI-045 engine lifecycle maps to stored pending confirmed discarded and never superseded` (same) | AI-045, A21 D9 mapping |
| `B18 encodeCard status equals ProposalStatus.ofLifecycle for every lifecycle` (`proposal_codec_test.dart`, WP1) | PA3 lifecycle pin |
| `B18 unknown wire codes decode to null` (`proposal_sync_codes_test.dart`) | D3 |
| `B18 cardFromSync and messageFromSync invert syncProjection` (`proposal_codec_test.dart`, WP1) | PA3 round trip, incl. multi-card and follow-up |
| `B18 malformed non-object or null sync fields return a fixed issue without throwing` (same) | PA3; content-free issue |
| `B18 generated vectors match committed bytes` (`chat_proposal_sync_vectors_test.dart`, WP2) | corpus drift gate |
| `AI-045 codec projections become accepted proposal and assistant message payloads` (same) | app→server; real six-item/multi-card/follow-up output fits every bound |
| `AI-045 codec rows restore from synced fields by budgetMessageId` (same) | through the inverse; follow-up carried card with immutable origin; pending cards survive a reinstall (app half) |
| `B18 accepted closed codes decode and rejected unknown codes stay unknown in Dart` (same) | server→app vocabulary direction |
| `B18 row admission does not require related message or card rows` (Dart half, same) | cross-row cases accepted; restore returns `sessionIncomplete`/`budgetConflict`, never throws |
| `B18 opaque engine JSON restores to a fixed issue without throwing` (same) | server→app opaque direction via the inverse (`{}`, `[]`, `null`, unknown version, deep/near-limit JSON, `foodLog` with null refs) |
| `B18 JSON string limit counts UTF-16 units including supplementary characters` (Dart half, same) | `fitsSyncString` agrees with every boundary case |
| `B18 asymmetric list is exactly server-rejected rows Dart tolerates` (same) | explicit asymmetry |
| `Embedded_schema_bounds_and_vocabularies_equal_Dart_corpus` (`ChatProposalPayloadTests`, WP3) | "constants equal the corpus"; embedded registry = contract |
| `Payload_matrix_matches_admission_for_live_and_tombstone` (Theory over every case) | every envelope/vocabulary/size rule: limit accepted, limit+1 rejected; omitted/`null`/wrong-type/extra |
| `B18_json_string_limit_counts_utf16_units_including_supplementary_characters` | 32768/32769 for all three JSON fields, text 8192/8193; surrogate pair straddling the limit |
| `B18_proposal_status_accepts_pending_confirmed_discarded_superseded` | closed status; rejects `active`/unknown; outcome `null` + three codes; rejects `adjusted chips` |
| `B18_proposal_not_created_from_chat_admits_null_message_refs_and_interpretation` | PA1; `draftJson`/`codecVersion` still required; no kind pairing |
| `B18_chatMessage_excludes_local_attachment_paths` | exact schema property set; attachment-like extras rejected (D8) |
| `B18_opaque_interpretation_draft_and_budget_JSON_round_trip_without_engine_validation` (pure half) | D4: odd but well-formed JSON admitted; fingerprint/payload not rewritten |
| `B18_row_admission_does_not_require_related_message_or_card_rows` (pure half) | D6: validator runs without a database; dangling references admitted |
| `Ill_formed_utf16_is_rejected_for_every_entity` | D7 regression pin: chatMessage/proposal/`weighIn.note`, top level and nested values/keys |
| `Codec_version_integer_bounds` | 1, max accepted; 0, −1, max+1, 1.5, `"1"` rejected; `1.0` accepted (D15); nullable only on chatMessage |
| `Near_limit_opaque_json_completes_with_bounded_work` (timeout, no throughput claim) | hostile 32 KiB inputs stay linear |
| `Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions` (`ChatProposalSyncTests`, WP4) | AC-010: authenticated push of every case in byte-bounded batches (≤ 500 changes); ordered `invalidPayload`; no canary in the ack; invalid IDs absent from documents/history/receipts |
| `B18_opaque_interpretation_draft_and_budget_JSON_round_trip_without_engine_validation` (HTTP half) | owner pull and item history return the payload `DeepEquals` and the opaque strings byte-exact |
| `B18_row_admission_does_not_require_related_message_or_card_rows` (HTTP half) | proposal with a dangling `budgetMessageId`; budget naming absent cards; both accepted and pulled |
| `AI-045 Pending_proposal_and_assistant_message_survive_fresh_device_pull` | fresh device pulling from cursor 0 receives the pending card + its budget row exactly (server half of "survive a reinstall") |
| `Maximum_size_rows_fit_one_push_and_round_trip` | D14: < 262144 request bytes, accepted, round-trips |
| `Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable` (Theory: both entities) | AC-012; `05.5-version-identity` |
| `Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection` (Theory) | AC-012; `05.5-retention`; the tombstone path A23's clear history (AC-033) relies on, including scrubbed valid tombstone payloads |
| `Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned` (Theory) | `04.6-rls` |
| `Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401` (Theory) | `04.6-authz` |
| `Ill_formed_utf16_never_500s_or_reaches_postgres_logs` | D7 regression pin over HTTP, including `weighIn.note` |
| `Delete_account_erases_chat_and_proposal_live_history_fences_and_receipts_and_preserves_second_owner` | AC-031: real `DELETE /v1/me`; privileged zero-row inventory; live + compacted rows; second owner intact |
| `B18_authorized_pull_returns_content_while_errors_logs_and_telemetry_omit_it` (`IdentityPrivacyTests`) | Rule `09.4-no-user-content` (PA9): EN/Arabic/Arabizi text, budget, interpretation and draft canaries across accepted, invalid vocab, 32769 oversize, unpaired surrogate, fixed 400, guest 403, Kestrel 413 and injected 500. No canary in any response body except owner pull/history, nor in logs, scopes, spans, metrics, Sentry, audit or Postgres logs |

### 6. Exit-criteria mapping

| Exit criterion | Evidence |
|---|---|
| Validator and corpus: every rule at limit/limit+1 (32768/32769, supplementary); constants = corpus; **fb_domain corpus test both directions** (rewritten in WP1, D10) | WP3 `Payload_matrix…`, `B18_json_string_limit…`, `Embedded_schema_bounds…`; WP1 inverse tests; WP2 Dart drift + both-direction tests. Mapper-level parity is now an A22/A23 exit criterion |
| Persistence (Testcontainers): accepted push, invalid → `invalidPayload` with no content in responses/telemetry, pull/history round trip, tombstone, cross-user isolation, guest 403; opaque and cross-row inconsistencies stay admitted | WP4 `ChatProposalSyncTests` (matrix, round trip, dangling references, null refs, tombstone, RLS, guest) + the WP4 privacy `[Fact]` |
| Account deletion covers both entities, history and fences | WP4 `Delete_account_erases_chat_and_proposal…` |
| `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet`; CI | gates in WP1/WP4/WP5; exact-commit CI through `merge-step.sh`, recorded in the evidence file |
| Fresh security review: no open blocker or major | WP1 schema pass + WP5 `security-reviewer` with `B18-verification.md`; plus fresh `code-reviewer` and `verifier` |

### 7. Risks and unknowns

| Risk | Handling |
|---|---|
| **Codec output vs the generic nested limits.** `choices` can exceed 128 members on a card with many tapped dimensions (`ids` peaks at 120). A floating residue below 1e-28 isn't decimal-representable | WP2 includes the real A21 scenarios plus a worst-case card at A21's defensive limits, and C# asserts each declaration. If a realistic case fails, the server isn't relaxed: the orchestrator logs an app-track fix (an `fb_domain` precheck in `syncProjection` returning `syncPayloadTooLarge`, or rounding) for A23. Pathological cases become an A23 handoff + backlog item. Not a B18 blocker unless the realistic fixtures fail |
| **Redundant copies:** `draftJson` also carries `status`, IDs and `codecVersion` | The server doesn't cross-check (D6). A23 handoff: top-level columns are authoritative |
| **Field-set choices** (`replyToMessageId`, `language`, open `kind`, nullable refs) become contract surface before A22/A23 are fully planned | Reviewed by the architect. After the contract merge, additive changes are fine; a breaking change goes to the owner (card rule) |
| **Large pull pages:** 500 rows × ~197 KB worst case | A34 handoff (smaller `limit`) |
| **Permanently rejected rows** (D15 integers, surrogates) | Existing backlog #111 (A34 must not retry endlessly); the corpus lists the asymmetries |
| **Parallel lanes** (A13/A14 may touch `Makefile`, `fb_domain` exports, board, backlog) | Rebase before each merge (D11); board/backlog edits only at close; never touch other clones |
| **Exit-criterion deviation** (mapper-level parity moves to A22/A23) | WP1 rewrites the criterion with the orchestrator's approval (PA4); the Outcome records it |

**Backlog candidates at close:** an A23 precheck of the generic nested limits, if the corpus shows it's needed.

### 8. Size, reviews and handoffs
**M**: one contract WP (with a small `fb_domain` addition), one Dart corpus WP, one pure-test WP and one Testcontainers WP, all reusing B05/B17 machinery. No split.

**Reviews** (`PROCESS.md` B, Risky): `architect` on this plan (done: PA1–PA9). On WP1, before the contract merge: a fresh `code-reviewer` + a short `security-reviewer` schema pass. At WP5: `code-reviewer` on the whole diff, `security-reviewer` (writes `technical-planning/steps/evidence/B18-verification.md`), and `verifier` against every exit criterion.

**Handoffs, written into the cards in the WP1 commit (PA4):**
- **A22:**
  - Composer cap 1000 (`contracts/openapi/modules/buddy.yaml` `text.maxLength`).
  - Stored assistant text ≤ 8192 UTF-16 units without splitting a surrogate pair; strip U+0000.
  - `language` = a normalized short tag from a fixed app list (`en`/`ar`/`ar-Latn`) or null, never the raw model `intent.language`.
  - No attachment paths.
  - `chatMessage` and `proposal` row IDs are random UUIDv7, never UUIDv5 derived from content.
  - Display order is `createdAtMs` then `id`; replies are grouped by `replyToMessageId`.
  - New exit criterion: `chat_message_sync_vectors_test.dart` (D10).
- **A23:**
  - Top-level columns are authoritative over draft copies.
  - Unknown `kind`/`codecVersion` or null refs mean "not restorable" (generic card), never a crash; a `foodLog` row with null refs fails restore with a fixed issue. The mapper uses `cardFromSync`/`messageFromSync`.
  - A pulled non-terminal message (`queued`/`pending_offline`/`processing`) is processed only by its last-writer `device_id`, or after an A23-chosen timeout.
  - Dedupe assistant replies by `replyToMessageId`.
  - Clear history (AC-033): tombstoning an assistant row orphans its pending cards (`sessionIncomplete`), so A23 must keep or resolve them deliberately. Tombstones **must** carry a scrubbed valid payload: `chatMessage` `text: ""`, `budgetJson: null`; `proposal` keeps `codecVersion`, `draftJson: "{}"`, `interpretationJson: null`. Cleared chats can remain in server history for up to 30 days (displaced versions, AC-012, `05` §7): privacy-policy backlog item at close.
  - Mapper `ProposalResult`s are never logged or interpolated (a success's `toString` contains the decoded draft); only `issue` may be logged (also A22).
  - Failure codes and reply chips (AI-150/152) aren't in v1: they become local-only columns or an additive v2.
  - New exit criterion: `proposal_sync_vectors_test.dart` (D10).
- **A34:** unescaped UTF-8 bodies (D14), `num` → `int` (D15), backlog #111, smaller pull pages for large rows.

## Progress log
- 2026-10-24 · A21 re-check `bd430bf` findings PA16–PA18/PA24/PA25 applied: dependency on A21 WP4 shape/size; bounded opaque engine JSON with envelope/vocabulary admission only; assistant-row budget and origin/current proposal binding; 32768 UTF-16 units; authorized reads retain content, errors/logs/telemetry do not; attachment paths excluded. Planning only.
- 2026-10-28 · Moved to Claude (TD-085, Codex retired). The Codex-drafted plan stands; as a Risky step it gets an `architect` plan review before WP1.
- 2026-10-28 · Full low-level plan written (step-planner, Claude); awaiting architect review.
- 2026-10-28 · Architect plan review: approve with required changes PA1–PA9, applied. Plan approved by the orchestrator (TD-037, no owner items).
- 2026-10-28 · WP1 review findings (code-reviewer + security pass, both approve) applied: D6 app-convention notes in `contracts/README.md`, mandatory scrubbed tombstones + 30-day history note, no logging of mapper results, UUIDv7 row IDs, schema nullability/format/bounds pins in the Dart contract test, doc fixes. The contract fixture's `interpretationJson: "[]"` is schema-valid but not restorable: it is not an example for A22/A23.
- 2026-10-28 · WP1 contract handoff implemented (WP1 commit): `chatMessage`/`proposal` v1 schemas + fixtures + embedded registry, `contracts/README.md` admission section, `05`/TD-083 edits, A22/A23/A34 handoffs and exit criteria, `fb_domain` sync codes + `cardFromSync`/`messageFromSync` + lifecycle pin with tests. No C# change.

## Outcome
_Written in Phase E._
