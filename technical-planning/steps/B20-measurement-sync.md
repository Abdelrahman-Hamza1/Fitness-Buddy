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

---

## Low-level plan
_Step-planner (Claude, 2026-10-30), lane 4 (`~/work/fitness_buddy_4`, branch `step/B20-measurement-sync` from `origin/main` fe4f671). Re-verified against the code on main: `SyncPayloads.InvalidReason`, `TargetsPayloadValidator`, the B19 tests and generator, A15b's `measurement.dart`, `measurement_mappers.dart`, the fixtures and the variants file. **Reviews (TD-106): Codex only, read-only.** One Codex plan review, then the orchestrator self-approves (TD-037, no owner item). Code review = two parallel Codex tasks (code/architecture + security/data integrity). **No local test runs** (owner rule, 2026-10-30): locally only codegen, `make check-dart`, `make check-dotnet` / `dotnet build`, `make check-sync-schemas`, `git diff --check`. CI is the test evidence. On a CI failure, reproduce only the failing tests through `tools/scripts/heavy.sh` with `timeout 600`._

**Tier: Risky** (user-data admission, untrusted input, account erasure). **Size: M** (about 1.5 sessions). Three build WPs plus the close, one commit each, **one merge**. No early merge: no lane is waiting, but the deploy hold makes B20 the first backend merge of wave 2. **Builders (TD-095, specialty seam as in B19):** a `flutter-engineer` builds WP1 (Dart corpus and parity); a `dotnet-engineer` takes WP2–WP3. Expected changes:
- **no contract schema, OpenAPI path, migration or generated-client change**: the schemas landed in A15b WP8, and `make gen` must leave no diff;
- no new dependency and no paid call;
- the production C# change is one small validator and one hook line;
- the production Dart change is one small `fb_domain` class (`MeasurementWireRules`, two members) that the app mapper now calls, with no behaviour change.

### 1. Summary
After B20 the server admits `measurementType` v1 and `measurement` v1 exactly as `contracts/README.md` § "Measurement semantic rules" says. That means the schema plus a hand-written `MeasurementPayloadValidator` for M1–M3 (TD-080), dispatched by entity and failing closed by schema version, on live rows and full tombstones alike. A Dart-generated corpus `contracts/testdata/sync/measurement-validation-vectors.json`, built from the real `fb_domain` measurement types, pins three sides:
- `fb_domain`, by a byte-equality drift test and the "server admits exactly M1–M3" invariant;
- the app, through its real `measurementOf`, `measurementTypeOf`, `measurementColumns` and `measurementTypeColumns`;
- the server, by C# tests reading the same file.

Testcontainers tests prove the existing generic paths for both entities: push, pull, LWW with history, tombstones and fences, RLS, guest 403, erasure, orphan references and a privacy canary. At the close the **deploy hold is lifted** (§8), so the B03 phone server can update to main again.

