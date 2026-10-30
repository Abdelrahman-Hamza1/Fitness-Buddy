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

## Weight trend

A14 D1–D6, D10 (WB-003–005, WB-010–012, TD-088). Code: `lib/src/body/`.
The app's `WeighInOpHandler` and the `weigh_ins` table use these; nothing
here does I/O, and the trend is derived, never stored (`05` §2.2).

- **Weigh-ins** (`WeighIn`, the read model): `EntryTime` + stored
  `localDate`, canonical `kg`, the typed `WeighInInput(value, unit)` (kg or
  lb, TD-017), an optional note and `preferredForDay`. `WeighInInput.kg`
  rounds once to storage precision (214 lb → 97.07 kg). `WeighInDraft`
  trims the note (empty → `null`); `validate()` returns a content-free
  `WeighInIssue`: unit, out of range (20–500 kg after conversion,
  `WeighInBounds.minIn/maxIn` give 20.0–500.0 kg and 44.1–1,102.3 lb), time
  (before 1970), note too long (200 code points) or invalid (`\p{Cc}`;
  `\p{Cf}` such as ZWJ and RLM is allowed). `isInFuture(nowUtc)` allows
  5 minutes of skew. These rules apply to local writes only: synced rows
  are never rejected, so `WeighIn` doesn't check `kg`.
- **Day choice** (`DayChoice.of`, WB-003): one weigh-in per `localDate`,
  the day's preferred one (the earliest preferred after a sync), else the
  earliest by measured time; ties break by ID.
- **Ops** (`sealed class WeighInOp`, family `weighIn`): `CreateWeighIn(id,
  draft)`, `UpdateWeighIn(id, expectedVersion, draft)`, `DeleteWeighIn`
  and `ChooseTrendWeighIn(day, chosen:, dayWeighIns:)`, which must list
  exactly the day's live weigh-ins at the versions shown (`chosen: null`
  goes back to the earliest).
- **Implausible values** (`WeighInCheck.check`, WB-005): first a unit
  mix-up against the nearest weigh-in in time (the number read in the other
  unit within ±5 % of it, read as typed more than 25 % away: 214 "kg" after
  97 kg suggests 214 lb), then a change of strictly more than 3 % from the
  nearest earlier weigh-in at most 7 days back (else the next one within 7
  days, for a backfill). An edit passes `editingId` so it isn't compared
  with itself. **A29 reuses `WeighInCheck` for chat and import rows.**
- **Trend** (`TrendWeight(config).compute(weighIns)`, WB-010): time-aware
  exponential smoothing over the day choices in date order. `T₁ = w₁`; a
  weigh-in `Δd` days after the previous one moves the trend by
  `α = min(1 − 2^(−Δd / 7), 0.75)` of the distance: 9.4 % for a daily
  weigh-in, 50 % for a weekly one, 75 % after 14 days or more, never all of
  it. A convex combination, so the trend stays within its inputs' range and
  a constant series stays constant. Rows without a positive finite `kg`
  are skipped. The constants live in one `TrendWeightConfig` (half-life
  7 d, cap 0.75, rate window 28 d, minimum span 14 d, stale after 28 d).
- **`trendOn(date)` holds the last value** between and after weigh-ins (a
  step function, WB-022); `null` before the first. `latest.trendKg` is the
  app's current weight (A14 PA1).
- **Weekly rate** (`asOf(date)`, WB-011): with `D` the last weigh-in day on
  or before the date, `(T(D) − T(D − 28)) / 4`; with a shorter history the
  span `s = D − first` gives `(T(D) − T₁) · 7 / s`, only when `s ≥ 14`.
  No rate when `date − D ≥ 28`, outside the last 4 weeks (`isStale`,
  PA2). Display rounding is the app's.
