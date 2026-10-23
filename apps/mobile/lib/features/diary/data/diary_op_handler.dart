import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/tables/diary_tables.dart';
import 'package:fb_mobile/features/diary/data/diary_copy.dart';
import 'package:fb_mobile/features/diary/data/diary_food_columns.dart';
import 'package:fb_mobile/features/diary/data/diary_mappers.dart';
import 'package:fb_mobile/features/diary/data/diary_tx_reads.dart';

/// The row ID of the day mark of [date]: the natural ID `dayMark:<date>`
/// (A06 D11), the same on every device.
String dayMarkRowId(LocalDate date) => naturalId(dayMarkEntity, '$date');

/// Turns [DiaryOp]s into row writes (A06 D1, D4, D6, D7, D9-D11, D13, D14).
///
/// Stateless. Reads what it needs once per op with batched queries, returns
/// [RowOp]s and never writes. Rejections are typed: `RowNotFound`,
/// `VersionConflict`, and `InvalidOp` with the codes `futureDate` (DY-003),
/// `unknownSlot`, `noSlot`, `groupMismatch`, `emptySource` and
/// `missingCopyId`.
///
/// Overrides set `edited_by_user`; food changes use the chosen flag (AI-072).
/// Undoing a log or a copy emits
/// [EntryDeleted]; undoing a delete emits [EntriesLogged]; undoing a day
/// mark emits the restored mark; the rest emit the same event both ways.
final class DiaryOpHandler extends ChangeOpHandler<DiaryOp> {
  /// The handler, writing the tables of [db].
  const new(this.db);

  /// The profile's database (its tables).
  final AppDatabase db;

  @override
  String get family => DiaryOp.familyName;

  @override
  Future<OpPlan> plan(DiaryOp op, TxReader tx, ApplyContext context) {
    final reads = DiaryTxReads(db, tx);
    return switch (op) {
      LogEntries() => _log(op, reads, context),
      OverrideNutrients() => _override(op, reads),
      UpdateDiaryEntry() => _updateEntry(op, reads, context),
      MoveEntries() => _moveEntries(op, reads, context),
      DeleteEntries() => _deleteEntries(op, reads),
      MarkDay() => _markDay(op, tx, context),
      CreateDishGroup() => _createGroup(op, reads, context),
      RenameDishGroup() => _renameGroup(op, reads),
      MoveDishGroup() => _moveGroup(op, reads, context),
      DeleteDishGroup() => _deleteGroup(op, reads),
      CopyMeal() => planCopyMeal(db, op, reads, context),
      SaveMeal() => planSaveMeal(db, op, reads, context),
    };
  }

  Future<OpPlan> _log(
    LogEntries op,
    DiaryTxReads reads,
    ApplyContext context,
  ) async {
    final slots = await reads.slots();
    final slotsById = {for (final slot in slots) slot.id: slot};
    final groups = await reads.groups([
      for (final entry in op.entries) ?entry.dishGroupId,
    ]);
    final rows = <RowOp>[];
    final dates = <LocalDate>{};
    for (final entry in op.entries) {
      final group = groups[entry.dishGroupId];
      if (entry.slotId case final slot?) requireUsableSlot(slots, slot);
      final explicitSlot = entry.slotId ?? group?.slotId;
      if (explicitSlot != null && !slotsById.containsKey(explicitSlot)) {
        throw const ChangeRejected(InvalidOp('unknownSlot'));
      }
      final time = switch (entry.when) {
        EntryAt(:final time) => time,
        EntryOnDay(:final date, :final time) => _timeOnDay(
          date,
          time ?? _defaultTime(date, slotsById[explicitSlot], context),
          context,
        ),
      };
      final date = time.localDate;
      if (date.isAfter(context.today)) {
        throw const ChangeRejected(InvalidOp('futureDate'));
      }
      final slotId =
          explicitSlot ??
          const SlotAssigner().assign(
            time.localDateTime.minuteOfDay,
            slots,
            SlotMode.normal,
          ) ??
          (throw const ChangeRejected(InvalidOp('noSlot')));
      if (group != null &&
          (group.localDate != '$date' || group.slotId != slotId)) {
        throw const ChangeRejected(InvalidOp('groupMismatch'));
      }
      rows.add(
        InsertRow(
          db.diaryEntries,
          FoodColumns.of(entry.food, entry.amount).entry(
            id: entry.id,
            localDate: '$date',
            time: time,
            slotId: slotId,
            dishGroupId: entry.dishGroupId,
          ),
        ),
      );
      dates.add(date);
    }
    final ids = op.entries.map((entry) => entry.id);
    return OpPlan(
      rows,
      events: [EntriesLogged(ids, dates)],
      revertEvents: [EntryDeleted(ids, dates)],
    );
  }

