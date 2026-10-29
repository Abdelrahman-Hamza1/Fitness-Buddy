# B19 — Body & targets sync entities (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B05 ✅, **B18** ✅, **A13a** ✅, **A14** ✅ | M | Claude | ✅ Done |

_New step (orchestrator, 2026-10-28, A13 plan review PA12; outline card, the Low-level plan is written in Phase B). The app sides are A13a (targets entities) and A14 (weigh-ins); the upload is A34's. **Tier: Risky** (user-data admission, untrusted input, account erasure)._

**Goal.** The server admits, stores, serves and erases the body and targets sync entities exactly as the contract and their wire rules say, so A34 can upload profile, goal phases, target settings and weigh-ins.

**Spec:** TG-001, TG-012, TG-040 (data that syncs), WB-001, WB-003 (weigh-ins), AC-010 (data syncs to the account), AC-012 (offline changes sync; row-level last-write-wins + history, `05` §5), AC-031 (deletion covers them) · **Decisions:** TD-031, TD-049, TD-080, TD-089, TD-090 (Accepted at the A13a merge)

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
- [x] Validator tests: every wire rule in `contracts/README.md` § "Targets semantic rules" accepts a valid case and rejects each violation (NaN/infinity/overflow included), equal to the corpus.
- [x] `weighIn` v2: valid and invalid cases (tz offset bounds, unit enum, negative input value); v1 still accepted.
- [x] Persistence tests (Testcontainers): accepted push, each invalid case → `invalidPayload` with no value in the response or telemetry, pull, history, tombstone, cross-user isolation (RLS), guest 403.
- [x] Account deletion test includes the four entities' documents, history and fences.
- [x] `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet` green; CI green.
- [x] Security review: no open blocker or major.

## Read first
`05-data-and-sync.md` §5.5 · `04-backend.md` §4.2, §7 · the A13 card's D2, D3, D15 and PA6 · the A14 card's D6/D7 and PA4 · B17's card and Outcome (the hook and corpus pattern)

## Owner involvement
None.

---

## Low-level plan
_Step-planner (Claude, 2026-10-29); architect plan review applied in §9 (self-approved, TD-037: no owner item). Lane 3 (TD-087): `/home/abood/work/fitness_buddy_3`, branch `step/B19-body-targets-sync`. Heavy commands (Testcontainers, `make contract-conformance`, migration dumps) go through `tools/scripts/heavy.sh`. Full suites run in CI; each WP runs focused tests plus `make check-dart` / `make check-dotnet` before its commit (TD-095, 2026-10-29)._

**Tier: Risky.** **Size: M** (about 2 sessions, upper end). Five ordered WPs, one commit each, **one merge** at the end. There's no early contract merge, because no lane is waiting: A34 hasn't started. **Builders (TD-095):** a `flutter-engineer` builds WP1–WP2 (contract JSON plus Dart: the tripwire, the corpus generator and the app parity tests); a `dotnet-engineer` takes over at the specialty seam for WP3–WP4. WP5 is the orchestrator with fresh reviewers. Expected changes:
- no migration, endpoint, OpenAPI path or generated-client change;
- no paid call and no new dependency;
- the production C# change is one small validator plus a one-line hook;
- the production Dart change is one named constant.

### 1. Summary
After B19 the server admits `profile`, `goalPhase` and `targetSettings` v1 exactly as `contracts/README.md` § "Targets semantic rules" says: the schema plus a hand-written `TargetsPayloadValidator` for the rules the exporter can't express (TD-080). It also admits `weighIn` v1 **and** a new additive `weighIn` v2, which carries A14's four local columns. Both versions are stored, pulled, versioned and erased by the unchanged B05/B06 machinery, each document under its own `schemaVersion`. A Dart-generated corpus (`contracts/testdata/sync/body-targets-validation-vectors.json`) is built from the real `TargetRules.wire` and weigh-in domain types. Three checks pin both sides to it:
- a byte-equality drift test in `fb_domain`;
- app tests through the real A13a/A14 decoders and column writers;
- C# tests that read the same corpus.

Testcontainers tests prove the following for every entity/version pair: push, pull, LWW plus history, tombstones and fences, RLS, guest 403, erasure and a telemetry canary.

