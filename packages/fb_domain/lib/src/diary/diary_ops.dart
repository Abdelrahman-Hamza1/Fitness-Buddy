import 'package:fb_domain/src/changes/change_op.dart';
import 'package:fb_domain/src/diary/diary_entry.dart';
import 'package:fb_domain/src/diary/food_ref.dart';
import 'package:fb_domain/src/nutrition/nutrient_field.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';

/// A row ID with the version the op expects it to have (optimistic
/// concurrency: a different stored version rejects the change set).
final class VersionedId {
  /// [id] (a lowercase canonical UUID) at [expectedVersion] (≥ 1). Throws an
  /// `ArgumentError` otherwise.
  new(this.id, this.expectedVersion) {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion, 'expectedVersion');
  }

  /// The row.
  final String id;

  /// The version the row must have.
  final int expectedVersion;

  @override
  bool operator ==(Object other) =>
      other is VersionedId &&
      other.id == id &&
      other.expectedVersion == expectedVersion;

  @override
  int get hashCode => Object.hash(id, expectedVersion);

  @override
  String toString() => '$id@v$expectedVersion';
}

/// Versions of the shown source, with every referenced live group (PA8).
final class SourceVersions {
  /// No duplicate identities; an empty group list also pins absent groups.
  new({
    required Iterable<VersionedId> entries,
    Iterable<VersionedId> groups = const [],
  }) : entries = List.unmodifiable(entries),
       groups = List.unmodifiable(groups) {
    for (final list in [this.entries, this.groups]) {
      if (list.map((v) => v.id).toSet().length != list.length) {
        throw ArgumentError('duplicate source IDs');
      }
    }
  }

  /// Every shown entry.
  final List<VersionedId> entries;

  /// Every referenced live group, including groups only partly selected.
  final List<VersionedId> groups;
  @override
  bool operator ==(Object other) =>
      other is SourceVersions &&
      _sameList(entries, other.entries) &&
      _sameList(groups, other.groups);
  @override
  int get hashCode =>
      Object.hash(Object.hashAll(entries), Object.hashAll(groups));
}