  Future<OpPlan> _override(OverrideNutrients op, DiaryTxReads reads) async {
    final [row] = await reads.versionedEntries([
      VersionedId(op.id, op.expectedVersion),
    ]);
    if (row.amount <= 0) throw const ChangeRejected(InvalidOp('zeroAmount'));
    final entry = diaryEntryOf(row);
    if (row.editedByUser &&
        op.values.entries.every(
          (e) =>
              entry.snapshot.valueOf(e.key) == StoragePrecision.round(e.value),
        )) {
      return OpPlan(const []);
    }
    final Nutrients per100;
    try {
      per100 = NutrientOverride.apply(
        entry.food.per100,
        amount: row.amount,
        values: op.values,
      );
      // Domain constructors validate user input with ArgumentError.
      // ignore: avoid_catching_errors
    } on ArgumentError {
      throw const ChangeRejected(InvalidOp('outOfRange'));
    }
    final changes = FoodColumns.per100Changes(per100, entry.amount);
    final event = EntryChanged([row.id], [entry.localDate]);
    return OpPlan(
      [
        UpdateRow(
          db.diaryEntries,
          row.id,
          changes,
          expectedVersion: row.version,
        ),
      ],
      events: [event],
      revertEvents: [event],
    );
  }

  Future<OpPlan> _updateEntry(
    UpdateDiaryEntry op,
    DiaryTxReads reads,
    ApplyContext context,
  ) async {
    final [row] = await reads.versionedEntries([
      VersionedId(op.id, op.expectedVersion),
    ]);
    final patch = op.patch;
    if (patch.slotId case final slot?) await reads.requireSlot(slot);
    final changes = <Insertable<DiaryEntryRow>>[];
    if (patch.food case final food?) {
      changes.add(
        FoodColumns.of(food, patch.amount ?? _amountOf(row)).entryChanges(),
      );
    } else if (patch.amount case final amount?) {
      changes.add(
        FoodColumns.amountChanges(FoodColumns.fromEntry(row).per100, amount),
      );
    }
    final moved = _relocate(
      row,
      toDate: patch.localDate,
      toTime: patch.localTime,
      toSlotId: patch.slotId,
      today: context.today,
    );
    if (moved != null) changes.add(moved.changes);
    final leaving = {
      if (moved != null && moved.leavesGroup) row.dishGroupId!: 1,
    };
    if (changes.isEmpty) return OpPlan(const []);
    final event = EntryChanged(
      [row.id],
      [LocalDate.parse(row.localDate), ?moved?.newDate],
    );
    return OpPlan(
      [
        UpdateRow(
          db.diaryEntries,
          row.id,
          _Changes(changes),
          expectedVersion: row.version,
        ),
        ...await _tombstoneEmptied(reads, leaving),
      ],
      events: [event],
      revertEvents: [event],
    );
  }

  Future<OpPlan> _moveEntries(
    MoveEntries op,
    DiaryTxReads reads,
    ApplyContext context,
  ) async {
    final entries = await reads.versionedEntries(op.entries);
    if (op.toSlotId case final slot?) await reads.requireSlot(slot);
    final rows = <RowOp>[];
    final leaving = <String, int>{};
    final ids = <String>[];
    final dates = <LocalDate>{};
    for (final row in entries) {
      final moved = _relocate(
        row,
        toDate: op.toDate,
        toSlotId: op.toSlotId,
        today: context.today,
      );
      if (moved == null) continue;
      rows.add(
        UpdateRow(
          db.diaryEntries,
          row.id,
          moved.changes,
          expectedVersion: row.version,
        ),
      );
      if (moved.leavesGroup) {
        _count(leaving, row.dishGroupId!);
      }
      ids.add(row.id);
      dates
        ..add(LocalDate.parse(row.localDate))
        ..add(moved.newDate);
    }
    if (rows.isEmpty) return OpPlan(const []);
    final event = EntryChanged(ids, dates);
    return OpPlan(
      [...rows, ...await _tombstoneEmptied(reads, leaving)],
      events: [event],
      revertEvents: [event],
    );
  }

  Future<OpPlan> _deleteEntries(DeleteEntries op, DiaryTxReads reads) async {
    final entries = await reads.versionedEntries(op.entries);
    final leaving = <String, int>{};
    for (final row in entries) {
      if (row.dishGroupId case final group?) {
        _count(leaving, group);
      }
    }
    final ids = entries.map((row) => row.id).toList();
    final dates = entries.map((row) => LocalDate.parse(row.localDate));
    return OpPlan(
      [
        for (final row in entries)
          TombstoneRow(db.diaryEntries, row.id, expectedVersion: row.version),
        ...await _tombstoneEmptied(reads, leaving),
      ],
      events: [EntryDeleted(ids, dates)],
      revertEvents: [EntriesLogged(ids, dates)],
    );
  }

