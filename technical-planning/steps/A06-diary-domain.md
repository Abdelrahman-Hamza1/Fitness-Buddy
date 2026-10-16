# A06 — Diary domain & storage

| Track | Depends on | Size | Owner | Status |
|---|---|---|---|---|
| App | A01 | M | Claude | ⬜ Not started |

_Old ID: S14 (renumbered by TD-063, 2026-10-16)._

**Goal.** The diary's data model and rules (entries, slots, groups, day marks, copies) as tested domain logic and drift tables, with every write going through change sets. The UI comes in A08.

**Spec:** DY-001, DY-002, DY-003, DY-004 (manual mark), DY-010 (default slots), DY-011, DY-021–024 (data side), DY-023 (copy/save data side), DY-032 (copy op), FD-010, FD-073, SC-4 · **Decisions:** TD-011, TD-017

## Scope
- **Tables:** `diary_entries`, `dish_groups`, `meal_slots` (defaults: Breakfast, Lunch, Dinner, Snacks with time windows), `day_marks`, `saved_meals` + `saved_meal_items` (data only; UI in A09).
- **Entry model:** `local_date`, `occurred_at_utc`, `tz_offset_min`, `slot_id`, `dish_group_id?`, `food_ref`, display name snapshot (EN + AR when present), input amount/unit, grams, **nutrient snapshot**, provenance fields (`05` §1).
- **ChangeOps:** create / update (amount, food, slot, time, day) / delete / move entry, create/update/delete group, copy meal (slot or day → another slot/day, DY-023/032), save meal as saved meal, mark day incomplete.
- **Domain:** `SlotAssigner` (time + windows → slot, DY-011), day totals (kcal, P, C, F, fiber), slot totals, past-day logging (DY-003), entries never move when the time zone changes (DY-002).
- **Repositories:** watch streams for a day, a slot, a date range (for charts later).
- **Domain events:** `EntriesLogged`, `EntryChanged`, `EntryDeleted`, `DayMarked`.

## Out of scope
- Search and adding foods (A07), UI (A08), batches (A27), the incomplete-day *suggestion* (A38).

## Fixed by the plan
- Nutrient snapshots at log time. Editing a food never rewrites history (FD-073).
- All writes via `ChangeSetApplier`, with undo.

## Decide in the low-level plan
- How dish groups relate to slots when entries move (move the group vs split it).
- Indexing for range queries (charts over a year).

## Exit criteria
- [ ] Unit tests: slot assignment at window edges, past-day entries, tz changes not moving entries, totals = sum of snapshots (property test).
- [ ] Data tests: each op + its undo restores the exact state. Copy produces new IDs with the same snapshots.
- [ ] Migration test from the A01 schema version.
- [ ] A day query with 30 entries < 5 ms on the A55.

## Read first
`05-data-and-sync.md` §1–2 · `spec/12-diary-meals-recipes.md` §1–4 · `03-architecture.md` §5

## Owner involvement
None.

---

## Low-level plan
_Written in Phase B (2026-10-17, wave 1, lane L) by the step-planner. **Builds on A01's plan**: op families + `ChangeOpHandler` (A01 D1), the snapshot inverse (D2/D3), deterministic UUIDv5 IDs (D6), uncaptured deterministic seeds (D7), `.drift` outbox triggers (D8), no SQL foreign keys between synced tables (D19), `ManualClock` (D20). If A01's implementation deviates from these, re-check this plan before WP2. No new dependencies._