/// Override absolute nutrients for one logged amount (AI-072).
final class OverrideNutrients extends DiaryOp {
  /// The shown version and at least one finite, nonnegative nutrient value.
  new(this.id, this.expectedVersion, Map<NutrientField, double> values)
    : values = Map.unmodifiable(values),
      super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion);
    NutrientOverride.checkValues(this.values);
  }

  /// Entry identity.
  final String id;

  /// Version shown in the sheet.
  final int expectedVersion;

  /// User content, never logged.
  final Map<NutrientField, double> values;
  @override
  bool operator ==(Object other) =>
      other is OverrideNutrients &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      values.length == other.values.length &&
      values.entries.every((e) => other.values[e.key] == e.value);
  @override
  int get hashCode => Object.hash(
    id,
    expectedVersion,
    Object.hashAllUnordered(
      values.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
  @override
  String toString() => 'OverrideNutrients($id@v$expectedVersion)';
}

/// When a new entry happened (A06 D6, D13).
sealed class EntryWhen {
  /// At the exact [time] (with its offset), e.g. now.
  factory at(EntryTime time) = EntryAt._;

  /// On [date] at the local [time]; without a time the handler picks one
  /// (the slot window's start, or the current local time of day when there
  /// is no slot either, A06 D6). For past days (DY-003).
  factory onDay(LocalDate date, {LocalTime? time}) = EntryOnDay._;

  const new _();
}

/// See [EntryWhen.at].
final class EntryAt extends EntryWhen {
  const new _(this.time) : super._();

  /// The instant and its offset.
  final EntryTime time;

  @override
  bool operator ==(Object other) => other is EntryAt && other.time == time;

  @override
  int get hashCode => Object.hash(EntryAt, time);

  @override
  String toString() => 'at $time';
}

/// See [EntryWhen.onDay].
final class EntryOnDay extends EntryWhen {
  const new _(this.date, {this.time}) : super._();

  /// The diary day.
  final LocalDate date;

  /// The local time, or `null` (the handler picks it).
  final LocalTime? time;

  @override
  bool operator ==(Object other) =>
      other is EntryOnDay && other.date == date && other.time == time;

  @override
  int get hashCode => Object.hash(EntryOnDay, date, time);

  @override
  String toString() => 'on $date${time == null ? '' : ' at $time'}';
}

/// One entry to log (A06 D13). Its [id] is assigned when the op is built,
/// so it stays the same when a proposal is recomputed and a second confirm
/// fails as a duplicate.
final class NewDiaryEntry {
  /// The entry [id] at [when], of [food] for [amount]. Without a [slotId]
  /// the handler picks one with the `SlotAssigner` (DY-011). A
  /// [dishGroupId] must name a group on the same date and slot. IDs are
  /// lowercase canonical UUIDs; an `ArgumentError` otherwise.
  new({
    required this.id,
    required this.when,
    required this.food,
    required this.amount,
    this.slotId,
    this.dishGroupId,
  }) {
    checkUuid(id, 'id');
    if (slotId case final slot?) checkUuid(slot, 'slotId');
    if (dishGroupId case final group?) checkUuid(group, 'dishGroupId');
  }

  /// The new entry's ID.
  final String id;

  /// When it happened.
  final EntryWhen when;

  /// The slot, or `null` for the `SlotAssigner`'s choice.
  final String? slotId;

  /// The dish group to add it to, if any.
  final String? dishGroupId;

  /// What was eaten (the handler computes the snapshot from it, A06 D4).
  final EntryFood food;

  /// How much.
  final EntryAmount amount;

  @override
  bool operator ==(Object other) =>
      other is NewDiaryEntry &&
      other.id == id &&
      other.when == when &&
      other.slotId == slotId &&
      other.dishGroupId == dishGroupId &&
      other.food == food &&
      other.amount == amount;

  @override
  int get hashCode => Object.hash(id, when, slotId, dishGroupId, food, amount);

  /// Without the food's names or values.
  @override
  String toString() => 'NewDiaryEntry($id, $when, slot ${slotId ?? 'auto'})';
}

/// The fields an entry update changes (DY-021, A06 D13). At least one.
final class EntryPatch {
  /// Changes to [amount] (the snapshot is recomputed from the per-100
  /// values), [food] (name, ref, per-100 and provenance together),
  /// [slotId], [localTime] (same date and stored offset) and [localDate]
  /// (same local time of day and stored offset). A move to another slot or
  /// date takes the entry out of its dish group (A06 D1). Throws an
  /// `ArgumentError` when nothing changes or [slotId] isn't a UUID.
  new({this.amount, this.food, this.slotId, this.localTime, this.localDate}) {
    if (amount == null &&
        food == null &&
        slotId == null &&
        localTime == null &&
        localDate == null) {
      throw ArgumentError('a patch changes at least one field');
    }
    if (slotId case final slot?) checkUuid(slot, 'slotId');
  }

  /// The new amount.
  final EntryAmount? amount;

  /// The new food.
  final EntryFood? food;

  /// The new slot.
  final String? slotId;

  /// The new local time on the same date.
  final LocalTime? localTime;

  /// The new diary day.
  final LocalDate? localDate;

  @override
  bool operator ==(Object other) =>
      other is EntryPatch &&
      other.amount == amount &&
      other.food == food &&
      other.slotId == slotId &&
      other.localTime == localTime &&
      other.localDate == localDate;

  @override
  int get hashCode => Object.hash(amount, food, slotId, localTime, localDate);

  /// The changed fields; for amount and food only that they change.
  @override
  String toString() {
    final fields = [
      if (amount != null) 'amount',
      if (food != null) 'food',
      if (slotId != null) 'slot $slotId',
      if (localTime != null) 'time $localTime',
      if (localDate != null) 'date $localDate',
    ];
    return 'EntryPatch(${fields.join(', ')})';
  }
}

/// The entries a copy or a saved meal is made from (DY-023, DY-032).
sealed class MealSource {
  /// The live entries of [slotId] on [date].
  factory slot(LocalDate date, String slotId) = MealSourceSlot._;

  /// All live entries of [date].
  factory day(LocalDate date) = MealSourceDay._;

  /// The entries [ids] (at least one, no duplicates), in this order.
  factory entries(Iterable<String> ids) = MealSourceEntries._;

  const new _();
}

/// See [MealSource.slot].
final class MealSourceSlot extends MealSource {
  new _(this.date, this.slotId) : super._() {
    checkUuid(slotId, 'slotId');
  }

  /// The day.
  final LocalDate date;

  /// The slot.
  final String slotId;

  @override
  bool operator ==(Object other) =>
      other is MealSourceSlot && other.date == date && other.slotId == slotId;

  @override
  int get hashCode => Object.hash(MealSourceSlot, date, slotId);

  @override
  String toString() => 'slot $slotId on $date';
}

/// See [MealSource.day].
final class MealSourceDay extends MealSource {
  const new _(this.date) : super._();

  /// The day.
  final LocalDate date;

  @override
  bool operator ==(Object other) =>
      other is MealSourceDay && other.date == date;

  @override
  int get hashCode => Object.hash(MealSourceDay, date);

  @override
  String toString() => 'day $date';
}

/// See [MealSource.entries].
final class MealSourceEntries extends MealSource {
  new _(Iterable<String> ids) : ids = _uniqueIds(ids, 'ids'), super._();

  /// The entries, in order. Unmodifiable.
  final List<String> ids;

  @override
  bool operator ==(Object other) =>
      other is MealSourceEntries && _sameList(other.ids, ids);

  @override
  int get hashCode => Object.hash(MealSourceEntries, Object.hashAll(ids));

  @override
  String toString() => '${ids.length} entries';
}

/// The op family of the diary (A06 D13): entries, dish groups, copies,
/// saved meals and day marks. The app's `DiaryOpHandler` turns each op
/// into row writes; the `switch` over this family is exhaustive.
///
/// New rows get their IDs in the op, assigned when it is built, so they
/// stay the same when a proposal is recomputed and a second confirm fails
/// as a duplicate. Only derived rows (saved-meal items) take IDs from the
/// applier's generator. `toString` never shows names or values.
sealed class DiaryOp implements ChangeOp {
  const new _();

  /// The [family] of every diary op.
  static const String familyName = 'diary';

  @override
  String get family => familyName;
}

/// Log new entries (DY-001, DY-003, DY-011). Emits `EntriesLogged`.
final class LogEntries extends DiaryOp {
  /// Log [entries]: at least one, no duplicate IDs. Throws an
  /// `ArgumentError` otherwise.
  new(Iterable<NewDiaryEntry> entries)
    : entries = List.unmodifiable(entries),
      super._() {
    _uniqueIds(this.entries.map((entry) => entry.id), 'entries');
  }

  /// The entries, in order. Unmodifiable.
  final List<NewDiaryEntry> entries;

  @override
  bool operator ==(Object other) =>
      other is LogEntries && _sameList(other.entries, entries);

  @override
  int get hashCode => Object.hash(LogEntries, Object.hashAll(entries));

  @override
  String toString() => 'LogEntries(${entries.map((e) => e.id).join(', ')})';
}

/// Change one entry (DY-021). Emits `EntryChanged`.
final class UpdateDiaryEntry extends DiaryOp {
  /// Apply [patch] to the entry [id] at [expectedVersion]. Throws an
  /// `ArgumentError` for an invalid ID or version.
  new(this.id, this.expectedVersion, this.patch) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion, 'expectedVersion');
  }

  /// The entry.
  final String id;

  /// The version it must have.
  final int expectedVersion;

  /// What changes.
  final EntryPatch patch;

  @override
  bool operator ==(Object other) =>
      other is UpdateDiaryEntry &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.patch == patch;

  @override
  int get hashCode => Object.hash(UpdateDiaryEntry, id, expectedVersion, patch);

  @override
  String toString() => 'UpdateDiaryEntry($id@v$expectedVersion, $patch)';
}

