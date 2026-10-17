# fb_domain

Pure Dart domain models, business rules and algorithms for Fitness Buddy
(see `technical-planning/03-architecture.md` §3.1).

Rules for this package:

- Pure Dart: no Flutter, no I/O (`dart:io`, `dart:ui`, `dart:ffi`,
  `dart:isolate`, `dart:html`).
- No `DateTime.now()` and no `Random`: inject a `Clock` and ID generators.
  The production ones (`SystemClock`, `secureRandom()`,
  `systemUuidV7Generator()`) live in `lib/system.dart`, which the barrel
  doesn't export; only the app's composition root imports it.
  `test/determinism_test.dart` fails if any other file uses `DateTime.now`,
  `DateTime.timestamp`, the local `DateTime(...)` constructor,
  `DateTime.parse`, `.toLocal()`, `.timeZoneOffset`, `.timeZoneName`,
  `Random(...)`, `Random.secure()`, or `fromMillisecondsSinceEpoch` without
  `isUtc: true` on the same line. Domain code uses UTC `DateTime`s only.
- Test fakes (`ManualClock`, `SequenceIdGenerator`, `utcMillis`) live in
  `lib/testing.dart`, also not exported by the barrel; tests in any package
  import `package:fb_domain/testing.dart`. They need no clock or randomness,
  so the determinism test checks that file like any other.
- No runtime dependencies unless they are added to the allowlist in
  `test/dependencies_test.dart`, which fails the build otherwise.

Run the tests with `make test-dart` from the repository root.

## Rounding rules

The one source for how numbers are rounded (S08 D1–D3, A8). Code:
`lib/src/math/rounding.dart`.

- **Numbers are `double`s** in value objects (`Mass`, `Volume`, `Length`,
  `Energy`, `Nutrients`). Nothing is rounded while computing.
- **Storage precision: 2 decimals, half away from zero**
  (`StoragePrecision.round`), applied **once**, when a value is persisted or
  snapshotted, in the unit of the persisted column: food amounts in g or ml,
  body weight in kg, measurements in cm, snapshot nutrients in kcal, g or mg.
  `x · 100` is first cleaned to 6 decimals, so binary noise never decides a
  tie: 2.675 → 2.68, 1.005 → 1.01, 0.004 → 0.
- **The original input is kept as typed** (`Quantity`: `input_amount`,
  `input_unit`) next to the canonical amount.
- **The calculator computes from the stored amount.** `NutritionCalculator`
  rounds the canonical amount to storage precision first (it is what the entry
  stores), then computes `per-100 value × amount / 100` and rounds each
  nutrient once. Recomputing from a stored entry gives the stored nutrients.
- **Yields use the exact converted amount.** Only the yield note's text is
  rounded (nearest 5 g from 50 g, else whole grams).
- **Display** (`DisplayRounding`, numbers only; the app formats the text):

  | Value | Shown as |
  |---|---|
  | kcal | whole number |
  | nutrient in g | 1 decimal below 10 g, whole from 10 g |
  | nutrient in mg | whole number |
  | food amount g / ml | whole number |
  | body weight kg / lb, oz, fl oz | 1 decimal |
  | cm, in | whole number (height in imperial: whole ft + in) |

- **Totals = display rounding of the sum of stored values**, never the sum of
  displayed values, so a day total is the same in every view.
- Unit factors (exact or label values): oz = 28.349523125 g,
  lb = 453.59237 g, fl oz = 29.5735295625 ml (US), cup = 240 ml,
  tbsp = 15 ml, tsp = 5 ml, in = 2.54 cm, ft = 12 in. Volume ↔ mass needs the
  food's density or its own serving unit; otherwise the result says so
  (`NeedsDensity`), it never guesses.

## Sanity tolerances

The FD-012 check (`SanityCheck`, `lib/src/nutrition/sanity.dart`; S08 D5,
A4). All thresholds are in one `SanityTolerance` value; A05 may tune them
after running the check over the catalog.

1. Expected kcal is computed two ways and the **closer** one is used:
   - fiber in carbs (US labels): `4·P + 4·C + 9·F + 7·alcohol`
   - fiber separate (EU labels): `4·P + 4·C + 2·fiber + 9·F + 7·alcohol`
2. **Hard fail** regardless of the deviation:
   - any value negative or not a number;
   - kcal above **920** per 100 g or ml (pure fat is 900);
   - per 100 g only: macros above **105 g**, counted with the selected
     convention (P + C + F with fiber in carbs, P + C + F + fiber otherwise).
     Not applied per 100 ml: dense liquids like honey legitimately exceed it.
3. Deviation `d = |kcal − expected|`, scale `s = max(kcal, expected)`:

   | Level | When |
   |---|---|
   | ok | `d ≤ max(15 kcal, 15% · s)` |
   | warn | `d ≤ max(30 kcal, 30% · s)` |
   | fail | otherwise |

The result carries the level, the reason, the expected kcal, the deviation
and the convention, so a review screen can highlight the values (FD-041).

