# B21 — Workout sync entities (server)

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| Backend | B05 ✅, B20 ✅, **A36** ✅, **A37a** ✅ (D12: merged first) | M–L | Claude | ✅ Closed, awaiting merge |

_New step (owner, 2026-10-30; backlog #189, A36 D6). Phase 1, wave 2 (TD-105). Tier: Risky (user-data admission). **A34 depends on B21.**_

**Goal.** The server admits, stores, serves and erases the workout entities, so A34 can upload workouts instead of leaving them queued.

**Spec:** WO-003, WO-010, WO-020, WO-021 (data that syncs), AC-010, AC-012, AC-031 · **Decisions:** TD-031, TD-080

## Scope
- Contract first: add `customExercise`, `workoutSession`, `sessionExercise`, `workoutSet`, `workoutTemplate`, `workoutTemplateItem`, `weeklyPlanDay` to the sync registry, matching A36's tables (A36 D6, D7) and any muscle fields A37a adds.
- Server admission: schema plus the wire rules the app applies on write (per-type set fields, ownership inside an aggregate).
- Storage, pull/history, account deletion coverage, Testcontainers tests, a Dart-generated corpus with app parity (like B19/B20).

## Out of scope
- The app upload (A34). Workout chat (B12).

## Exit criteria
- [ ] Contract conformance green; the Dart client regenerated.
- [ ] Admission tests reject rule-breaking rows; deletion erases every workout row.
- [ ] Security review recorded (Risky).

## Read first
A36 card (D6, D7) · B20 card (same pattern) · `contracts/README.md` · backlog #189

## Owner involvement
None.

## A37a handoff (2026-10-30, A37a low-level plan D6, §9)
- `customExercise` gains **`primaryMuscle`** (string or null; one of the 15 codes `chest`, `shoulders`, `biceps`, `triceps`, `forearms`, `traps`, `upper_back`, `lower_back`, `abs`, `obliques`, `quadriceps`, `hamstrings`, `glutes`, `calves`, `adductors`) and **`secondaryMuscles`** (array of at most 4 distinct codes from the same list, never containing `primaryMuscle`; empty allowed).
- App columns (schema v11, A37a): `custom_exercises.primary_muscle` (nullable) and `custom_exercises.secondary_muscles_json` (JSON array, default `[]`).
- Server admission rejects codes outside the list (the app never writes others). `primaryMuscle` stays nullable (custom rows created before v11 have none).
- A37a D25: a session's removed children (session exercises, sets) can be **revived with the same ID**; they arrive as ordinary updates with `deleted` false, so admission must accept an update that clears a tombstone of the same aggregate.

---

## Low-level plan
_Step-planner (Claude, 2026-10-30), lane 4 (`~/work/fitness_buddy_4`, branch `step/B21-workout-sync` from `origin/main` 54daffa). Checked against the code on main: `SyncPayloads.InvalidReason`, `MeasurementPayloadValidator`, `TargetsPayloadValidator`, `PostgresSyncStore.ApplyAsync`, `SyncRetention`, `UserDataErasure`, `SemanticValidatorTests`, the generic UTF-16 and fixture tests, `SyncTestIds`, `export-sync-schemas.py`, and A36's tables. Also checked against **A37a's unmerged branch** (`~/work/fitness_buddy_5`, `step/A37a-workouts`, ef761ae): `workout_tables.dart` (schema v11), `workout_columns.dart`, `workout_op_handler.dart` (D25), `workout_repository.dart`, and fb_domain's `muscle.dart`, `workout_set.dart`, `workout_drafts.dart`. **Reviews (TD-106): Codex only, read-only.** One Codex plan review, then the orchestrator self-approves (TD-037, no owner item). Code review = two parallel Codex tasks (code/architecture + security/data integrity). **No local test runs** (owner rule, 2026-10-30): locally only codegen, `make check-dart`, `make check-dotnet` / `dotnet build`, `make check-sync-schemas`, `git diff --check`. Commits stay local; `merge-step.sh` carries the branch, and its CI run is the evidence (TD-108)._

**Tier: Risky** (user-data admission, untrusted input, account erasure). **Size: M–L** (about 2.3 sessions; §10). Four build WPs plus the close, one commit each, **one merge**, no early contract merge (D12). **Starts only after A37a is on `main`** (D12): the corpus, the tripwire and the parity tests need A37a's schema v11 columns and fb_domain `Muscle`. Expected changes:
- one contract commit: seven entity schemas in `contracts/openapi/sync-entities.json`, seven fixtures, the regenerated embedded `entities.json` and the README rule list. **No OpenAPI path and no generated-client change** (`make gen` leaves no diff);
- one production C# validator plus one hook line;
- one small `fb_domain` class (`WorkoutWireRules`). `checkExerciseId` delegates to it, with no behaviour change. **No app production change**;
- no migration, no new dependency, no paid call.

### 1. Summary
After B21 the server admits, stores, serves and erases the seven workout entities at schema version 1, matching A36's tables plus A37a's muscle columns: `customExercise`, `workoutSession`, `sessionExercise`, `workoutSet`, `workoutTemplate`, `workoutTemplateItem`, `weeklyPlanDay`.

Admission is the schema plus a fail-closed `WorkoutPayloadValidator` that checks **exactly five row-local wire rules, W1–W5**:
- muscles;
- the aliases shape;
- the set shape;
- the exercise reference format;
- the plan-day natural ID.

Aggregate ownership and per-type set values stay app-side, because they're cross-row (D4). A37a's revived children (D25, R14) are ordinary newer last-write-wins versions, and the generic engine already accepts them. B21 proves this, including after compaction (D5).

A Dart-generated corpus `contracts/testdata/sync/workout-validation-vectors.json` pins three sides:
- `fb_domain`;
- the app's real column writers, `WorkoutRepository` reads and local CHECKs (so the server never accepts a row the phone can't store);
- the C# validator.

Testcontainers tests prove push/pull, LWW with history, tombstones, revival, RLS, guest 403, any-order arrival, erasure and a privacy canary. **No deploy hold is needed** (D12).

