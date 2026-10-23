import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/diary_tables.dart';
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
  // Membership is checked even when the source became empty.
  final referencedGroups = await reads.groups([
    for (final row in entries) ?row.dishGroupId,
  ], strict: false);
  // Cross-day references are missing groups, just as in the day layout.
  final groups = {
    for (final row in entries)
      if (referencedGroups[row.dishGroupId] case final group?)
        if (group.localDate == row.localDate) group.id: group,
  };
  checkSourceVersions(op.expected, entries, groups);
  final copiedGroups = <String, DishGroupRow>{};
  if (op.source is MealSourceEntries) {
    final listed = {for (final row in entries) row.id};
    final outside = {
      for (final member in await reads.members(groups.keys))
        if (!listed.contains(member.id) &&
            groups[member.dishGroupId]?.localDate == member.localDate)
          member.dishGroupId!,
    };
    for (final MapEntry(:key, :value) in groups.entries) {
      if (!outside.contains(key)) copiedGroups[key] = value;
    }
  } else {
    copiedGroups.addAll(groups);
  }

  final entryIds = entries.map((e) => e.id).toSet();
  final groupCopyIds = op.copyIds.keys
      .where((id) => !entryIds.contains(id))
      .toSet();
  if (groupCopyIds.length != copiedGroups.length ||
      !groupCopyIds.containsAll(copiedGroups.keys)) {
    throw const ChangeRejected(InvalidOp('sourceChanged'));
  }
  if (entries.isEmpty) throw const ChangeRejected(InvalidOp('emptySource'));

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
          dishGroupId: copiedGroups[row.dishGroupId]?.localDate == row.localDate
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
  checkSourceVersions(op.expected, entries, const {});
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

/// Checks the observed source inside the applier transaction (PA2/PA7).
/// All referenced live groups pin observed missing-group state (PA8).
void checkSourceVersions(
  SourceVersions expected,
  List<DiaryEntryRow> entries,
  Map<String, DishGroupRow> groups,
) {
  bool sameIds(Iterable<String> actual, Iterable<String> wanted) {
    final a = actual.toSet();
    final b = wanted.toSet();
    return a.length == b.length && a.containsAll(b);
  }

  if (!sameIds(entries.map((e) => e.id), expected.entries.map((e) => e.id)) ||
      !sameIds(groups.keys, expected.groups.map((g) => g.id))) {
    throw const ChangeRejected(InvalidOp('sourceChanged'));
  }
  final byId = {for (final entry in entries) entry.id: entry};
  for (final entry in expected.entries) {
    checkVersion(
      diaryEntryEntity,
      entry.id,
      byId[entry.id]!.version,
      entry.expectedVersion,
    );
  }
  for (final group in expected.groups) {
    checkVersion(
      dishGroupEntity,
      group.id,
      groups[group.id]!.version,
      group.expectedVersion,
    );
  }
}