## Time

S08 D7 (DY-001, DY-002, LC-021). Code: `lib/src/time/`.

- **`Clock`**: `nowUtc()` and `offsetMinutesAt(utc)`, the device zone's
  offset **at that instant**, so instants across a DST change get the right
  offset.
- **`LocalDate`**: a calendar date (years 1–9999), stored as ISO
  `YYYY-MM-DD`; `parse` is strict. `plusDays`, `daysUntil`, `epochDay`,
  `weekday` (`DayOfWeek`, ISO numbers Monday = 1 … Sunday = 7).
- **`EntryTime(occurredAtUtc, tzOffsetMin)`**: the stored pair
  (`occurred_at_utc`, `tz_offset_min`). Its `localDateTime` and `localDate`
  (`local_date`) come from the **stored** offset, never the device's current
  zone, so travelling doesn't move past entries (DY-002). `EntryTime.at` and
  `EntryTime.now` take the offset from the `Clock` for that instant. Offsets
  must be −720…+840 minutes.
- **`EntryTime.local(localDateTime, offset)`** builds the instant from a
  wall time and a given offset (edits keep the entry's stored offset:
  `withLocalTime`, `onDate`). **`EntryTime.fromLocal(localDateTime, clock)`**
  uses the device zone's offset at that instant (A06 D6). DST edges resolve
  like `java.time`: in an overlap the earlier instant, in a gap the wall time
  moves forward by the gap (02:30 in a 02:00→03:00 gap is 03:30).
- **`LocalTime`**: a time of day (`HH:MM:SS`), `minuteOfDay`, `on(date)`.
- **`localDateOf(utc, offset)`**: the diary day of an instant (DY-001): the
  local calendar day, so food after midnight, suhoor included, counts toward
  the new day.
- **`WeekCalendar(weekStart)`**: default **Saturday** (LC-021, D-070).
  `weekStartOf`, `weekOf` (start … start + 6), `daysInOrder` for headers.

## IDs and the hybrid logical clock

S08 D9, D10, A5, A6. Code: `lib/src/ids/`.

- **`UuidV7Generator(clock, random)`** (an `IdGenerator`): RFC 9562 UUIDv7,
  method 1. 48-bit Unix ms, version 7, a 12-bit counter seeded randomly with
  its top bit clear on each new ms and incremented within one ms, the RFC
  variant, 62 random bits; lowercase `8-4-4-4-12` text. IDs from one
  generator are strictly increasing (as text too): a clock that goes
  backwards reuses the last ms, and a counter overflow moves to the next ms
  and reseeds. `isUuid`, `isUuidV7`, `uuidV7Millis`.
- **`Hlc`** text form, fixed widths:
  `<wall ms, 13 digits>-<counter, 5 digits>-<device id>`, e.g.
  `1760351234567-00000-0199e3c2-5b1a-7c3d-8e4f-0123456789ab`. The device ID
  must be a lowercase canonical UUID. Text order = `compareTo` order (wall,
  counter, then device ID; ties go to the higher device ID). **Compare HLC
  columns with a binary collation**: SQLite `BINARY` (the default; never
  `NOCASE`), Postgres `COLLATE "C"` (A01, B01, B05).
- **`HybridLogicalClock(clock:, deviceId:, maxForwardDrift:, last:)`**:
  `now()` for local events, `receive(remote)` for timestamps from other
  devices, both strictly after everything seen before. `receive` returns
  `HlcReceived(hlc)`, or `HlcDriftRejected` (clock unchanged) when the remote
  wall time is more than `maxForwardDrift` (default 24 h) ahead of the
  physical clock; what sync does then is B05's policy. A counter past 99,999
  throws `HlcOverflowException`. The app passes `last` (the highest stored
  HLC) at startup so the order holds across restarts.

## Change sets

A01 D1, D4, D16. Code: `lib/src/changes/`, `lib/src/settings/`. The app's
`ChangeSetApplier` is the only writer of user data (`03` §5); this package
holds the pure values it takes and emits, so domain code (the
ProposalEngine, `buddy_eval`) can build drafts.

- **`ChangeOp`**: one intended change. Each feature owns one `sealed` op
  family that implements it and names its `family` (the key the app's
  handler is registered under). Ops are immutable values with `==`, carry
  IDs, expected versions and intent, never SQL. Hand-written, not freezed:
  this package has no runtime dependencies.
- **`ChangeSet(ops, origin:)`**: 1 to 500 ops, applied in order in one
  transaction, all or nothing. Equal when the origin and the ops in order
  are equal.
- **`Origin`** (sealed), stored on every row in its text form:
  `direct` · `proposal:<proposal id>` · `undo:<change set id>` · `system`.
  IDs are lowercase canonical UUIDs. `Origin.parse` is strict
  (`FormatException`), `tryParse` returns `null`.