  Future<OpPlan> _markDay(MarkDay op, TxReader tx, ApplyContext context) async {
    if (op.date.isAfter(context.today)) {
      throw const ChangeRejected(InvalidOp('futureDate'));
    }
    final id = dayMarkRowId(op.date);
    final existing = await tx.liveRow(db.dayMarks, id);
    // Already as asked: nothing to write, nothing changed.
    if ((existing?.incomplete ?? false) == op.incomplete) {
      return OpPlan(const []);
    }
    return OpPlan(
      [
        UpsertRow(
          db.dayMarks,
          DayMarksCompanion(
            id: Value(id),
            localDate: Value('${op.date}'),
            incomplete: Value(op.incomplete),
            notFasting: Value(existing?.notFasting ?? false),
          ),
        ),
      ],
      events: [DayMarked(op.date, incomplete: op.incomplete)],
      revertEvents: [
        DayMarked(op.date, incomplete: existing?.incomplete ?? false),
      ],
    );
  }

  Future<OpPlan> _createGroup(
    CreateDishGroup op,
    DiaryTxReads reads,
    ApplyContext context,
  ) async {
    if (op.date.isAfter(context.today)) {
      throw const ChangeRejected(InvalidOp('futureDate'));
    }
    await reads.requireSlot(op.slotId);
    return OpPlan([
      InsertRow(
        db.dishGroups,
        DishGroupsCompanion(
          id: Value(op.id),
          name: Value(op.name),
          localDate: Value('${op.date}'),
          slotId: Value(op.slotId),
        ),
      ),
    ]);
  }

  Future<OpPlan> _renameGroup(RenameDishGroup op, DiaryTxReads reads) async {
    final group = await reads.versionedGroup(op.id, op.expectedVersion);
    return OpPlan([
      UpdateRow(
        db.dishGroups,
        group.id,
        DishGroupsCompanion(name: Value(op.name)),
        expectedVersion: group.version,
      ),
    ]);
  }

  Future<OpPlan> _moveGroup(
    MoveDishGroup op,
    DiaryTxReads reads,
    ApplyContext context,
  ) async {
    final group = await reads.versionedGroup(op.id, op.expectedVersion);
    if (op.toSlotId case final slot?) await reads.requireSlot(slot);
    final toDate = op.toDate;
    if (toDate != null && toDate.isAfter(context.today)) {
      throw const ChangeRejected(InvalidOp('futureDate'));
    }
    final oldDate = LocalDate.parse(group.localDate);
    final dateChanged = toDate != null && toDate != oldDate;
    final slotChanged = op.toSlotId != null && op.toSlotId != group.slotId;
    if (!dateChanged && !slotChanged) return OpPlan(const []);
    final members = await reads.members([group.id]);
    final rows = <RowOp>[
      UpdateRow(
        db.dishGroups,
        group.id,
        DishGroupsCompanion(
          localDate: dateChanged ? Value('$toDate') : const Value.absent(),
          slotId: slotChanged ? Value(op.toSlotId!) : const Value.absent(),
        ),
        expectedVersion: group.version,
      ),
    ];
    final dates = <LocalDate>{oldDate, ?toDate};
    for (final row in members) {
      final moved = _relocate(
        row,
        toDate: toDate,
        toSlotId: op.toSlotId,
        today: context.today,
        keepGroup: true,
      );
      if (moved == null) continue;
      rows.add(UpdateRow(db.diaryEntries, row.id, moved.changes));
      dates
        ..add(LocalDate.parse(row.localDate))
        ..add(moved.newDate);
    }
    if (members.isEmpty) return OpPlan(rows);
    final event = EntryChanged(members.map((row) => row.id), dates);
    return OpPlan(rows, events: [event], revertEvents: [event]);
  }

  Future<OpPlan> _deleteGroup(DeleteDishGroup op, DiaryTxReads reads) async {
    final group = await reads.versionedGroup(op.id, op.expectedVersion);
    final members = await reads.members([group.id]);
    final ids = members.map((row) => row.id).toList();
    final dates = members.map((row) => LocalDate.parse(row.localDate));
    final rows = <RowOp>[
      for (final row in members)
        if (op.deleteEntries)
          TombstoneRow(db.diaryEntries, row.id, expectedVersion: row.version)
        else
          UpdateRow(
            db.diaryEntries,
            row.id,
            const DiaryEntriesCompanion(dishGroupId: Value(null)),
            expectedVersion: row.version,
          ),
      TombstoneRow(db.dishGroups, group.id, expectedVersion: group.version),
    ];
    if (members.isEmpty) return OpPlan(rows);
    return op.deleteEntries
        ? OpPlan(
            rows,
            events: [EntryDeleted(ids, dates)],
            revertEvents: [EntriesLogged(ids, dates)],
          )
        : OpPlan(
            rows,
            events: [EntryChanged(ids, dates)],
            revertEvents: [EntryChanged(ids, dates)],
          );
  }