### 1. Summary
After A06 the diary exists as data and rules, without UI. `fb_domain` holds the diary model (`MealSlot`, `FoodRef`, `DiaryEntry`), the `SlotAssigner` (DY-011), day and slot totals, the `DiaryOp` family and the diary domain events. The app holds six synced drift tables (schema v3, migrated from A01's v2, default slots seeded), read-only repositories (day, slot, date range, daily totals), and a `DiaryOpHandler` that turns every diary op into A01 row ops. So each op is atomic, undoable, syncs through the outbox, and is rejected on a version conflict. Entries carry their own name, per-100 values and nutrient snapshot, so nothing outside the entry can change a logged value (FD-073).

### 2. Decisions

| # | Decision | Reason |
|---|---|---|
| D1 | **Dish groups when entries move (card item 1): split the entry, move the group explicitly.** A group and its live entries always share `local_date` + `slot_id` (an invariant the handler enforces). Moving or re-dating **one entry** that belongs to a group takes it **out** of the group (`dish_group_id = null`). `MoveDishGroup` moves the group **and** all its live entries. When a change leaves a group with no live entries, the handler tombstones the group in the same change set (undo revives it through the snapshot) | "Move this item to lunch" means the item, and "move the maqluba" means the dish. A split never moves food the user didn't touch, and the invariant keeps DY-024's grouped display trivial |
| D2 | **Indexing (card item 2):** one partial **covering** index `ix_diary_entries_live (local_date, slot_id, kcal, protein_g, carbs_g, fat_g, fiber_g) WHERE deleted_at IS NULL`. It serves the day and slot queries by prefix; the yearly `GROUP BY local_date` / range-totals query uses it as an index-only (covering) scan. **Keep the 7-column covering index only if the host benchmark shows a need; otherwise use `(local_date, slot_id) WHERE deleted_at IS NULL`.** Plus `ix_diary_entries_group (dish_group_id) WHERE dish_group_id IS NOT NULL AND deleted_at IS NULL` and `ix_dish_groups_live (local_date) WHERE deleted_at IS NULL`. Declared in `core/db/diary.drift` (drift supports partial indexes there). Every read query includes `deleted_at IS NULL`, so the planner can use them | A heavy year is about 5,500 rows (`03` §4), so a range aggregate stays small with an index-only plan. No cache table until a chart is measured slow (`03` §4). A test checks the plans |
| D3 | **`food_ref` (seam with A05/A09/A27):** `food_kind TEXT` (`catalog` · `personal` · `estimate`; A27 adds `batch`, a text value with no migration), `food_id TEXT NULL` (an **opaque, stable** ID string; `null` only for `estimate`), `food_version TEXT NULL` (an opaque catalog pack version). For `catalog`, `food_version` = the pack's `meta.catalog_version` at log time (as text), not the row's first version (A05 D3). Nothing in the diary parses or joins on these. They're for "log again" and provenance only | The lane seam: no assumption about A05's ID scheme beyond an opaque string + kind |
| D4 | **Entries carry their values.** `name_en` (+ `name_ar?`), the input (`input_amount`, `input_unit`), the canonical `amount` + `amount_basis` (`g`/`ml`), the **per-100 snapshot** (`per100_*`, + extras JSON) and the **entry snapshot** (`kcal`, `protein_g`, `carbs_g`, `fat_g`, `fiber_g`, + `extras_json`). An amount edit recomputes the snapshot with `NutritionCalculator.forAmount(per100, amount, basis)` from the entry's own per-100 values, never by rescaling the old snapshot (no rounding drift, TD-048). A food change replaces name, ref, per-100 and provenance together | FD-073: a food edit or deletion can't reach a logged entry. The card says "grams", but a canonical amount + basis is needed for drinks logged in ml (S08 `NutrientBasis`). The 6 extra per-100 columns are what makes amount edits correct without the food |
| D5 | **Provenance (FD-010, SC-4):** `source TEXT` (`yours` · `database` · `reference` · `estimate`, the spec badge, separate from `food_kind`), `is_estimate INTEGER`, `estimate_range_json TEXT NULL` (`{lowKcal, highKcal}`), `assumptions_json TEXT NULL` (list of strings), plus A01's `origin` and `edited_by_user`. A06 ops never set `edited_by_user` (no value-override op in A06's scope; DY-021 edits amount, food, slot, time). The AI-072 override op (with its own step) sets it, and the UI shows ⓨ when it's set. `source` holds the four `spec/11` §2 values. From a catalog pack food: `usda` → `database`, `reference` → `reference` | The `05` §1 fields. The badge is stored, not derived (a catalog item can be `database` or `reference`) |
| D6 | **Time (DY-001/002/003):** `local_date`, `occurred_at_utc`, `tz_offset_min` are set **once** when the entry is created from an `EntryTime` (stored offset, S08), and are never recomputed from the device zone. A **time edit** keeps `local_date` and sets the new local time with the entry's stored offset. A **day move** keeps the local time of day on the new date. New `fb_domain` helper `EntryTime.fromLocal(LocalDateTime, Clock)`: the offset at that instant, with a second pass for DST edges. **Past days:** any date ≤ today (today in the current offset) is allowed. A **future** `local_date` → `InvalidOp('future-date')` (DY-003: planning is Later). A new entry with no time on a past day gets its slot window's start (12:00 if the slot has no window). A new entry given neither a time nor a slot on a past day takes the current local time of day (then D7 picks the slot). A day move keeps the entry's stored `tz_offset_min` (`occurred_at_utc` is recomputed from it) | Entries don't move when the user travels. Edits mean what the user sees. The future-date guard follows the spec's "Later" |
| D7 | **`SlotAssigner` (DY-011, pure):** input: local minute of day, the slots, mode (`normal`/`ramadan`). Windows are `[start, end)` in minutes 0–1439, may wrap midnight (`start > end`), and `start == end` is invalid. Rule: (1) the active slots of the mode whose window contains the time, lowest `sort_order`, tie → lowest ID. (2) Otherwise the active slot of the mode with **no** window, lowest `sort_order` (the default Snacks). (3) Otherwise the slot whose window started most recently before the time (circular). (4) No active slot → `null` (the handler rejects with `InvalidOp('no-slot')`). Used when an op leaves `slotId` empty. An explicit slot always wins (DY-011 override) | Deterministic, covers gaps and overlaps, and works for A10's custom slots and A41's Ramadan set without changes |
| D8 | **Default slots (DY-010)**, seeded by the v3 migration and by `onCreate`, with A01 D7 metadata (system origin, lowest HLC, deterministic): IDs `uuidv5(FB_NAMESPACE, 'mealSlot:normal:breakfast')` and so on (04:00–11:00, lunch 11:00–16:00, dinner 16:00–22:00, snacks no window). `DefaultSlots` in `fb_domain` holds the four precomputed UUID literals, and an app test recomputes them. Seeds go through A01's `seedRows` helper (A01 PA2: not captured into the outbox, `created_at = 0`). `default_key` = `breakfast`…, **`name` NULL**: the UI shows the ARB label for `default_key` until the user renames (A08/A10 own the strings). `mode = normal`. A41 seeds the Ramadan slots the same way (`mealSlot:ramadan:*`) | Deterministic IDs and the lowest HLC make every device seed identical rows, which converge under sync (A01 D6/D7). A NULL name keeps user-facing text in ARB. Windows follow typical Levantine meal times, and A10 lets the user change them |
| D9 | **Copy (DY-023/032):** `CopyMeal(source, toDate, toSlotId?)` with `source` = `slot(date, slotId)` · `day(date)` · `entries(ids)`. A day copy keeps each entry's slot (`toSlotId` must be null). Every copied entry and group gets a **new UUIDv7**, the **same** food ref, names, per-100, snapshot, provenance and input, the source's local time of day on `toDate` (D6), and `origin` of the change set. Groups are copied as new groups with their entries. The target must not be a future date. Undo tombstones the copies | The exit criterion "new IDs with the same snapshots". Copying values, not re-resolving foods, is what "Same as yesterday" means |
| D10 | **Saved meals (data only; UI and logging from one are A09):** `SaveMeal(savedMealId, name, source)` (same `source` shape as D9) writes one `saved_meals` row and one `saved_meal_items` row per live source entry (`sort_order`, food ref, names, input, amount + basis, per-100, snapshot, provenance). Items keep their snapshot, so a saved meal doesn't change when a food changes | DY-023 "save as saved meal", DY-031 (`05` §2.1: food ref + snapshot + amount) |
| D11 | **Day marks (DY-004 manual):** `day_marks` with ID `uuidv5(FB_NAMESPACE, 'dayMark:<YYYY-MM-DD>')` (`MarkDay` carries the date, and the handler derives the ID), `local_date`, `incomplete`, `not_fasting` (column for A41, default 0). `MarkDay(date, incomplete)` upserts. Unmarking sets `incomplete = 0` (no tombstone). Emits `DayMarked` | One row per date on every device (A01 D6). The suggestion (A38) builds the same op as a proposal |
| D12 | **Totals:** `DiaryTotals.day(entries)` and `.slot(entries, slotId)` in `fb_domain` = `Nutrients.sum` of the stored snapshots (core five; an extra only when every entry has it, S08 D16). Display rounding stays S08's (round the sum, never sum rounded values). For ranges, `watchDailyTotals(from, to)` is the indexed SQL `SUM … GROUP BY local_date` (D2) returning stored-precision sums. A data test proves it equals the domain sum for the same rows | The card's "totals = sum of snapshots". Charts (A16) get the SQL aggregate (`03` §4) |
| D13 | **Ops (`sealed class DiaryOp implements ChangeOp`, family `diary`, in `fb_domain`):** `LogEntries(List<NewDiaryEntry>)` · `UpdateDiaryEntry(id, expectedVersion, EntryPatch{amount?, food?, slotId?, localTime?, localDate?})` · `MoveEntries(List<VersionedId>, toDate?, toSlotId?)` · `DeleteEntries(List<VersionedId>)` · `CreateDishGroup(id, name, date, slotId)` · `RenameDishGroup(id, expectedVersion, name)` · `MoveDishGroup(id, expectedVersion, toDate?, toSlotId?)` · `DeleteDishGroup(id, expectedVersion, {deleteEntries})` · `CopyMeal` (D9) · `SaveMeal` (D10) · `MarkDay` (D11). IDs of new rows come in the op (the caller's `IdGenerator`), except copies, whose IDs the handler draws from `ApplyContext.ids`. `NewDiaryEntry` gets `EntryWhen.at(EntryTime)` or `EntryWhen.onDay(date, time?)`, an optional `slotId` (null → D7), an optional `dishGroupId` (the group must exist and match date + slot, else `InvalidOp('group-mismatch')`), and a `FoodRef` + names + `Quantity` + canonical amount + per-100 + provenance. The handler computes the snapshot (D4) | Covers every op on the card. One family, so the handler's `switch` is exhaustive. Slot customization ops (add/rename/reorder/window) belong to A10, batches to A27 |
| D14 | **Events (`fb_domain`):** `EntriesLogged(entryIds, dates)` (log + copy), `EntryChanged(entryIds, dates)` (update, move, group move/ungroup; dates = old ∪ new), `EntryDeleted(entryIds, dates)` (delete, group delete with entries), `DayMarked(date, incomplete)`. They carry only IDs and dates, never food names or numbers | The card's four events. The minimal payload keeps memory (AI-081) and the notification planner reading from the DB, and nothing sensitive goes on the bus |

No ⚠️ OWNER items: no spec change, no Accepted TD change, no new dependency. **TD candidate:** D1 (group invariant + split rule) is small and can live in `05` §2.1 instead of a TD. The orchestrator decides at close.

### 3. Design

**3.1 `fb_domain`** (`src/diary/`, exported; pure)
```
meal_slot.dart      MealSlot(id, defaultKey?, name?, sortOrder, window: TimeWindow?, mode, active); TimeWindow(startMin, endMin)
                    (validation, contains(min) incl. wrap); SlotMode {normal, ramadan}; DefaultSlots (D8 table)
slot_assigner.dart  SlotAssigner.assign(minuteOfDay, slots, mode) → String? slotId (D7)
food_ref.dart       FoodRefKind {catalog, personal, estimate} (+ unknown-code guard), FoodRef(kind, id?, version?)
provenance.dart     FoodSource {yours, database, reference, estimate}, EstimateRange, Provenance(source, isEstimate, range?, assumptions)
diary_entry.dart    DiaryEntry (read model: id, version, EntryTime, localDate, slotId, groupId?, FoodRef, names, input Quantity,
                    amount + basis, per100 Nutrients, snapshot Nutrients, Provenance); DishGroup; DayMark
totals.dart         DiaryTotals.day / .slot (D12)
diary_ops.dart      sealed DiaryOp + NewDiaryEntry, EntryWhen, EntryPatch, VersionedId, MealSource (D13)
diary_events.dart   EntriesLogged, EntryChanged, EntryDeleted, DayMarked (D14)
src/time/local_time.dart  + EntryTime.fromLocal(LocalDateTime, Clock) (D6)
```

**3.2 Tables** (`apps/mobile/lib/core/db/tables/diary_tables.dart`, all `with SyncColumns`, wire entity names in brackets; no FKs, A01 D19)

| Table [entity] | Columns (besides A01 D5's sync columns) |
|---|---|
| `meal_slots` [`mealSlot`] | `default_key TEXT NULL`, `name TEXT NULL`, `sort_order INTEGER`, `window_start_min INTEGER NULL`, `window_end_min INTEGER NULL` (both or neither, CHECK 0–1439, start ≠ end), `mode TEXT` (CHECK normal/ramadan), `active INTEGER` |
| `dish_groups` [`dishGroup`] | `name TEXT`, `local_date TEXT`, `slot_id TEXT` |
| `diary_entries` [`diaryEntry`] | `local_date TEXT` (YYYY-MM-DD), `occurred_at_utc INTEGER` (ms), `tz_offset_min INTEGER` (CHECK −720…840), `slot_id TEXT`, `dish_group_id TEXT NULL`, `food_kind TEXT`, `food_id TEXT NULL`, `food_version TEXT NULL`, `name_en TEXT`, `name_ar TEXT NULL`, `input_amount REAL`, `input_unit TEXT`, `amount REAL`, `amount_basis TEXT` (CHECK g/ml), `per100_kcal/protein_g/carbs_g/fat_g/fiber_g REAL`, `per100_extras_json TEXT NULL`, `kcal/protein_g/carbs_g/fat_g/fiber_g REAL` (CHECK ≥ 0), `extras_json TEXT NULL`, `source TEXT`, `is_estimate INTEGER`, `estimate_range_json TEXT NULL`, `assumptions_json TEXT NULL` |
| `day_marks` [`dayMark`] | `local_date TEXT`, `incomplete INTEGER`, `not_fasting INTEGER DEFAULT 0` |
| `saved_meals` [`savedMeal`] | `name TEXT` |
| `saved_meal_items` [`savedMealItem`] | `saved_meal_id TEXT`, `sort_order INTEGER`, then the entry's food/name/input/amount/per-100/snapshot/provenance columns (no time, slot or group) |

`core/db/diary.drift`: D2 indexes + `ix_saved_meal_items_meal (saved_meal_id) WHERE deleted_at IS NULL`. `core/db/sync_triggers.drift`: three triggers per new table (A01 D8; the completeness test fails until they're there). Migration **v3**: `migrations/from_2_to_3.dart` creates the tables, indexes and triggers and seeds D8. `onCreate` uses the same seed function. The schema dump `drift_schema_v3.json` is added by `make db-migrations`. v1/v2 files are untouched (frozen check).

**3.3 App feature `features/diary/`** (barrel `diary.dart` exports the repository providers and the handler for `app/`)
```
data/diary_repository.dart   diaryRepositoryProvider (lives here so `application/` never imports `core/db/`, A01 D12);
                             DiaryRepository (read-only, A01 D12): watchDay(date) → DiaryDay(slots, groups, entries, mark),
                             watchSlot(date, slotId), watchEntries(from, to), watchDailyTotals(from, to), watchSlots(mode),
                             watchDayMarks(from, to); row ↔ fb_domain mapping in data/diary_mappers.dart
data/diary_reads.dart        the same queries as one-shot reads, used by the handler inside the transaction (TxReader)
data/diary_op_handler.dart   DiaryOpHandler implements ChangeOpHandler<DiaryOp>: validates (D1 invariant, D6 future date,
                             group match, slot exists and is active), resolves slots (D7) and times (D6), computes snapshots (D4),
                             emits A01 RowOps + D14 events
application/diary_providers.dart  dayProvider(date), dayTotalsProvider(date) (DiaryTotals over watchDay), built on the data provider
```
`app/app_scope.dart` adds `DiaryOpHandler` to the applier's handler list. Data flow: command (A07/A08/A21) → `ChangeSet([DiaryOp…])` → applier → handler → rows → triggers/outbox → drift streams → `dayProvider` → UI (A08). Layering: the handler and repository live in `data/` (they read drift), `application/` imports only `data/` providers (A01 D12), and nothing in `features/diary` writes SQL (A01 `db-write-call` rule + guard).

### 4. Work packages (sequential, all `flutter-engineer`; branch `step/A06-diary-domain` from `main` **after A01 merges**)

| WP | Content | Files | Done when |
|---|---|---|---|
| **WP1** diary domain in `fb_domain` | §3.1: models, `TimeWindow`, `SlotAssigner`, `DefaultSlots`, `FoodRef`, provenance, `DiaryTotals`, `DiaryOp` family + value types, events, `EntryTime.fromLocal`. Property tests | `packages/fb_domain/lib/src/diary/**`, `src/time/local_time.dart`, tests, README section "Diary" | `make check-dart test-dart` green, fb_domain coverage ≥ 95%, property tests at 1,000 runs |
| **WP2** tables, migration v3, repositories | §3.2 tables + `.drift` indexes/triggers, `from_2_to_3.dart` + seeds, `make db-migrations` (v3 dump + generated tests), `DiaryRepository`/`DiaryReads`/mappers, providers, query-plan test, host day-query benchmark + Patrol on-device benchmark | `lib/core/db/{tables/diary_tables.dart,diary.drift,sync_triggers.drift,app_database.dart,migrations/from_2_to_3.dart}`, `drift_schemas/drift_schema_v3.json`, `test/drift/**`, `lib/features/diary/{diary.dart,data/,application/}`, tests, `patrol_test/diary_perf_test.dart` | v2→v3 migration test green (with a v2 setting row). Trigger completeness green. Repository tests green. `make gen-check` clean. Frozen check green (v1/v2 untouched). Benchmark printed |
| **WP3** handler: entry ops + day marks | `DiaryOpHandler` for `LogEntries`, `UpdateDiaryEntry`, `MoveEntries`, `DeleteEntries`, `MarkDay`, with D1/D4/D6/D7 rules and D14 events; `app_scope` registration | `lib/features/diary/data/diary_op_handler.dart`, `lib/app/app_scope.dart`, tests | Each op's apply + undo data tests green (§5) |
| **WP4** handler: groups, copy, save | `CreateDishGroup`, `RenameDishGroup`, `MoveDishGroup`, `DeleteDishGroup`, `CopyMeal`, `SaveMeal`; empty-group cleanup | same handler file (+ `diary_copy.dart` if it grows), tests | §5 group/copy/save tests green. `make check test` and `make trace` green, with the step's spec IDs listed as tested |

### 5. Test list
**fb_domain (WP1)**
- `DY-011 slot by time at window edges: 10:59 → breakfast, 11:00 → lunch, 15:59 → lunch, 16:00 → dinner, 22:00 → snacks, 03:59 → snacks`
- `DY-011 a wrapping window (22:00–02:00) contains 23:30 and 01:00, not 02:00`; `overlapping windows → the lower sort_order`; `inactive and other-mode slots are ignored`; `no window match and no windowless slot → the most recently started window`; `no active slot → null`; `invalid windows rejected (start == end, out of range, only one bound)`
- `property: SlotAssigner always returns an active slot of the mode when one exists, and is the same for the same input` (1,000 runs)
- `DY-010 the default slots are Breakfast, Lunch, Dinner, Snacks with the D8 windows and natural IDs`
- `DY-002 EntryTime.fromLocal uses the offset at that instant; DST gap and overlap resolve deterministically`; `DY-002 a stored entry's local date and time don't change when the clock's zone changes`
- `DY-001 an entry at 00:30 (and suhoor at 03:30) belongs to the new calendar day`
- `totals: day totals = Nutrients.sum of snapshots`; `property: day totals equal the sum of slot totals and are order-independent (within 0.01)` (1,000 runs); `an extra is totalled only when every entry has it`
- `DiaryOp value equality; family is 'diary'`; `NewDiaryEntry rejects a negative or non-finite amount`

**Data (WP2–4), each against an in-memory DB with A01's applier, `ManualClock` and `SequenceIdGenerator`.** "Undo restores the exact state" = the A01 D3 comparison over every diary table (content columns, `deleted_at`, `edited_by_user`):
- `migration v2→v3 keeps the v2 setting and seeds the four default slots`; generated `v3 schema equals the dump`; `AC-012 outbox triggers exist for all six diary tables`
- `DY-003 LogEntries on a past day stores that local_date`; `DY-003 a new entry with neither time nor slot on a past day takes the current local time of day, then D7 picks the slot`; `DY-022 a day move keeps the entry's stored tz_offset_min and recomputes occurred_at_utc`; `DY-003 a future local_date → InvalidOp(future-date)`; `DY-011 LogEntries without slotId uses SlotAssigner; an explicit slotId wins`; `FD-010 / SC-4 the source badge and provenance are stored and read back`; `LogEntries + undo` (the rows end tombstoned)
- `DY-021 UpdateDiaryEntry amount recomputes the snapshot from the stored per-100 values (no drift after 10 edits)`; `… food replaces ref, names, per-100, provenance`; `… slot`; `… time keeps local_date`; `… day keeps the local time of day`; each `+ undo restores the exact state`; `stale expectedVersion → VersionConflict`
- `FD-073 an entry's values never change when another entry with the same food_id is edited, and no read joins a food table`
- `DY-022 DeleteEntries tombstones + undo revives`; `DY-022 MoveEntries to another slot + undo`
- `DY-024 D1: moving a grouped entry takes it out of the group; the last entry leaving tombstones the group; undo restores both`; `MoveDishGroup moves the group and its live entries + undo`; `DeleteDishGroup with and without entries + undo`; `LogEntries into a group of another slot → InvalidOp(group-mismatch)`
- `DY-023 / DY-032 CopyMeal slot → another day: new IDs, same snapshots, names, per-100, provenance, source time of day`; `copy a day keeps each slot`; `copy copies groups as new groups`; `copy + undo tombstones the copies only`; `copy to a future date rejected`
- `DY-023 SaveMeal writes a saved meal with one item per live entry, snapshots equal`; `+ undo`
- `DY-004 MarkDay incomplete, then unmark: one row with the derived dayMark ID; DayMarked emitted; + undo`
- `events: each op emits its D14 event with IDs and dates only, after commit`
- `repository: watchDay emits again after an apply; excludes tombstoned rows; watchDailyTotals equals DiaryTotals.day for the same rows; watchEntries(range) is ordered by local_date, occurred_at_utc`
- `index: EXPLAIN QUERY PLAN of the day query uses ix_diary_entries_live; the range-totals query uses it as a COVERING index`

**Performance (tag `perf`)**: `day query with 30 entries in a 5,500-entry year < 5 ms`: median and p95 over 200 runs of the `watchDay` query body (first emission) through the background isolate on a file DB. The host asserts and prints. The same body runs in `patrol_test/diary_perf_test.dart` on the A55. Also printed, not asserted: `yearly daily-totals query` timing.

### 6. Exit-criteria mapping

| Exit criterion | Shown by |
|---|---|
| Unit tests: slot edges, past days, tz changes, totals property | WP1 `DY-011 …`, `DY-003 …`, `DY-002 …`, totals property tests |
| Each op + undo restores the exact state; copy gives new IDs with the same snapshots | WP3/WP4 per-op `+ undo` tests; `DY-023 / DY-032 CopyMeal …` |
| Migration test from the A01 schema version | Generated v2→v3 verifier + `migration v2→v3 keeps the v2 setting and seeds the defaults` |
| A day query with 30 entries < 5 ms on the A55 | Host benchmark (recorded in the Outcome). On-device `diary_perf_test` batched into the wave's owner on-device list (TD-037: doesn't block the merge) |

### 7. Risks & unknowns
- **A01 lands differently** (op handler API, natural IDs, migration layout). Mitigation: A06 starts from merged A01. WP2's brief re-reads A01's Outcome and adapts names, not the design.
- **Isolate latency on the A55** for the day query (one query plus mapping 30 rows). If > 5 ms: select only the needed columns, and if still slow, map in the DB isolate. The host number is an early signal.
- **Deterministic seeds:** none for B05 (UUIDv5 IDs keep the contract, A01 PA1). Seeds are not captured, so nothing is pushed until a real edit.
- **Default slot windows** (D8) are a product guess. They're editable in A10, so no spec change. Owner FYI in the plan summary.
- **DST `fromLocal`**: Palestine has DST, so the gap/overlap rule is pinned by tests. The S08 clock contract (`offsetMinutesAt`) is enough.
- **Forward notes:** A08 shows `default_key` labels from ARB when `name` is NULL and wires A01's undo hook. A09 logs a saved meal with `LogEntries`. A10 owns slot customization ops on `meal_slots`. A27 adds `food_kind = batch` + `batch_portion_id` (migration). A38 reads `watchDayMarks`. A41 seeds `slot:ramadan:*` and uses `not_fasting`. AI-072 override op sets `edited_by_user`.

### 8. Size check
**M (~1.5–2 sessions):** WP1 ≈ 0.4, WP2 ≈ 0.5, WP3 ≈ 0.4, WP4 ≈ 0.4, plus review and verify. If WP4 doesn't fit, the seam is **A06a = WP1–3** (entries, slots, marks, totals: everything A07/A08 need first) and **A06b = WP4** (groups, copy, save meal: needed by A08's group display and A09).

### Plan review (architect, 2026-10-17, wave 1)
- PA1: `diaryRepositoryProvider` moved to `data/diary_repository.dart`; `application/` keeps only `dayProvider` and `dayTotalsProvider`.
- PA2: D8/D11 IDs are UUIDv5 (`DefaultSlots` literals + recompute test; handler derives dayMark ID); seeds via `seedRows`; test renamed.
- PA3: D5 A06 ops never set `edited_by_user`; `source` mapping from catalog; §7 forward note added.
- PA4: D2 covering claim limited to totals; index test replaced; 7-column index kept only if the benchmark shows a need.
- PA5: D6 edge cases appended (no time and no slot on a past day; day move keeps `tz_offset_min`); two tests added.
- PA6: D3 `food_version` = pack `catalog_version` at log time.

## Progress log
_One dated line per event, newest last (process §8a)._
- 2026-10-17: Wave 1 (TD-068): plan written, architect group review approve-with-changes, amendments applied. Plan approved by the orchestrator under TD-037 (no blocking owner item). Next: implementation.

## Outcome
_Written in Phase E._