- **Honesty** (`WeighInCadence.of(days, today)`, WB-012): weigh-in days in
  the last 28 (today included): none at all, 1–7 sparse, 8+ frequent, 0
  with older ones stale. `CadenceTipRule.shouldShow` shows the suggestion
  only when sparse, at most once per 30 days; on the day it first shows it
  stays until dismissed (`CadenceTipState`, a display preference).
- **Shared smoothing** (`smoothDaily(dayValues, config)`, A15b D16):
  the loop above over `(date, value)` pairs with strictly increasing dates.
  `TrendWeight.compute` delegates to it with identical numbers, and the
  measurement trends reuse it.
- **For A38 (adaptive TDEE)**: take trend windows that start and end on
  weigh-in days (`points`), not on arbitrary dates, since `trendOn` is a
  step function and a window edge between weigh-ins sees a held value.

## Weight projection

A15a D7, D10 (WB-021, WB-023, TD-099 Proposed). Code: `lib/src/body/weight_graph.dart`. Derived, never stored.

- **`WeightProjection.of({trend, today, goalKg})`** returns a `WeightProjection` or `NoProjection(reason)` (`noGoal`, `stale`, `noRate`, `flat`, `awayFromGoal`, `reached`, `tooFewPoints`). Centre from the latest trend point along the weight card's weekly rate; σ the OLS slope standard error of the day choices in the 56 days ending there (floor 0.1 kg/week); `at(date)` gives lower/centre/upper = centre ± 1.28·σ·t/7, each clamped at the goal; `drawUntil` is where the slow edge reaches the goal (≤ 730 days); `reachDate` where the centre does (none past 730 days). Rate uncertainty only: never shown as a probability. Constants: `ProjectionConfig`.
- **`WeightStats.of({trend, today, history, monthTargetKgPerWeek})`**: change since the active phase's start (else the first weigh-in; a start more than 28 days after the last weigh-in uses the first trend point after it), this month's change (from the 1st, or a phase start this month), this month's target from the rate the targets show (TG-011, SF-011-capped; pro-rated when the phase started this month), and the average weekly rate after 14 days ("Average since {date}"). `toString` carries no values.

## Weight history batch

A15b D17 (WB-001, WB-003, WB-005, WB-031). Code: `lib/src/body/weigh_in_batch.dart`.

- **`WeighInBatchCheck.check({rows, existing, today, timeFor})`** checks the rows of the multi-row entry in date order. Blocking (Save disabled): `incomplete` (no date or value), `outOfRange` (20–500 kg, or before 1970), `future` (after today). Excluded until the user keeps the row: `duplicate` (a stored weigh-in, or an earlier included row, on that date within 0.05 kg) and `implausible` (`WeighInCheck` against the stored weigh-ins and the earlier included rows; a unit mix-up suggests the other unit). Info: `sameDay` (a stored weigh-in that date with another value; the row stays included). Kept rows become references for later rows.
- **Keep** stores the result's opaque `keepToken`: the flag, the row's date, value and unit, and the exact reference and finding. A Keep counts only while the token is unchanged, so editing the row, or the earlier row or stored weigh-in it was checked against, clears it.
- **`WeighInBatch.timeFor(date, clock)`**: 08:00 local (`EntryTime.fromLocal`, DST-safe); today gets the earlier of 08:00 and now. **`WeighInBatch.ops(drafts, ids)`** builds one `CreateWeighIn` per included row (1 to 500 = `ChangeSet.maxOps`); the app applies them as one change set with one undo. A29's paste import reuses both.

## Measurements

A15b D13–D16 (WB-040–042, TD-103 Proposed). Code: `lib/src/body/measurement*.dart`.