### 2. Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **In scope:** `measurementType` v1 and `measurement` v1, unchanged from A15b WP8 (verified: `contracts/openapi/sync-entities.json`, 16 entities, both at version `1` only; the embedded `entities.json` equals them, per `make check-sync-schemas`). **No contract schema change.** If one turns out to be needed, it goes back to the app track as a contract commit first (breaking → owner). **Card corrections:**<br>• "A fresh Opus security review" → **two parallel Codex review tasks** (code/architecture + security/data integrity; TD-106); the orchestrator still writes `evidence/B20-verification.md`.<br>• A15b's tripwire already maps fixtures and variants 1:1 to the columns (`measurement_migration_test.dart`). Since WP8, the generic C# loops already push both fixtures: all-fixture admission, the production round-trip and the account-deletion inventory | The card's Scope; TD-106 replaced Opus reviews on 2026-10-30 |
| D2 | **Validator seam = B19's.** New `internal static class MeasurementPayloadValidator` in `backend/src/Modules/UserData/Infrastructure/`, next to `TargetsPayloadValidator`.<br>• **Members:** `Versions = {1}`, `Covers(entity)` (`measurementType` or `measurement`), `Matches(SyncVersion)` and the constants of D4.<br>• **Hook:** one line in `SyncPayloads.InvalidReason`, right after the targets line: `if (MeasurementPayloadValidator.Covers(version.Entity) && !MeasurementPayloadValidator.Matches(version)) { return "invalidPayload"; }`.<br>• **Fail closed:** a version outside `Versions` returns false. For an unregistered version the registry lookup has already returned `unsupported`, so this matters only when someone registers v2 without touching the validator, and that fails every v2 row loudly.<br>• **`measurementType` is covered with an empty rule set** (`Matches` only checks the version). A future `measurementType` v2 then can't skip a rule it might need: the registry-equals-validator test fails until someone looks.<br>• **Errors:** a bool only; the caller returns the bare `invalidPayload`. The schema has already fixed the JSON types, so `GetDecimal`/`ValueEquals` can't throw on admitted shapes, and the existing catch maps anything unexpected to `invalidPayload`. No allocation per field, no regex, no I/O, no store access | TD-080; B19 D2 (dispatch by entity, fail closed). The same seam serves B21 (D10) |
| D3 | **The rule set is exactly the README list:**<br>• **M1:** `kind == "custom"` ⇔ `customTypeId` is non-null;<br>• **M2:** `inputUnit == "percent"` ⇔ `kind == "bodyFat"` (the schema already limits `inputUnit` to `cm`/`in`/`percent`, so "else cm/in" follows);<br>• **M3:** `kind == "bodyFat"` ⇒ `value` ≤ 100 **and** `inputValue` ≤ 100, as decimal compares (`100.0` passes; `100.0000001` fails).<br>**Not checked:**<br>• the app's plausibility ranges (10–300 cm, 2–75 %);<br>• `value` = `inputValue` × factor;<br>• `localDate` ↔ `measuredAtUtc` + `tzOffsetMin`;<br>• the custom type existing, being live or belonging to anyone (an ID reference across rows: the server never reads other rows, TD-089 style);<br>• name uniqueness, emptiness or characters beyond the schema;<br>• the row-ID version (the README has no row-ID rule for measurements, so a v4 row ID is admitted).<br>**Tombstones** carry full payloads and get identical rules. Compacted `{}` payloads are server-made fences, never client input | Card Scope; A15b D14. App-only rules can change without a server deploy |
| D4 | **Closed vocabularies and constants: one source, pinned three ways** (card "decide" #1). The **contract schema** is the source of the vocabularies and bounds. The **README** is the source of the rule labels. **`fb_domain`** is the source of the corpus.<br>• **New in `fb_domain`** (`src/body/measurement.dart`): `abstract final class MeasurementWireRules` with `static const double maxPercent = 100` and `static bool holds({required MeasurementKind kind, required String? customTypeId, required MeasurementUnit unit, required double value, required double inputValue})` (M1–M3, nothing else). `measurementOf` in the app replaces its inline M1–M3 checks with `holds` (same behaviour; the existing mapper tests stay green). So the app's tolerant read, the corpus's `appWire` and the server are three implementations of one listed rule set, and two of them share code.<br>• **Corpus `vocabularies`:** `kind` = `MeasurementKind.values` codes, `inputUnit` = `MeasurementUnit.values` codes, in enum order.<br>• **Corpus `constants`:**<br>  – `maxPercent` (`MeasurementWireRules.maxPercent`);<br>  – `maxValue` (`MeasurementBounds.readMax`, documented as the wire maximum);<br>  – `tzOffsetMin`/`tzOffsetMax` (`minTzOffsetMinutes`/`maxTzOffsetMinutes`);<br>  – `maxMeasuredAtUtc` (2^53 − 1) and `maxNameLength` (120): literals, because `fb_domain` has no wire constant for them; the C# test pins them to the schema.<br>  – `customKind` `custom`, `percentKind` `bodyFat`, `percentUnit` `percent`, from the enums.<br>• **Corpus `rules`:** `{id, readme}` for `M1 custom type`, `M2 unit fits kind`, `M3 percent bound` (the README bullet labels).<br>• **C# pins** (WP2): the embedded registry = the contract = the corpus, for the enums in order, the bounds, `maxLength`, `additionalProperties: false` and all-required. The validator constants (`MaxPercent = 100m`, `CustomKind`, `PercentKind`, `PercentUnit`) = the corpus constants. The README's M bullets = the corpus `rules`, and each rule has at least one accepted and one rejected tagged case | B19 D4 / B17 D2: no third hand-kept list. A new kind or unit then fails C#'s registry-vs-corpus pin until both sides move (TD-080: a new `measurement` version, server first) |
| D5 | **The variants file stays a fixture, not folded into the corpus** (card "decide" #2).<br>• `measurement-payload-variants.json` is hand-written, A15b's tripwire reads it, and it is the `targets-payload-variants.json` pattern (B19 kept that one too).<br>• The corpus is generated, so folding would make the tripwire depend on a generator.<br>• **Instead:** the C# pure test and the Testcontainers matrix also push every variant (accepted). The Dart corpus test asserts that every variant is schema-shaped and `MeasurementWireRules.holds` | One owner per file; the variants keep testing the column mapping, the corpus tests admission |
| D6 | **Corpus semantics (B19 D9, trimmed).** Each payload: `{id, entity, schemaVersion: 1, rawPayload, deleted, rule?, asymmetry?, serverAccepts, appWire, appReads}`.<br>• **`serverAccepts`** is declared by the generator; C# asserts it, live and as a tombstone.<br>• **`appWire`** (`measurement` only; `null` for `measurementType`, which has no wire rules) is **computed** by the generator. When the decoded content has known `kind`/`inputUnit` codes, `customTypeId` null or a string, and numeric `value`/`inputValue`, it is `MeasurementWireRules.holds(…)`; otherwise false (a vocabulary or type failure the schema also rejects).<br>• **`appReads`** is declared; the app test asserts it against the real `measurementOf`/`measurementTypeOf` (through `db.measurements.map(row)`, so local CHECKs aren't involved, as in B19's weigh-in test).<br>• **The invariant, checked by the Dart test:** for `measurement`, `serverAccepts == appWire` unless the case carries a tag from the closed set:<br>  – `schemaOnly`: metadata, extra or missing members, bounds, formats, `name` length, dates; things M1–M3 don't read;<br>  – `generic`: a lone surrogate, U+0000, a duplicate key, a number decimal can't hold exactly;<br>  – `wholeNumberInteger`: `180.0` for an integer (the server accepts);<br>  – `decimalPrecision`: a value just past 100 that a double rounds onto 100 (the server rejects).<br>  There is no `rowId` tag (no row-ID rule).<br>• **Derived lists, generated and asserted on both sides:**<br>  – `serverRejectsAppTolerates` (`!serverAccepts && appReads`), e.g. a 121-unit name or `decimalPrecision`;<br>  – `serverAcceptsAppSkips` (`serverAccepts && !appReads`), e.g. `value` 0 or `-0.0`, `measuredAtUtc` 2^53−1 (beyond year 9999, A15b review M1), and an empty or blank type name | Makes "admits exactly M1–M3, nothing more" a failing test, not a review claim. Same vocabulary as B19, minus `rowId` |
| D7 | **Corpus content** (synthetic only; `packages/fb_domain/tool/generate_measurement_vectors.dart` exposes `measurementVectors()` plus a CLI writer; `make gen-measurement-vectors`, manual, no CI dependency; about 150 cases). Full list in §3.2 | Covers every edge the README and the schema name, plus the read-bound skips the app has |
| D8 | **Tombstone scrubbing (backlog #136, owner A34).** The server checks no scrubbing; full and scrubbed tombstones get the live rules.<br>• A scrubbed `measurementType` tombstone (`name` `""`) is **admissible** (the schema has no `minLength`).<br>• A scrubbed `measurement` tombstone must stay M1–M3-valid: `value`/`inputValue` 0 are fine (schema min 0, M3 holds), but `kind`/`customTypeId`/`inputUnit` must keep their pairing.<br>• Both are pinned in the corpus, and `contracts/README.md` states them (WP3) | Same split as B19 D11: the app owns the convention, the server applies admission |
| D9 | **Orphan references are valid** (card; A15b D25). The server doesn't cascade a type tombstone to its measurements and doesn't reject a measurement whose `customTypeId` is unknown, tombstoned or another user's ID. Pull returns them; the app hides them. A Testcontainers test pins it | The validator never reads the store (D2). Cross-row consistency is the app's read projection |
| D10 | **B21-ready shape, no speculative framework.**<br>• **Production:** one validator class per entity family plus one hook line each; no validator interface or registry object yet (two validators don't need one).<br>• **Test side:** a pure test `Fail_closed_validators_cover_exactly_their_registry_versions` loops a small test-side table `(name, Covers, Versions, entities)` with rows for Targets and Measurement. It asserts:<br>  – every listed entity is covered;<br>  – its registry versions = the validator's `Versions`;<br>  – no unlisted registry entity is covered.<br>  B21 adds one row.<br>• **The B20 card is the pattern B21 copies:** contract commit (B21 has one), the validator, the hook line, a corpus with `serverAccepts`/`appWire`/`appReads`, the pure + Testcontainers + privacy + erasure tests.<br>• `backend/README.md` § Document sync gets a short "adding an entity family" checklist (WP3) | Keeps B21 mechanical without adding abstractions now. A shared generator helper waits until there are three-plus generators (B21 may extract it; noted under Risks) |
| D11 | **Test helpers:** `MeasurementCases.cs` in `backend/tests/UserData.Tests/` (corpus reader, `Baseline(entity)`, `Raw(id)`, `NewId` = `SyncTestIds.For`), compile-linked into `Persistence.Tests` (the `BodyTargetsCases` pattern). `SyncHttpSupport` and `PersonalFoodHttp` are reused unchanged (B19 already added `SchemaVersion` and `id`). Content links: the corpus, the variants file and `contracts/README.md` in both test csproj files, where they aren't linked already | Reuse over copy |
| D12 | **Docs** (WP3, with the server change):<br>• `contracts/README.md` § Measurement semantic rules in the present tense ("B20 admits…"), with the deploy-hold sentence removed and the corpus pointer and tombstone note (D8) added;<br>• `contracts/testdata/README.md`: the corpus format (WP1);<br>• `05` §5.5: line 154 in the present tense, hold removed;<br>• `backend/README.md` § Document sync: a B20 paragraph plus the D10 checklist;<br>• A34 handoff lines (§8) | The payload authority stays readable, and the hold disappears from every doc at once |

**⚠️ OWNER items: none.** Everything is additive: a server validator for rules the README already lists, one small `fb_domain` class, and tests. There's no spec change, no Accepted-TD change (TD-080 applied as written; TD-103 stays Proposed and isn't touched), no vendor or cost, and no security trade-off. **Owner FYI at the close:** the deploy hold is lifted, so the phone server can update. **TD candidates: none** (the fail-closed dispatch is already documented in `contracts/README.md` and `05` §5.5).

### 3. Design

**3.1 Server** (UserData module only; no new cross-module call; Postgres stays the only state):
```csharp
internal static class MeasurementPayloadValidator
{
    public const decimal MaxPercent = 100m;
    public const string CustomKind = "custom", PercentKind = "bodyFat", PercentUnit = "percent";
    public static readonly FrozenSet<int> Versions = FrozenSet.Create(1);
    public static bool Covers(string entity) => entity is "measurementType" or "measurement";
    public static bool Matches(SyncVersion version) =>
        Versions.Contains(version.SchemaVersion) && version.Entity switch
        {
            "measurementType" => true,                     // no wire rules (README); version-pinned only
            "measurement" => Measurement(version.Payload), // M1, M2, M3
            _ => false,
        };
}
```
- `SyncPayloads.cs`: the one hook line (D2).
- Storage, `PushForSessionAsync`, the advisory lock, forced RLS, LWW/history, receipts, retention and compaction, and `UserDataErasure` are untouched: they're entity- and version-agnostic (B05/B06), and B20 only proves them for these entities.

**3.2 Corpus** (`contracts/testdata/sync/measurement-validation-vectors.json`; top-level blocks `version`, `constants`, `vocabularies`, `rules`, `payloads`, `serverRejectsAppTolerates`, `serverAcceptsAppSkips`, `writerCases`):
- **Bases**, built from `fb_domain` drafts and refs (`MeasurementDraft`, `MeasurementTypeRef`, `MeasurementInput`, `EntryTime`), with no app mapper copied:
  - `measurementType-base`;
  - one per built-in kind in cm;
  - `waist` typed in inches;
  - `bodyFat` in percent;
  - `custom` in cm and in inches.
- **M1:**
  - `custom` with a null ID (rejected);
  - each built-in kind with an ID (rejected);
  - `custom` with an ID (accepted).
- **M2:**
  - `bodyFat` with `cm` and with `in`;
  - each length kind and `custom` with `percent` (all rejected).
- **M3 (on `bodyFat`):**
  - `value` 100 and `100.0`: accepted;
  - `value` 100.0000001: rejected;
  - `value` 99 with `inputValue` 100.01: rejected;
  - `value` 0 and `-0.0`: accepted, app skips;
  - `100.0000000000000001`: `decimalPrecision`.
- **M3 scope:** a length kind at 150 cm is accepted (M3 applies to `bodyFat` only).
- **Not wire rules (all accepted, D3):**
  - `waist` 5 cm and 999999 cm;
  - body fat 1 % and 90 %;
  - `value` ≠ `inputValue` × 2.54;
  - a `localDate` that doesn't match the instant;
  - a custom measurement pointing at a type that was never created;
  - a nil and a v4 `customTypeId`;
  - a v4 row ID;
  - type names `""`, `"   "` and one with control characters.
- **Schema cases:**
  - `kind`: unknown, `BodyFat`, `WAIST`;
  - `inputUnit`: `inch`, `IN`, `%`, `""`;
  - `customTypeId`: uppercase, no hyphens, braces, `""`, a number;
  - `measuredAtUtc`: −1; 2^53−1 (accepted, app skips); 2^53; 1.5; `1792310400000.0` (`wholeNumberInteger`);
  - `tzOffsetMin`: −720 and 840 (accepted); −721, 841, 60.5, `"60"` (rejected); `180.0` (`wholeNumberInteger`);
  - `localDate`: `2026-02-29`, `0000-01-01`, `9999-12-31`, padded or short forms, Arabic-Indic digits;
  - `value`/`inputValue`: −0.1, 1e6 (accepted), 1000000.001;
  - `name`: 120 and 121 UTF-16 units, plus a supplementary pair straddling the limit;
  - **metadata boundaries, for both entities** (plan review round 1): `createdAtMs` 0 and 2^53−1 (accepted); −1, 2^53, 1.5 and `1e400` (rejected); `origin` 128 UTF-16 units (accepted) and 129 (rejected); tagged `schemaOnly` where the server rejects (`generic` for `1e400`, the representability pass);
  - each field missing, an extra field, and a metadata field with the wrong type.
- **Numbers:** quoted `"NaN"` and `"Infinity"`; raw `1e400`, `-1e400` and `1e-400`; a 31-significant-digit decimal (`generic`).
- **Generic:** a lone high and a lone low surrogate in `name`, U+0000, and a duplicate `kind` key (raw text kept).
- **Tombstones:** a full-payload tombstone of each base and of each M violation (same outcome), and the scrubbed tombstones of D8.
- **Writer cases** `{id, entity, payloadId}`: each base `measurement` ↔ `measurementColumns(draft)`; the type base and a trimmed name (`"  Left arm "` → `"Left arm"`) ↔ `measurementTypeColumns(name)`.

**3.3 App parity** (test-only; production change = the mapper calling `MeasurementWireRules.holds`). `apps/mobile/test/features/body/data/measurement_sync_vectors_test.dart`:
- **Server → app:** every payload's content → a snake_case SQL row with fixed sync columns → `db.measurements.map` / `db.measurementTypes.map` (a `TypeError`/`FormatException` counts as not read) → `measurementOf` / `measurementTypeOf` (`MeasurementMappingError` = not read). The result must equal `appReads`.
- **App → server:** every writer case: `measurementColumns(draft)` / `measurementTypeColumns(name)` → camelCase content = the payload content, with doubles normalized as in B19.

**3.4 Data flow and rules.** Contract-first holds: the contract is unchanged, and the server conforms to it plus the README rules. The single writer on the phone is untouched: no app write path changes, and nothing uploads until A34. Module boundaries: the validator lives in UserData/Infrastructure, with no other module. RLS and per-user isolation are unchanged and proven (`04` §6). No user content in logs: a bare `invalidPayload`, no value or name, proven by the canary.

### 4. Work packages

| WP | By | Tasks · files | Done when |
|---|---|---|---|
| **WP1 · Corpus and Dart/app parity** `test(sync): measurement validation corpus and app parity` | `flutter-engineer` | • `MeasurementWireRules` (D4) in `packages/fb_domain/lib/src/body/measurement.dart` (exported), and `measurementOf` calling it in `apps/mobile/lib/features/body/data/measurement_mappers.dart`<br>• `packages/fb_domain/tool/generate_measurement_vectors.dart`<br>• `contracts/testdata/sync/measurement-validation-vectors.json`<br>• `packages/fb_domain/test/body/measurement_vectors_test.dart`<br>• `apps/mobile/test/features/body/data/measurement_sync_vectors_test.dart`<br>• `Makefile` `gen-measurement-vectors`<br>• `contracts/testdata/README.md` (corpus format)<br>• Progress-log line.<br>No throwaway server cross-check (plan review round 1): WP2's permanent admission tests check every `serverAccepts` in CI. A disagreement is reported, never hidden by editing either side | `make gen-check` (no diff beyond the new corpus); `make check-dart`; `git diff --check`; CI `dart-test` green, with `fb_domain` coverage still 100 % |
| **WP2 · Semantic admission + pure tests** `feat(userdata): admit measurement wire rules M1–M3` | `dotnet-engineer` | • `MeasurementPayloadValidator.cs` and the hook in `SyncPayloads.cs` (D2/D3)<br>• `backend/tests/UserData.Tests/MeasurementCases.cs`: the corpus plus a schema-derived missing/null/wrong-type/extra matrix for both entities (the `BodyTargetsCases` pattern)<br>• `MeasurementPayloadTests.cs`<br>• the D10 cross-validator test (it may live in `BodyTargetsPayloadTests.cs` or in a new `SemanticValidatorTests.cs`)<br>• csproj content links (D11).<br>If a corpus declaration disagrees with the server, stop and report; never widen either side silently | `make check-dotnet`; `make check-sync-schemas`; `git diff --check`; CI `dotnet` job green, with the B17/B18/B19 suites unchanged |
| **WP3 · Persistence, erasure, privacy, docs** `test(userdata): measurement sync persistence, erasure and privacy` | `dotnet-engineer` | • `backend/tests/Persistence.Tests/MeasurementSyncTests.cs`<br>• the B20 privacy `[Fact]` in `IdentityPrivacyTests.cs` (`SinkCapture`)<br>• compile links in `FitnessBuddy.Persistence.Tests.csproj`<br>• D12 docs (`contracts/README.md`, `05` §5.5, `backend/README.md`) and the A34 handoff lines.<br>Privileged migrator connections only for inventory and aging; production grants unchanged | `make check-dotnet`; `git diff --check`; CI `dotnet` (Testcontainers) and `contract-conformance` green. Locally at most `heavy.sh timeout 600` reproductions of failing CI tests |
| **Close** | orchestrator; two parallel Codex review tasks (code/architecture + security/data integrity), read-only, whole diff `main..branch`; fixes by the WP's engineer; at most about 2 fix-check rounds | • `evidence/B20-verification.md` from the security task<br>• Outcome; board row<br>• backlog #214 and **#215 closed**; #136 note (D8); `make progress`<br>• merge via `tools/scripts/merge-step.sh B20 "Measurement sync entities (server)" step/B20-measurement-sync` (background; one merge at a time)<br>• then the **deploy-hold release** (§8) and an owner FYI | No open blocker or major; CI green on the merge commit; `make trace`. No `android-it` or Patrol (no app UI or native change) |

### 5. Test list
Lean (TD-104): risk-focused tests only, meaning admission and validation, RLS isolation, conflict/revision behaviour, erasure, privacy and conformance. No copy asserts, no Patrol, no goldens. C# tests carry `[Trait("Req", "WB-040" | "WB-042" | "AC-010" | "AC-012" | "AC-031")]` or `[Trait("Rule", "B20.<slug>")]` / the existing `05.5-…`, `04.6-…`, `09.4-no-user-content` tags. Dart test names start with the spec ID or `B20`.

| Test (file) | Proves |
|---|---|
| `B20 generated vectors match committed bytes` (`measurement_vectors_test.dart`) | corpus drift gate (TD-080) |
| `B20 untagged measurement cases have serverAccepts equal to MeasurementWireRules; asymmetry lists are exactly the derived cases` (same) | D3/D6: exactly M1–M3, nothing more or less |
| `WB-040 WB-042 app-only plausibility outliers and the variants file are wire-valid` (same) | D3, D5 |
| `WB-040 WB-042 corpus payloads decode through measurementOf and measurementTypeOf as declared` (`measurement_sync_vectors_test.dart`) | exit 4, server → app; read-bound skips listed |
| `WB-040 drafts and names written by the real column writers equal accepted corpus payloads` (same) | exit 4, app → server |
| `Embedded_schema_vocabularies_and_bounds_equal_contract_and_corpus` (`MeasurementPayloadTests`) | D4; `make check-sync-schemas` in meaning |
| `Validator_constants_equal_corpus` | D4 |
| `Fail_closed_validators_cover_exactly_their_registry_versions` (Targets + Measurement rows) | D2/D10; the B21 hook |
| `Measurement_validator_fails_closed_for_unregistered_versions_and_other_entities` | D2 |
| `Readme_measurement_rules_equal_corpus_rules_and_each_has_accept_and_reject_cases` | exit 1, single source |
| `Payload_matrix_matches_admission_for_live_and_tombstone` (Theory over every corpus case + the schema matrix + fixtures and variants) | exit 1/conformance: each wire rule and schema rule (unknown kind or unit, extra or missing field, over-long name, out-of-range number), live and as a tombstone |
| `Wire_rules_accept_valid_and_reject_each_violation` (Theory over M1–M3) | exit 1, named per rule |
| `Numbers_reject_nan_infinity_overflow_and_unrepresentable` | exit 1: quoted NaN/Infinity, ±1e400, 1e-400, 31 digits; never a 500 |
| `Not_wire_rules_are_admitted` | D3 "nothing more": plausibility, factor, local date, unknown/nil/v4 type ID, v4 row ID, blank names |
| `Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions` (`MeasurementSyncTests`) | exit 2, AC-010: authenticated push of every case in byte-bounded batches; ordered `invalidPayload` with no canary in the ack; invalid `(entity, id, hlc)` absent from documents, history and receipts; accepted versions pulled exactly |
| `Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable` (Theory, 2 entities) | AC-012, `05.5-version-identity` (conflict/revision) |
| `Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection` (Theory, 2; including the scrubbed tombstones of D8) | AC-012, `05.5-retention`, D8 |
| `Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned` (Theory, 2) | `04.6-rls`, exit 2 |
| `Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401` (one entity per path) | `04.6-authz`, exit 2 |
| `Orphan_and_tombstoned_type_references_are_admitted_and_pulled` | D9: measurement before its type, after the type's tombstone, pointing at another owner's type ID; no cascade |
| `Delete_account_erases_measurement_live_history_fences_and_receipts_and_preserves_second_owner` | AC-031, exit 3: real `DELETE /v1/me`; per entity: live, displaced, compacted fence, receipts; privileged zero-row inventory; second owner intact |
| `B20_measurement_names_and_values_never_reach_errors_logs_or_telemetry` (`IdentityPrivacyTests`) | `09.4-no-user-content`, exit 2. **Canaries:** a custom type name (`CANARY-B20-TYPE-NAME`) and an Arabic one, plus distinctive numbers (`value` 87.6543219, `inputValue` 34.5098761, body fat 18.7654321, an M3 violator 150.1234567). **Legs:** accepted, M1-invalid, M3-invalid, schema-invalid (extra field, unknown `inputUnit`), guest 403. **Assertion:** no canary in any response except owner pull/history, nor in logs, scopes, spans, metrics, Sentry, audit or Postgres logs |

Count: **22 named tests**: 3 `fb_domain`, 2 app, 9 C# pure, 7 Testcontainers, 1 privacy. The Theories expand to about 300 C# cases (the corpus × live/tombstone).

### 6. Exit-criteria mapping

| Exit criterion | Evidence |
|---|---|
| Validator tests: M1–M3 accept a valid case and reject each violation (NaN/inf/overflow included), equal to the corpus | WP2 `Readme_…`, `Wire_rules_…`, `Numbers_…`, `Payload_matrix_…`; WP1 drift + invariant tests |
| Persistence (Testcontainers): accepted push, invalid → `invalidPayload` with no value in the response or telemetry, pull, history, tombstone, RLS, guest 403 | WP3 matrix, LWW/tombstone/RLS Theories, guest test, privacy fact |
| Account deletion covers both entities' documents, history and fences | WP3 `Delete_account_erases_measurement_…` |
| App parity: A15b's mappers and writers round-trip the corpus | WP1 `measurement_sync_vectors_test.dart` (both directions) |
| `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet`; CI green | WP2/WP3 gates; exact-commit CI via `merge-step.sh`, recorded in the evidence file |
| Security review: no open blocker or major; deploy hold lifted | Codex security task + `B20-verification.md`; §8 release check, backlog #215 closed, owner FYI |

### 7. Risks and unknowns

| Risk | Handling |
|---|---|
| **Dart/.NET parsing differences** (dates, digit forms, `-0.0`, tiny decimals, `100.0000000000000001`) | Pinned as corpus cases and tagged from the closed set (`generic`, `decimalPrecision`, `wholeNumberInteger`). A new kind of difference is reported to the orchestrator; the server is never relaxed and the corpus never edited to hide it |
| **The mapper refactor changes app read behaviour** | `holds` is the same M1–M3 logic; A15b's mapper and repository tests (tolerant reads, M1/M2/M3 mismatch skips) must stay green in CI, and the parity test re-proves it on about 150 cases |
| **`customTypeId` format strictness** (the server requires a lowercase canonical UUID; the app's `checkUuid` too) | Pinned (uppercase, braces, no hyphens rejected on both sides). If the app turns out to accept a form the server rejects, it lands in `serverRejectsAppTolerates` for A34 #111 |
| **Permanently rejected rows** (a blank-name or scrub edge, `decimalPrecision`) | Listed in the corpus; A34 handoff: no endless retry (#111) |
| **Deploy hold stays on longer than planned** (phone checks blocked) | B20 is ordered first in wave 2; no other lane waits on B20's files. If a review round drags past ~2 fix rounds, edge cases go to the backlog per PROCESS A4 and the step merges |
| **Parallel lanes** (`Makefile`, `contracts/README.md`, `05`, `backend/README.md`, `IdentityPrivacyTests.cs`, board, backlog) | Rebase before the merge; board/backlog edits and `make progress` only at the close; never touch other clones |
| **B21 duplicates a fourth generator** | Out of scope here; B21's plan may extract a shared corpus helper from the B19/B20 generators (noted in the handoff) |
| **Card wording "fresh Opus security review"** | Superseded by TD-106 (Codex), D1; no owner item |

### 8. Deploy-hold release (orchestrator, after the merge)
Before updating the B03 phone server, check:
1. **B20 is on `main`:** `merge-step.sh` finished with `ci` green on the B20 squash commit `<B20>`.
2. **The server image will contain it:** follow the runbook upgrade (`docs/runbooks/laptop-test-server.md` § Stop, restart and upgrade): back up and restore-check with the installed controller, stop, then `make serve-phone-prepare` from a clean, up-to-date `main`. Then confirm that the revision it records (`make serve-phone-status`) satisfies `git merge-base --is-ancestor <B20> <recorded revision>`, and that `git grep -n MeasurementPayloadValidator <recorded revision> -- backend/src/Modules/UserData/Infrastructure/SyncPayloads.cs` finds the hook.
3. **No schema surprise:** B20 adds no migration. The migrations the image brings since the server's current revision are forward-only (runbook); start with `make serve-phone`, then check that `make serve-phone-status` is healthy and `/health/ready` is `Healthy`.
4. **No live probe against the owner's database:** the admission evidence is CI's Testcontainers and pure tests on the exact merge commit. Don't push synthetic rows into the real phone volume.
5. **Records:** close backlog #215 (and #214) with the B20 commit and the recorded server revision; `make progress`; one-line owner FYI ("B20 merged: the phone server can update again; your phone checks are unblocked").

### 9. Handoffs (written in WP3)
- **A34 Scope:**
  - upload `measurementType`/`measurement` v1 only after B20 is deployed;
  - a scrubbed `measurement` tombstone keeps the M1–M3 pairing (D8);
  - the corpus's `serverRejectsAppTolerates` rows are never retried endlessly (#111).
- **B21:** copy the D10 pattern (contract commit, validator + hook line, a row in the cross-validator test, a corpus with `serverAccepts`/`appWire`/`appReads`, persistence/erasure/privacy tests).

### 10. Size check
WP1 0.6 (generator ~150 cases, the `fb_domain` class, the two Dart tests) · WP2 0.4 · WP3 0.4 · close and Codex rounds 0.2 = **~1.6 sessions (M)**. Below L, so no split. A natural seam exists if needed (WP1 Dart vs WP2–WP3 C#), but splitting would mean two merges for one admission rule set, and the deploy hold favours one merge.

## Progress log
- 2026-10-30 · Outline card written at A15b's review round 1 from A15b D23 (server validator M1–M3, shared corpus, Testcontainers, security review, deploy hold).
- 2026-10-30 · Low-level plan written (step-planner, lane 4, from fe4f671): D1–D12, WP1–WP3 + close, size M (~1.6 sessions), Risky, no owner items or TD candidates; the deploy-hold release check is in §8. Next: Codex plan review, then orchestrator self-approval.
- 2026-10-30 · Plan review round 1 (Codex): approve with minor corrections, applied: WP1's throwaway server cross-check dropped (WP2's CI tests cover it); metadata boundary vectors (`createdAtMs`, `origin` 128/129) added to §3.2 for both entities. Orchestrator self-approved (TD-037). Next: WP1.
- 2026-10-30 · WP1 built: `MeasurementWireRules` (fb_domain; `measurementOf` calls it), generator + corpus (185 payloads, 12 writer cases; tags `schemaOnly`/`generic`/`decimalPrecision`, no `wholeNumberInteger`: M1–M3 read no integer field), fb_domain drift/invariant/outlier/consistency tests, app parity test, `make gen-measurement-vectors`, testdata README. `make gen` no diff; scoped `dart analyze` clean (the full-repo analyzer crashed on memory). Next: WP2.
- 2026-10-30 · WP1 CI green on 46afc77. WP2 built: `MeasurementPayloadValidator` (M1–M3, `measurementType` version-pinned only) + the hook line in `SyncPayloads.InvalidReason`; `MeasurementCases.cs` (corpus + schema matrix + fixtures + variants), `MeasurementPayloadTests.cs` (10 tests), `SemanticValidatorTests.cs` (the D10 table, Targets + Measurement); csproj links. `make check-dotnet` (0 warnings), `make check-sync-schemas` green. Next: WP3.
- 2026-10-30 · WP2 CI green on b938682. WP3 built: `MeasurementSyncTests.cs` (7 Testcontainers tests), the B20 privacy fact, Persistence csproj links; docs: `contracts/README.md` (present tense, hold sentence removed, tombstone/orphan note, corpus pointer), `05` §5.5, `backend/README.md` (B20 paragraph + "adding a semantic entity family" checklist), A34 B20 handoff block. `make check-dotnet` green. Next: CI on the WP3 commit, then the close (Codex reviews, merge, deploy-hold release: orchestrator).

## Outcome
_Build WPs done 2026-10-30 (lane 4); the close (Codex code + security review tasks, `evidence/B20-verification.md`, merge, board/backlog #214/#215, deploy-hold release §8, owner FYI) is the orchestrator's._

**Built**
- **Contract:** unchanged (A15b WP8); `make gen` leaves no diff, `make check-sync-schemas` green.
- **Server:** `MeasurementPayloadValidator` (UserData/Infrastructure) = exactly README M1–M3 (`measurementType` version-pinned only), dispatch by entity, **fail closed** by schema version; one hook line in `SyncPayloads.InvalidReason`. Storage, LWW/history, retention/fences, RLS and erasure unchanged (entity-agnostic).
- **fb_domain / app:** `MeasurementWireRules` (`maxPercent`, `holds`); `measurementOf` calls it (same behaviour).
- **Shared corpus:** `contracts/testdata/sync/measurement-validation-vectors.json` (185 payloads, 12 writer cases; `packages/fb_domain/tool/generate_measurement_vectors.dart`, `make gen-measurement-vectors`), with the metadata boundary vectors of plan review round 1. 38 `serverRejectsAppTolerates`, 9 `serverAcceptsAppSkips`.
- **Tests (26 named, lean TD-104):** Dart: 4 fb_domain (byte drift; untagged `serverAccepts == holds`, closed tags, `schemaOnly` only where M1–M3 don't look, derived lists; plausibility outliers + fixtures/variants wire-valid; rules/tombstones/writers/constants) + 3 app (contract field order; corpus through the real `measurementOf`/`measurementTypeOf`; drafts and names through `measurementColumns`/`measurementTypeColumns`). C# pure: `MeasurementPayloadTests` 10 (the matrix Theory = 275 cases × live/tombstone: corpus + schema matrix + 2 fixtures + 3 variants; M1–M3 hand-built Theory; numbers; not-wire rules; README = corpus rules; embedded = contract = corpus; validator constants; fail-closed) + `SemanticValidatorTests` 1 (the D10 table, Targets + Measurement). Testcontainers: `MeasurementSyncTests` 7 (batched matrix with privileged inventory, LWW ×2, tombstones/fences incl. scrubbed ×2, RLS ×2, guest 403/401, orphan/tombstoned/foreign type references, account deletion) + the B20 privacy canary fact (accepted, M1/M2/M3/schema-invalid, guest 403).

**Deviations:** one builder (this agent) for WP1–WP3 instead of the flutter/dotnet split; WP1's throwaway cross-check dropped (plan review round 1). Asymmetry set is `schemaOnly`/`generic`/`decimalPrecision`: no `wholeNumberInteger` (M1–M3 read no integer field, so `180.0` is accepted on both sides) and no `rowId`. Every `measurementType` rejection carries `schemaOnly` or `generic` (it has no wire rules), pinned on both sides. Corpus adds `constants.maxOriginLength` and a `name` on the type writer cases (the trimmed-name write). 26 named tests vs 22 planned (a contract-field pin on the app side, a schema-matrix coverage test, split consistency tests). Locally the full-repo `dart analyze` crashed on memory (7 GB box); package-scoped analysis was clean and CI's `dart` job is the gate. No local test runs (owner rule); CI is the evidence.

**Follow-ups:** A34 B20 handoff block (upload after deploy, scrubbed tombstones keep the pairing #136, permanent rejections #111, num→int, no cascade). B21 copies the checklist in `backend/README.md` § Document sync; a shared generator helper can be extracted when a third corpus generator lands.

**New TDs:** none.

**Metrics:** planned M, build actual ~1 session (3 WPs, one builder). Plan review: Codex approve with minor corrections (2, applied). CI: WP1 `46afc77` green, WP2 `b938682` green; WP3 below in the report / Progress log.