- **`DomainEvent`**: the base of every event the app's `DomainEventBus`
  emits after commit. Events carry IDs and keys, never user content.
  `ChangeSetApplied(changeSetId, origin, entities)` follows the events of a
  change set's ops; `entities` are the entity wire names written.
- **`SettingsOp`**: the settings family (`settings`):
  `SettingsOp.put(key, valueJson)` and `SettingsOp.reset(key)` (back to the
  default; the row is tombstoned). Keys are dot-separated camelCase
  segments (`units.system`), because they are part of the row's natural ID
  `setting:<key>`. `valueJson` must be JSON text. `toString` shows the key,
  never the value. `SettingsChanged(keys)` is its event.

## Diary

A06 D1–D14 (DY-001–004, DY-010/011, DY-021–024, DY-032, FD-010, FD-073,
SC-4). Code: `lib/src/diary/`. The app's `DiaryOpHandler` and drift tables
use these; nothing here does I/O.

- **Slots** (`MealSlot`): `defaultKey` (default slots) or a user `name`,
  `sortOrder`, an optional `TimeWindow`, `mode` (`SlotMode.normal` /
  `ramadan`) and `active`. A `TimeWindow(startMin, endMin)` is
  `[start, end)` in minutes after local midnight (0–1439); start > end wraps
  midnight; start == end is invalid. A default slot shows the ARB label for
  its `defaultKey` until renamed (`name` is `null`).
- **`DefaultSlots`** (DY-010, A06 D8): breakfast 04:00–11:00, lunch
  11:00–16:00, dinner 16:00–22:00, snacks (no window). Their IDs are fixed
  UUIDv5 literals of `mealSlot:normal:<key>` (TD-070); the app's tests
  recompute them.
- **`SlotAssigner.assign(minuteOfDay, slots, mode)`** (DY-011, A06 D7),
  among the active slots of the mode: (1) a window containing the time,
  lowest `sortOrder` then lowest ID; (2) else a slot with no window;
  (3) else the window that started most recently (back across midnight);
  (4) else `null`. Only used when the op gives no slot.
- **Entries** (`DiaryEntry`, the read model) carry everything they show
  (FD-073): `EntryTime` + `localDate`, `slotId`, `dishGroupId?`, an
  `EntryFood` (`FoodRef`, `FoodNames` en + ar?, per-100 `Nutrients`,
  `Provenance`), an `EntryAmount` (input `Quantity`, canonical amount and
  `NutrientBasis` g/ml) and the nutrient `snapshot`. Amount edits recompute
  the snapshot from the entry's own per-100 values.
- **`FoodRef`** (A06 D3): `FoodRefKind` (`catalog` · `personal` ·
  `estimate`; `fromCode` returns `null` for a kind a newer app wrote, like
  A27's `batch`), an **opaque** ID (`null` only for an estimate) and the
  catalog pack version at log time. Never parsed or joined on.
- **`Provenance`** (FD-010, SC-4): `FoodSource` (`yours` · `database` ·
  `reference` · `estimate`, the `spec/11` §2 badges), `isEstimate`
  (implied by an estimate source), an `EstimateRange` (estimates only) and
  the assumptions.
- **Totals** (`DiaryTotals.day`, `.slot`, `.bySlot`; A06 D12, TD-048): the
  sum of the stored snapshots at storage precision, an extra only when every
  entry has it. Display rounds the total, never sums rounded values.
- **Ops** (`sealed class DiaryOp`, family `diary`): `LogEntries`
  (`NewDiaryEntry` with `EntryWhen.at` / `EntryWhen.onDay`),
  `UpdateDiaryEntry` (`EntryPatch`: amount, food, slot, local time, local
  date), `MoveEntries`, `DeleteEntries`, `CreateDishGroup`,
  `RenameDishGroup`, `MoveDishGroup`, `DeleteDishGroup`, `CopyMeal`,
  `SaveMeal` (`MealSource.slot` / `.day` / `.entries`) and `MarkDay`.
  Existing rows are addressed with `VersionedId` / `expectedVersion`.
  **New rows get their IDs in the op**, assigned when it is built, so a
  recomputed proposal keeps them and a second confirm fails as a duplicate:
  `NewDiaryEntry.id`, `CreateDishGroup.id`, `SaveMeal.savedMealId`, and
  `CopyMeal.copyIds` (source entry or group ID → copy ID, for every row
  copied). Only derived rows (saved-meal items) take IDs from the applier.
- **Events** (A06 D14): `EntriesLogged`, `EntryChanged`, `EntryDeleted`
  (entry IDs and dates) and `DayMarked(date, incomplete)`. No names, no
  numbers.
- **No user content in `toString`**: food and group names, saved-meal
  names and assumptions never appear; errors about blank names don't echo
  the text.

## Tests

Property tests use `glados` with `propertyRuns` (1,000 runs, from
`test/helpers/property.dart`); never lower it per test. `make test-dart`
fails if line coverage of `lib/` drops below 95%, and
`test/structure_test.dart` checks that the barrel exports every `lib/src`
file (coverage only sees files a test loads).
