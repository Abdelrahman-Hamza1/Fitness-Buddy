# B20 — Measurement sync entities (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B05 ✅, **B19** ✅, **A15b** (contract) | M | Claude | ⬜ |

_New step (A15b D23, 2026-10-30; outline card written at A15b's close, the Low-level plan comes in Phase B). The app side is A15b (tables, write path, screens); the upload is A34's, and **A34 depends on B20**. **Tier: Risky** (user-data admission, untrusted input, account erasure)._

**Goal.** The server admits, stores, serves and erases the body measurement sync entities exactly as the contract and their wire rules say, so A34 can upload custom measurement types and measurements.

**Spec:** WB-040, WB-041, WB-042 (measurements that sync), AC-010 (data syncs to the account), AC-012 (offline changes sync; row-level last-write-wins + history, `05` §5), AC-031 (deletion covers them) · **Decisions:** TD-031, TD-080, TD-103 (Proposed at A15b: body measurements model)

## ⚠️ Deploy hold (until B20 merges)
Since A15b's contract commit, the registry (`contracts/openapi/sync-entities.json` → the embedded `entities.json`) carries `measurementType` and `measurement` v1, and the server admits them **by schema only**, so a live server would accept rows that break M1–M3. **No server, the B03 laptop/phone test server included, runs a build carrying the measurement registry until B20 is merged.** Nothing uploads them before A34 (which depends on B20), so this is a hold, not a security trade-off. Backlog: the A15b deploy-hold row (#215).

## Scope
- **Starts from A15b's contract commit** (WP8): `measurementType` v1 (`createdAtMs`, `origin`, `editedByUser`, `name` ≤ 120) and `measurement` v1 (the metadata plus `kind` enum of 8, `customTypeId` uuid|null, `measuredAtUtc`, `tzOffsetMin`, `localDate`, `value`, `inputValue` 0 … 1e6, `inputUnit` `cm`/`in`/`percent`) in `contracts/openapi/sync-entities.json`, one fixture each in `contracts/testdata/sync/entity-payloads.json`, the variants in `contracts/testdata/sync/measurement-payload-variants.json`, the regenerated embedded `entities.json`. B20 doesn't change those schemas; a needed change goes back to the app track as a contract commit first (breaking → owner).
- **Semantic admission of exactly M1–M3 (TD-080)**, as listed once in `contracts/README.md` § "Measurement semantic rules" (the single source):
  - **M1** `customTypeId` is non-null exactly when `kind` is `custom`;
  - **M2** `inputUnit` is `percent` exactly when `kind` is `bodyFat`, else `cm`/`in`;
  - **M3** a `bodyFat` row's `value` and `inputValue` are at most 100.

  A `MeasurementPayloadValidator` behind B19's fail-closed dispatch by entity and schema version (one hook line in `SyncPayloads.InvalidReason`). **Not** wire rules (never checked): the app's plausibility ranges (10–300 cm, 2–75 %), `value` = `inputValue` × factor, `localDate` ↔ `measuredAtUtc`, the custom type existing or being live, name uniqueness. Invalid rows return a bare `invalidPayload` with no value or name in the response or telemetry. Tombstones carry the full payload under the same rules.
- **Shared corpus and app parity (TD-080):** a Dart-generated corpus `contracts/testdata/sync/measurement-validation-vectors.json` from the real `fb_domain` measurement types and the app's mappers and column writers (A15b's `measurementOf`, `measurementTypeOf`, `measurementColumns`), with a byte-equality drift test and an app parity test; the C# tests read the same corpus.
- **Conformance:** push accepts a valid document of each entity (fixtures and variants) from its owner; each wire rule and each schema rule (unknown kind or unit, extra or missing field, over-long name, out-of-range number) has a rejection case.
- **Behaviour (Testcontainers):** pull, LWW with history (`row_history`, 30 days), tombstones and compaction fences, guest 403, RLS (another user can't read them), item history: the existing generic paths, proven for these entities. A measurement whose type is missing or deleted is **valid** on the wire (the app hides it, A15b D25).
- **Erasure:** B06's account deletion removes these documents, history and fences.
- **Privacy canary:** a custom type name and measurement values never appear in logs, metrics or problem responses (the B05/B19 canary pattern).
- A fresh Opus **security review** of the diff (authorization/RLS, input handling, logging), findings fixed and recorded in `evidence/B20-verification.md`.
- **Lift the deploy hold** at the close (backlog row closed, owner told).

## Out of scope
- The app's tables, ops and UI (A15b). Uploading from the app (A34). Plausibility ranges (app-only). Workout entities (backlog #189, separate).

## Fixed by the plan
- One JSON document per row in `userdata.documents` (TD-031); the contract is the payload authority, no runtime schema fetching (`05` §5.5). Wire rules equal `contracts/README.md` § "Measurement semantic rules" (A15b D14). A new built-in kind or unit is a new `measurement` schema version, server validator first (TD-080).

## Decide in the low-level plan
- How the validator's closed vocabularies are shared with the corpus generator.
- Whether the A15b variants file is folded into the corpus or stays a fixture file.

## Exit criteria
- [ ] Validator tests: M1–M3 each accept a valid case and reject each violation (NaN/infinity/overflow included), equal to the corpus.
- [ ] Persistence tests (Testcontainers): accepted push, each invalid case → `invalidPayload` with no value in the response or telemetry, pull, history, tombstone, cross-user isolation (RLS), guest 403.
- [ ] Account deletion test includes both entities' documents, history and fences.
- [ ] App parity: A15b's mappers and writers round-trip the corpus.
- [ ] `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet` green; CI green.
- [ ] Security review: no open blocker or major; deploy hold lifted.

## Read first
`05-data-and-sync.md` §5.5 · `contracts/README.md` § Measurement semantic rules · the A15b card's D13–D15, D23, D25 · B19's card and Outcome (the fail-closed dispatch, the corpus pattern)

## Owner involvement
None (FYI when the deploy hold lifts).

## Progress log
- 2026-10-30 · Outline card written at A15b's review round 1 from A15b D23 (server validator M1–M3, shared corpus, Testcontainers, security review, deploy hold).
