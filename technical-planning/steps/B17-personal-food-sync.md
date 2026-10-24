# B17 — personalFood sync entity (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B05 ✅, **A09a** (contract) | S–M | Codex | ⬜ Not started |

_New step (orchestrator, 2026-10-23, A09 plan review PA3; semantic validation added at re-check 1, F1). The app side is A09a; the upload is A34's._

**Goal.** The server stores, validates, serves and erases the new `personalFood` sync entity exactly as the contract says, so A34 can upload personal foods.

**Spec:** FD-071 (private personal foods), AC-010 (foods sync to the account), AC-012 (offline changes sync; row-level last-write-wins + history, `05` §5), AC-031 (deletion covers them) · **Decisions:** TD-031, TD-049, TD-061

## Scope
- **Starts from A09a WP1's contract commit** on `main`: `personalFood` v1 in `contracts/openapi/sync-entities.json`, its fixture in `contracts/testdata/sync/entity-payloads.json`, and the regenerated embedded `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json`. B17 doesn't change the contract; a needed change goes back to the app track as a contract commit first (breaking → owner).
- **Semantic validation (F1):** the schema checks only what the exporter can express (types, enums, number bounds, `maxLength`), and `SyncPayloads` checks `...Json` strings only for representability. B17 adds a `personalFood` validator in the UserData module that enforces **every rule of the A09 card's §3.0 table** ("Shared `personalFood` rules"), the same numbers as the app's `PersonalFoodBounds`: names and brand 1–80 / 1–60 characters after trimming; `aliasesJson` a list of ≤ 30 strings of 1–80 characters, no exact duplicates; `barcodesJson` ≤ 10 unique GTIN-8/12/13/14 strings with valid check digits; `per100ExtrasJson` keys from the `NutrientKey` codes, gram values 0–1,000, mg values 0–100,000; `servingsJson` ≤ 10 `{unit, amount}` with units from the closed vocabulary, unique, amounts 0.1–5,000; `entryServingUnit` and `entryServingAmount` both null or both set (amount 0.1–5,000); `createdFrom` 1–32 letters; every number finite. A failure is a per-change `invalidPayload` with no value echoed. The validator's constants are pinned by a test against the same table (the app pins `PersonalFoodBounds` on its side). The FD-012 sanity check stays app-side: a food saved with a warning must sync.
- **String/JSON parity (A09a security round 1):** all string-length limits count **UTF-16 code units**, matching Dart `String.length` and .NET `string.Length` (not Unicode code points). Trimming must equal Dart `String.trim()` exactly; do not assume the platform's default trim has the same whitespace set. Pin Unicode whitespace and supplementary-character boundary cases against the app. Reject duplicate JSON object keys before materializing objects, including inside JSON-string payload fields, so a parser cannot silently select a conflicting value. **Sanity is not a sync rule**: wire-valid values remain syncable even when the app-only check reports `macrosTooHeavy` or another hard sanity failure; sanity constrains new app input, not stored-row reads, metadata updates or merges.
- **Conformance:** push accepts a valid `personalFood` v1 document from its owner; each §3.0 rule and each schema rule (unknown `state`/`basis`, over-long strings, extra or missing fields) has a rejection case.
- **Behaviour:** pull, LWW with history (`row_history`, 30 days), tombstones and compaction fences, guest 403, RLS (another user can't read it), item history `GET /v1/sync/history/personalFood/{id}`: the existing generic paths, proven for this entity.
- **Erasure:** B06's account deletion removes `personalFood` documents, history and fences (the "no rows remain" test includes it).
- **Telemetry:** metrics and logs carry no names, aliases, barcodes or values (the B05 canary pattern).
- A fresh read-only Codex **security review** of the diff (authorization/RLS, input handling, logging), findings fixed and recorded.

## Out of scope
- The app's table, ops and UI (A09a). Uploading from the app (A34). Barcode lookup of personal foods (A28, on the device).

## Fixed by the plan
- One JSON document per row in `userdata.documents` (TD-031); the contract is the payload authority, with no runtime schema fetching (`05` §5.5).

## Decide in the low-level plan
- Where the semantic validator plugs into `SyncPayloads` (an entity-specific hook after schema validation) and how its constants are shared with the §3.0 table (a constants class plus a test; no runtime contract fetch).
- Whether the exporter should accept and strip `description` so the rules can also live in `sync-entities.json` (default: no; `contracts/README.md` points to the table).

## Exit criteria
- [ ] Validator tests: every §3.0 rule accepts its limit and rejects just past it (incl. both-or-neither, duplicate aliases or barcodes, a bad check digit, an unknown extras key or serving unit, NaN/infinity/overflow), and the constants equal the table.
- [ ] Persistence tests (Testcontainers): accepted push, each invalid case → `invalidPayload` with no value in the response or telemetry, pull, history, tombstone, cross-user isolation (RLS), guest 403.
- [ ] Account deletion test includes `personalFood` documents, history and fences.
- [ ] `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet` green; CI green.
- [ ] Fresh Codex security review: no open blocker or major.

## Read first
`05-data-and-sync.md` §5.5 · `04-backend.md` §4.2, §7 · the A09 card's D2, D3 and §3.0 table · B05 and B06 Outcomes

## Owner involvement
None.

---

**Board changes (steps/README.md):** §4.2 gets a row `| [B17](B17-personal-food-sync-entity.md) | personalFood sync entity (server) | B05 ✅, **A09a** (contract) | S–M | new |  | ⬜ |`; §4.1's **A34** row gains **B17** in "Depends on" (`A33, **B05**, **B17**`); the A09 row becomes **A09a** "Personal foods & guarded repeat-log ops" (Claude, A08b, L) and **A09b** "Saved meals & quick-add" (Claude, A09a, M); **A11** and **A27** depend on **A09b** instead of A09; the mermaid flowchart and §6's cross-track dependency list (if they name A09 or A34's inputs) are updated to match.

## Low-level plan
_Written in Phase B by Codex._

## Progress log
_One dated line per event, newest last (process §8a)._

## Outcome
_Written in Phase E._
