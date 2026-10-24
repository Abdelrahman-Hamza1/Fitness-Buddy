import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/diary_tables.dart';
import 'package:fb_mobile/core/db/tables/food_tables.dart';
import 'package:fb_mobile/features/diary/data/diary_food_columns.dart';
import 'package:fb_mobile/features/diary/data/diary_tx_reads.dart';

Future<SavedMealRow> _meal(
  AppDatabase db,
  TxReader tx,
  String id,
  int version,
) async {
  final row = await tx.liveRow(db.savedMeals, id);
  if (row == null) {
    throw ChangeRejected(RowNotFound(entity: savedMealEntity, id: id));
  }
  checkVersion(savedMealEntity, id, row.version, version);
  return row;
}

Future<List<SavedMealItemRow>> _items(AppDatabase db, TxReader tx, String id) =>
    (tx.db.select(db.savedMealItems)
          ..where((t) => t.savedMealId.equals(id) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();

/// Checks the parent and exact item set before planning any inserts (PA1).
Future<OpPlan> planLogSavedMeal(
  AppDatabase db,
  LogSavedMeal op,
  DiaryTxReads reads,
  ApplyContext context,
) async {
  await _meal(
    db,
    reads.tx,
    op.expected.meal.id,
    op.expected.meal.expectedVersion,
  );
  final items = await _items(db, reads.tx, op.expected.meal.id);
  if (items.isEmpty) throw const ChangeRejected(InvalidOp('emptySource'));
  final expected = {for (final v in op.expected.items) v.id: v.expectedVersion};
  if (items.length != expected.length ||
      items.any((r) => !expected.containsKey(r.id))) {
    throw const ChangeRejected(InvalidOp('sourceChanged'));
  }
  for (final row in items) {
    checkVersion(savedMealItemEntity, row.id, row.version, expected[row.id]!);
  }
  final slots = await reads.slots();
  final slot = op.slotId == null ? null : requireUsableSlot(slots, op.slotId!);
  final now = localDateTimeOf(
    context.nowUtc,
    context.clock.offsetMinutesAt(context.nowUtc),
  ).time;
  final time = switch (op.when) {
    EntryAt(:final time) => time,
    EntryOnDay(:final date, :final time) => EntryTime.fromLocal(
      (time ??
              (date == context.today &&
                      slot != null &&
                      slot.defaultTime.compareTo(now) > 0
                  ? now
                  : slot?.defaultTime ?? now))
          .on(date),
      context.clock,
    ),
  };
  if (time.localDate.isAfter(context.today)) {
    throw const ChangeRejected(InvalidOp('futureDate'));
  }
  final slotId =
      op.slotId ??
      const SlotAssigner().assign(
        time.localDateTime.minuteOfDay,
        slots,
        SlotMode.normal,
      );
  if (slotId == null) throw const ChangeRejected(InvalidOp('noSlot'));
  final ids = [for (final row in items) op.entryIds[row.id]!];
  final dates = [time.localDate];
  try {
    return OpPlan(
      [
        for (final row in items)
          InsertRow(
            db.diaryEntries,
            FoodColumns.fromSavedItem(row).entry(
              id: op.entryIds[row.id]!,
              localDate: '${time.localDate}',
              time: time,
              slotId: slotId,
              dishGroupId: null,
            ),
          ),
      ],
      events: [EntriesLogged(ids, dates)],
      revertEvents: [EntryDeleted(ids, dates)],
    );
  } on FormatException {
    throw const ChangeRejected(InvalidOp('invalidSource'));
    // Stored items are untrusted; constructor errors may contain values.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    throw const ChangeRejected(InvalidOp('invalidSource'));
  }
}

/// Changes references only, never snapshot or provenance columns (FD-073).
Future<OpPlan> planRelink(
  AppDatabase db,
  RelinkFoodRefs op,
  TxReader tx,
) async {
  if (await tx.liveRow(db.personalFoods, op.to.id!) == null) {
    throw ChangeRejected(
      RowNotFound(entity: personalFoodEntity, id: op.to.id!),
    );
  }
  final entries =
      await (tx.db.select(db.diaryEntries)..where(
            (t) =>
                t.foodKind.equals(op.from.kind.code) &
                (op.from.id == null
                    ? t.foodId.isNull()
                    : t.foodId.equals(op.from.id!)) &
                t.deletedAt.isNull(),
          ))
          .get();
  final items =
      await (tx.db.select(db.savedMealItems)..where(
            (t) =>
                t.foodKind.equals(op.from.kind.code) &
                (op.from.id == null
                    ? t.foodId.isNull()
                    : t.foodId.equals(op.from.id!)) &
                t.deletedAt.isNull(),
          ))
          .get();
  final event = EntryChanged(
    entries.map((r) => r.id),
    entries.map((r) => LocalDate.parse(r.localDate)),
  );
  return OpPlan(
    [
      for (final row in entries)
        UpdateRow(
          db.diaryEntries,
          row.id,
          DiaryEntriesCompanion(
            foodKind: Value(op.to.kind.code),
            foodId: Value(op.to.id),
            foodVersion: Value(op.to.version),
          ),
          expectedVersion: row.version,
        ),
      for (final row in items)
        UpdateRow(
          db.savedMealItems,
          row.id,
          SavedMealItemsCompanion(
            foodKind: Value(op.to.kind.code),
            foodId: Value(op.to.id),
            foodVersion: Value(op.to.version),
          ),
          expectedVersion: row.version,
        ),
    ],
    events: [if (entries.isNotEmpty) event],
    revertEvents: [if (entries.isNotEmpty) event],
  );
}

/// Optimistic rename, with no write for an identical trimmed name.
Future<OpPlan> planRenameSavedMeal(
  AppDatabase db,
  RenameSavedMeal op,
  TxReader tx,
) async {
  final meal = await _meal(db, tx, op.id, op.expectedVersion);
  return OpPlan([
    if (meal.name != op.name)
      UpdateRow(
        db.savedMeals,
        meal.id,
        SavedMealsCompanion(name: Value(op.name)),
        expectedVersion: meal.version,
      ),
  ]);
}

/// Parent and current live items form one atomic tombstone/undo operation.
Future<OpPlan> planDeleteSavedMeal(
  AppDatabase db,
  DeleteSavedMeal op,
  TxReader tx,
) async {
  final meal = await _meal(db, tx, op.id, op.expectedVersion);
  final items = await _items(db, tx, op.id);
  return OpPlan([
    for (final row in items)
      TombstoneRow(db.savedMealItems, row.id, expectedVersion: row.version),
    TombstoneRow(db.savedMeals, meal.id, expectedVersion: meal.version),
  ]);
}
