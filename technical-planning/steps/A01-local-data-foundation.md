# A01 — Local data foundation

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | S06 ✅, S08 ✅ | M | Claude | ⬜ Not started |

_Old ID: S09 (renumbered by TD-063, 2026-10-16)._

**Goal.** The app's local database and its single write path: drift with migration tests, sync metadata on every table, outbox triggers, and the `ChangeSetApplier` with undo and domain events. Every feature that stores data uses exactly this.

**Spec:** AI-048, UX-030 (direct action + undo mechanism), AI-036 (proposals never applied implicitly, mechanism), AC-012 (sync metadata), D-079 · **Decisions:** TD-005, TD-011, TD-017

## Scope
- **drift setup:** `user.db` (read/write) in a background isolate. A `catalog.db` attach point (the pack arrives in A05). **One database file per account/guest** (`05` §3).
- **Conventions as code:** a table mixin for sync metadata (`id` UUIDv7, `created_at`, `updated_hlc`, `version`, `deleted_at`, `device_id`, `origin`, `edited_by_user`). A generator or helper so every synced table gets its **outbox trigger** automatically.
- **Migration harness:** schema dumps per version + generated migration tests from every older version. A rule (and CI check) that shipped migrations are never edited.
- **`ChangeOp` / `ChangeSet`** (sealed, freezed). The **`ChangeSetApplier`**: one transaction, precondition checks (`expectedVersion`), applies ops, bumps `version`/`updated_hlc`, writes the outbox (via triggers), records `origin`, returns the **inverse** change set, emits **domain events**.
- **`UndoStack`** + the hook used by the design system's undo snackbar (5 s, UX-030).
- **`DomainEventBus`** (typed events, synchronous after commit).
- **Repositories:** read streams (`watch()`) + a **library-private write API** only the applier can call. An **architecture test** fails if anything else imports the write API.
- `settings_kv` table + a settings store (first real use of the stack), and `sync_state` / `sync_outbox` tables (used by B01/A34).

## Out of scope
- Diary/food tables (A06+). Sync transport (B01/A34).

## Fixed by the plan
- The single-writer pattern and its guarantees (`03` §5). Tombstones for deletes. HLC from S08.

## Decide in the low-level plan
- How ops are expressed for generic CRUD vs entity-specific ops (balance type safety vs boilerplate).
- Inverse computation strategy (snapshot before write vs per-op inverse).
- How domain events are delivered to Riverpod (stream vs callbacks).

## Notes from earlier steps
- **From S08:** HLC columns use binary collation (SQLite default `BINARY`; TD-049). Use `fb_domain`'s `Clock`/`IdGenerator`; the app wires `lib/system.dart` (not exported from the barrel). `EntryTime` stores `occurredAtUtc` + `tzOffsetMin`.

## Exit criteria
- [ ] A change set with several ops applies atomically. A failure in one op rolls everything back (test).
- [ ] Undo restores the exact previous state, including tombstoned rows (test).
- [ ] An `expectedVersion` mismatch is rejected with a typed failure (test).
- [ ] Every synced table write produces an outbox row (trigger test). Writes outside the applier fail the architecture test.
- [ ] The migration harness is green with at least two schema versions.
- [ ] Applying a 10-op change set takes < 10 ms on the A55 (measured).