- **Kinds** (`MeasurementKind`): waist, chest, hips, arm, thigh, neck, `bodyFat` and `custom`; the codes are a closed wire enum. Every kind but body fat is a length. `MeasurementTypeRef {kind, customTypeId?}` names a series; its `key` (`waist`, `custom-<uuid>`) is for routes and providers, `parse` reads it back.
- **Input** (`MeasurementInput(value, unit)`, TD-017): cm, inches (2.54 cm) or percent; `canonical` rounds once to storage precision (36.5 in → 92.71 cm). `MeasurementDraft.validate()` returns a content-free `MeasurementIssue`: `customWithoutType` (wire rule M1), `unit` (M2: percent exactly for body fat), `outOfRange` (10–300 cm, 2–75 %; local writes only), `time` (before 1970). `isInFuture(nowUtc)` allows 5 minutes of skew.
- **Custom type names** (`CustomTypeName`): trimmed, 1–40 code points, no `\p{Cc}` (`\p{Cf}` allowed); live names are unique by `compareKey` (trimmed, lower-cased in Dart, so non-ASCII letters fold too).
- **Ops** (`sealed class MeasurementOp`, family `measurement`): `CreateMeasurement`, `UpdateMeasurement` (an identical draft writes nothing; the type can't change), `DeleteMeasurement`, `CreateMeasurementType`, `RenameMeasurementType`, `DeleteMeasurementType(type, measurements)` (exactly the type's live measurements as shown, tombstoned together).
- **Series** (`MeasurementSeries.of`, WB-041/042): every measurement is a point (by measured time); the day choice is the earliest of each date (ties by ID); the trend is `smoothDaily` over the day choices, shown only from 5 entries (points, not days). No rate, no projection. `latest`, `first` and `change` feed the header.
- `toString` never shows a value or a name.

## Progress series

A16 D4–D6, D9 (IN-002, IN-003, IN-007, IN-009, DY-004). Code: `lib/src/insights/`. Derived per read, never stored (G10). A39a's weekly summary joins this folder.