  /// Tombstones the groups that no longer have a live entry once [leaving]
  /// (group ID → entries leaving it in this op) are gone (A06 D1).
  Future<List<RowOp>> _tombstoneEmptied(
    DiaryTxReads reads,
    Map<String, int> leaving,
  ) async {
    if (leaving.isEmpty) return const [];
    final groups = await reads.groups(leaving.keys, strict: false);
    if (groups.isEmpty) return const [];
    final remaining = <String, int>{};
    for (final row in await reads.members(groups.keys)) {
      _count(remaining, row.dishGroupId!);
    }
    return [
      for (final MapEntry(:key, :value) in groups.entries)
        if ((remaining[key] ?? 0) <= leaving[key]!)
          TombstoneRow(db.dishGroups, key, expectedVersion: value.version),
    ];
  }

  /// The new place of [row] after a move or a time edit, or `null` when
  /// nothing changes. The offset stays the entry's own (A06 D6, PA5); an
  /// entry leaving its day or slot leaves its group, unless [keepGroup]
  /// (the group moves with it, A06 D1).
  _Relocation? _relocate(
    DiaryEntryRow row, {
    required LocalDate today,
    LocalDate? toDate,
    LocalTime? toTime,
    String? toSlotId,
    bool keepGroup = false,
  }) {
    if (toDate != null && toDate.isAfter(today)) {
      throw const ChangeRejected(InvalidOp('futureDate'));
    }
    final old = EntryTime(
      DateTime.fromMillisecondsSinceEpoch(row.occurredAtUtc, isUtc: true),
      row.tzOffsetMin,
    );
    final oldDate = LocalDate.parse(row.localDate);
    final time = toDate == null && toTime == null
        ? old
        : EntryTime.local(
            (toTime ?? old.localDateTime.time).on(toDate ?? oldDate),
            row.tzOffsetMin,
          );
    final newDate = time.localDate;
    final slotId = toSlotId ?? row.slotId;
    final dateChanged = newDate != oldDate;
    final slotChanged = slotId != row.slotId;
    final timeChanged = time != old;
    if (!dateChanged && !slotChanged && !timeChanged) return null;
    final leaves =
        !keepGroup && row.dishGroupId != null && (dateChanged || slotChanged);
    return (
      newDate: newDate,
      leavesGroup: leaves,
      changes: DiaryEntriesCompanion(
        localDate: dateChanged ? Value('$newDate') : const Value.absent(),
        occurredAtUtc: timeChanged
            ? Value(time.occurredAtUtc.millisecondsSinceEpoch)
            : const Value.absent(),
        slotId: slotChanged ? Value(slotId) : const Value.absent(),
        dishGroupId: leaves ? const Value(null) : const Value.absent(),
      ),
    );
  }

  EntryAmount _amountOf(DiaryEntryRow row) => EntryAmount(
    input: Quantity(row.inputAmount, row.inputUnit),
    amount: row.amount,
    basis: basisOf(row.amountBasis),
  );

  void _count(Map<String, int> counts, String key) =>
      counts[key] = (counts[key] ?? 0) + 1;

  /// The time of an entry logged on [date] without a time: the slot's
  /// default time, else now. Today never gets a time after now (a slot whose
  /// window starts later takes the current time).
  LocalTime _defaultTime(LocalDate date, MealSlot? slot, ApplyContext context) {
    final now = _localTimeNow(context);
    if (slot == null) return now;
    final slotTime = slot.defaultTime;
    return date == context.today && slotTime.compareTo(now) > 0
        ? now
        : slotTime;
  }

  /// The wall-clock time of [context]'s instant in the device zone.
  LocalTime _localTimeNow(ApplyContext context) => localDateTimeOf(
    context.nowUtc,
    context.clock.offsetMinutesAt(context.nowUtc),
  ).time;

  EntryTime _timeOnDay(LocalDate date, LocalTime time, ApplyContext context) =>
      EntryTime.fromLocal(time.on(date), context.clock);
}

typedef _Relocation = ({
  LocalDate newDate,
  bool leavesGroup,
  DiaryEntriesCompanion changes,
});

/// Several partial updates of one entry row as one.
final class _Changes implements Insertable<DiaryEntryRow> {
  const new(this.parts);

  final List<Insertable<DiaryEntryRow>> parts;

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) => {
    for (final part in parts) ...part.toColumns(nullToAbsent),
  };
}