### 2. Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **In scope:** `profile` v1, `goalPhase` v1, `targetSettings` v1 (unchanged, from A13a) and `weighIn` v1 (unchanged) + v2 (new). **Out of scope:** the contract has no `measurement`/`measurementType`, workout or Ramadan entity. AC-010's measurements get their own contract commit with their app step and a sibling server step. **Card correction:** TD-089 and TD-090 are now **Accepted** (A13a merge, 2026-10-29), not Proposed | Verified against `contracts/openapi/sync-entities.json` (14 entities) |
| D2 | **Validator seam.** New `internal static class TargetsPayloadValidator` in `backend/src/Modules/UserData/Infrastructure/`, next to `PersonalFoodPayloadValidator`. **Hook:** `SyncPayloads.InvalidReason` calls it after `Representable` + `Matches` (and the `mealSlot` check), before the nested `...Json` loop; the targets entities have no `...Json` fields. The hook line is `if (TargetsPayloadValidator.Covers(version.Entity) && !TargetsPayloadValidator.Matches(version)) { return "invalidPayload"; }`. **Signature:** it takes the whole `SyncVersion`, because the row-ID rule needs `version.Id`. **Dispatch** is by entity for **every** schema version and **fails closed**: a version outside `TargetsPayloadValidator.Versions` (`{1}`) returns false, and a pure test pins registry versions = validator versions. **Return value:** a bool only; the caller returns the bare `invalidPayload`. The schema has already fixed the JSON types, so `GetDecimal`/`GetBoolean`/`DateOnly.ParseExact` can't throw on admitted shapes, and the existing `catch` maps anything unexpected to `invalidPayload` | The B17 pattern (TD-080). Failing closed means a future `targetSettings` v2 can't silently skip the wire rules (B17's `SchemaVersion == 1` dispatch would fail open) |
| D3 | **The rule set is exactly the README list; nothing more is checked.**<br>• **R1 positive:** `heightCm`, `baseKcal`, `basisWeightKg` > 0, and `targetKg` > 0 when non-null.<br>• **R2 expression fields:** per `expressionKind`, exactly its own fields among `targetKg`, `targetDate`, `kgPerWeek`, `monthKg`, `month` are non-null.<br>• **R3 target-rate speed:** `targetRate` ⇒ `kgPerWeek` > 0.<br>• **R4 maintain:** `maintain` ⇒ `weekly` ∧ `kgPerWeek` = 0 (decimal compare, so `-0.0` = 0).<br>• **R5 phase dates:** `endDate` null or ≥ `startDate` (`DateOnly` compare).<br>• **R6 macro pairs:** `…Value`/`…IsPercent` both null or both set; percent value ≤ 100.<br>• **R7 acknowledgement:** `acknowledged` ⇒ `manual`.<br>• **R8 row IDs:** `goalPhase`/`targetSettings` IDs are UUIDv7 (`Guid.Version == 7` and the RFC variant); the `profile` ID equals `naturalId('profile','self')`.<br>**Not checked:** plausibility ranges (A13 D15), goal direction vs sign, `month` being a first day, shift-weight levels, name characters beyond the schema, and anything across rows (TD-089).<br>**Tombstones** carry full payloads and get identical rules (B17 D6). Compacted `{}` payloads are server-produced fences, never client input | A13 PA6 / card Scope: the server admits `TargetRules.wire` and the README's row-ID rule. App-only rules may change without a server deploy |
| D4 | **Single source, pinned three ways.** The README section stays the human source; the corpus is the machine copy generated from `fb_domain`.<br>• **Dart:** add `static const double maxPercent = 100` to `TargetWireRules` and use it in place of the literal `100` in `targetSettings()`. It's a one-line `lib/` change and coverage stays 100 %.<br>• **Corpus `constants`:** `maxNumber` (`TargetLimits.maxNumber`), `maxRevision`, `maxNameLength`, `maxPercent`, `tzOffsetMin`/`tzOffsetMax` (`minTzOffsetMinutes`/`maxTzOffsetMinutes`), `profileRowId`.<br>• **Corpus `vocabularies`:** from `FormulaSex`, `HeightInputUnit`, `ActivityLevel`, `GoalType`, `GoalExpressionKind`, `GoalWeightUnits`, `TargetMode`, `WeighInInput.units`.<br>• **Corpus `rules`:** `{id, readme}`, one per README bullet label (`Positive numbers`, `Expression fields`, `Maintain`, `Phase dates`, `Macro pairs`, `Acknowledgement`, `Row IDs`).<br>• **C# pins:** C# constants (`MaxPercent`, `ProfileRowId`) = corpus; embedded registry = contract = corpus (bounds and enums); README bullets = corpus `rules`, and each rule has at least one accepted and one rejected tagged case.<br>• **`profileRowId`:** `naturalId` lives in `apps/mobile`, so the generator writes the literal and the **app** test proves it equals `profileRowId` | B17 D2 / B18 D9: no third hand-kept list. The README check makes "exactly that list" testable |
| D5 | **`weighIn` v2 schema (own commit first).** The v1 properties are unchanged and in the same order, plus `tzOffsetMin` (`integer`, −720…840), `inputValue` (`number`, 0…1e12), `inputUnit` (`string`, enum `kg`/`lb`) and `preferredForDay` (`boolean`). Every property is required; `additionalProperties: false`. v1 isn't edited. `inputValue` gets `maximum: 1e12` because every number in the contract has a technical maximum (checked) and 1e12 is v1 `kg`'s; the app's limit is 1,102.3 lb (A14 D6). `contracts/openapi.yaml` and `fb_api_client` don't change (the envelope `payload` is a generic object): `make gen` touches only the embedded `entities.json` | A14 D7/PA4 + WB-003 (value, unit, date **and** time). Additive; no owner gate |
| D6 | **v1/v2 coexistence needs no server code.**<br>• **Admission:** `SyncPayloads` already looks up the schema by the change's `schemaVersion`. A v1 payload sent as 2 (missing fields) and a v2 payload sent as 1 (extra fields) are `invalidPayload`; version 3 is `unsupported`.<br>• **Storage and reads:** `documents`/`row_history` store `schema_version` per version; pull and item history return each document's own.<br>• **LWW:** by HLC whatever the version. A newer v1 from an old client replaces a v2; the server never upgrades or downgrades.<br>• **Version identity:** the fingerprint includes `schemaVersion`, so the same `(entity, id, hlc)` sent as v1 and as v2 is `versionConflict`.<br>• **No weighIn-specific validator:** every v2 rule is expressible in the schema. Cross-field consistency (`kg` = `inputValue` × factor, offset ↔ `localDate`) is app-local, as in A14 D6.<br>• **App reads of v1** use A14 D7's v1→v2 upgrader, which is A34's (`05` §5.2 "upgraders in fb_domain").<br>• **Server-first:** A34 uploads only v2, after B19 is deployed | `05` §5.2 schema evolution; TD-031 |
| D7 | **Fixtures.** `contracts/testdata/sync/entity-payloads.json` stays "one schema-1 payload per entity". Six C# sites push it at schema 1 (`ProductionSyncTests`, `AccountDeletionTests`, `IdentityPrivacyTests`, `PersonalFoodHttp.Fixture`, two all-fixture checks), and the app migration tests seed from it. New hand-written `contracts/testdata/sync/entity-payloads-v2.json` = `{"weighIn": {…v2…}}`, same format, documented in `contracts/testdata/README.md`: one file per schema version, and an entity's latest version is in the highest-numbered file that has it. WP3 extends the two all-fixture C# checks to the v2 file | Switching the `weighIn` fixture to v2 would break every schema-1 loop |
| D8 | **No app production change** (beyond D4's constant).<br>• **The local row is already v2:** A14's `weigh_ins` row is exactly v2's field set, because the snake_case columns map 1:1. `weighInColumns` writes all of them except `preferred_for_day`, which the handler sets.<br>• **No app encoder needed now:** the outbox stores only `(entity, row_id, hlc, deleted)`, and payload encoding is A34's.<br>• **WP1 updates the tripwire** `apps/mobile/test/drift/user/weigh_in_migration_test.dart`. `_localOnly` becomes `{}`. The coverage check compares the v2 fixture with the latest schema version, and the v1 fixture must map to a **subset** of the columns. The failure message drops "B19".<br>• **WP2 adds app parity tests** that drive the real `profileOf`/`goalPhaseOf`/`targetSettingsOf`, `profileColumns`/`goalPhaseColumns`/`targetSettingsColumns` + `wireOfRow`, `weighInOf` and `weighInColumns`.<br>• **v1 `weighIn` app parity** is the existing tripwire test plus A34's upgrader. **WP1 adds the missing A34 Scope line** (A14 PA4 promised it, but the A34 card doesn't have it): "weighIn v1→v2 upgrader on pull (A14 D7); upload v2 only" | Card: "keep app changes minimal"; the remaining app work is A34's |
| D9 | **Corpus semantics.** Each payload: `{id, entity, schemaVersion, rowId?, rawPayload, deleted, rule?, asymmetry?, serverAccepts, appWire, appReads}`.<br>• **`serverAccepts`** is declared by the generator; C# asserts it.<br>• **`appWire`** (targets only; `null` for weighIn) is **computed** by the generator with the real `TargetRules.wire` on `jsonDecode(rawPayload)`.<br>• **`appReads`** is declared; the app tests assert it against the real decoders (a non-null record / no `WeighInMappingError`).<br>• **Invariant checked by the Dart drift test:** for targets, `serverAccepts == appWire` unless the case carries an `asymmetry` tag from a closed set:<br>  – `schemaOnly`: metadata fields, extra members, wrong-type `origin`;<br>  – `generic`: an unpaired surrogate, U+0000, a number below decimal range or with too many digits, duplicate keys;<br>  – `rowId`;<br>  – `wholeNumberInteger`: `1990.0` → the server accepts and raw `TargetRules.wire` rejects (the README's A34 decoding note).<br>• **Derived lists:** `serverRejectsAppTolerates` (`!serverAccepts && appReads`) and `serverAcceptsAppSkips` (`serverAccepts && !appReads`, e.g. `weighIn` `kg: 0` below A14's read bound) are generated and asserted on both sides | This makes "B19 admits `TargetRules.wire`, nothing more and nothing less" a failing test rather than a review claim. Same asymmetry vocabulary as B17/B18 |
| D10 | **HTTP test IDs and helpers.**<br>• **`PersonalFoodHttp`:** `Row` gains `int SchemaVersion = 1` and `Body` writes it; `NewRow` gains `Guid? id = null, int schemaVersion = 1`. B17/B18 call sites are unchanged.<br>• **Row IDs:** `BodyTargetsCases.NewId(entity)` returns `ProfileRowId` for `profile`, `Guid.CreateVersion7()` for `goalPhase`/`targetSettings` and `Guid.NewGuid()` for `weighIn`. Corpus cases with an explicit `rowId` (the R8 cases) keep it.<br>• **The shared profile ID:** every `profile` case shares one ID, so the batched matrix gives each case HLC counter = its index. Same-ID versions then strictly increase, absence checks use `(entity, id, hlc)`, and pull is compared with the **latest** accepted version per ID.<br>• **Shared helpers:** B18's private `PullAll`, `ByteBoundedCases`, `HistoryCount`, `AgeAndCleanup` and `Cleanup` move to a shared `backend/tests/Persistence.Tests/SyncHttpSupport.cs`. This is a mechanical move with no assertion change, and the B18 tests call it | Reuse over copy (B18 D12). The profile natural ID makes "same ID, other owner" the real-world RLS case |
| D11 | **Tombstone scrubbing (backlog #136).** The server admits full and scrubbed tombstones alike under the live rules and checks no scrubbing. **`weighIn`:** a scrubbed v2 tombstone (`kg: 0`, `inputValue: 0`, `note: null`, other fields kept) is admissible and pinned in the corpus. **Targets:** tombstones must stay wire-valid, so a scrub can't zero `heightCm`/`baseKcal`/`basisWeightKg` or break the expression fields. `contracts/README.md` states both; whether and when to scrub stays A34's (#136's owner becomes A34 at close) | Same split as B18: the convention belongs to the app and the server applies the same admission |
| D12 | **Docs.** **WP1:** `contracts/README.md` gets a "weighIn versions" paragraph and the targets section's "B19 adds…" becomes present tense, plus the tombstone note (D11), with a corpus pointer. `contracts/testdata/README.md` documents the v2 file and the corpus format. `05` §5.5 entity list adds `profile`, `goalPhase`, `targetSettings` (A13a) and `weighIn` v2 (B19), plus one sentence on targets admission. **WP5:** `backend/README.md` §Document sync gets a B19 paragraph | Keeps the payload authority readable |

**⚠️ OWNER items: none.** Everything is additive: a new schema version, a server validator for rules the README already lists, and tests. No spec change, no change to an Accepted TD (TD-080 is applied as written), no vendor, no security trade-off. **TD candidates: none**: the fail-closed dispatch (D2) is an implementation detail of TD-080.

### 3. Design

**3.1 Contract diff** (`contracts/openapi/sync-entities.json`, `weighIn` only):
```jsonc
"weighIn": {
  "1": { …unchanged… },
  "2": { "type": "object", "additionalProperties": false,
    "required": ["createdAtMs","origin","editedByUser","measuredAtUtc","localDate","kg","note",
                 "tzOffsetMin","inputValue","inputUnit","preferredForDay"],
    "properties": { /* the seven v1 properties, copied verbatim */
      "tzOffsetMin":     {"type": "integer", "minimum": -720, "maximum": 840},
      "inputValue":      {"type": "number",  "minimum": 0,    "maximum": 1000000000000.0},
      "inputUnit":       {"type": "string",  "enum": ["kg", "lb"]},
      "preferredForDay": {"type": "boolean"} } } }
```
The exporter accepts every keyword used (`tools/scripts/export-sync-schemas.py`). `make gen-sync-schemas` regenerates `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json`.

**3.2 Server** (UserData module only; no new cross-module call; Postgres stays the only state):
- `TargetsPayloadValidator.cs`: `Versions`, `Covers(string entity)`, `Matches(SyncVersion)`, `MaxPercent = 100m`, `ProfileRowId` (a `Guid` literal), and a private `Expected` table `expressionKind → (targetKg, targetDate, kgPerWeek, monthKg, month)` presence. The checks are linear over a fixed field set: no allocation per field, no regex, no I/O.
- `SyncPayloads.cs`: the one hook line (D2).
- Storage, `PushForSessionAsync`, the advisory lock, forced RLS, LWW/history, receipts, retention/compaction and `UserDataErasure` are untouched (entity- and version-agnostic, B05/B06).

**3.3 Corpus** (`contracts/testdata/sync/body-targets-validation-vectors.json`, synthetic only; generated by `packages/fb_domain/tool/generate_body_targets_vectors.dart`, which exposes `bodyTargetsVectors()` and a CLI writer; `make gen-body-targets-vectors`, manual):
- **Base cases:** `profile-base`, `goalPhase-base` (each kind), `targetSettings-base`, `weighIn1-base`, `weighIn2-base`. Built with fb_domain records (`ProfileRecord`, `GoalPhaseRecord`, `TargetSettingsRecord` `.toWire()`) and `WeighInDraft` getters. No app mapper is copied.
- **Per rule (tagged `rule`):**
  - R1: 0, `-0.0`, `1e-28` (accepted), the negative of each positive field, and a null `targetKg` where the kind allows it.
  - R2: every kind × every one of the five fields present/absent.
  - R3: `targetRate` with speed 0, negative and positive.
  - R4: maintain + weekly 0 / `-0.0` / 0.1 / monthly / targetDate.
  - R5: end = start, end < start, end null.
  - R6: each macro with both null / value only / flag only / percent 100 / 100.000001 / grams 5000 (accepted).
  - R7: all four `manual` × `acknowledged` combinations.
  - R8: profile with the natural ID / a v4 ID / `naturalId('profile','other')` / nil; goalPhase and settings with v7 / v4 / v5 / nil.
- **Plausibility outliers, all accepted (D3):** birth year → age 150, height 30 cm, target 600 kg, weekly 5 kg, monthly 20 kg, manual kcal 50, shift 5.0, macro grams 5000, fiber 900, a name with control characters, lose with a positive weekly rate.
- **Schema cases:**
  - every enum unknown or in another case;
  - `name` at 120/121 UTF-16 units, including a supplementary pair straddling the limit;
  - `note` at 4096/4097;
  - dates `2026-02-29`, `0000-01-01`, `9999-12-31`, Arabic-Indic digits, padded/short forms;
  - `revision` 0 / max / max+1 / `2.0`; `birthYear` `1990.0`.
- **Numbers:** quoted `"NaN"` / `"Infinity"`, raw `1e400` / `-1e400` (both sides reject), `1e-400` and a 31-significant-digit decimal (`generic` asymmetry).
- **Generic:** lone high and low surrogates in `name`/`note`, U+0000, a duplicate key (raw text kept).
- **weighIn v2:**
  - `tzOffsetMin` −720/840 accepted; −721/841/60.5/`"60"` rejected; `60.0` accepted (`wholeNumberInteger`);
  - `inputUnit` `kg`/`lb` accepted; `KG`/`st`/`""`/null rejected;
  - `inputValue` 0 (accepted, `serverAcceptsAppSkips`), `-0.1`, 1e12, 1e12+1;
  - `preferredForDay` `"true"`/null rejected;
  - each v2 field missing; a v1 payload sent as v2; a v2 payload sent as v1; the scrubbed tombstone (D11).
- **Tombstones:** a full-payload tombstone of each base and of each R-violation (same outcome).
- **Top-level blocks:** `version`, `constants`, `vocabularies`, `rules`, `payloads`, `serverRejectsAppTolerates`, `serverAcceptsAppSkips`, and `writerCases`. A writer case is `{id, entity, payloadId}`: the accepted payload that the app column writer must reproduce from the same record or draft.

**3.4 App parity** (test-only):
- `apps/mobile/test/features/targets/data/targets_sync_vectors_test.dart`. For each targets payload: content → row via `columnOfWireField` (booleans 0/1), with `rowId` or the default ID → real decoder → `appReads`. For every writer case: `*Columns(record)` → `wireOfRow` = the payload's content, with `_normalized` doubles as in `targets_contract_test.dart`. Also `profileRowId == constants.profileRowId`.
- `apps/mobile/test/features/body/data/weigh_in_sync_vectors_test.dart`. Every v2 payload → `WeighInRow` → `weighInOf` (reads, or throws `WeighInMappingError`) = `appReads`. Writer cases: `weighInColumns(draft)` + `preferred_for_day` default → camelCase = the payload content.

### 4. Work packages

| WP | By | Tasks · files | Done when |
|---|---|---|---|
| **WP1 · weighIn v2 contract** (own commit `feat(contract): weighIn v2 sync schema`) | `flutter-engineer` | • §3.1 in `contracts/openapi/sync-entities.json`<br>• `contracts/testdata/sync/entity-payloads-v2.json` (synthetic v2 fixture; `tzOffsetMin` 180, `inputUnit` `lb`)<br>• `make gen-sync-schemas` → `entities.json`<br>• D12 WP1 docs (`contracts/README.md`, `contracts/testdata/README.md`, `05` §5.5)<br>• tripwire update in `weigh_in_migration_test.dart` (D8)<br>• the A34 Scope line (D8)<br>• Progress-log line.<br>**Must not contain:** C# changes, the corpus, `fb_domain` changes | `make gen` leaves no diff beyond `entities.json`; `make gen-check`; `make check-sync-schemas`; focused `weigh_in_migration_test.dart` + `targets_contract_test.dart`; `make check-dart`; Docker-free `UserData.Tests` still green (registry change only); `git diff --check` |
| **WP2 · Corpus and Dart/app parity** | `flutter-engineer` | • `TargetWireRules.maxPercent` (D4) in `packages/fb_domain/lib/src/targets/target_rules.dart`<br>• `packages/fb_domain/tool/generate_body_targets_vectors.dart`<br>• `contracts/testdata/sync/body-targets-validation-vectors.json`<br>• `packages/fb_domain/test/targets/body_targets_vectors_test.dart` (byte equality + D9 invariant + derived lists)<br>• the two app tests (§3.4)<br>• `Makefile` `gen-body-targets-vectors` (manual, no `check`/CI dependency)<br>• `contracts/testdata/README.md` corpus format.<br>**Server cross-check:** every `serverAccepts` value is checked once against the real `SyncPayloads` with a throwaway C# test (not committed; WP3 makes it permanent), as in B18 WP2 | Focused fb_domain drift test and both app tests pass with counted cases; fb_domain coverage stays 100 % (`make test-dart` in CI); `make check-dart`; `git diff --check` |
| **WP3 · Semantic admission + pure tests** | `dotnet-engineer` | • `TargetsPayloadValidator.cs` + the hook in `SyncPayloads.cs` (D2/D3)<br>• `backend/tests/UserData.Tests/BodyTargetsCases.cs`: corpus cases + a schema-derived missing/null/wrong-type/extra matrix for the five entity/version pairs, compile-linkable, B18 `ChatProposalCases` pattern, with `schemaVersion`/`rowId`<br>• `BodyTargetsPayloadTests.cs`<br>• content links for the corpus, `entity-payloads-v2.json` and `contracts/README.md` in `FitnessBuddy.UserData.Tests.csproj`<br>• extend `All_current_entity_fixtures_still_pass_schema_admission` (and B18's all-fixture registry check if it loops versions) to the v2 file.<br>If a corpus declaration disagrees with the server, stop and report; don't widen the server or the corpus silently | Whole Docker-free `UserData.Tests` passes (B17/B18 suites unchanged); `make check-dotnet`; `make check-sync-schemas`; `git diff --check` |
| **WP4 · Persistence, erasure, privacy** | `dotnet-engineer` | • `backend/tests/Persistence.Tests/BodyTargetsSyncTests.cs`<br>• `SyncHttpSupport.cs` (moved B18 helpers) and the `PersonalFoodHttp` `SchemaVersion`/`id` parameters (D10)<br>• compile-link `BodyTargetsCases.cs` + the corpus + the v2 fixture in `FitnessBuddy.Persistence.Tests.csproj`<br>• the new privacy `[Fact]` in `IdentityPrivacyTests.cs` using `SinkCapture`.<br>Privileged migrator connections only for inventory and aging; production grants unchanged | `make check-dotnet`; `tools/scripts/heavy.sh` focused Testcontainers run of `BodyTargetsSyncTests`, the B18 tests touched by the helper move, `AccountDeletionTests` and the new privacy fact; `tools/scripts/heavy.sh make contract-conformance`; full `make test-dotnet` in CI; `git diff --check` |
| **WP5 · Reviews and close** | orchestrator; fresh `code-reviewer` + `security-reviewer` (writes `technical-planning/steps/evidence/B19-verification.md`); no `verifier` (not a milestone step, PROCESS A4 / TD-095); fixes by the WP's engineer | • Whole-diff reviews<br>• `backend/README.md` B19 paragraph<br>• backlog: #136's owner → A34, with the D11 note<br>• board row (size/status)<br>• Outcome | No open blocker or major; `make trace`; CI green on the merge commit via `tools/scripts/merge-step.sh B19 "Body & targets sync entities (server)" step/B19-body-targets-sync` (run in the background). No `[it]` needed (no Patrol or native change) |

### 5. Test list
Dart test names start with the spec ID or `B19`. C# tests use `[Trait("Req", …)]` or `[Trait("Rule", "B19.<slug>")]` / the existing `05.5-…`, `04.6-…`, `09.4-no-user-content` tags.

| Test (file) | Proves |
|---|---|
| `B19 generated vectors match committed bytes` (`body_targets_vectors_test.dart`) | corpus drift gate (TD-080) |
| `B19 untagged targets cases have serverAccepts equal to TargetRules.wire` (same) | D3/D9: the server admits exactly the wire rules, nothing more and nothing less |
| `TG-001 app-only plausibility outliers are wire-valid and server-accepted` (same) | D3, A13 D15 |
| `B19 asymmetry lists are exactly the derived cases` (same) | D9 |
| `TG-001 TG-012 TG-040 targets corpus payloads decode through the real mappers as declared` (`targets_sync_vectors_test.dart`) | app mapper parity, server→app |
| `TG-040 records written by the real column writers equal accepted corpus payloads` (same) | app→server |
| `B19 profileRowId equals the corpus profile id` (same) | R8 constant |
| `WB-003 weighIn v2 corpus payloads decode through weighInOf as declared` (`weigh_in_sync_vectors_test.dart`) | v2 server→app; read-bound skips listed |
| `WB-003 drafts written by weighInColumns equal accepted v2 payloads` (same) | v2 app→server |
| `the weighIn v1 fixture maps to weigh_ins columns and the v2 wire covers every local column` (`weigh_in_migration_test.dart`, renamed tripwire) | D8; v2 = the local row |
| `Embedded_schema_bounds_and_vocabularies_equal_contract_and_corpus` (`BodyTargetsPayloadTests`) | D4/D5 |
| `Validator_constants_equal_corpus` | D4 (`MaxPercent`, `ProfileRowId`) |
| `Readme_targets_rules_equal_corpus_rules_and_each_has_accept_and_reject_cases` | exit 1: "every wire rule in the README", single source |
| `Payload_matrix_matches_admission_for_live_and_tombstone` (Theory, every case) | exit 1/2: every wire and schema rule (unknown enum, extra/missing, over-long, type), live and tombstone, each against its own `schemaVersion` |
| `Wire_rules_accept_valid_and_reject_each_violation` (Theory over R1–R8) | exit 1, named per rule |
| `Numbers_reject_nan_infinity_overflow_and_unrepresentable` | exit 1: quoted NaN/Infinity, ±1e400, 1e-400, 31 digits; never a 500 |
| `App_only_plausibility_outliers_are_admitted` | D3 "nothing more" |
| `Cross_row_conflicts_are_not_validated` | TD-089: the validator takes no store; overlapping phases and same-date settings each admitted |
| `WeighIn_v1_and_v2_are_each_admitted_only_by_their_own_schema` | exit 2: tz bounds, unit enum, negative input value, missing v2 fields, v1↔v2 mismatch, version 3 → `unsupported`, v1 still accepted |
| `Targets_validator_fails_closed_for_unregistered_versions` | D2 |
| `All_current_entity_fixtures_still_pass_schema_admission` (extended) | D7 |
| `Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions` (`BodyTargetsSyncTests`) | exit 3, AC-010: authenticated push of every case in byte-bounded batches of ≤ 500 changes; ordered `invalidPayload`, no canary in the ack; invalid `(entity, id, hlc)` absent from documents/history/receipts; latest valid versions pulled exactly |
| `WeighIn_v1_and_v2_coexist_in_pull_history_and_lww` | D6, AC-012: v1→v2 on the same ID, history keeps `schemaVersion` 1, a newer v1 replaces v2, stale v1 kept in history, same HLC v1/v2 → `versionConflict`, mixed versions in one pull |
| `Cross_row_overlapping_phases_and_same_date_settings_are_admitted_and_pulled` | card Scope / TD-089 |
| `Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable` (Theory, 5 pairs) | AC-012, `05.5-version-identity` |
| `Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection` (Theory, 5 pairs; weighIn v2 uses the scrubbed tombstone) | AC-012, `05.5-retention`, D11 |
| `Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned` (Theory, 5 pairs; profile = the shared natural ID) | `04.6-rls`, exit 3 |
| `Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401` (Theory, 5 pairs) | `04.6-authz`, exit 3 |
| `Delete_account_erases_body_and_targets_live_history_fences_and_receipts_and_preserves_second_owner` | AC-031, exit 4: real `DELETE /v1/me`; per entity/version live + displaced + compacted fence + receipts; privileged zero-row inventory; second owner intact |
| `B19_body_and_targets_values_never_reach_errors_logs_or_telemetry` (`IdentityPrivacyTests`) | `09.4-no-user-content`, exit 3. **Canaries:** a phase name and an Arabic weigh-in note, plus distinctive numbers (`heightCm` 173.4567891, `kg` 81.2345671, `inputValue` 179.0987651, `baseKcal` 2345.678901, `targetKg` 71.8765431, protein 141.2345671). **Legs:** accepted, wire-invalid (R7 / R2), schema-invalid (extra field, unknown `inputUnit`), unreadable body with bare `NaN` (400), guest 403, Kestrel 413, injected 500. **Assertion:** no canary in any response except owner pull/history, nor in logs, scopes, spans, metrics, Sentry, audit or Postgres logs |

### 6. Exit-criteria mapping

| Exit criterion | Evidence |
|---|---|
| Validator tests: every README wire rule accepts a valid case and rejects each violation (incl. NaN/inf/overflow), equal to the corpus | WP3 `Readme_targets_rules…`, `Wire_rules…`, `Numbers…`, `Payload_matrix…`; WP2 Dart invariant + drift test; app parity tests |
| `weighIn` v2 valid/invalid (tz bounds, unit enum, negative input); v1 still accepted | WP1 contract; WP3 `WeighIn_v1_and_v2…`; WP4 `WeighIn_v1_and_v2_coexist…`; WP2 `WB-003` app tests |
| Persistence (Testcontainers): accepted push, invalid → `invalidPayload` without value in response/telemetry, pull, history, tombstone, RLS, guest 403 | WP4 matrix + Theories + privacy fact |
| Account deletion covers the four entities' documents, history and fences | WP4 `Delete_account_erases_body_and_targets…` (weighIn v1 and v2) |
| `make check-sync-schemas`, `make contract-conformance`, `make test-dotnet`; CI green | WP1/WP3/WP4 gates; exact-commit CI through `merge-step.sh`, recorded in the evidence file |
| Security review: no open blocker or major | WP5 `security-reviewer` + `B19-verification.md`; fresh `code-reviewer` |

### 7. Risks and unknowns

| Risk | Handling |
|---|---|
| **Dart/.NET parsing differences** (dates, digit forms, `-0.0`, tiny decimals) | Pinned as corpus cases. A real difference is either tagged `generic` (server stricter, listed for A34 #111) or reported to the orchestrator. The server is never relaxed and the corpus never edited to hide it |
| **Row-ID rule** rejects a future app path that mints non-v7 phase/settings IDs | A contract and README change first (TD-080). The app tests pin `profileRowId`; the ops already mint UUIDv7 |
| **Permanently rejected rows** (`generic` / `wholeNumberInteger` asymmetries, a scrub that breaks wire rules) | Listed in the corpus; A34 handoff (whole `num` → `int`, scrubbed targets tombstones stay wire-valid, #111 no endless retry) |
| **Shared profile ID** in the HTTP matrix (same ID, many versions) | D10: HLC counter per case, absence by `(entity, id, hlc)`, latest-version pull comparison |
| **Helper move** touches B18 tests | Mechanical move, same assertions; the B18 tests run in WP4's focused Testcontainers run |
| **Parallel lanes** (`Makefile`, `fb_domain`, `contracts/README.md`, `05`, board, backlog) | Rebase before the merge; board/backlog edits only in WP5; never touch other clones |
| **v1→v2 upgrader** not built here | Out of scope; WP1 writes it into A34's Scope (D8) |

### 8. Handoffs (written in WP1/WP5)
- **A34 Scope:**
  - `weighIn` v1→v2 upgrader on pull (A14 D7); upload v2 only.
  - Read whole `num` as `int` for integer fields.
  - Scrubbed targets tombstones must stay wire-valid; `weighIn` scrub per D11 (#136).
  - The corpus asymmetry lists name the rows the server rejects permanently (#111).

### 9. Architect plan review (2026-10-29): approved with changes, applied
These amend the sections above; where they differ, this section wins.
- **PA1 · R8 vs existing tests.** R8 makes the v4 IDs that existing tests mint for every fixture entity `invalidPayload` for `profile`/`goalPhase`/`targetSettings`: `PersonalFoodPayloadTests.All_current_entity_fixtures_still_pass_schema_admission`, `ChatProposalPayloadTests.Admit` (feeds `Ill_formed_utf16_is_rejected_for_every_entity`), the `Utf16Cases` coverage check, and `ProductionSyncTests.Row` (`Every_current_entity_round_trips…`). **Fix:** one compile-linked test helper `SyncTestIds.For(entity)` (the `ProfileRowId` literal for `profile`, `Guid.CreateVersion7()` otherwise), used at those sites and by `BodyTargetsCases.NewId` (weighIn may use it too). WP3 owns the `UserData.Tests` sites, WP4 the `Persistence.Tests` sites. WP3/WP4 Done-when: **only the ID minting changes in B17/B18/production-sync tests; no assertion weakened.**
- **PA2 · No verifier** (WP5 amended above).
- **PA3 · R8's exact C# meaning:** `id.Version == 7 && (id.Variant & 0xC) == 0x8` (.NET 10 `Guid.Variant` = high nibble of byte 8, matching Dart `isUuidV7`'s `[89ab]`). Corpus adds v7-nibble IDs with a non-RFC variant (`…-7xxx-cxxx-…`, `…-7xxx-0xxx-…`), rejected on both sides. `contracts/testdata/README.md` notes: the server binds IDs as `Guid`, so case is invisible; an uppercase v7 ID is accepted and pulled back lowercase (not a poison row; tag it `rowId` if the app side differs).
- **PA4 · Rule labels.** Each corpus case's `rule` is the **README bullet label** (R3 lives under `Expression fields`; R1 `Positive numbers`, R2/R3 `Expression fields`, R4 `Maintain`, R5 `Phase dates`, R6 `Macro pairs`, R7 `Acknowledgement`, R8 `Row IDs`). The C# README parser in `Readme_targets_rules_equal…` reads only the wire-rule bullets and skips the "Not wire rules" bullet.
- **PA5 · Double-vs-decimal precision.** Dart reads `100.0000000000000001` as `100.0` (accepted percent) while the C# decimal compare rejects it; likewise `heightCm` `1000000.0000000001` at the schema maximum. Add these cases with a new closed-set tag `decimalPrecision`; they land in `serverRejectsAppTolerates` (A34 #111 handoff).
- **Adopted suggestions:** **S1** the B19 privacy fact keeps only the entity-dependent legs (accepted, wire-invalid, schema-invalid, guest 403); the 401/403 test runs one entity per path, not five pairs. **S2** `Embedded_schema_bounds…` asserts weighIn v2 = v1's properties (identical sub-schemas, same order) + exactly the four new fields. **S3** a pure test pins the registry's `personalFood` versions = `{1}` (B17's dispatch fails open); no production change to B17. **S4** move only the B18 helpers B19 uses into `SyncHttpSupport.cs`; keep the `PersonalFoodHttp` name. **S5** §3.3 R1: `0` and `-0.0` are **rejected** for positive fields; `1e-28` is accepted.
- **Fail-closed dispatch:** no TD; one sentence in `contracts/README.md` (targets section) and `05` §5.5 states that entity semantic validators dispatch by entity and fail closed for an unknown schema version.

## Progress log
- 2026-10-28 · Outline card created from the A13 plan review (PA12); board rows added.
- 2026-10-29 · Orient (lane 3): deps on main, branch `step/B19-body-targets-sync`; nightly android-it red (1 app Patrol test, not this lane). Phase B planning started.
- 2026-10-29 · Low-level plan written (step-planner): D1–D12, WP1–WP5, size M, no owner items or TD candidates. Awaiting the architect plan review.
- 2026-10-29 · Low-level plan drafted by step-planner (5 WPs, M, no owner items); architect plan review running. Orchestrator: no verifier (not a milestone, TD-095).
- 2026-10-29 · Architect: approve with changes PA1–PA5 (+S1–S5), applied in §9; plan self-approved (no owner item). Phase C: flutter-engineer WP1–WP2.
- 2026-10-29 · WP1 (flutter-engineer): `weighIn` v2 in the contract + `entity-payloads-v2.json`, regenerated `entities.json`, docs (`contracts/README.md`, `testdata/README.md`, `05` §5.5), A14 tripwire updated (`_localOnly` empty), A34 B19 handoff. `make gen` no other diff; `check-sync-schemas`, `check-dart`, focused tripwire + targets contract tests, Docker-free UserData.Tests 1013/1013 green.
- 2026-10-29 · WP2 (flutter-engineer): `TargetWireRules.maxPercent`, generator + 389-payload corpus (`body-targets-validation-vectors.json`, 12 writer cases, 49 server-rejects/app-tolerates, 4 server-accepts/app-skips), fb_domain drift/invariant test (7), app parity tests (targets 3, weighIn 3), `make gen-body-targets-vectors`, corpus format in `testdata/README.md`. Throwaway C# cross-check vs `SyncPayloads`: 389 cases × live/tombstone, 0 mismatches (weighIn exact; targets schema stage). PA5 heightCm literal changed to `1000000.00000000001` (Dart reads `…0001` as above 1e6).
- 2026-10-29 · WP3 (dotnet-engineer): `TargetsPayloadValidator` (R1–R8, PA3 v7 check, fail-closed by entity) + the one `SyncPayloads` hook; `BodyTargetsCases`/`BodyTargetsPayloadTests` (corpus 389 × live/tombstone, schema matrix for 5 pairs, README rules, constants, registry/S3, S2, wire-rule theory R1–R8, numbers, plausibility, cross-row, weighIn v1/v2, fail-closed); `SyncTestIds.For` at the PA1 UserData sites (ID minting only); all-fixture check extended to the v2 file. No corpus/server disagreement. Docker-free UserData.Tests 1797/1797; mutation (hook removed) → 152 failures; `check-dotnet`, `check-sync-schemas`, `git diff --check` green.
- 2026-10-29 · WP4 (dotnet-engineer): `BodyTargetsSyncTests` (20: batched matrix, weighIn v1/v2 coexistence, cross-row, LWW/tombstones/RLS × 5 pairs, guest 403/401 one request per path (S1), erasure via `DELETE /v1/me` incl. weighIn v1+v2); B18 helpers moved to `SyncHttpSupport` (S4); `PersonalFoodHttp` `SchemaVersion`/`id` (D10); `SyncTestIds` at `ProductionSyncTests.Row` (PA1); B19 privacy fact (S1 legs); `backend/README.md` B19 paragraph (D12, moved from WP5). Focused Testcontainers run (BodyTargets, ChatProposal, ProductionSync, AccountDeletion, IdentityPrivacy, PersonalFoodSync) 63/63; `check-dotnet`, `contract-conformance`, `git diff --check` green.
- 2026-10-29 · Phase D: fresh code-reviewer + security-reviewer on the whole diff (main..branch).
- 2026-10-29 · Reviews: code + security approve (0 blocker/major); fixes `bff1fe8`, `bb7d134`; CI green on `1e36fa3`. Outcome written; merging via merge-step.sh.

## Outcome
_Closed 2026-10-29 (lane 3; self-approved and self-merged under TD-037: no owner item)._

**Built**
- **Contract:** `weighIn` v2 in `contracts/openapi/sync-entities.json`, additive (v1 byte-identical; v2 = v1's seven properties + `tzOffsetMin` −720…840, `inputValue` 0…1e12, `inputUnit` kg|lb, `preferredForDay`), fixture `contracts/testdata/sync/entity-payloads-v2.json`, regenerated embedded `entities.json`. No OpenAPI path or generated-client change. Docs: `contracts/README.md` (targets section present tense, fail-closed dispatch sentence, tombstone note, "weighIn versions"), `contracts/testdata/README.md`, `05` §5.5, `backend/README.md`.
- **Server:** `TargetsPayloadValidator` (UserData/Infrastructure) = exactly the README "Targets semantic rules" R1–R8 incl. the row-ID rule (UUIDv7 with RFC variant; profile = `naturalId('profile','self')`), dispatch by entity and **fail closed** by schema version; one hook line in `SyncPayloads.InvalidReason`; the admission catch filter also maps `KeyNotFoundException`. Storage, LWW/history, retention/fences, RLS and erasure unchanged (entity-agnostic).
- **Shared corpus:** `contracts/testdata/sync/body-targets-validation-vectors.json` (389 cases, Dart-generated by `packages/fb_domain/tool/generate_body_targets_vectors.dart`, `make gen-body-targets-vectors`), byte-drift + `serverAccepts == TargetRules.wire` invariant with a closed asymmetry-tag set (`schemaOnly`, `generic`, `rowId`, `wholeNumberInteger`, `decimalPrecision`), each tag now pinned by construction (`rowId` cases admitted under a default ID; `schemaOnly` cases differ from an accepted base only in metadata/extra/missing-nullable members). App parity through the real A13a/A14 decoders and column writers. C# asserts all 389 live and as tombstones.
- **Tests:** `BodyTargetsPayloadTests` (784 cases), `BodyTargetsSyncTests` (20: batched matrix, v1/v2 coexistence, cross-row admitted, LWW, tombstones/fences, RLS with the shared profile ID, guest 403/401, account deletion for all four entities incl. weighIn v1 and v2), B19 privacy canary fact (5 invalid legs incl. profile), shared `SyncTestIds`/`SyncHttpSupport` helpers (B17/B18 tests: ID minting only, no assertion changed). Dart: 8 fb_domain + 6 app tests; A14 tripwire updated.

**Deviations:** builders split at the specialty seam (flutter-engineer WP1–2, dotnet-engineer WP3–4; TD-095 allows); `backend/README.md` paragraph done in WP4; no verifier (not a milestone, TD-095); privacy fact trimmed to entity-dependent legs (architect S1); `schemaOnly` also covers missing nullable members (as the generator/README define it, wider than D9's wording); PA5 literal `1000000.00000000001` (Dart rounds it onto the max); weighIn v1 `appReads` null until A34's upgrader. Local test runs stopped mid-Phase D by the owner's no-local-tests rule; CI is the test evidence.

**Follow-ups:** A34 handoff block (v1→v2 upgrader, upload v2 only, num→int, tombstone scrubbing #136, asymmetry lists #111); backlog #136 → A34; #133 privacy policy now names body/target data (security finding 2). A newer v1 from an old client can replace a v2 by LWW (documented D6; recoverable from history).

**New TDs:** none (fail-closed dispatch documented in `contracts/README.md` and `05` §5.5).

**Metrics:** planned M, actual M (4 build WPs + close; 2 builders). Plan review: architect approve-with-changes (PA1–PA5, S1–S5). Code review 1 round: 0 blocker, 0 major, 1 minor (fixed), 2 nits (1 fixed, 1 noted). Security review: 0 blocker, 0 major, 2 minor (1 fixed, 1 → backlog #133/#136), 2 nits (1 fixed, 1 documented). Evidence: `evidence/B19-verification.md`; CI green on `1e36fa3` (all jobs; android-it skipped, no Patrol/native change), merge-commit CI via `merge-step.sh`.