### 2. Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **In scope: all seven A36 entities at v1.** The A36 tables are on main (schema v8). A37a v11 adds `custom_exercises.primary_muscle` and `secondary_muscles_json`. **A37c adds no columns:** it reuses the A36 template and plan tables (A37 §3, §8, verified on the A37a branch). So templates, items and plan days sync now. A later column means a new schema version, server first (TD-080). **Card corrections (orchestrator level, not owner items):**<br>• "Depends on" gains **A37a** (merged; D12).<br>• "per-type set fields, ownership inside an aggregate": the parts that need other rows can't be wire rules, so only their row-local form is admitted (D4).<br>• Security review = the Codex security task (TD-106) | Card scope; A37 card §3/§8 |
| D2 | **Payload = the table's content columns in camelCase, plus `createdAtMs`, `origin`, `editedByUser`** (`05` §5.5; the A15b tripwire pattern: every content column on the wire, nothing else).<br>**The muscle list travels as `secondaryMusclesJson`, a string holding a JSON array**, not as a JSON array member `secondaryMuscles`. This supersedes the A37a handoff's wording:<br>• `05` §5.5 says "JSON-valued local text columns remain their explicit `...Json` strings";<br>• no registry entity has an array member today;<br>• the 1:1 column tripwire and A34's generic row→payload mapping keep working without an entity-specific encoder.<br>The rules (codes, ≤ 4, distinct, ≠ primary) are unchanged and become W1. `aliasesJson` follows the same convention. Field shapes are in §3.1 | Convention over a one-off shape; the content is identical |
| D3 | **Validator seam = B19/B20's.** `internal static class WorkoutPayloadValidator` in `backend/src/Modules/UserData/Infrastructure/`:<br>• `Versions = {1}`;<br>• `Covers(entity)` for the seven names;<br>• `Matches(SyncVersion)` switching by entity; it fails closed for a version outside `Versions`.<br>**Hook:** one line in `SyncPayloads.InvalidReason` after the measurement line.<br>**Entities without rules** (`workoutSession`, `workoutTemplate`) are covered with an empty rule set, so a future v2 can't skip review.<br>The validator returns a bool only and the caller returns the bare `invalidPayload`. No store access, no I/O, no regex: hand-written character loops and `Guid.TryParseExact` | TD-080; B20 D2/D10 |
| D4 | **The rule set is exactly W1–W5**, listed once in `contracts/README.md` § "Workout semantic rules" (written in WP1, contract-first). Each is row-local and is applied by the app on every write:<br>• **W1 muscles** (`customExercise`): `secondaryMusclesJson` decodes to a JSON array of at most 4 strings. Each string is one of the 15 A37a D2 codes, compared after JSON unescaping, exact and case-sensitive. The strings are distinct, and none equals `primaryMuscle` when that is non-null. An empty array is valid. `primaryMuscle` itself is a nullable schema enum of the same 15 codes; the legacy `back`, `core` and `full_body` are rejected.<br>• **W2 aliases shape** (`customExercise`): `aliasesJson` decodes to a JSON array of at most 10 strings (`WorkoutLimits.aliasesMax`).<br>• **W3 set shape** (`workoutSet`, the row-local form of WO-004: a set fits *some* exercise type). (a) Exactly one of `reps` and `durationSeconds` is non-null. (b) A non-null `kg` needs a non-null `reps`, and a non-null `distanceMeters` needs a non-null `durationSeconds`. (c) `kg`, `inputValue` and `inputUnit` are all null or all non-null (TD-017, `setColumns`). Rule (c) also protects the app read: `LoggedSet` throws on a typed value without `kg`, which would hide the whole session.<br>• **W4 exercise reference** (`sessionExercise`, `workoutTemplateItem`): `exerciseId` is a catalog ID (`ex:` then 1–60 of `[a-z0-9_]`) or a lowercase canonical UUID (`checkExerciseId`).<br>• **W5 plan-day row ID** (`weeklyPlanDay`): the row ID equals `naturalId('weeklyPlanDay', '<weekday>')` (UUIDv5, TD-070). Without it, two live rows for one weekday would break the phone's unique partial index `ux_weekly_plan_days_weekday`, a poison row on pull.<br>**Not wire rules (admitted, app-side or cross-row):**<br>• child ownership: a child's parent existing, being live, being in "this" aggregate or belonging to this user;<br>• child-ID uniqueness across an aggregate; positions being dense or unique; exercises ≤ 30 per aggregate and sets ≤ 40 per exercise;<br>• the exact per-type check `SetValues.issueFor(type)`, which needs the exercise's type from another row or the catalog;<br>• write bounds: reps 1–1000, kg ≤ 1000, duration 1–86400 s, distance ≤ 1e6 m, `durationMinutes` 1–1440, target sets 1–20;<br>• name and alias trimming and 1–80 code points; `exerciseId` or `templateId` pointing at something unknown or dead;<br>• `localDate` not after today (WO-011); the row-ID version for the other entities.<br>The server never reads other rows (B20 D2/D9, TD-089 style). Rows arrive independently, in any order and across batches, and the app's read projection already tolerates orphans | The card's "ownership inside an aggregate" can't be checked without cross-row reads and would break any-order sync and R14. Row-local rules are cheap, and each one prevents an app-read failure or a poison row |
| D5 | **Child tombstones and R14 revival: no special server path.** A tombstone is an ordinary version (`05` §5.2), and `ApplyAsync` replaces it with any strictly newer HLC (`deletedAt` null, `compacted=false`). That holds even after 30-day compaction: the fence keeps the tombstone's HLC, so an older offline version is `stale` and a newer one restores the row (B05; `Tombstones_…_fence_prevents_resurrection` already shows this for other entities).<br>So A37a D25's revival (same ID, newer HLC from the row writer, full valid payload, `deletedAt` null) **is accepted as is**. The R14 fallback ("revive only before upload") is **not needed**.<br>Because the server has no aggregate concept, it also accepts a "revival" under a different parent. That is pinned as intended behaviour: the handler owns aggregate integrity on writes, and the read projection on pulls.<br>**A34 notes:** push the row's current content at its current HLC; never re-stamp a revival older than the tombstone (TD-049). Tombstones carry full payloads under W1–W5 | R14, A37a D25; B05 retention semantics |
| D6 | **Vocabularies and constants: one source, pinned three ways.** The contract schema is the source of enums and bounds; the README of the rule labels; `fb_domain` of the corpus.<br>**New in `fb_domain`** (`src/workouts/workout_wire_rules.dart`, exported): `abstract final class WorkoutWireRules` with:<br>• `musclesHold(String? primary, Object? decodedSecondaries)` (W1);<br>• `aliasesHold(Object? decoded)` (W2);<br>• `setShapeHolds({int? reps, double? kg, double? inputValue, String? inputUnit, int? durationSeconds, double? distanceMeters})` (W3);<br>• `isExerciseRef(String)` (W4; `checkExerciseId` now calls it);<br>• `planDayIds` (7 UUIDv5 literals by ISO weekday; the app test pins them to `planDayId`) and `planDayIdHolds(String id, int weekday)` (W5).<br>Limits come from `Muscle.secondariesMax` and `WorkoutLimits.aliasesMax`.<br>**Corpus `vocabularies`:** `exerciseType`, `equipment`, `muscle`, `inputUnit` (enum codes in enum order). **`constants`:** `maxSecondaries`, `maxAliases`, `maxCatalogIdLength` (60), `maxNameLength`, `maxNumber`, `maxInteger`, `maxOriginLength`, `planDayIds`. **`rules`:** `{id, readme}` for W1–W5.<br>**C# pins (WP3):** embedded registry = contract = corpus (enums in order, bounds, `maxLength`, `additionalProperties: false`, all required); validator constants = corpus constants; README W bullets = corpus `rules`, each with at least one accepted and one rejected case | TD-080; B20 D4. A new muscle code or exercise type fails the pins until both sides move (TD-080: new schema version, server first) |
| D7 | **Corpus semantics (B20 D6, extended).** Each payload: `{id, entity, schemaVersion: 1, rowId?, rawPayload, deleted, rule?, asymmetry?, serverAccepts, appWire, appReads}`.<br>• `serverAccepts` is declared; C# asserts it live and as a tombstone.<br>• `appWire` is computed from `WorkoutWireRules` on the decoded content (and `rowId` for W5). It is `true` for entities without rules when the content decodes to the declared types.<br>• `appReads` is declared; the app test asserts it through the real repository (D9).<br>**Invariant (Dart):** `serverAccepts == appWire` unless the case carries a tag from the closed set:<br>• `schemaOnly`: metadata, extra or missing members, bounds, formats, lengths, enums the W rules don't read;<br>• `generic`: lone surrogate, U+0000, duplicate key, unrepresentable number;<br>• `wholeNumberInteger`: `6.0` for `weekday`/`reps`, which the server accepts.<br>The builder drops unused tags (B20 precedent).<br>**New, second invariant (app):** every `serverAccepts` row **inserts into the real drift table**, so local CHECKs are never stricter than the wire (A36's table comment). This guards against a poison row on pull.<br>**Derived lists**, generated and asserted on both sides: `serverRejectsAppTolerates` and `serverAcceptsAppSkips` (for example a blank alias, `durationMinutes` 0 or a name above 80 code points: the app hides the row and A34 keeps it) | "Exactly W1–W5" becomes a failing test, and "storable on the phone" becomes one too |
| D8 | **Corpus content:** synthetic only, about 230 cases. `packages/fb_domain/tool/generate_workout_vectors.dart` exposes `workoutVectors()` plus a CLI writer; `make gen-workout-vectors` (manual). Full list in §3.2. **No shared generator helper is extracted.** There would be five generators, but each one's bases differ. Extraction stays a backlog idea (logged at close) rather than B21 scope | Proportionate; avoids refactoring three merged generators inside a Risky step |
| D9 | **App parity without app production changes.** One test, `apps/mobile/test/features/workouts/data/workout_sync_vectors_test.dart`, over an in-memory `AppDatabase`.<br>**Server → app:** each payload's content → snake_case row with fixed sync columns → `INSERT` into the real table (a CHECK or type error = not stored). For child entities it first inserts fixed live parents: the base session, the base session exercise, the base template. It then reads through the **real `WorkoutRepository`**, and the result must equal `appReads`:<br>• `watchCustomExercises().first`;<br>• `session(id)`, the child appearing inside it;<br>• `watchTemplates().first`;<br>• `plan()`.<br>**App → server:** writer cases compare the content written by the real `customExerciseColumns`, `sessionColumns`, `sessionExerciseColumns`, `setColumns`, `templateColumns` and `templateItemColumns` (plus `planDayId` with `weekday`/`templateId` for plan days) with the accepted payloads. Doubles are normalized as in B19/B20.<br>**Tripwire:** `apps/mobile/test/drift/user/workout_contract_test.dart` checks that the seven fixtures map 1:1 to the table columns, both ways, and that every content column is on the wire (A15b pattern) | The repository is the read path users see; going through it avoids exposing private mappers |
| D10 | **Tombstone scrubbing (backlog #136, owner A34).** The server checks no scrubbing; full and scrubbed tombstones get the live rules.<br>• A scrubbed `customExercise` (`name` `""`, `aliasesJson` `"[]"`, `secondaryMusclesJson` `"[]"`, `primaryMuscle` null) is admissible, as are scrubbed session and template names (`null` / `""`).<br>• A scrubbed `workoutSet` may zero its numbers but must keep W3's null pattern.<br>Pinned in the corpus and stated in the README (WP1) | B19 D11 / B20 D8 split |
| D11 | **RLS, erasure, privacy: generic, proven.**<br>• Forced RLS and per-user documents are unchanged (`04` §6). The plan-day natural IDs are the same for every user, so the "same ID, independently owned" RLS theory covers them, as with `profile`.<br>• `UserDataErasure` deletes by `user_id` and is entity-agnostic; WP4 proves it per entity: live, displaced, compacted fence, receipts, second owner intact.<br>• Privacy canaries: exercise, alias, session and template names (ASCII and Arabic), plus distinctive set numbers. Invalid responses are bare `invalidPayload`; nothing appears in logs, metrics, spans, Sentry, audit or Postgres logs (`09` §4) | Workout data is user content; the B17–B20 canary pattern |
| D12 | **No deploy hold; A37a first.**<br>• **Hold:** B20 needed one because A15b's registry landed before the validator. B21 ships the registry (WP1) and the validator (WP3) **in one merge**, so no build ever admits workouts by schema only. **Condition:** no contract-only early merge (no lane waits: A34 is wave 4). If one is ever requested, apply B20 §8 (hold row in the backlog; release check after the validator merges).<br>• **Merge order:** A37a merges first. B21's corpus, tripwire and parity tests compile only against A37a's v11 columns and fb_domain `Muscle`, so implementation starts from a `main` that contains A37a. Re-read the merged column names in WP1, and stop if they differ from §3.1. The A37a branch also edits this card (handoff section plus a Progress-log line). The handoff is copied here verbatim, so the rebase conflicts only in the Progress log: keep both lines.<br>• **Phone server:** may update to main after B21 like after any merge; nothing uploads workouts before A34 | One merge = no window with weaker admission |
| D13 | **Test helpers and generic-test touches (WP3/WP4):**<br>• `WorkoutCases.cs` in `backend/tests/UserData.Tests/`: corpus reader, `Baseline(entity)`, `Raw(id)`, a schema-derived missing/null/wrong-type/extra matrix for all seven. It is compile-linked into `Persistence.Tests`.<br>• `SyncTestIds.For("weeklyPlanDay")` returns the fixture weekday's natural ID, pinned to the corpus (as `ProfileRowId`).<br>• `ChatProposalPayloadTests.Utf16Cases` skips `customExercise.secondaryMusclesJson`, `customExercise.aliasesJson` and `exerciseId`: their generic control values break W1/W2/W4, as `personalFood`'s did. The workout corpus covers lone surrogates in those fields instead.<br>• Content links for the corpus and README in both test csproj files | Generic tests keep covering every entity without weakening W rules |
| D14 | **Docs:**<br>• `contracts/README.md` § "Workout semantic rules" (WP1: rules, not-rules, tombstones, revival; WP4: present tense and corpus pointer);<br>• `contracts/testdata/README.md` (corpus format, WP2);<br>• `05` §2.2 (`customExercise` naming, muscles) and §5.5 (entity list plus a B21 bullet);<br>• `backend/README.md` § Document sync (B21 paragraph);<br>• A34 handoff lines (§9) | Single source; A34 knows what's admitted |
| D15 | **Builders (TD-095, specialty seam as in B19):**<br>• `dotnet-engineer` (Opus): WP1 contract, then WP3–WP4;<br>• `flutter-engineer` (Opus): WP2 (fb_domain class, generator, corpus, tripwire, parity).<br>The orchestrator may give all four WPs to one Opus builder, as B20 did | Brief |

**⚠️ OWNER items: none.** Everything is additive:
- new sync entities with a fail-closed validator;
- one small `fb_domain` class;
- tests.

There's no spec change, no Accepted-TD change (TD-031 and TD-080 applied as written), no vendor or cost, and no security trade-off. Accepting cross-row inconsistency within one user's own data is the established TD-089/B20 D9 rule, not a new trade-off.

**TD candidate (recommend: record as Proposed at B21's close, like TD-103):** "**Workout sync model.** The seven A36 entities are row documents. Aggregate integrity (ownership, unique child IDs, per-type set values) is app-side (handler on write, tolerant repository on read). The wire admits the row-local rules W1–W5. A revived child is a newer LWW version. The muscle vocabulary (A37a D2) is a closed wire enum, server first." It folds in A37a D2's cross-track TD candidate if A37a's close didn't record it.

### 3. Design

**3.1 Contract** (`contracts/openapi/sync-entities.json`; WP1). Every schema has `type: object`, `additionalProperties: false` and all properties required. Each starts with the shared metadata `createdAtMs` (integer 0…2^53−1), `origin` (string ≤ 128) and `editedByUser` (boolean). Only the exporter's keywords are used (`export-sync-schemas.py`). "int" means integer 0…2^53−1 and "num" means number 0…1e12 (the wire maximum, `05` §1) unless stated otherwise.

| Entity | Content fields (column) |
|---|---|
| `customExercise` | `name` string ≤ 160 · `aliasesJson` string ≤ 16384 · `exerciseType` enum (`weight_reps`, `bodyweight_reps`, `assisted`, `reps_only`, `duration`, `distance_duration`) · `equipment` enum (`barbell`, `dumbbell`, `cable`, `machine`, `kettlebell`, `bodyweight`, `other`) · `primaryMuscle` [string, null] enum of the 15 D2 codes · `secondaryMusclesJson` string ≤ 256 |
| `workoutSession` | `localDate` string `date` ≤ 10 · `name` [string, null] ≤ 160 · `startMinute` [integer, null] 0…1439 · `durationMinutes` [integer, null] int · `templateId` [string, null] `uuid` ≤ 36 |
| `sessionExercise` | `sessionId` `uuid` · `exerciseId` string ≤ 64 · `position` int |
| `workoutSet` | `sessionExerciseId` `uuid` · `position` int · `reps` [integer, null] int · `kg` [number, null] num · `inputValue` [number, null] num · `inputUnit` [string, null] enum `kg`, `lb` · `durationSeconds` [integer, null] int · `distanceMeters` [number, null] num |
| `workoutTemplate` | `name` string ≤ 160 |
| `workoutTemplateItem` | `templateId` `uuid` · `exerciseId` string ≤ 64 · `position` int · `targetSets` integer 1…2^53−1 · `targetReps` integer 1…2^53−1 |
| `weeklyPlanDay` | `weekday` integer 1…7 · `templateId` [string, null] `uuid` |

- **Name limit 160:** names are app-trimmed to at most 80 code points, so at most 160 UTF-16 units; every app write fits. **`exerciseId` limit 64:** `ex:` plus 60 characters is 63, a UUID is 36.
- **Local CHECKs** (enums, `startMinute`, ≥ 0 or ≥ 1 minima, `weekday`) are each matched or exceeded by the schema; the D7 app invariant proves it.
- **Fixtures** (`contracts/testdata/sync/entity-payloads.json`, one per entity) are built from A37a-style content:
  - a dumbbell custom exercise with a primary muscle and two secondaries;
  - a named session;
  - a catalog-ID session exercise;
  - a set typed in lb;
  - a template and an item;
  - a Saturday plan day pointing at the template.
- `make gen-sync-schemas` regenerates the embedded `entities.json`.
- **OpenAPI:** unchanged (`sync-entities.json` isn't part of the bundle). Adding registry entities is additive for `make contract-breaking`.

**3.2 Corpus content** (`contracts/testdata/sync/workout-validation-vectors.json`; top-level blocks `version`, `constants`, `vocabularies`, `rules`, `payloads`, `serverRejectsAppTolerates`, `serverAcceptsAppSkips`, `writerCases`; payloads built from the fb_domain drafts, with no app mapper copied):
- **Bases:**
  - a custom exercise of each type and each equipment (folded together), a legacy one with `primaryMuscle` null and 0 secondaries, one with 4 secondaries;
  - a session with all optionals null and one with all set;
  - a catalog and a custom-UUID session exercise;
  - one set per type shape: weight×reps in kg and in lb, bodyweight with and without added load, assisted, reps-only, duration, cardio with and without distance;
  - a template and an item;
  - plan days for all 7 weekdays, rest and templated.
- **W1 muscles:**
  - rejected: 5 items; a duplicate; the primary repeated; an unknown code; legacy `back`/`core`/`full_body`; `Chest`; ` chest`; non-array roots (`{}`, `"chest"`, `null`, `1`); non-string items (`1`, `null`, `[]`);
  - accepted: an escaped `"chest"`; whitespace-formatted JSON; primary null with 4 secondaries; `[]`;
  - schema: `primaryMuscle` unknown or legacy `back` rejected (`schemaOnly`).
- **W2 aliases:**
  - accepted: `[]` and 10;
  - rejected: 11; a non-array; a non-string item;
  - accepted but the app skips the row: a blank alias and an 81-code-point alias.
- **W3 set shape:**
  - rejected: both `reps` and `durationSeconds` null; both set; `kg` with a duration; distance with reps; `kg` without `inputValue`/`inputUnit`; `inputUnit` without `kg`; `inputValue` without `kg`;
  - accepted (app-only bounds): `reps` 0 and 1001, `kg` 1500, duration 0 and 86401, distance 0.
- **W4 exercise reference:**
  - accepted: `ex:bench_press`, `ex:` + 60 characters, a lowercase UUID;
  - rejected: `ex:`, `ex:` + 61, `ex:Bench`, `ex:bench-press`, `EX:bench`, ` ex:bench`, an uppercase or unhyphenated UUID, `""`;
  - each case for both `sessionExercise` and `workoutTemplateItem`.
- **W5 plan-day ID:**
  - accepted: each weekday with its own natural ID;
  - rejected: weekday 3 with Monday's ID; a random v4 and a v7 ID;
  - `weekday` 0, 8 and `"3"` rejected (`schemaOnly`); `6.0` accepted (`wholeNumberInteger`).
- **Cross-row non-rules (all accepted):** a set under an unknown exercise; a session exercise under an unknown or another session; an item with an unknown exercise; a plan day pointing at a missing template; an unknown session `templateId`; duplicate positions; a future `localDate`.
- **Schema cases:**
  - every enum's wrong-case and unknown values;
  - integer and number bounds: `startMinute` −1/1440, `position` −1, `reps` −1, `kg` −0.1 and 1e12 + ε, `targetSets`/`targetReps` 0, plus 1.5 for integers;
  - `localDate` forms (B20 list);
  - UUID forms;
  - `name` 160/161 units with a surrogate pair straddling the limit;
  - metadata boundaries for `customExercise` and `workoutSet`;
  - each field missing, an extra field, and a wrong type (the C# matrix covers all seven).
- **Generic:** lone surrogates in `name` and inside both `...Json` strings; U+0000; a duplicate key; `1e400`.
- **Tombstones:** a full-payload tombstone of each base and each W violation (same outcome); D10's scrubbed tombstones.
- **Writer cases** `{id, entity, payloadId}`: each base ↔ its real column writer (D9), including lb input, null primary, and the plan day ↔ `planDayId`.

**3.3 Server.** `WorkoutPayloadValidator` (D3) plus the hook line. Storage, `PushForSessionAsync`, the advisory lock, forced RLS, LWW/history, receipts, retention/compaction and `UserDataErasure` are untouched (entity-agnostic, B05/B06).
```csharp
internal static class WorkoutPayloadValidator
{
    public const int MaxSecondaries = 4, MaxAliases = 10, MaxCatalogIdLength = 60;
    public static readonly FrozenSet<string> Muscles = /* 15 D2 codes */;
    public static readonly Guid[] PlanDayIds = /* naturalId('weeklyPlanDay','1'…'7') */;
    public static readonly FrozenSet<int> Versions = FrozenSet.Create(1);
    public static bool Covers(string entity) => entity is "customExercise" or "workoutSession" or "sessionExercise"
        or "workoutSet" or "workoutTemplate" or "workoutTemplateItem" or "weeklyPlanDay";
    public static bool Matches(SyncVersion v) => Versions.Contains(v.SchemaVersion) && v.Entity switch
    {
        "customExercise" => MusclesHold(v.Payload) && AliasesHold(v.Payload),    // W1, W2
        "workoutSet" => SetShape(v.Payload),                                      // W3
        "sessionExercise" or "workoutTemplateItem" => ExerciseRef(v.Payload),     // W4
        "weeklyPlanDay" => v.Id == PlanDayIds[(int)v.Payload.GetProperty("weekday").GetDecimal() - 1], // W5 (6.0 ok)
        "workoutSession" or "workoutTemplate" => true,                            // no wire rules; version-pinned
        _ => false,
    };
}
```
Nested strings are parsed with `JsonDocument` (`MaxDepth` 24). The generic pass has already checked them, and the existing catch maps anything unexpected to `invalidPayload`. `weekday` is a schema-checked integer 1…7, read through `GetDecimal` so a whole `6.0` works (`GetInt32` would throw on it).

**3.4 Data flow and rules.**
- **Contract-first:** WP1 (contract and README rules) comes before the corpus and the server.
- **Single writer on the phone:** untouched. No app write path changes, and nothing uploads until A34.
- **Module boundaries:** the validator is in UserData/Infrastructure only.
- **Postgres** stays the only state; there's no migration.
- **RLS and per-user isolation:** unchanged and proven.
- **No user content in logs:** proven by the canary.

### 4. Work packages

| WP | By | Tasks · files | Done when |
|---|---|---|---|
| **WP1 · Contract** `feat(contracts): workout sync entities v1` (its own commit, Progress-log note naming the change, PROCESS A1) | `dotnet-engineer` | • Re-read A37a's merged columns.<br>• The seven schemas (§3.1) in `contracts/openapi/sync-entities.json`.<br>• Seven fixtures in `contracts/testdata/sync/entity-payloads.json`.<br>• `make gen-sync-schemas` → `backend/src/Modules/UserData/Infrastructure/Schemas/entities.json`.<br>• `contracts/README.md` § "Workout semantic rules": W1–W5, the not-rules, tombstones, revival; stating that the validator lands in WP3 of this same merge. | `make check-sync-schemas`; `make gen` with no diff beyond the above; `make check-dotnet`; `git diff --check` |
| **WP2 · Corpus, tripwire, Dart/app parity** `test(sync): workout validation corpus and app parity` | `flutter-engineer` | • `WorkoutWireRules` (D6) in `packages/fb_domain/lib/src/workouts/workout_wire_rules.dart`, exported; `checkExerciseId` calls `isExerciseRef`.<br>• `packages/fb_domain/tool/generate_workout_vectors.dart` and the corpus.<br>• `packages/fb_domain/test/workouts/workout_vectors_test.dart` and `workout_wire_rules_test.dart`.<br>• `apps/mobile/test/drift/user/workout_contract_test.dart` (tripwire).<br>• `apps/mobile/test/features/workouts/data/workout_sync_vectors_test.dart` (D9).<br>• `Makefile` `gen-workout-vectors`; `contracts/testdata/README.md`.<br>A corpus/server disagreement is reported, never hidden | `make gen-check`; `make check-dart`; `git diff --check`; fb_domain coverage stays 100 % (CI) |
| **WP3 · Semantic admission + pure tests** `feat(userdata): admit workout wire rules W1–W5` | `dotnet-engineer` | • `WorkoutPayloadValidator.cs` and the hook in `SyncPayloads.cs`.<br>• `WorkoutCases.cs`; `WorkoutPayloadTests.cs`.<br>• A `SemanticValidatorTests` row.<br>• `SyncTestIds` plan-day ID; the `Utf16Cases` skip (D13); csproj content links.<br>Stop and report if a corpus declaration disagrees with the server | `make check-dotnet`; `make check-sync-schemas`; `git diff --check` |
| **WP4 · Persistence, revival, erasure, privacy, docs** `test(userdata): workout sync persistence, revival, erasure and privacy` | `dotnet-engineer` | • `backend/tests/Persistence.Tests/WorkoutSyncTests.cs`.<br>• The B21 privacy fact in `IdentityPrivacyTests.cs`; compile links.<br>• D14 docs (`contracts/README.md` present tense, `05` §2.2/§5.5, `backend/README.md`) and the A34 handoff lines (§9).<br>Privileged migrator connections only for inventory and aging | `make check-dotnet`; `git diff --check` |
| **Close** | orchestrator; two parallel Codex review tasks (code/architecture + security/data integrity), read-only, whole diff `main..branch`; fixes by the WP's engineer; at most about 2 fix-check rounds | • `evidence/B21-verification.md` from the security task.<br>• Outcome; board row (✅, and `A37a` in the dependencies); backlog #189 closed; the generator-helper idea logged (D8); `make progress`.<br>• TD candidate recorded as Proposed.<br>• Merge via `tools/scripts/merge-step.sh B21 "Workout sync entities (server)" step/B21-workout-sync` (or a group merge, TD-108), background, one at a time | No open blocker or major; CI green on the merge run (`dart`, `dart-test`, `dotnet`, `contract`); `make trace`. No `android-it`/Patrol (no UI or native change) |

### 5. Test list
Lean (TD-104): admission, storability, revival, RLS, erasure, privacy and conformance only. C# tests carry `[Trait("Req", …)]` with WO-003/WO-004/WO-010/WO-020/WO-021/AC-010/AC-012/AC-031, or `[Trait("Rule", "B21.<slug>")]` / the existing `05.5-…`, `04.6-…`, `09.4-no-user-content`. Dart test names start with the spec ID or `B21`.

| Test (file) | Proves |
|---|---|
| `B21 generated vectors match committed bytes` (`workout_vectors_test.dart`) | corpus drift gate (TD-080) |
| `B21 untagged cases have serverAccepts equal to WorkoutWireRules; tags from the closed set; asymmetry lists are exactly the derived cases` (same) | D4/D7: exactly W1–W5 |
| `B21 workout fixtures satisfy every wire rule` (same) | WP1 fixtures valid |
| `WO-004 any SetValues that issueFor accepts for some type, written as columns, satisfies the set shape` (`workout_wire_rules_test.dart`, property, `PROPERTY_RUNS`) | W3 soundness: the server never rejects a set the app writes |
| `WO-003 WO-020 valid drafts satisfy W1, W2, W4; checkExerciseId agrees with isExerciseRef` (same) | W1/W2/W4 soundness |
| `B21 workout fixtures map 1:1 to the table columns both ways; every content column is on the wire` (`workout_contract_test.dart`) | exit 1, contract = A36/A37a tables |
| `B21 every server-accepted corpus payload stores in the real tables` (`workout_sync_vectors_test.dart`) | D7: no poison rows on pull (local CHECKs ⊆ wire) |
| `WO-003 WO-010 WO-020 WO-021 corpus payloads read through WorkoutRepository as declared` (same) | parity server → app; skips listed |
| `WO-003 WO-010 WO-020 drafts written by the real column writers equal accepted corpus payloads` (same) | parity app → server |
| `WO-021 WorkoutWireRules.planDayIds equal planDayId for all seven weekdays` (same) | W5 = TD-070 natural IDs |
| `Embedded_schema_vocabularies_and_bounds_equal_contract_and_corpus` (`WorkoutPayloadTests`) | D6; exit 1 |
| `Validator_constants_equal_corpus` | D6 |
| `Fail_closed_validators_cover_exactly_their_registry_versions` (+ Workout row) | D3 |
| `Workout_validator_fails_closed_for_unregistered_versions_and_other_entities` | D3 |
| `Readme_workout_rules_equal_corpus_rules_and_each_has_accept_and_reject_cases` | exit 2, single source |
| `Payload_matrix_matches_admission_for_live_and_tombstone` (Theory: corpus + schema matrix + fixtures) | exit 2: every W and schema rule, live and tombstone |
| `Wire_rules_accept_valid_and_reject_each_violation` (Theory W1–W5) | exit 2, named per rule; D2 muscle edges |
| `Nested_json_fields_reject_non_arrays_non_strings_and_ill_formed_utf16` | W1/W2; covers the D13 UTF-16 skip |
| `Not_wire_rules_are_admitted` | D4 "nothing more": cross-row, app bounds, names |
| `Batched_matrix_preserves_result_order_and_valid_neighbors_without_persisting_invalid_versions` (`WorkoutSyncTests`) | exit 2, AC-010: ordered `invalidPayload`, no canary in the ack, invalid versions absent from documents/history/receipts |
| `Lww_preserves_displaced_and_incoming_losers_and_replays_are_immutable` (Theory × 7) | AC-012 |
| `Tombstones_compact_by_acceptance_time_and_fence_prevents_resurrection` (Theory × 7, scrubbed tombstones included) | AC-012, `05.5-retention`, D10 |
| `Revived_children_are_newer_live_versions_before_and_after_compaction` (sessionExercise, workoutSet) | **R14 / A37a D25 (D5):**<br>• live → tombstone → same-ID revival with a newer HLC is accepted and pulled live, and history keeps the tombstone;<br>• after compaction the revival replaces the fence;<br>• an older live version is `stale`;<br>• a revival under another session is accepted (no aggregate judgement) |
| `Aggregate_children_are_admitted_in_any_order_and_across_aggregates` | D4: child before parent, after the parent's tombstone, re-parented, unknown exercise/template; no cascade |
| `Another_owner_cannot_read_live_history_or_fence_and_same_id_is_independently_owned` (Theory × 7) | `04.6-rls`; plan-day natural IDs shared across users |
| `Guests_get_403_for_push_pull_and_item_history_and_unauthenticated_get_401` | `04.6-authz` |
| `Delete_account_erases_workout_live_history_fences_and_receipts_and_preserves_second_owner` | AC-031, exit 2: real `DELETE /v1/me`, privileged zero-row inventory per entity |
| `B21_workout_names_and_values_never_reach_errors_logs_or_telemetry` (`IdentityPrivacyTests`) | `09.4-no-user-content`. **Canaries:** `CANARY-B21-EXERCISE`, an alias, session and template names, an Arabic name, `kg` 87.6543219.<br>**Legs:** accepted, W1-, W3-, W4- and schema-invalid, guest 403 |

Count: **28 named tests**: 5 fb_domain, 5 app, 9 C# pure, 8 Testcontainers, 1 privacy. The Theories expand to roughly 500 C# cases.

### 6. Exit-criteria mapping

| Exit criterion | Evidence |
|---|---|
| Contract conformance green; the Dart client regenerated | WP1: `make gen` (no client diff: no OpenAPI change), `make check-sync-schemas`; CI `contract` job (`contract-conformance`, `contract-breaking` additive); tripwire `workout_contract_test` |
| Admission tests reject rule-breaking rows; deletion erases every workout row | WP3 `Wire_rules_…`, `Payload_matrix_…`, `Nested_json_…`, `Readme_…`; WP2 invariant; WP4 batched matrix + `Delete_account_erases_workout_…` (7 entities: live, history, fences, receipts) |
| Security review recorded (Risky) | Codex security task → `evidence/B21-verification.md`, no open blocker or major |
| (plan) R14 revival accepted | WP4 `Revived_children_…` |
| (plan) app parity | WP2 storability, repository-read and writer tests |

### 7. Risks and unknowns

| Risk | Handling |
|---|---|
| **A37a not merged, or its column names change in review** | B21 implementation waits for A37a on `main` (D12). WP1 re-reads the merged columns; a difference updates §3.1 before any code |
| **`secondaryMusclesJson` differs from the handoff's `secondaryMuscles` array** | D2; same content and rules. Stated in the README and the A34 handoff. If the orchestrator or Codex prefers an array member, the cost is an entity-specific encoder in A34 plus a tripwire exception, so the string form is recommended |
| **Generic tests change behaviour once workout fixtures exist:**<br>• A23's migration test now seeds workout tables at v8–v10;<br>• `Utf16Cases` controls break W1/W2/W4;<br>• `SyncTestIds` needs the plan-day ID | D13 handles the last two in WP3. The migration seeding should pass (A37a's v10→v11 adds defaulted columns); a failure there is a real migration bug, fixed in WP2 |
| **A server-accepted row fails a local CHECK or the unique plan index** (poison row on pull) | Schema minima match the CHECKs, W5 guards the index, and D7's storability invariant fails CI otherwise |
| **Hostile same-user client builds inconsistent aggregates** (re-parented children, sets under timed exercises) | Within the user's own RLS scope only. The repository reads tolerantly (orphans hidden, malformed rows skipped). Pinned as accepted (D4/D5) for the security review |
| **Dart/.NET differences** (escaped codes, JSON whitespace, `6.0`, digit forms, surrogates) | Corpus cases with the closed tags; a new kind of difference is reported, never hidden |
| **Permanently rejected local rows** (only via non-app writers) | Listed in `serverRejectsAppTolerates`; A34 #111 (no endless retry) |
| **Parallel lanes** (`contracts/README.md`, `entity-payloads.json`, `05`, `backend/README.md`, `IdentityPrivacyTests.cs`, `ChatProposalPayloadTests.cs`, `SyncTestIds.cs`, `Makefile`, board, backlog) | Rebase before the merge; board/backlog edits and `make progress` only at the close |
| **Card conflict with the A37a branch** (handoff section, Progress log) | Handoff copied verbatim; on rebase keep both Progress-log lines |
| **Size creeps past L** (7 entities × matrices) | Split seam in §10; the corpus stays about 230 cases (not B19's 389) |

### 8. Deploy hold
**None** (D12): the registry and the validator ship in one merge. If a contract-only merge is ever requested, apply B20 §8 before any server runs that build.

### 9. Handoffs (written in WP4)
- **A34:**
  - upload the seven workout entities v1 after B21 is on the server;
  - the muscle list is `secondaryMusclesJson` (the column as is);
  - plan days keep their natural IDs;
  - a revival is the row's current content at its new HLC (never re-stamped older);
  - scrubbed tombstones keep W3's null pattern (#136);
  - `serverRejectsAppTolerates` rows are never retried endlessly (#111);
  - read integers as `num` → `int` (`6.0`).
- **A37a/A37c:** none beyond D25 (works as is). A future workout column = a new schema version, server first.

### 10. Size check
| Part | Sessions |
|---|---|
| WP1 (7 schemas, fixtures, README rules) | 0.3 |
| WP2 (fb_domain class, generator ~230 cases, 4 Dart test files) | 0.8 |
| WP3 | 0.5 |
| WP4 | 0.5 |
| Close and Codex rounds | 0.2 |
| **Total** | **~2.3 (M–L)** |

At or below L, so no split. If needed, a natural seam exists: **B21a** = WP1 + WP3 (contract plus the validator with hand-built tests; no hold because they merge together), then **B21b** = WP2 + WP4 (corpus, parity, persistence). Splitting would need B21a's README rules to be final and two merges, so one step is recommended.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-30: card created (owner decisions 2026-10-30, TD-105).
- 2026-10-30: A37a handoff added (custom-exercise muscle fields, child revival).
- 2026-10-30: Low-level plan written (step-planner, lane 4, from 54daffa): D1–D15, WP1–WP4 + close, size M–L (~2.3 sessions), Risky, no owner items, one TD candidate (workout sync model, record as Proposed at close); no deploy hold (registry + validator in one merge); implementation starts after A37a is on main. Next: Codex plan review, then orchestrator self-approval.
- 2026-10-30: Codex plan review (fresh, read-only): APPROVE, no findings. Plan self-approved by the orchestrator (TD-037; no owner items). Coding starts after A37a merges (needs the v11 columns and fb_domain `Muscle`).
- 2026-10-30: WP1 contract (lane 4, after merging main d42b060 with A37a): seven workout entity schemas v1 in `contracts/openapi/sync-entities.json` (A37a v11 columns re-read: match §3.1; nullable enums carry `null` like `personalFood.entryServingUnit`), seven fixtures, regenerated `entities.json`, `contracts/README.md` § "Workout semantic rules" W1–W5. `make gen` no other diff; `check-contract`, `check-dotnet`, `check-sync-schemas` green.
- 2026-10-30: WP2 corpus and parity: `WorkoutWireRules` in fb_domain (`checkExerciseId` delegates to `isExerciseRef`), generator + corpus `workout-validation-vectors.json` (321 cases, above the ~230 estimate: tombstones on every W rejection, W4 on both entities), fb_domain vectors + wire-rule tests (W3/W1/W2/W4 properties), app tripwire `workout_contract_test` and parity `workout_sync_vectors_test` (a fresh in-memory DB per case, because the delete triggers forbid resets; every server-accepted row stores; repository reads as declared; 32 writer cases). Only 2 app reads were mispredicted (drift truncates 1.5 in integer columns), and they are now declared. Cross-check: fb_domain workouts tests, the workout op handler/library/log-controller tests, and `tools/sync_sim` all pass; fb_domain and the touched app files analyze clean (whole-repo `dart analyze` crashed for lack of memory with swap full); stale-base clean.
- 2026-10-30: WP3 admission: `WorkoutPayloadValidator` (W1–W5, fail-closed by version, no regex, no I/O) plus one hook line in `SyncPayloads`; `WorkoutCases.cs` (corpus + 7-entity schema matrix, compile-linked into Persistence.Tests), `WorkoutPayloadTests` (630 cases, the C# server agrees with all 321 corpus declarations live and as tombstones on the first run), a `SemanticValidatorTests` row, `SyncTestIds.For("weeklyPlanDay")` = Saturday's natural ID, the D13 `Utf16Cases` skip, csproj links. Cross-check: WorkoutPayloadTests, SemanticValidatorTests and the other 4 UserData payload classes (Chat/Measurement/BodyTargets/PersonalFood) pass; `make check-dotnet` and `check-sync-schemas` green.
- 2026-10-30: WP4 persistence: `WorkoutSyncTests` (Testcontainers, 27 cases: batched matrix of all corpus + schema cases with privileged no-persist inventory, LWW × 7, tombstone compaction/fence × 7 with scrubbed tombstones, **R14 revival before and after compaction** for session exercises and sets (older version stale, revival under another parent accepted), any-order/cross-aggregate admission without cascade, RLS × 7 (plan-day natural IDs independently owned), guest 403/401, account erasure per entity) and the `B21_workout_names_and_values_never_reach_errors_logs_or_telemetry` privacy fact; D14 docs (`contracts/README.md` present tense + corpus, `05` §2.2/§5.5, `backend/README.md`) and the A34 handoff. All pass locally on the first run, as does `ProductionSyncTests` (9, generic fixture round trip incl. the plan day's natural ID). Cross-check: `make gen` (no diff), `check-contract`, `check-sync-schemas`, `check-dotnet`, WorkoutPayloadTests (630) and `make trace` (no B21 warnings) are green.
- 2026-10-30: Close prep: board row 🟨 awaiting merge, Outcome draft with the TD candidate "Workout sync model" (for the orchestrator to record). Next: combined Codex review, then merge-step.

- 2026-10-30: close: evidence, TD-109 recorded, review APPROVE (combined Codex review, 0 blocker/major/minor). Board ✅ awaiting merge; backlog #189 done, #222/#223 added.

## Outcome
_Written in Phase E: built · deviations · follow-ups · new TDs · measurements._

**Final (2026-10-30, after the combined Codex review; CI evidence comes from the merge run, TD-108).**

**Built.** The server admits, stores, serves and erases the seven workout entities v1 (`customExercise`, `workoutSession`, `sessionExercise`, `workoutSet`, `workoutTemplate`, `workoutTemplateItem`, `weeklyPlanDay`). Admission is the schema plus `WorkoutPayloadValidator`, which checks exactly W1–W5 and fails closed per version. The registry and the validator ship in one merge, so there's no deploy hold. `fb_domain` gains `WorkoutWireRules`, and `checkExerciseId` delegates to it. A Dart-generated corpus of 321 cases pins three sides: `fb_domain`, the real app tables, `WorkoutRepository` and column writers, and the C# server. The server agreed with every declaration on the first run, and every server-accepted row stores in the app's tables. R14 revival works without a server change, before and after compaction. No migration, no new dependency, no OpenAPI path change.

**Commits (one per WP):** WP1 `feat(contracts)`, WP2 `test(sync)`, WP3 `feat(userdata)`, WP4 `test(userdata)`.

**Tests:**
- fb_domain: 4 vectors tests and 7 wire-rule tests, including the W3, W1/W2 and W4 properties.
- App: the tripwire, plus 4 parity tests.
- C#: `WorkoutPayloadTests` (630 cases), a `SemanticValidatorTests` row, `WorkoutSyncTests` (27 Testcontainers cases) and one privacy fact.

**Deviations.**
1. **Corpus size:** 321 cases instead of about 230. Every W rejection carries a tombstone, W4 runs for both entities, and app write bounds have `notWire-*` cases. Runtime is small: the app parity test takes about 6 s.
2. **The app parity test uses a fresh in-memory database per case.** The tables' tombstone triggers forbid `DELETE`, so the plan's single database couldn't be reset. Rows are seeded with raw SQL inside `runAuthorizedWrite` (test seeding, as the migration tests do).
3. **Tombstones read as their live content.** In the app test a tombstone is stored as one (the storability check), then revived as live for the repository read, so `-tombstone` cases keep the live `appReads`.
4. **Nullable enums list `null`** (`primaryMuscle`, `inputUnit`), as `personalFood.entryServingUnit` does. The corpus vocabularies list the codes without `null`.
5. **Plan-day cases always carry `rowId`.** The `wholeNumberInteger` case is Wednesday's `3.0`, not `6.0`.
6. **W3 doesn't protect an app read.** The plan said rule (c) prevents a `LoggedSet` throw, but `WorkoutRepository._set` already drops a typed value without kg, so the app reads every W3 violation. They are listed in `serverRejectsAppTolerates`; the rule still keeps the wire to the shapes the app writes.
7. **Local checks:** the whole-repo `dart analyze` crashed for lack of memory (swap full, other lanes busy), so analysis ran per package: fb_domain and the touched app files are clean.

**Follow-ups.**
- `apps/mobile/lib/core/db/tables/workout_tables.dart` still says the entity names are "not in the sync contract yet". That's a comment only; fix it in A34, because B21 makes no app production change.
- Backlog idea: a shared corpus-generator helper for the five generators (D8).
- Backlog #189 done by B21; new items #222 (generator helper) and #223 (stale comment, A34).

**TD-109 "Workout sync model" (Accepted, recorded at close).**
- The seven A36 entities are row documents.
- Aggregate integrity is app-side: ownership, unique child IDs, positions and per-type set values are handled by the handler on write and the tolerant repository on read.
- The wire admits only the row-local rules W1–W5:
  - muscle codes;
  - aliases shape;
  - set shape;
  - catalog or UUID exercise reference;
  - plan-day natural row ID.
- A revived child is a newer LWW version, also after compaction; the server never cascades or judges aggregates.
- The muscle vocabulary (A37a D2) is a closed wire enum, and JSON-valued columns stay `...Json` strings (`secondaryMusclesJson`).
- A new code or column is a new schema version, server first (TD-080).
- It folds in A37a D2's cross-track candidate.

**Metrics.**
- **Review:** 1 combined Codex round (correctness, architecture, security/data integrity): APPROVE, 0 blocker / 0 major / 0 minor. No fix-check needed.
- **Tests added:** 28 named tests as planned (5 fb_domain, 5 app, 9 C# pure, 8 Testcontainers, 1 privacy). Theories expand to about 630 pure cases plus 27 Testcontainers cases; corpus 321 cases.
- **Size:** planned M–L (~2.3 sessions); actual within the estimate, one merge, no split. The corpus ran above plan (321 vs ~230).
- **Evidence:** `evidence/B21-verification.md`.

**Production / deploy:** no EF migration and no data change. On deploy the server simply starts admitting the seven entities. Nothing uploads them before A34.
