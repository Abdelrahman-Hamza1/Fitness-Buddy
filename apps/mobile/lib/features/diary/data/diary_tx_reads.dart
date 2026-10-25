import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/diary_tables.dart';
import 'package:fb_mobile/features/diary/data/diary_mappers.dart';

/// The reads of the diary op handler inside a change set (A06 D1, D9): one
/// query per kind of row, batched with `IN (...)`, tombstones excluded.
/// A missing or tombstoned row rejects the change set with `RowNotFound`.
final class DiaryTxReads {
  /// Reads for [tx], with the tables of [db].
  const new(this.db, this.tx);

  /// The database, for its tables.
  final AppDatabase db;

  /// The change set's reader.
  final TxReader tx;

  /// Every live entry and group in the source, across all dates (PA1).
  Future<({List<DiaryEntryRow> entries, List<DishGroupRow> groups})> liveInSlot(
    String slotId,
  ) async => (
    entries: await (tx.db.select(
      db.diaryEntries,
    )..where((t) => t.slotId.equals(slotId) & t.deletedAt.isNull())).get(),
    groups: await (tx.db.select(
      db.dishGroups,
    )..where((t) => t.slotId.equals(slotId) & t.deletedAt.isNull())).get(),
  );

  /// Every live slot.
  Future<List<MealSlot>> slots() async {
    final rows = await (tx.db.select(
      db.mealSlots,
    )..where((t) => t.deletedAt.isNull())).get();
    return rows.map(mealSlotOf).toList();
  }

  /// The usable slot [slotId] (A06 plan 3.3): it exists, is active and is of
  /// the normal mode. Rejects `InvalidOp('unknownSlot')` or
  /// `InvalidOp('inactiveSlot')`.
  Future<MealSlot> requireSlot(String slotId) async =>
      requireUsableSlot(await slots(), slotId);

  /// The live entries [ids] by ID; an ID without one rejects.
  Future<Map<String, DiaryEntryRow>> entries(Iterable<String> ids) async {
    final wanted = ids.toSet();
    if (wanted.isEmpty) return {};
    final rows = await (tx.db.select(
      db.diaryEntries,
    )..where((t) => t.id.isIn(wanted) & t.deletedAt.isNull())).get();
    final byId = {for (final row in rows) row.id: row};
    for (final id in wanted) {
      if (!byId.containsKey(id)) {
        throw ChangeRejected(RowNotFound(entity: diaryEntryEntity, id: id));
      }
    }
    return byId;
  }

  /// The live entries of [wanted], in order, each at its expected version.
  Future<List<DiaryEntryRow>> versionedEntries(List<VersionedId> wanted) async {
    final byId = await entries(wanted.map((w) => w.id));
    final rows = <DiaryEntryRow>[];
    for (final w in wanted) {
      final row = byId[w.id]!;
      checkVersion(diaryEntryEntity, row.id, row.version, w.expectedVersion);
      rows.add(row);
    }
    return rows;
  }

  /// The live group [id] at [expectedVersion]; rejects otherwise.
  Future<DishGroupRow> versionedGroup(String id, int expectedVersion) async {
    final group = (await groups([id]))[id]!;
    checkVersion(dishGroupEntity, id, group.version, expectedVersion);
    return group;
  }

  /// The live groups [ids] by ID; an ID without one rejects, or, when not
  /// [strict], is left out.
  Future<Map<String, DishGroupRow>> groups(
    Iterable<String> ids, {
    bool strict = true,
  }) async {
    final wanted = ids.toSet();
    if (wanted.isEmpty) return {};
    final rows = await (tx.db.select(
      db.dishGroups,
    )..where((t) => t.id.isIn(wanted) & t.deletedAt.isNull())).get();
    final byId = {for (final row in rows) row.id: row};
    for (final id in wanted) {
      if (strict && !byId.containsKey(id)) {
        throw ChangeRejected(RowNotFound(entity: dishGroupEntity, id: id));
      }
    }
    return byId;
  }

  /// The live entries in any of the groups [groupIds], by time then ID.
  Future<List<DiaryEntryRow>> members(Iterable<String> groupIds) {
    final wanted = groupIds.toSet();
    if (wanted.isEmpty) return Future.value(const []);
    return (tx.db.select(db.diaryEntries)
          ..where((t) => t.dishGroupId.isIn(wanted) & t.deletedAt.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.occurredAtUtc),
            (t) => OrderingTerm(expression: t.id),
          ]))
        .get();
  }

  /// The live entries of [source], in order: by time then ID for a slot or
  /// a day, as listed for entries. Rejects a listed entry that isn't live.
  Future<List<DiaryEntryRow>> source(MealSource source) => switch (source) {
    MealSourceEntries(:final ids) => _listed(ids),
    MealSourceSlot(:final date, :final slotId) => _onDay(date, slotId),
    MealSourceDay(:final date) => _onDay(date, null),
  };

  Future<List<DiaryEntryRow>> _listed(List<String> ids) async {
    final byId = await entries(ids);
    return [for (final id in ids) byId[id]!];
  }

  Future<List<DiaryEntryRow>> _onDay(LocalDate date, String? slotId) =>
      (tx.db.select(db.diaryEntries)
            ..where(
              (t) =>
                  t.localDate.equals('$date') &
                  t.deletedAt.isNull() &
                  (slotId == null
                      ? const Constant(true)
                      : t.slotId.equals(slotId)),
            )
            ..orderBy([
              (t) => OrderingTerm(expression: t.occurredAtUtc),
              (t) => OrderingTerm(expression: t.id),
            ]))
          .get();
}

/// Rejects with a `VersionConflict` of [entity] unless row [id] is at the
/// [expected] version.
void checkVersion(String entity, String id, int actual, int expected) {
  if (actual != expected) {
    throw ChangeRejected(
      VersionConflict(
        entity: entity,
        id: id,
        expected: expected,
        actual: actual,
      ),
    );
  }
}

/// The slot [slotId] of [slots], if it is usable for logging: active and of
/// the normal mode. Rejects `InvalidOp('unknownSlot')` when there is no such
/// slot and `InvalidOp('inactiveSlot')` when it is inactive or of another
/// mode.
MealSlot requireUsableSlot(Iterable<MealSlot> slots, String slotId) {
  for (final slot in slots) {
    if (slot.id != slotId) continue;
    if (!slot.active || slot.mode != SlotMode.normal) {
      throw const ChangeRejected(InvalidOp('inactiveSlot'));
    }
    return slot;
  }
  throw const ChangeRejected(InvalidOp('unknownSlot'));
}
