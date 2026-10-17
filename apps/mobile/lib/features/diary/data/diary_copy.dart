import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/features/diary/data/diary_food_columns.dart';
import 'package:fb_mobile/features/diary/data/diary_tx_reads.dart';

/// Plans [CopyMeal] (A06 D9): new entries and groups with the op's IDs and
/// the source's values (food ref, names, per-100, snapshot, provenance,
/// input), at the source's local time of day on `toDate`.
///
/// A group is copied with its entries. For an entries source that is only
/// when the source holds all of the group's live entries; otherwise the
/// entries are copied ungrouped. A live source row without a copy ID is
/// `InvalidOp('missingCopyId')`.
Future<OpPlan> planCopyMeal(
  AppDatabase db,
  CopyMeal op,
  DiaryTxReads reads,
  ApplyContext context,
) async {
  if (op.toDate.isAfter(context.today)) {
    throw const ChangeRejected(InvalidOp('futureDate'));
  }
  if (op.toSlotId case final slotId?) await reads.requireSlot(slotId);
  final entries = await reads.source(op.source);
  if (entries.isEmpty) throw const ChangeRejected(InvalidOp('emptySource'));
  final groups = await reads.groups([
    for (final row in entries) ?row.dishGroupId,
  ], strict: false);
  final copiedGroups = <String, DishGroupRow>{};
  if (op.source is MealSourceEntries) {
    final listed = {for (final row in entries) row.id};
    final outside = {
      for (final member in await reads.members(groups.keys))
        if (!listed.contains(member.id)) member.dishGroupId!,
    };
    for (final MapEntry(:key, :value) in groups.entries) {
      if (!outside.contains(key)) copiedGroups[key] = value;
    }
  } else {
    copiedGroups.addAll(groups);
  }

  String copyId(String sourceId) =>
      op.copyIds[sourceId] ??
      (throw const ChangeRejected(InvalidOp('missingCopyId')));

  final rows = <RowOp>[
    for (final group in copiedGroups.values)
      InsertRow(
        db.dishGroups,
        DishGroupsCompanion(
          id: Value(copyId(group.id)),
          name: Value(group.name),
          localDate: Value('${op.toDate}'),
          slotId: Value(op.toSlotId ?? group.slotId),
        ),
      ),
  ];
  final dates = <LocalDate>{};
  for (final row in entries) {
    final time = EntryTime(
      DateTime.fromMillisecondsSinceEpoch(row.occurredAtUtc, isUtc: true),
      row.tzOffsetMin,
    ).onDate(op.toDate);
    dates.add(time.localDate);
    rows.add(
      InsertRow(
        db.diaryEntries,
        FoodColumns.fromEntry(row).entry(
          id: copyId(row.id),
          localDate: '${time.localDate}',
          time: time,
          slotId: op.toSlotId ?? row.slotId,
          dishGroupId: copiedGroups.containsKey(row.dishGroupId)
              ? copyId(row.dishGroupId!)
              : null,
        ),
      ),
    );
  }
  final ids = entries.map((row) => copyId(row.id)).toList();
  return OpPlan(
    rows,
    events: [EntriesLogged(ids, dates)],
    revertEvents: [EntryDeleted(ids, dates)],
  );
}

/// Plans [SaveMeal] (A06 D10): a saved meal and one item per live source
/// entry, with its snapshot. Item IDs come from the applier's generator.
Future<OpPlan> planSaveMeal(
  AppDatabase db,
  SaveMeal op,
  DiaryTxReads reads,
  ApplyContext context,
) async {
  final entries = await reads.source(op.source);
  if (entries.isEmpty) throw const ChangeRejected(InvalidOp('emptySource'));
  return OpPlan([
    InsertRow(
      db.savedMeals,
      SavedMealsCompanion(id: Value(op.savedMealId), name: Value(op.name)),
    ),
    for (final (index, row) in entries.indexed)
      InsertRow(
        db.savedMealItems,
        FoodColumns.fromEntry(row).savedItem(
          id: context.ids.next(),
          savedMealId: op.savedMealId,
          sortOrder: index,
        ),
      ),
  ]);
}