/// Move entries to another day and/or slot (DY-001, DY-022), out of their
/// dish groups (A06 D1). Emits `EntryChanged`.
final class MoveEntries extends DiaryOp {
  /// Move [entries] (at least one, no duplicates) to [toDate] and/or
  /// [toSlotId] (at least one). Throws an `ArgumentError` otherwise.
  new(Iterable<VersionedId> entries, {this.toDate, this.toSlotId})
    : entries = List.unmodifiable(entries),
      super._() {
    _uniqueIds(this.entries.map((entry) => entry.id), 'entries');
    _checkTarget(toDate, toSlotId);
  }

  /// The entries. Unmodifiable.
  final List<VersionedId> entries;

  /// The new day, or `null` to keep each entry's day.
  final LocalDate? toDate;

  /// The new slot, or `null` to keep each entry's slot.
  final String? toSlotId;

  @override
  bool operator ==(Object other) =>
      other is MoveEntries &&
      other.toDate == toDate &&
      other.toSlotId == toSlotId &&
      _sameList(other.entries, entries);

  @override
  int get hashCode =>
      Object.hash(MoveEntries, Object.hashAll(entries), toDate, toSlotId);

  @override
  String toString() =>
      'MoveEntries(${entries.join(', ')} → ${_target(toDate, toSlotId)})';
}