- **Series** (`ProgressSeries.build`): one `ProgressDay` per date from `from` to `min(to, today)` with the day's intake (`DayLog`: totals, entry count, incomplete mark), its `DayStatus` and its target. The target is `TargetsTimeline.day` **per date** with the same inputs as the app's `dayTargetsProvider` (the trend weight on that date, that week's earlier days, the week calendar, the training input), so a chart's target for a day is what Today shows for it. `logs` must start at the first week's start. Days before the first settings version (or without a profile) have no target.
- **Status** (`ProgressSeries.statusOf`): a mark wins (`incomplete`), then today (`inProgress`), then entries (`logged`), else `unknown` (TG-032: missing is never zero). Only `logged` days count in averages.
- **Buckets** (`ProgressBuckets.of`): ≤ 62 days → daily bars, ≤ 366 → weekly bars aligned to the week start (the first may be partial), longer → calendar months. A daily bucket keeps its day's actual intake and target whatever the status (an incomplete day draws its hatched bar, PA1); a week or month bucket averages intake, targets and nutrients over its counted days only, and is empty without one (`countedDays` / `uncountedDays` say why).
- **Goal progress** (`GoalProgress.of(phase, trend, today)`): from A15a's stale-start point (`WeightStats.startPoint`) at the phase start to the trend at `min(phase end, today)`; `fraction` toward the target weight clamped to 0…1 (moving away is 0, never negative, IN-020), null without a target or a trend or when the start is the target; `reached` at 1; `weeklyKg` after 14 days, for rate-only goals.
- `toString` never shows a value.

## Tests

Property tests use `glados` with `propertyRuns` (1,000 runs, from
`test/helpers/property.dart`); never lower it per test. `make test-dart`
fails if line coverage of `lib/` drops below 95%, and
`test/structure_test.dart` checks that the barrel exports every `lib/src`
file (coverage only sees files a test loads).

## Targets engine (A12)

`TargetProfile` accepts canonical kg/cm (use the existing `MassUnit` and
`LengthUnit` factors for imperial input). `GoalExpression` preserves the four
user expressions; `ResolvedGoal.resolve` checks direction. Monthly goals use
the full named calendar month, including leap February. `TargetCalculator`
returns numeric explanation fields and warning codes for A13's ARB strings:
requested, rate-capped and calorie-implied achievable kg/week are distinct.
Completion projections use the achievable rate and round required days upward.
Age uses evaluation year minus birth year, the precision the profile stores.
All spec13§8 defaults and four initial activity factors are in `TargetDefaults`.

`WeeklyBudget.calculate` reserves planned calories for missing/incomplete past
days, consumes actual calories only for known complete days (including explicit
zero), and allocates the remainder inside the floor and ±25% bounds. Optional
weekday weights share the same budget. `remainingWeights` represents an
unplanned workout: it affects only future allocation, preserving past unknown
day reservations. No exercise calories are added. Positive `carryKcal` means
unallocated overage; negative means unused budget. The accounting identity is
`accountedPastKcal + sum(targets) = budgetKcal + carryKcal`; past reservations
are uncertain, exposed as `unknownDates`. Targets stay unrounded until display.
Fixed mode has no weekly correction; rebalancing-off keeps the planned targets.

`MacroPlan` resolves P/F/fiber once against **base** calories and goal weight
(or current weight when no goal weight exists). Daily calories/carbs can flex;
P/F/fiber stay fixed. Overrides accept grams or base-energy percentages for
P/F/C, and grams for fiber. Fat keeps its g/kg floor. Incompatible overrides or
low shifted days expose `energyDeficitKcal`/`energyDifferenceKcal` rather than
silently rescaling fixed targets or producing negative carbs. Protein-only
mode has no fat/carbs targets. The app renders these outcomes with ARB strings.

`TargetSettingsHistory.at(date)` selects the effective revision for **each
requested date**, including midweek revisions. `TargetPlan.day` recomputes that
date's projection with the selected base and caller-supplied intake/weight.
It does not apply the newest settings retroactively to the entire week.
`TargetSettings.plan(ramadanActive: ...)` is a data hook; A41 controls activation.
An acknowledged below-floor manual target is permitted only as a fixed explicit
value. It cannot enter the weekly generator, even its fixed projection mode.

A13 owns the persistence adapters, effective-version commands through
`ChangeSetApplier`, providers, screens and warning acknowledgement UI. This
package contains no writes, I/O, UI copy or stored derived daily targets.

### A13 persistence and conflicting histories

Persist enums by `name`; encode `GoalExpression` with a stable kind tag
(`targetDate`, `targetRate`, `weekly`, `monthly`) and its fields. Encode
`MacroOverride` as `{value, isPercent}`. Retain canonical UUIDv7 row IDs and
per-row domain revisions across edits; integers are not globally unique. Domain
revisions are content fields, separate from SQLite optimistic row versions and
sync HLCs; they need their own contract schema fields when A13 adds syncing.
A13 adds these codecs/tables and sync schemas through the contract-first path.

**Never persist `TargetPlan.floorKcal`.** It is transient calculation input:
when hydrating a plan, recompute it with `TargetCalculator` using the relevant
profile/weight and evaluation date, including historical requests. Persist the
user's base target, preferences and manual acknowledgement, not derived floors
or `TargetDay`/weekly outputs. A weekly base that no longer meets a recomputed
floor must be raised to that floor when constructing the generated projection;
an acknowledged below-floor manual value remains fixed and explicitly manual.

Read histories from the current LWW row for each ID, excluding tombstones.
`TargetSettingsHistory` accepts concurrent dates/revisions; its order is
`effectiveFrom`, then revision, then UUID, with the later row winning a date.
`GoalHistory.records` preserves all current rows; `phases` is a nonoverlapping
projection: same-start rows choose revision then UUID, and a later start ends
the earlier phase on the preceding day. An earlier phase never resumes after
its successor ends. Do not persist these synthetic end dates or discard losing
rows as a side effect of reading. Sync still merges each row by its HLC; this
cross-row selection rule is only the domain read projection.

Before a local save, A13 can call `TargetSettingsHistory.validateForWrite` or
`GoalHistory.validateForWrite` on the proposed local timeline in its command
handler/preconditions, then use `ChangeSetApplier`. Never call these stricter
checks while constructing providers or importing synced rows. Conflict-bearing
existing timelines can be explicitly corrected by a user action, not silently
rewritten on reads. `monthlyKgFromWeeklyRate` converts requested or achievable
rates to the actual named month for TG-011 display.

### A13 adapter: records, wire rules and the per-date projection (A13a)

`ProfileRecord` (one natural-key row, no weight: weigh-ins are the only stored
body weight, TD-090), `GoalPhaseRecord` and `TargetSettingsRecord` are the
stored rows. Each has `toWire()` / `fromWire()` over the camelCase content
fields in `TargetWireFields` (the sync payload without its metadata; maintain
is `weekly` with `kgPerWeek` 0; `month` is written as the month's first day;
the seven shift weights are nullable, NULL = 1.0). `fromWire` returns null for
anything the wire rules reject, so a broken synced row is skipped, never
thrown. Their `toString` shows no values (body data is sensitive).

**Wire rules** (`TargetRules.wire`, shared with server admission in B19) are
listed once, in `contracts/README.md` § "Targets semantic rules"; the
contract test in the app pins the schema bounds to the Dart constants.

Plausibility ranges (age 18–100, height 100–250 cm, weights 20–500 kg, rates,
manual kcal 500–10,000, macros, shifts 1.0–2.0, names) are app-only
(`TargetRules.input`) and can change without a contract change; the handler
checks them only on fields that differ from the stored row or, for a new
settings version, from the version it supersedes (the one in effect the day
before), so a synced outlier never blocks an unrelated edit. A first row is
checked in full.

Writes are the `targets` op family (`PutProfile`, `PutGoalPhase`,
`PutTargetSettings`; a null expected version creates) with
`TargetsChanged`. For timelines the handler compares
`GoalHistory.conflicts` / `TargetSettingsHistory.conflicts` (ordered ID pairs)
before and after a write and refuses only new pairs, so conflicts that
arrived by sync never block an edit (TD-089); `validateForWrite` stays for
whole-timeline checks. `TargetSettingsRevision.next` is the D5 revision rule.

`TargetsTimeline.day` is the only place Today and Targets numbers come from:
the version effective on the date, the trend weight (else the version's
basis weight), the floor from `TargetCalculator.floor`, a below-floor base
raised unless acknowledged manual fixed (`manualNeedsReview` otherwise), an
unresolvable goal reported as `goalNeedsUpdate` instead of throwing, days with
no entries or an incomplete mark unknown (never zero), and `WeekPosition`
(eaten minus planned over the known complete earlier days; none in fixed
mode). `TargetsTimeline.explain` gives the TG-021 numbers from the version's
basis weight and effective date. Command outcomes (`TargetsOutcome`) are
content-free values for the app's `TargetsActions`.

## Food search and portions (A07 WP1)

`NameMatcher` accepts normalized query/name keys and a `FuzzyIndex`. Strengths
are ordered exact, prefix, words (good band), then fuzzy, substring, partial
(weak band). Fuzzy corrections verify rune-based OSA distance, including adjacent
transpositions. Prefixes and words under four runes skip fuzzy. The deletion
index truncates words to 12 runes, enables distance two only for 7–12 runes,
and drops distance two above 30,000 words or 400,000 deletion keys. If even
distance one exceeds that key budget, fuzzy is disabled rather than returning
an arbitrary vocabulary subset. `deletionKeyCount` and `distanceTwoEnabled`
allow the app to report counts only. WP2 builds the index in an isolate and
owns its readiness, rebuild scheduling, and retained-memory/time gates.

`SearchCandidate<T>` takes precomputed duplicate keys and a stable unique ID.
The adapter constructs `catalog:<id>` / `personal:<id>` / `dish:<dishId>` keys,
plus strict English and Arabic `name:<identityKey>|<state>|<brand or ->` keys
only when state is known. Normalize brand values consistently at that boundary.
Snapshots without pack metadata have only their identity key. This package has
no `fb_text` dependency: the app supplies `fb_text.identityKey` results.

`FoodSearchRanker.rank` merges transitive key groups before limiting to 30 rows.
The representative follows tier, recency, own match strength, default variant,
ID. Group statistics use best strength, maximum uses and latest HLC. Good rows
sort by personal, history, database, reference, then strength; weak rows sort
by strength then tier. Both break ties by uses, recency, shorter representative
name, ID. These are lexicographic priorities, not additive scores.

`DefaultPortion.choose` prefers resolvable last input, then parsed input, then
the first prioritized serving, else 100 g/ml. A parsed count without a unit uses
the default unit. `UnitOptions.of` lists resolvable servings, basis and standard
units once. `FoodHistoryItem` retains `EntryFood` (including ref version and full
provenance), original `EntryAmount`, usage and nullable pack metadata. Its
`derivedServing` reconstructs only portion units, preserving the g/ml basis.

`StateSibling.choose` accepts strict English identity keys and offers only the
requested state in the same yield group with the identical key after removing
state words. Ratios, cuts, skin and other qualifiers remain significant (PA12).
The app must also check that a yield factor is available. In particular, a
skinless raw chicken row cannot replace an unqualified roasted breast row.

`tool/` and `test/` may use `dart:io`; `lib/` may not.


## Proposal boundary and initial food drafts (A21 WP1/WP2)

`ProposalRequest` normalizes public `interpret-v1` JSON with
`InterpretationDecoder` immediately, freezing local food facts, policy and
context before `ProposalEngine.build`. Inject a `ProposalIdSource` (UUIDv7),
reference `EntryTime`, active slots and yield factors. Build returns a typed
`ProposalResult<ProposalSession>`; each meal card has rounded ingredient lines,
provenance/ranges, visible dimensions/chips, totals and **draft ops**.
Only an explicit confirm use case wraps one card’s ops in
`ChangeSet(..., origin: Origin.proposal(card.id))` and calls the app applier.
A missing/invalid input never produces executable ops.

The message shares one bounded question collection, ranked by absolute kcal
impact with stable input-order ties. Both config thresholds must be strictly
exceeded. The question cap and oil-retention policy are code constants.
`ProposalFacts.cookingFatIds` contains verified IDs; an interpretation’s own
fat-option candidates also classify cooking fats. No classification comes from
names, ID spelling or nutrient values. Local personal rows always win; an
attached pack wins for catalog keys, and an absent pack permits embedded
per-100g server facts. A missing key in an attached pack is a typed failure.

Recompute/follow-up/target projections are WP3; compact card/message-budget
restore, the read-only app loader and the evaluation facade are WP4. A21 adds
no persistence, network calls, confirmation controller or user-facing copy.
Diagnostics redact content; response JSON, food data and assumption codes are
user content and must never be logged. Synthetic public-response fixtures live
in `test/proposals/fixtures/`; properties use the existing 1,000-run helper.

### A21 proposal/evaluation and persistence seams

`ProposalEngine.build(ProposalRequest(...))` consumes the B08 v1 JSON and frozen
`ProposalFacts`, `ProposalContext`, `ProposalPolicy` and an injected UUIDv7 source.
`recompute(session, absoluteAdjustment, context: refreshedContext)` returns a
replacement session and typed `ProposalDiff`; only build/add/unmatched rebuild
allocate IDs. `rebuild(card, newRequest)` preserves matched identities and binds
the updated card to the follow-up message. The engine has no I/O or writer.

`ProposalEvaluation.evaluate(request)` calls that exact production build path.
Its result exposes the complete typed production cards/lines (FoodRef, source,
fact origin, canonical amounts, snapshots, ranges, estimate flags, assumptions,
lifecycle, preview and readiness) and the message-wide `questionCount`. B09 owns
reference scoring and population metrics. Run the minimal plain Dart entry
example with `dart run example/proposal_evaluation.dart`; inject recorded pack
facts for food evaluations. Personal rows always win; an attached pack's missing
key blocks, and embedded per-100g facts apply only when the whole pack is absent.

`ProposalDraftCodec.encodeCard(session, cardId)` returns canonical per-card state;
`encodeMessageBudget(session)` returns the one assistant-message budget. Neither
stores derived ops/totals or performs persistence. `restore(message, cards,
context: context, trustedFacts: trustedFacts)` accepts only current members
selected by `budgetMessageId`, checks revisions/ownership/lifecycle and recomputes.
Frozen time/slots/yields and
fact tables survive restoration; the caller supplies refreshed confirmed/target
context and the same normalization function. Missing rows return
`sessionIncomplete`; conflicting budgets return `budgetConflict`.

On M1→M2 follow-up, persist the changed card and M2 budget together. Also project
M1 with `encodeMessageBudget(oldSession, movedCardIds: [card.id])`: its issued
history remains, but its current membership/open questions omit the moved card.
A23 owns that transaction and recovery; A21 writes no rows. Confirm wraps only
one active card's draft ops with `Origin.proposal(card.id)`; A23 adds its resolve
op in the same ChangeSet. Personal versions are checked by the existing guard.

`syncProjection` separately encodes normalized card intents, compact draft facts
and message budget, each at most 32768 UTF-16 units (including surrogate pairs).
Its typed `syncPayloadTooLarge` leaves the local session intact. At restore,
join the decoded interpretation field back under the draft map's
`interpretation` key. Never put a second budget copy in a proposal row. A22 owns
assistant-message storage/UI; A23 owns proposal storage, migrations, atomic
resolution and B18 consumption. Superseded rows restore as historical only.

A21 public barrel surface (explicit `show`; normalized interpreter constructors
and the equality base remain internal):

`InterpretationDecoder`, `ProposalAdd`, `ProposalAdjustment`, `ProposalBuildResult`, `ProposalCard`, `ProposalChip`, `ProposalChoiceOrigin`, `ProposalComponentEffect`, `ProposalContext`, `ProposalDayContext`, `ProposalDayPreview`, `ProposalDiff`, `ProposalDimension`, `ProposalDimensionKind`, `ProposalDraftCodec`, `TrustedFoodFacts`, `ProposalEffect`, `ProposalEngine`, `ProposalEvaluation`, `ProposalEvaluationResult`, `ProposalFactOrigin`, `ProposalFacts`, `ProposalField`, `ProposalFood`, `ProposalFoodEffect`, `ProposalIdSource`, `ProposalInputException`, `ProposalIssue`, `ProposalItem`, `ProposalLifecycle`, `ProposalLine`, `ProposalOption`, `ProposalPolicy`, `ProposalQuantityEffect`, `ProposalQuestion`, `ProposalRange`, `ProposalRequest`, `ProposalResult`, `ProposalRetentionEffect`, `ProposalSelect`, `ProposalServing`, `ProposalSession`, `ProposalSetAmount`, `ProposalSetLifecycle`, `ProposalSetRemoved`, `ProposalSetWhen`, `ProposalShareEffect`, `ProposalSwap`, `ProposalSyncProjection`, `ProposalUpdate`, `ProposalUpdateResult`, `QuestionBudget`.

Intake preview `eaten` is unavailable (`null`) unless confirmed totals include
the card date. A known empty date must be supplied as `Nutrients.zero`. Target
preview also requires explicit weight; no body weight is invented.

Restore requires independently loaded `TrustedFoodFacts` (current food source/version, nutrients/measures and yield factors). Missing versions block the affected card with `staleFacts`; same-version differences use `factsMismatch`. Its preview remains read-only until rebuild; serialized claims never establish trust.