## Read first
`03-architecture.md` §4–5 · `05-data-and-sync.md` §1–3

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B (2026-10-17, wave 1, lane L) by the step-planner. Versions checked on the pub.dev API on 2026-10-17: drift 2.35.2 (2026-10-07), drift_dev 2.35.1 (2026-09-30, `analyzer >=13 <15`, so it fits the workspace's analyzer 13.3 cap), drift_flutter 0.3.1 (2026-07-11), sqlite3 3.7.1 (2026-10-13). `sqlite3_flutter_libs` is end-of-life (0.6.0+eol): sqlite3 3.x bundles SQLite through build hooks, with hash-checked prebuilt binaries and FTS5 enabled ([sqlite3 hook docs](https://github.com/simolus3/sqlite3.dart/blob/main/sqlite3/doc/hook.md)). The migration workflow follows [drift Migrations](https://drift.simonbinder.eu/Migrations/) (`make-migrations`, `stepByStep`, generated tests). The write guard uses drift's `QueryInterceptor` / `interceptWith` ([drift tracing example](https://drift.simonbinder.eu/examples/tracing/)). The background isolate and the open hook come from `DriftNativeOptions` (`databasePath`, `setup`) ([API](https://pub.dev/documentation/drift_flutter/latest/drift_flutter/DriftNativeOptions-class.html))._

### 1. Summary
After A01 the app has one drift database per profile (`user.db`, background isolate, WAL) and a single write path. Domain code describes a change as a `ChangeSet` of typed `ChangeOp`s. These are pure value types in `fb_domain`, so Buddy's ProposalEngine and `buddy_eval` can build drafts. Each feature's op handler turns an op into inert row operations. The `ChangeSetApplier` (in `core/changes`) runs them in one transaction through the only row writer. The writer checks `expectedVersion`, stamps the sync metadata (UUIDv7, HLC, version, device, origin) and snapshots each row before writing it, so it can return an exact inverse. After commit the applier emits domain events. SQL triggers append a row to `sync_outbox` for every synced write. A runtime write guard plus two `app_check` rules make any other write path fail. The migration harness (drift schema dumps, generated tests, a frozen-migrations check) ships with schema v1 → v2. `settings_kv` + `SettingsStore` is the first real user of the stack. `UndoStack` and its providers are ready for A02's snackbar.

### 2. Decisions

| # | Decision | Reason / source |
|---|---|---|
| D1 | **Op layering (card item 1).** Two levels. (a) **Domain ops**: `abstract interface class ChangeOp { String get family; }` in `fb_domain` (`src/changes/`), with one `sealed` family per feature (`SettingsOp` here, `DiaryOp` in A06, …). They're pure, immutable, hand-written value classes with `==`/`hashCode` (S08 style). They carry IDs, `expectedVersion` and intent, never SQL. (b) **Row ops**: a closed `sealed class RowOp` in the app (`core/changes/row_ops.dart`): `InsertRow`, `UpsertRow`, `UpdateRow(expectedVersion?)`, `TombstoneRow(expectedVersion?)`, and `RestoreRow` (inverse only), typed on drift's `TableInfo<T, D>` + `Insertable<D>`. A **`ChangeOpHandler<O>`** per family (registered by `family` at the composition root) reads the current state in the transaction and returns an `OpPlan(rows, events)`. Generic CRUD needs no new op types (a handler emits row ops), and entity ops stay intention-revealing and exhaustively switched inside their family | A sealed hierarchy can't span packages or features. Ops must be pure Dart, because `03` §5.2 has the ProposalEngine (domain) build draft change sets. Families keep features owning their ops without touching core. Row ops give one typed, generic write path. **Deviation from the card's "freezed":** `fb_domain` has an empty runtime-dependency allowlist (S08), so the ops are hand-written. A21 adds JSON for stored drafts. **TD candidate** |
| D2 | **Inverse strategy (card item 2): snapshot before write, per row**, inside the transaction. The row writer reads the full row (`D`) before each write and records the inverse: an insert → `TombstoneRow`; an update/tombstone/upsert-over-existing → `RestoreRow(snapshot, expectedVersion: versionAfterWrite)`. Inverses are applied in reverse order. Rows touched twice in one change set keep only the **first** snapshot | Generic and exact for every table and op, including tombstoned rows and derived rows a handler touches (A06's empty-group cleanup). No per-op inverse code to get wrong. The cost is one indexed PK read per row, inside the budget (§7) |
| D3 | **What undo restores.** Every content column + `deleted_at` + `edited_by_user` are set back to the snapshot. `version` +1, a new `updated_hlc`, `device_id`, and `origin = undo:<changeSetId>`, because undo is just another change and must sync (`03` §5.3). Undoing an insert tombstones the row (no hard delete). If a row changed after the apply, its `expectedVersion` fails and undo returns a typed `VersionConflict`. The UI says "can't undo" (A08) | The meaning of the exit criterion "exact previous state", defined so sync stays correct |
| D4 | **Event delivery (card item 3): stream.** `DomainEventBus` wraps one `StreamController<DomainEvent>.broadcast(sync: true)`. `emit` is called only **after commit**, in op order, and never on rollback. `on<T>()` is the typed filter. Riverpod gets it through `domainEventBusProvider` (keepAlive). Consumers subscribe in their own provider (`ref.onDispose(sub.cancel)`). A listener that throws is reported to the zone's error handler and never fails the apply | Streams are what Riverpod composes with (`ref.listen`, `StreamProvider`). Sync delivery keeps "synchronous after commit". No callback registry to manage. Base types: `abstract class DomainEvent` in `fb_domain`. A01 adds `ChangeSetApplied(changeSetId, origin, entities)` and `SettingsChanged(keys)` |
| D5 | **Sync metadata columns** (mixin `SyncColumns on Table`): `id TEXT PK`, `created_at INTEGER` (UTC ms), `updated_hlc TEXT NOT NULL` (TD-049, BINARY collation), `version INTEGER NOT NULL` (1 on insert, +1 per write), `deleted_at INTEGER NULL` (UTC ms tombstone), `device_id TEXT NOT NULL`, `origin TEXT NOT NULL` (`direct` · `proposal:<uuid>` · `undo:<changeSetId>` · `system`), `edited_by_user INTEGER NOT NULL DEFAULT 0` (a **content/provenance** column kept in the mixin per `03` §5.3. The row writer **never sets it**. Ops set it explicitly when the user overrides a value that came from another source (AI-072, "edited by you" → ⓨ badge, `spec/11` §2). Default 0, carried forward unchanged on updates, restored by undo like any content column.). Times are integer milliseconds, not drift `DateTime` columns | drift's default `DateTime` storage is whole seconds. Explicit ints are portable and exact for B05's payload mapping. `origin` matches `03` §5.3 auditability |
| D6 | **Row IDs.** User-created rows: UUIDv7 (`IdGenerator`). Rows that are a natural key and must converge across devices use a **deterministic UUIDv5**: `uuidv5(FB_NAMESPACE, '<entityWireName>:<key>')`. Examples: `setting:units.system`, `mealSlot:normal:breakfast`, `dayMark:2026-10-17`. `FB_NAMESPACE` is one fixed UUID constant in `core/db/natural_id.dart`, computed with `package:crypto` (add `crypto: ^3.0.7` to the app; it's already in the lockfile). `fb_domain` stays dependency-free. Where the domain needs fixed IDs (default slots), they are literal UUID strings in `fb_domain`, and an app test recomputes them. The ID stays a lowercase canonical UUID, so the sync contract (`id: format: uuid`) and `05` §1 are unchanged. No B05 action is needed. **TD candidate (TD-070)** | Two phones would otherwise each create a "units" setting or a default "Breakfast" with different UUIDs, and LWW per ID would never merge them |
| D7 | **Seeds and migrations bypass the applier** but follow the conventions: `origin = system`, device `00000000-0000-0000-0000-000000000000`, HLC `0000000000000-00000-<that device>`, the lowest possible value. Any real edit on any device wins over a seed. Seeds are **not captured** into the outbox. The seed helper `seedRows(...)` (in `core/db/`) upserts `sync_state['outbox.capture'] = '0'`, writes the rows, then restores `'1'`, all inside the migration transaction. Seed rows are fully deterministic: `created_at = 0`, `version = 1`, every content value from a constant table. A seeded row only reaches the server once a real edit gives it a real HLC and device | Migrations run before the applier exists and need no device ID. The lowest HLC means a seed can never overwrite user data through sync |
| D8 | **Outbox through SQL triggers**, hand-written in `core/db/sync_triggers.drift`, so they're part of drift's schema (dumps, `createAll`, verifier). Per synced table: `<t>_outbox_ai` (AFTER INSERT) and `<t>_outbox_au` (AFTER UPDATE `WHEN NEW.updated_hlc IS NOT OLD.updated_hlc`), both `INSERT INTO sync_outbox(entity, row_id, hlc, deleted)`, plus `<t>_no_delete` (BEFORE DELETE → `RAISE(ABORT, 'tombstone, never delete')`). Every trigger is gated by `WHEN (SELECT value FROM sync_state WHERE key = 'outbox.capture') IS NOT '0'`. The **helper** is a completeness test: every table that has the `SyncColumns` columns must have exactly these three triggers with the right entity name, and on failure it prints the SQL to paste | A static `.drift` file is what drift's migration tooling understands. A generator would add tooling for ~15 lines per table. The test makes forgetting impossible. The capture flag lets A34 apply pulled rows without echoing them back |
| D9 | **Outbox shape** (`sync_outbox`, local-only): `seq INTEGER PK AUTOINCREMENT`, `entity TEXT`, `row_id TEXT`, `hlc TEXT`, `deleted INTEGER`. One row per written version. **The payload is not copied.** A34 reads the row at push time, coalesces per `(entity, row_id)` to the newest `hlc`, and on acknowledgement deletes `WHERE entity=? AND row_id=? AND hlc <= ackedHlc` | Matches B01's handoff (`05` §5.4): `(entity, id, hlc)` is an immutable version identity, because any later change bumps the HLC. An acknowledgement can't erase a newer local edit. No JSON serialisation per table in SQL. `sync_state(key TEXT PK, value TEXT)` holds `outbox.capture`, `hlc.last` and A34's cursors |
| D10 | **HLC across restarts:** the applier upserts `sync_state['hlc.last']` (the change set's highest HLC) inside every transaction. At first use it builds `HybridLogicalClock(clock, deviceId, last: Hlc.tryParse(stored))` | One tiny write per change set. Order holds even if the wall clock goes backwards between runs (S08 HLC contract). **Confirms TD-053** (the install device ID from `DeviceIdStore` is the HLC node ID). Move it to Accepted at close |
| D11 | **Write guard, the runtime half of "only the applier writes":** a drift `QueryInterceptor` on the connection rejects `runInsert/runUpdate/runDelete/runCustom/runBatched` unless the current `Zone` carries the private write token. Only `RowWriter`, the migration strategy, the catalog attach and (from A34) the sync remote-apply scope set it. A raw write anywhere else throws `UnauthorizedWriteError` in tests and in release | Catches what an import rule can't (a repository calling `db.into(...)`). It costs a zone lookup per statement. Spike in WP2, **time-boxed to ~30 min**: drop the zone guard if it needs special cases (the static rules in D12 remain). **Fallback** if zones don't reach the interceptor reliably: keep only the static rules (D12) and log it |
| D12 | **Static architecture rules** (`tools/app_check`, boundary rules, no escape hatch, TD-052): **`db-write-api`**: `core/db/write/**` is imported only by `core/changes/change_set_applier.dart`. **`db-write-call`**: in files importing `package:drift/`, outside `core/db/` and `core/sync/`, the calls `into(`, `update(`, `delete(`, `batch(`, `transaction(`, `customStatement(`, `customInsert(`, `customUpdate(`, `insertOnConflictUpdate`, `insertReturning`, `.replace(` fail. **Layering (closes backlog #38):** `features/*/application/` must not import `core/db/` (go through `data/` repositories), and `presentation/` must not import `core/changes/` (go through application commands) | The card's architecture test, plus the backlog decision. Fixture tests in `tools/app_check/test/` prove each rule fails readably |
| D13 | **Database files:** `<applicationSupport>/profiles/<profileKey>/user.db`, `profileKey = 'local'` until A33 adds accounts and guest profiles (one file each, `05` §3/§6). Opened with `driftDatabase(native: DriftNativeOptions(databasePath:, setup:))` (background isolate). `setup` sets `journal_mode=WAL`, `synchronous=NORMAL`, `busy_timeout=5000`. The `AppDatabase` provider is **synchronous** and opens lazily on the first query, so nothing touches storage before the first frame (UX-001, S06) | drift_flutter wraps `createInBackground` + `path_provider`. Lazy open keeps the startup path clean. The device ID (async) is needed only by the applier, which awaits it on first apply |
| D14 | **Catalog attach point (A05 seam):** `abstract interface class CatalogPackSource { Future<String?> currentPackPath(); }` in `core/db/catalog/`, default `NoCatalogPack` (returns `null`). `beforeOpen` runs `ATTACH DATABASE 'file:<path>?mode=ro&immutable=1' AS catalog` when a path is given. `AppDatabase.reattachCatalog(String? path)` (DETACH + ATTACH, outside any transaction) is for A05/A24's atomic pack swap. Catalog tables are read with `customSelect('… FROM catalog.<t>')` or drift views that A05 defines. A01 defines no catalog schema | Fixes the seam: A05 supplies the file and its tables, A01 only attaches. The read-only URI needs URI handling on the connection. The WP2 spike checks that a write to `catalog.*` fails. **Fallback** (if the read-only URI isn't honoured, e.g. URI filenames are disabled so `file:…` would open a new empty database): A05 opens the pack as a **separate read-only connection** (`sqlite3.open(path, mode: OpenMode.readOnly)` wrapped in a small drift executor) and `OfflineCatalog` reads from it. Cross-file joins aren't needed in R1 (entries carry their own snapshot, FD-073). The WP2 spike must assert that a **known table in the pack is readable** after ATTACH (not just that ATTACH succeeded), and that `INSERT INTO catalog.<t>` fails |
| D15 | **Migration harness:** `build.yaml` `drift_dev` options `databases: {user: lib/core/db/app_database.dart}`, `schema_dir: drift_schemas/`, `test_dir: test/drift/`. Schema changes run `dart run drift_dev make-migrations` (via `make db-migrations`). Each step callback lives in its own file `lib/core/db/migrations/from_<n>_to_<n+1>.dart`, wired with the generated `stepByStep`. **Frozen rule:** `tools/scripts/check-frozen-migrations.sh` (in `check-dart`, so local + CI) fails if a file under `apps/mobile/drift_schemas/` or `lib/core/db/migrations/from_*` that exists at the merge base with `origin/main` (on `main` itself: `HEAD^`) is modified, renamed or deleted. Adding files is fine. **v1** = `sync_state`, `sync_outbox`. **v2** = `settings_kv` + its triggers (a real second version, so the generated v1→v2 test has data to carry) | The documented drift workflow. One file per step makes "never edit a shipped migration" checkable by path. CI already checks out with `fetch-depth: 0` |
| D16 | **Settings store:** `settings_kv` = `SyncColumns` + `value_json TEXT NOT NULL`, id = `setting:<key>` (D6). `SettingKey<T>(name, codec, default)` is typed (JSON codec). `SettingsStore.watch(key) → Stream<T>`, `read(key)`, and `put(key, value, origin)` / `reset(key)` build `SettingsOp.put/reset` change sets and return the `ApplyResult` (the caller decides on undo). `SettingsChanged(keys)` event | The first real use of the stack (card). Typed keys keep the JSON at one edge. Entity wire name `setting` (camelCase wire names, ≤ 64 chars per the contract's `entity` limit). `SyncedTable` asserts both rules |
| D17 | **`UndoStack`:** `push(UndoEntry(id, label: UndoLabel, inverse, appliedAt))`. It keeps at most 5 entries, and each expires `undoWindow` = 5 s + 1 s grace (tap latency) after `appliedAt`, measured with the injected `Clock`. `undo(entryId) → UndoOutcome {undone, expired, conflict, unknown}` applies the inverse via `applier.revert`, which **doesn't** push a new entry (no redo). `UndoLabel` is a typed key + args (e.g. `entriesLogged(count)`). The presentation layer maps it to ARB text. **Hook for A02/A08:** `latestUndoProvider` (`StreamProvider<UndoEntry?>`) + `undoStackProvider`. The app wires A02's `onUndo: () => ref.read(undoStackProvider).undo(entry.id)`. No UI here | UX-030's 5 s and A02's data-free component (label + callback). Expiry in the stack stops a stale undo from another screen |
| D18 | **Failures are typed results, not exceptions:** `ApplyResult = Applied(changeSetId, inverse, events) \| Rejected(ChangeFailure)`. `ChangeFailure` is a sealed type: `VersionConflict(entity, id, expected, actual)`, `RowNotFound(entity, id)`, `InvalidOp(code)`, `ConstraintViolation(code)`. Inside the transaction a private exception triggers drift's rollback, and the applier maps it. Change sets apply **serially**, one at a time | The exit criteria need typed failures. A proposal rebuild (A21) switches on them. drift transactions on one connection are serial anyway, and the explicit queue keeps the HLC and snapshots consistent |
| D19 | **No SQL foreign keys between synced tables.** Handlers check references in the transaction | Pull order across entities is arbitrary (B01 `server_seq`), and a parent may be tombstoned. FKs would make sync apply fail. Applies from A06 on |
| D20 | **Test support** (closes backlog #27): `package:fb_domain/testing.dart`, a separate library like `system.dart` and not exported from the barrel, with `ManualClock` (settable UTC + offset) and `SequenceIdGenerator` (deterministic UUIDv7s). It's pure Dart, so the determinism test allows it. Backlog #30's ban-list edges (`clock?.now()` false positive, `[.now()]`, `{.now()}`, EOF backslash) are fixed in the same WP | A01 and A06 tests need a fake clock in the app. Both items are assigned to A01 |
| D21 | **Device backup (backlog #45), conservative default, owner question.** A01 **excludes** `profiles/` (the db, `-wal` and `-shm` together) and `catalog/` from `<cloud-backup>`, `<device-transfer>`, the Android 16 `<cross-platform-transfer>` section and the legacy `backup_rules.xml`, keeping the existing exclusions. Nothing leaves the device, so A01 makes no security trade-off and no owner gate applies. **⚠️ OWNER question (must be answered before A11):** "Back up the diary database? Rec: device-to-device + Google cloud only when end-to-end encrypted (`disableIfNoEncryptionCapabilities="true"`, Android 12+). Android 8–11 stays excluded." When the owner agrees, a follow-up flips the profile exclusion in `<cloud-backup>` and `<device-transfer>`. Backlog #45 stays open and is re-targeted to "before A11" | Until sync ships (production comes last, TD-064), the phone holds the only copy, so the owner decides before the first dogfood build |

**TD candidates for close:** D1 (op layering, ops in `fb_domain`), D6 (deterministic UUIDv5 natural IDs, TD-070; seeds not captured, D7), D8/D9 (outbox trigger + version-identity shape), D11/D12 (write guard + rules). D1–D4, D8–D12 together are TD-069. TD-005/011/017 can move to Accepted with A01's evidence. TD-053 confirmed (D10).

### 3. Design

**3.1 `fb_domain` additions** (pure, zero runtime deps; exported from the barrel)
```
src/changes/change_op.dart     ChangeOp (interface: family), ChangeSet(ops, origin; non-empty, ≤ 500 ops)
src/changes/origin.dart        sealed Origin: direct | proposal(id) | undo(changeSetId) | system; toText()/parse()
src/changes/domain_event.dart  abstract DomainEvent; ChangeSetApplied(changeSetId, origin, entities)
src/settings/settings_ops.dart sealed SettingsOp implements ChangeOp: put(key, valueJson) | reset(key); SettingsChanged
lib/testing.dart               ManualClock, SequenceIdGenerator (D20; separate library)
```

**3.2 App (`apps/mobile/lib/core/`)**
```
db/app_database.dart          @DriftDatabase(tables: [SyncState, SyncOutbox, SettingsKv], include: {'sync_triggers.drift'});
                              schemaVersion 2; migration = stepByStep(...) + beforeOpen (catalog attach, capture flag row)
db/app_database.steps.dart    generated by make-migrations
db/tables/sync_columns.dart   mixin SyncColumns (D5) + SyncMeta value (read side)
db/tables/sync_tables.dart    SyncState, SyncOutbox (local-only, no triggers)
db/tables/settings_tables.dart SettingsKv
db/sync_triggers.drift        D8 triggers for settings_kv (A06+ append their tables here)
db/migrations/from_1_to_2.dart  creates settings_kv + its 3 triggers
db/connection.dart            openUserDatabase(DatabaseLocation, CatalogPackSource) → QueryExecutor (driftDatabase + setup + interceptWith(WriteGuard))
db/write_guard.dart           WriteGuard (QueryInterceptor) + library-private zone token, runAuthorized()
db/database_location.dart     profiles/<profileKey>/user.db (D13)
db/catalog/catalog_pack_source.dart  CatalogPackSource, NoCatalogPack (D14)
db/write/row_writer.dart      RowWriter: executes RowOp → snapshot, precondition, meta stamp, write; returns RowInverse   [restricted, D12]
db/natural_id.dart           FB_NAMESPACE + uuidv5 helper (D6, package:crypto)
db/seed_rows.dart             seedRows(...) helper (D7: capture off, deterministic rows)
db/synced_tables.dart         SyncedTable<T, D>(table, entity wire name, contentColumns); registry of synced tables
db/db_providers.dart          appDatabaseProvider (sync, keepAlive, onDispose close), catalogPackSourceProvider, profileKeyProvider
changes/row_ops.dart          sealed RowOp (D1b): inert data, importable by feature handlers
changes/op_handler.dart       ChangeOpHandler<O extends ChangeOp>, ApplyContext(clock, ids, origin, today), OpPlan(rows, events), TxReader
changes/change_set_applier.dart  apply(ChangeSet) / revert(InverseChangeSet) → ApplyResult; serial queue; HLC; events after commit
changes/apply_result.dart     ApplyResult, ChangeFailure (D18), InverseChangeSet
changes/change_providers.dart changeSetApplierProvider (handlers composed in app/app_scope.dart), hlc via deviceIdStoreProvider
events/domain_event_bus.dart  DomainEventBus (D4) + domainEventBusProvider
undo/undo_stack.dart          UndoStack, UndoEntry, UndoLabel, UndoOutcome (D17) + undoStackProvider, latestUndoProvider
settings/setting_key.dart, settings_store.dart, settings_op_handler.dart (D16) + settingsStoreProvider
time/clock_provider.dart      clockProvider (overridden in app_scope with SystemClock, like idGeneratorProvider)
```
`app/app_scope.dart` adds the `clockProvider` override and composes the handler list (`[SettingsOpHandler()]`, and the diary's from A06) into the applier, because `app/` is the only layer that sees every feature barrel.

**3.3 Apply flow** (one call, `03` §5.2):
`apply(cs)` → await device ID / HLC (first time) → `db.transaction`: for each op, in order: `handler.plan(op, txReader, ctx)` → for each `RowOp`: `RowWriter.write` (inside the guard zone): read the snapshot by PK → check `expectedVersion` / existence → merge meta (`version`, `updated_hlc = hlc.now()`, `device_id`, `origin`, `created_at` on insert; `edited_by_user` carried forward unless the op sets it) → typed write (`into().insert`, `update().write` with `WHERE id=? AND version=?`, affected rows checked) → triggers write the outbox → record the inverse (first snapshot per row) → upsert `hlc.last` → commit → `db.notifyUpdates({sync_outbox})` (trigger writes are invisible to drift's stream invalidation) → `bus.emit(plan events…, ChangeSetApplied)` → `Applied(id, inverse, events)`. Any failure → rollback, no events, `Rejected(failure)`.

**3.4 Rules kept:** single writer (D11 + D12), tombstones only (`no_delete` trigger), HLC from S08 with BINARY comparison, layers (`core` imports no feature; handlers are injected by `app/`), local-first (no network anywhere here; lazy DB open), no user content in logs (failures carry entity, ID and code only, never values).

**3.5 Build/tooling:** `apps/mobile/pubspec.yaml`: `drift: 2.35.2`, `drift_flutter: 0.3.1`, `path_provider: ^2.1.5` (runtime). `sqlite3: ^3.7.1` as a **direct** dependency (the `setup` callback receives a `sqlite3` `Database`). A03's `fb_catalog` uses the same constraint, so the shared workspace lock resolves one bundled SQLite (3.54, FTS5 with trigram) for app and tools. Any `hooks: user_defines: sqlite3:` override (e.g. `source: system`) goes in the **root** `pubspec.yaml` only. Doc fix at close: `02` §1 drops `sqlite3_flutter_libs` (EOL). `crypto: ^3.0.7` (D6). `drift_dev: 2.35.1` (dev). These are exact pins for the codegen pair, like S06. `build.yaml` gains the `drift_dev` builder + options (D15). `GEN_DART_DIRS` gains `apps/mobile/lib/**/*.steps.dart`. New make target `db-migrations`. `check-dart` runs `check-frozen-migrations.sh`. Android `data_extraction_rules.xml` / `backup_rules.xml` per D21 (exclusions only).

### 4. Work packages (sequential, all `flutter-engineer`; branch `step/A01-local-data`; one Gradle/test run at a time)

| WP | Content | Files | Done when |
|---|---|---|---|
| **WP1** fb_domain change types + test support | §3.1: `ChangeOp`, `ChangeSet`, `Origin`, `DomainEvent`, `ChangeSetApplied`, `SettingsOp` + `SettingsChanged`, `testing.dart` (D20), backlog #30 ban-list fixes | `packages/fb_domain/lib/src/{changes,settings}/**`, `lib/testing.dart`, tests, README section "Change sets" | `make check-dart test-dart` green, fb_domain coverage ≥ 95%, determinism test allows `testing.dart` and no other new file |
| **WP2** drift foundation + harness | Deps (`flutter pub get` first; stop and report if the resolution fails). `SyncColumns`, sync tables, `settings_kv`, `.drift` triggers, `AppDatabase` v1 → v2 with `make-migrations` dumps + generated tests, `from_1_to_2.dart`, `connection.dart` (isolate, pragmas), `WriteGuard`, `CatalogPackSource` + attach. **Spikes, reported with evidence:** (a) the zone token reaches the interceptor through `transaction()` and the isolate client, (b) `ATTACH … mode=ro` makes a known pack table readable and rejects a write to `catalog.*` (D14 fallback if not); the zone-guard spike (a) is time-boxed to ~30 min (D11). `check-frozen-migrations.sh` + `db-migrations` target + `GEN_DART_DIRS` | `apps/mobile/{pubspec.yaml,build.yaml,drift_schemas/**,test/drift/**}`, `lib/core/db/**` (minus `write/`), `tools/scripts/check-frozen-migrations.sh`, `Makefile`, `pubspec.lock` | Migration tests green (v1→v2 with data). Trigger completeness test green. Guard + attach tests green (or the spike fallback recorded). `make gen-check` clean. **Frozen-check proof:** temporarily edit `drift_schema_v1.json` on a scratch commit → `make check-dart` fails (output in the report, then reverted) |
| **WP3** applier, row writer, undo, events | `RowOp`s, `RowWriter`, `ChangeOpHandler`/`ApplyContext`/`OpPlan`, `ChangeSetApplier` (serial queue, HLC + `hlc.last`, inverse, notifyUpdates), `ApplyResult`/`ChangeFailure`, `DomainEventBus`, `UndoStack`, `clockProvider`, providers, `app_scope` wiring. Tests use a **test-only synced table** (`test/core/changes/support/test_db.dart`, its own small drift DB with the same mixin + triggers) to cover multi-table and failure cases | `lib/core/{db/write,changes,events,undo,time}/**`, `lib/app/app_scope.dart`, tests | §5 applier, undo and event tests green. Coverage of the new `core/` code reported |
| **WP4** settings store, arch rules, backup, perf | `SettingKey`, `SettingsStore`, `SettingsOpHandler`. `app_check` rules `db-write-api`, `db-write-call` + layering (D12) with fixtures and README rows. Android backup XML (D21) + manifest comment. Host benchmark test + Patrol on-device benchmark (§5, tag `perf`) | `lib/core/settings/**`, `tools/app_check/{lib,test,README.md}`, `apps/mobile/android/app/src/main/res/xml/*.xml`, `AndroidManifest.xml` comment, `test/core/changes/apply_benchmark_test.dart`, `patrol_test/db_perf_test.dart`, `dart_test.yaml` (`perf` tag) | `make check test` green. `make apk-hardening-selftest` green. Each new app_check rule has a failing fixture. The benchmark prints median/p95 and passes on the host |

### 5. Test list
**fb_domain:** `ChangeSet rejects empty and > 500 ops` · `Origin text round trip (direct, proposal:<id>, undo:<id>, system); invalid text rejected` · `SettingsOp equality and family` · `ManualClock / SequenceIdGenerator are deterministic` · determinism test still passes, plus the #30 cases (`clock?.now()` allowed, `[.now()]` / `{.now()}` caught).

**Database & harness:**
- `migration v1→v2 keeps sync_state and sync_outbox rows and creates settings_kv` (generated verifier + data test)
- `current schema equals the latest dump` (generated)
- `AC-012 every synced table has insert/update/no-delete outbox triggers with its entity name` (completeness, D8)
- `AC-012 insert, update and tombstone each append one outbox row with the row's hlc`; `an update that doesn't change updated_hlc appends nothing`; `outbox.capture = '0' suppresses outbox rows` (A34 path); `hard DELETE on a synced table aborts`
- `write outside the applier throws UnauthorizedWriteError` (raw `into()`, `customStatement`, inside and outside `transaction()`), `reads are never blocked`
- `catalog: no pack → nothing attached`; `pack attached read-only: select from a known pack table works, insert into catalog.* fails`; `reattachCatalog swaps the file`
- `seeding appends no outbox rows; two fresh databases seed byte-identical rows`
- `natural ids: uuidv5 is deterministic, lowercase canonical, and the fb_domain default-slot literals equal the recomputed values`
- `database location: one file per profile key`; `open runs no query until first use`
- `frozen-migrations script: modified/deleted shipped file fails, added file passes` (shell test over a temp git repo, run from `make check-dart`'s self-test like the APK hardening self-test)

**Applier, undo, events** (`AI-036`, `UX-030`, `AI-048`, `AC-012` tags where they apply):
- `AI-036 a change set with several ops across two tables applies atomically` · `a failing third op rolls back the first two (rows, outbox, hlc.last) and emits no events`
- `expectedVersion mismatch → Rejected(VersionConflict) with expected and actual, nothing written`; `update of a missing id → RowNotFound`; `duplicate insert id → ConstraintViolation`
- `AC-012 meta stamped: version 1 then +1, updated_hlc strictly increasing, device_id = install id, origin text, created_at kept on update`; `edited_by_user is written only when an op sets it, and is carried forward on other updates`
- `hlc.last survives reopen; a clock moved backwards still yields a larger HLC`
- `UX-030 undo restores the exact previous state: content columns, deleted_at and edited_by_user equal the snapshot for update, tombstone and upsert`; `undo of an insert tombstones it`; `undo of a delete revives the tombstoned row`; `a row touched twice in one set restores its first snapshot`; `undo after a later change → conflict, nothing written`; `undo syncs: it appends outbox rows, origin undo:<id>`
- `UndoStack keeps 5, expires after 6 s on the ManualClock, undo twice → unknown, revert pushes no new entry`; `latestUndoProvider emits the newest entry, then null after expiry`
- `events are emitted after commit in op order, never on rollback; a throwing listener doesn't fail the apply`; `on<T>() filters by type`
- `change sets submitted concurrently apply one after another` (no interleaved snapshots)
- `settings: put/read/watch typed values; reset tombstones; SettingsChanged emitted; natural id setting:<key>; two puts → one row`

**Architecture (`tools/app_check`):** fixtures `db-write-api imported from features/x/data fails`, `db-write-call: db.into(...) in features/x/data fails; Map.update in a file without a drift import passes`, `application importing core/db fails`, `presentation importing core/changes fails`, `allow comment on these rules is invalid-allow`.

**Performance (tag `perf`):** `apply a 10-op change set (10 inserts over 2 tables): median and p95 over 200 runs after 20 warm-ups, file DB in WAL through the background isolate`. Host: asserts median < 10 ms and prints the numbers. Device: the same body in `patrol_test/db_perf_test.dart`, printing median and p95 for the A55.

### 6. Exit-criteria mapping

| Exit criterion | Shown by |
|---|---|
| Several ops apply atomically, one failure rolls everything back | The two `AI-036 … atomically` / `rolls back` tests (rows, outbox and `hlc.last` all checked) |
| Undo restores the exact previous state, including tombstoned rows | The `UX-030 undo …` group (D3 defines "exact") |
| `expectedVersion` mismatch → typed failure | `Rejected(VersionConflict)` test |
| Every synced write → outbox row; writes outside the applier fail the architecture test | Trigger completeness + per-write outbox tests; `app_check` rule fixtures (`db-write-api`, `db-write-call`) in `make check-dart`; runtime guard test |
| Migration harness green with ≥ 2 schema versions | v1/v2 dumps + generated v1→v2 tests in `make test-dart` (CI `dart` job); frozen-check proof in WP2 |
| 10-op change set < 10 ms on the A55 | Host benchmark (recorded in the Outcome). **On-device:** `make test-it` on the A55 runs `db_perf_test`, batched into the wave's owner on-device list (TD-037: doesn't block the merge; if it fails, the follow-up goes into a fix step) |

### 7. Risks & unknowns
- **Isolate round trips on the A55.** About 3 statements per row × 10 rows = ~30 messages to the isolate. If the device median goes above 10 ms: (1) prefetch the snapshots of one op with one `WHERE id IN (…)` query, (2) run the whole transaction inside the DB isolate (`computeWithDatabase`). Handlers are plain objects, so this is a contained change. The host run gives an early signal.
- **Zone token through the interceptor** (D11) is not documented. The WP2 spike answers it. If it fails, the static rules alone remain (still meets the exit criterion), and a backlog item is logged.
- **Read-only ATTACH needs URI handling** on drift's connection (D14). Spike in WP2. Fallback: A05's separate read-only connection (D14).
- **sqlite3 hook download** (prebuilt binary, hash-checked) needs the network on the first build, on the laptop and in CI. It uses the existing pub/build caches. `source: system` is the documented escape hatch for host tests if the download is ever blocked.
- **Codegen resolution** (drift_dev with analyzer 13.3, build_runner 2.16.1) was checked from the version constraints but not resolved yet. WP2 starts with `flutter pub get`. If it fails, the fallback is drift_dev 2.34.6 (the same analyzer range).
- **Natural IDs (D6):** none (UUIDv5 keeps the contract).
- **`version` is local optimistic concurrency only;** A34 decides how remote apply sets it.
- **Backup (D21):** owner question must be answered before A11 (backlog #45).
- **Freezed deviation (D1):** the card names freezed, but the ops are hand-written in `fb_domain`. A21 may revisit if the JSON boilerplate grows (a `fb_domain`-local codec, still without dependencies).

### 8. Size check
**M, upper end (~2 sessions):** WP1 ≈ 0.25, WP2 ≈ 0.6 (codegen + spikes), WP3 ≈ 0.6, WP4 ≈ 0.4, plus review and verify. If WP3 isn't finished in the first session, the seam is **A01a = WP1–2** (database, harness, triggers, guard) and **A01b = WP3–4** (applier, undo, events, settings, rules). A06 needs both.

### Plan review (architect, 2026-10-17, wave 1)
- PA1: D6 replaced (deterministic UUIDv5 natural IDs, `natural_id.dart`, `crypto`); §7 and TD-candidate line updated (TD-070).
- PA2: D7 seeds not captured (`seedRows`, `created_at = 0`); test added.
- PA3: D5 `edited_by_user` is provenance set only by ops; §3.3 and §5 test updated.
- PA4: D21 replaced (exclude `profiles/` and `catalog/` everywhere; ⚠️ OWNER question before A11; backlog #45 re-targeted).
- PA5: D14 fallback replaced (separate read-only connection); `0444` removed from §7; WP2 spike asserts a readable pack table.
- PA6: §3.5 pins `sqlite3: ^3.7.1` direct, root-only hook overrides, `02` §1 doc fix at close.
- PA7: D16 entity wire name `setting`; `SyncedTable` asserts camelCase and ≤ 64 chars.
- Suggestions adopted: D11 zone-guard spike time-boxed to ~30 min (drop if special cases); §7 note on `version` as local optimistic concurrency.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-17: Wave 1 (TD-068): plan written, architect group review approve-with-changes, amendments applied. Plan approved by the orchestrator under TD-037 (no blocking owner item). Next: implementation.

## Outcome
_Written in Phase E._