/// Delete entries (DY-022; tombstones). Emits `EntryDeleted`.
final class DeleteEntries extends DiaryOp {
  /// Delete [entries]: at least one, no duplicates. Throws an
  /// `ArgumentError` otherwise.
  new(Iterable<VersionedId> entries)
    : entries = List.unmodifiable(entries),
      super._() {
    _uniqueIds(this.entries.map((entry) => entry.id), 'entries');
  }

  /// The entries. Unmodifiable.
  final List<VersionedId> entries;

  @override
  bool operator ==(Object other) =>
      other is DeleteEntries && _sameList(other.entries, entries);

  @override
  int get hashCode => Object.hash(DeleteEntries, Object.hashAll(entries));

  @override
  String toString() => 'DeleteEntries(${entries.join(', ')})';
}

/// Create a dish group (DY-024).
final class CreateDishGroup extends DiaryOp {
  /// The new group [id] named [name] (not blank) on [date] in [slotId].
  /// Throws an `ArgumentError` otherwise.
  new({
    required this.id,
    required this.name,
    required this.date,
    required this.slotId,
  }) : super._() {
    checkUuid(id, 'id');
    checkNotBlank(name, 'name');
    checkUuid(slotId, 'slotId');
  }

  /// The new group's ID.
  final String id;

  /// The dish name. User content.
  final String name;

  /// The day.
  final LocalDate date;

  /// The slot.
  final String slotId;

  @override
  bool operator ==(Object other) =>
      other is CreateDishGroup &&
      other.id == id &&
      other.name == name &&
      other.date == date &&
      other.slotId == slotId;

  @override
  int get hashCode => Object.hash(CreateDishGroup, id, name, date, slotId);

  /// Without the name.
  @override
  String toString() => 'CreateDishGroup($id, $date, slot $slotId)';
}

/// Rename a dish group.
final class RenameDishGroup extends DiaryOp {
  /// Rename the group [id] at [expectedVersion] to [name] (not blank).
  /// Throws an `ArgumentError` otherwise.
  new(this.id, this.expectedVersion, this.name) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion, 'expectedVersion');
    checkNotBlank(name, 'name');
  }

  /// The group.
  final String id;

  /// The version it must have.
  final int expectedVersion;

  /// The new name. User content.
  final String name;

  @override
  bool operator ==(Object other) =>
      other is RenameDishGroup &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.name == name;

  @override
  int get hashCode => Object.hash(RenameDishGroup, id, expectedVersion, name);

  /// Without the name.
  @override
  String toString() => 'RenameDishGroup($id@v$expectedVersion)';
}

/// Move a dish group and all its live entries (A06 D1). Emits
/// `EntryChanged`.
final class MoveDishGroup extends DiaryOp {
  /// Move the group [id] at [expectedVersion] to [toDate] and/or
  /// [toSlotId] (at least one). Throws an `ArgumentError` otherwise.
  new(this.id, this.expectedVersion, {this.toDate, this.toSlotId}) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion, 'expectedVersion');
    _checkTarget(toDate, toSlotId);
  }

  /// The group.
  final String id;

  /// The version it must have.
  final int expectedVersion;

  /// The new day, or `null` to keep it.
  final LocalDate? toDate;

  /// The new slot, or `null` to keep it.
  final String? toSlotId;

  @override
  bool operator ==(Object other) =>
      other is MoveDishGroup &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.toDate == toDate &&
      other.toSlotId == toSlotId;

  @override
  int get hashCode =>
      Object.hash(MoveDishGroup, id, expectedVersion, toDate, toSlotId);

  @override
  String toString() =>
      'MoveDishGroup($id@v$expectedVersion → ${_target(toDate, toSlotId)})';
}

/// Delete a dish group, with or without its entries. Emits `EntryDeleted`
/// when entries go too, `EntryChanged` when they are ungrouped.
final class DeleteDishGroup extends DiaryOp {
  /// Delete the group [id] at [expectedVersion]; its live entries are
  /// deleted too when [deleteEntries], else they stay, ungrouped. Throws
  /// an `ArgumentError` for an invalid ID or version.
  new(this.id, this.expectedVersion, {this.deleteEntries = false}) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion, 'expectedVersion');
  }

  /// The group.
  final String id;

  /// The version it must have.
  final int expectedVersion;

  /// Whether its entries are deleted too.
  final bool deleteEntries;

  @override
  bool operator ==(Object other) =>
      other is DeleteDishGroup &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.deleteEntries == deleteEntries;

  @override
  int get hashCode =>
      Object.hash(DeleteDishGroup, id, expectedVersion, deleteEntries);

  @override
  String toString() =>
      'DeleteDishGroup($id@v$expectedVersion'
      '${deleteEntries ? ', with entries' : ''})';
}

/// Copy a slot, a day or some entries to another day and/or slot (DY-023,
/// DY-032, A06 D9). Copies keep the food ref, names, per-100 values,
/// snapshot, provenance and input, and the source's local time of day.
/// Emits `EntriesLogged`.
final class CopyMeal extends DiaryOp {
  /// Copy [source] to [toDate], into [toSlotId] or (when `null`) each
  /// entry's own slot. A day copy keeps the slots, so it takes no
  /// [toSlotId].
  ///
  /// [copyIds] maps every source entry and each eligible source dish
  /// group to its copy's new ID, assigned when the op is built from the
  /// entries the user saw. The handler rejects the op when a live source
  /// row has no copy ID. For an entries source, every listed ID needs one.
  /// New IDs are unique and never a source ID. Throws an `ArgumentError`
  /// otherwise.
  new(
    this.source, {
    required this.toDate,
    required Map<String, String> copyIds,
    required this.expected,
    this.toSlotId,
  }) : copyIds = Map.unmodifiable(copyIds),
       super._() {
    if (toSlotId case final slot?) {
      checkUuid(slot, 'toSlotId');
      if (source is MealSourceDay) {
        throw ArgumentError.value(slot, 'toSlotId', 'a day copy keeps slots');
      }
    }
    if (this.copyIds.isEmpty) {
      throw ArgumentError.value(copyIds, 'copyIds', 'must not be empty');
    }
    for (final MapEntry(key: from, value: to) in this.copyIds.entries) {
      checkUuid(from, 'copyIds key');
      checkUuid(to, 'copyIds value');
    }
    final sourceIds = {
      ...expected.entries.map((v) => v.id),
      ...expected.groups.map((v) => v.id),
    };
    if (!expected.entries.every((v) => this.copyIds.containsKey(v.id)) ||
        !this.copyIds.keys.every(sourceIds.contains)) {
      throw ArgumentError(
        'copyIds must contain entries and only observed source IDs',
      );
    }
    final newIds = this.copyIds.values.toSet();
    if (newIds.length != this.copyIds.length ||
        newIds.any(sourceIds.contains)) {
      throw ArgumentError('copyIds values must be unique new IDs');
    }
    if (source case MealSourceEntries(:final ids)) {
      if (!ids.every(this.copyIds.containsKey)) {
        throw ArgumentError('every source entry needs a copy ID');
      }
    }
  }

  /// What is copied.
  final MealSource source;

  /// The target day.
  final LocalDate toDate;

  /// The target slot, or `null` to keep each entry's slot.
  final String? toSlotId;

  /// Observed source versions.
  final SourceVersions expected;

  /// Source row ID → the copy's ID. Unmodifiable.
  final Map<String, String> copyIds;

  @override
  bool operator ==(Object other) =>
      other is CopyMeal &&
      other.expected == expected &&
      other.source == source &&
      other.toDate == toDate &&
      other.toSlotId == toSlotId &&
      other.copyIds.length == copyIds.length &&
      copyIds.entries.every((e) => other.copyIds[e.key] == e.value);

  @override
  int get hashCode => Object.hash(
    CopyMeal,
    expected,
    source,
    toDate,
    toSlotId,
    Object.hashAllUnordered(
      copyIds.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );

  @override
  String toString() =>
      'CopyMeal($source → ${_target(toDate, toSlotId)}, '
      '${copyIds.length} copies)';
}

/// Save a slot, a day or some entries as a saved meal (DY-023, A06 D10).
/// One item per live source entry, with its snapshot.
final class SaveMeal extends DiaryOp {
  /// Save [source] as the new saved meal [savedMealId] named [name]
  /// (1–60 characters after trimming). Throws an `ArgumentError` otherwise.
  /// The items' IDs come from the applier's generator (derived rows).
  new({
    required this.savedMealId,
    required String name,
    required this.source,
    required this.expected,
  }) : name = name.trim(),
       super._() {
    checkUuid(savedMealId, 'savedMealId');
    if (expected.groups.isNotEmpty) {
      throw ArgumentError('save expects no groups');
    }
    if (this.name.isEmpty || this.name.length > 60) {
      throw ArgumentError('name must have 1–60 characters');
    }
  }

  /// Observed entry versions.
  final SourceVersions expected;

  /// The new saved meal's ID.
  final String savedMealId;

  /// Its name. User content.
  final String name;

  /// What is saved.
  final MealSource source;

  @override
  bool operator ==(Object other) =>
      other is SaveMeal &&
      other.expected == expected &&
      other.savedMealId == savedMealId &&
      other.name == name &&
      other.source == source;

  @override
  int get hashCode =>
      Object.hash(SaveMeal, savedMealId, name, source, expected);

  /// Without the name.
  @override
  String toString() => 'SaveMeal($savedMealId, $source)';
}

/// Mark a day incomplete, or unmark it (DY-004 manual, A06 D11). The row's
/// ID is derived from the date by the handler. Emits `DayMarked`.
final class MarkDay extends DiaryOp {
  /// Set [date]'s incomplete mark to [incomplete].
  const new(this.date, {required this.incomplete}) : super._();

  /// The day.
  final LocalDate date;

  /// Whether the day is incomplete.
  final bool incomplete;

  @override
  bool operator ==(Object other) =>
      other is MarkDay && other.date == date && other.incomplete == incomplete;

  @override
  int get hashCode => Object.hash(MarkDay, date, incomplete);

  @override
  String toString() => 'MarkDay($date, incomplete: $incomplete)';
}

/// [ids] as an unmodifiable list: at least one, all UUIDs, no duplicates.
List<String> _uniqueIds(Iterable<String> ids, String name) {
  final list = List<String>.unmodifiable(ids);
  if (list.isEmpty) throw ArgumentError.value(list, name, 'must not be empty');
  for (final id in list) {
    checkUuid(id, name);
  }
  if (list.toSet().length != list.length) {
    throw ArgumentError.value(list, name, 'has duplicate IDs');
  }
  return list;
}

void _checkTarget(LocalDate? toDate, String? toSlotId) {
  if (toDate == null && toSlotId == null) {
    throw ArgumentError('a move needs a toDate or a toSlotId');
  }
  if (toSlotId case final slot?) checkUuid(slot, 'toSlotId');
}

String _target(LocalDate? toDate, String? toSlotId) =>
    [?toDate?.toString(), if (toSlotId != null) 'slot $toSlotId'].join(', ');

bool _sameList<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// Observed saved-meal membership and versions (A09 D19).
final class SavedMealVersions {
  /// A nonempty exact set of item identities.
  new({required this.meal, required Iterable<VersionedId> items})
    : items = List.unmodifiable(items) {
    if (this.items.isEmpty ||
        this.items.map((v) => v.id).toSet().length != this.items.length) {
      throw ArgumentError('invalid saved meal source');
    }
  }

  /// Shown parent row.
  final VersionedId meal;

  /// Shown item rows.
  final List<VersionedId> items;
  @override
  String toString() => 'SavedMealVersions';
  @override
  bool operator ==(Object other) =>
      other is SavedMealVersions &&
      other.meal == meal &&
      _sameList(items, other.items);
  @override
  int get hashCode =>
      Object.hash(SavedMealVersions, meal, Object.hashAll(items));
}

/// Copies the exact shown saved snapshots, without recalculation (DY-031).
final class LogSavedMeal extends DiaryOp {
  /// New IDs correspond exactly to the shown item set.
  new({
    required this.expected,
    required Map<String, String> entryIds,
    required this.when,
    this.slotId,
  }) : entryIds = Map.unmodifiable(entryIds),
       super._() {
    final sources = {expected.meal.id, ...expected.items.map((v) => v.id)};
    final items = expected.items.map((v) => v.id).toSet();
    if (this.entryIds.length != items.length ||
        !this.entryIds.keys.every(items.contains) ||
        this.entryIds.values.toSet().length != this.entryIds.length ||
        this.entryIds.values.any(sources.contains)) {
      throw ArgumentError('invalid saved meal entry IDs');
    }
    for (final id in this.entryIds.values) {
      checkUuid(id, 'entryId');
    }
    if (slotId != null) checkUuid(slotId!, 'slotId');
  }

  /// Observed source.
  final SavedMealVersions expected;

  /// Item to new entry ID.
  final Map<String, String> entryIds;

  /// Target day/time.
  final EntryWhen when;

  /// Target slot, or inferred from time.
  final String? slotId;
  @override
  String toString() => 'LogSavedMeal';
  @override
  bool operator ==(Object other) =>
      other is LogSavedMeal &&
      other.expected == expected &&
      other.when == when &&
      other.slotId == slotId &&
      entryIds.length == other.entryIds.length &&
      entryIds.entries.every((e) => other.entryIds[e.key] == e.value);
  @override
  int get hashCode => Object.hash(
    LogSavedMeal,
    expected,
    when,
    slotId,
    Object.hashAllUnordered(
      entryIds.entries.map((e) => Object.hash(e.key, e.value)),
    ),
  );
}

/// Repoints live diary and saved-item references, preserving all snapshots.
final class RelinkFoodRefs extends DiaryOp {
  /// Source and destination references.
  new({required this.from, required this.to}) : super._() {
    if (from.kind != FoodRefKind.personal ||
        to.kind != FoodRefKind.personal ||
        from.id == null ||
        to.id == null ||
        from.id == to.id) {
      throw ArgumentError('invalid personal relink');
    }
  }

  /// Match by kind and ID; catalog version is not part of the selector.
  final FoodRef from;

  /// Replacement reference, including its version.
  final FoodRef to;
  @override
  String toString() => 'RelinkFoodRefs';
  @override
  bool operator ==(Object other) =>
      other is RelinkFoodRefs && other.from == from && other.to == to;
  @override
  int get hashCode => Object.hash(RelinkFoodRefs, from, to);
}

/// Rename a saved meal at the shown version.
final class RenameSavedMeal extends DiaryOp {
  /// Trimmed name, 1–60 characters.
  new(this.id, this.expectedVersion, String name)
    : name = name.trim(),
      super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion);
    if (this.name.isEmpty ||
        this.name.length > 60 ||
        this.name.contains('\u0000')) {
      throw ArgumentError('invalid meal name');
    }
  }

  /// Parent ID.
  final String id;

  /// Shown version.
  final int expectedVersion;

  /// Private name.
  final String name;
  @override
  String toString() => 'RenameSavedMeal';
  @override
  bool operator ==(Object other) =>
      other is RenameSavedMeal &&
      other.id == id &&
      other.expectedVersion == expectedVersion &&
      other.name == name;
  @override
  int get hashCode => Object.hash(RenameSavedMeal, id, expectedVersion, name);
}

/// Tombstones a saved meal and all its live items atomically.
final class DeleteSavedMeal extends DiaryOp {
  /// Parent identity and shown version.
  new(this.id, this.expectedVersion) : super._() {
    checkUuid(id, 'id');
    checkRowVersion(expectedVersion);
  }

  /// Parent ID.
  final String id;

  /// Shown version.
  final int expectedVersion;
  @override
  String toString() => 'DeleteSavedMeal';
  @override
  bool operator ==(Object other) =>
      other is DeleteSavedMeal &&
      other.id == id &&
      other.expectedVersion == expectedVersion;
  @override
  int get hashCode => Object.hash(DeleteSavedMeal, id, expectedVersion);
}
