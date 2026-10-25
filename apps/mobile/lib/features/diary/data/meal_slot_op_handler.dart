import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/tables/diary_tables.dart';
import 'package:fb_mobile/features/diary/data/diary_mappers.dart';
import 'package:fb_mobile/features/diary/data/diary_tx_reads.dart';

/// Plans atomic customization and relinking (A10 D10–D12, PA1).
final class MealSlotOpHandler extends ChangeOpHandler<MealSlotOp> {
  /// Stateless handler bound to the applier's database.
  const new(this.db);

  /// Profile tables.
  final AppDatabase db;
  @override
  String get family => MealSlotOp.familyName;

  @override
  Future<OpPlan> plan(MealSlotOp op, TxReader tx, ApplyContext context) async {
    final all = await (tx.db.select(
      db.mealSlots,
    )..where((t) => t.deletedAt.isNull())).get();
    final active = all.where((s) => s.active && s.mode == 'normal').toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        return order != 0 ? order : a.id.compareTo(b.id);
      });
    final rows = <RowOp>[];
    final changed = <String>{};
    final events = <DomainEvent>[];
    final revertGuards = <RevertGuard>[];
    MealSlotRow source(String id, int version) {
      final row = all.where((s) => s.id == id).firstOrNull;
      if (row == null) {
        throw ChangeRejected(RowNotFound(entity: mealSlotEntity, id: id));
      }
      checkVersion(mealSlotEntity, id, row.version, version);
      if (!row.active) _reject('inactiveSlot');
      if (row.mode != 'normal') _reject('wrongMode');
      return row;
    }

    void planSlotUpdate(MealSlotRow row, MealSlotsCompanion patch) {
      rows.add(
        UpdateRow(db.mealSlots, row.id, patch, expectedVersion: row.version),
      );
      changed.add(row.id);
    }

    void reorder(List<String> ids) {
      final positions = MealSlotRules.renumber(ids);
      for (final row in active) {
        final position = positions[row.id]!;
        if (row.sortOrder != position) {
          planSlotUpdate(row, MealSlotsCompanion(sortOrder: Value(position)));
        }
      }
    }

    switch (op) {
      case AddMealSlot():
        if (active.length >= MealSlotRules.maxActive) _reject('tooManySlots');
        if (!MealSlotRules.validName(op.name)) _reject('nameInvalid');
        // A caller-generated identity must never overwrite history.
        if (await tx.row(db.mealSlots, op.id) != null) _reject('duplicateId');
        final index = MealSlotRules.insertIndex(
          active.map(mealSlotOf).toList(),
          op.window,
        );
        final ids = [
          ...active.take(index).map((s) => s.id),
          op.id,
          ...active.skip(index).map((s) => s.id),
        ];
        reorder(ids);
        rows.add(
          UpsertRow(
            db.mealSlots,
            MealSlotsCompanion(
              id: Value(op.id),
              name: Value(op.name),
              sortOrder: Value(index),
              windowStartMin: Value(op.window?.startMin),
              windowEndMin: Value(op.window?.endMin),
              mode: const Value('normal'),
              active: const Value(true),
            ),
          ),
        );
        changed.add(op.id);
        revertGuards.add((reader, inverseRows) async {
          final contents = await DiaryTxReads(
            db,
            TxReader(reader),
          ).liveInSlot(op.id);
          if (contents.entries.isNotEmpty || contents.groups.isNotEmpty) {
            _reject('slotInUse');
          }
        });
      case UpdateMealSlot():
        final row = source(op.id, op.expectedVersion);
        final patch = op.patch;
        var name = row.name;
        if (patch.setName) {
          name = patch.name;
          if (name == '' ||
              (row.defaultKey != null &&
                  name?.toLowerCase() == row.defaultKey!.toLowerCase())) {
            name = null;
          }
          if (name == null
              ? row.defaultKey == null
              : !MealSlotRules.validName(name)) {
            _reject('nameInvalid');
          }
        }
        final start = patch.setWindow
            ? patch.window?.startMin
            : row.windowStartMin;
        final end = patch.setWindow ? patch.window?.endMin : row.windowEndMin;
        if (name != row.name ||
            start != row.windowStartMin ||
            end != row.windowEndMin) {
          planSlotUpdate(
            row,
            MealSlotsCompanion(
              name: Value(name),
              windowStartMin: Value(start),
              windowEndMin: Value(end),
            ),
          );
        }
      case ReorderMealSlots():
        if (!_sameIds(active.map((r) => r.id), op.order.map((v) => v.id))) {
          _reject('sourceChanged');
        }
        for (final v in op.order) {
          source(v.id, v.expectedVersion);
        }
        reorder(op.order.map((v) => v.id).toList());
      case RemoveMealSlot():
        final row = source(op.id, op.expectedVersion);
        if (active.length <= 1) _reject('lastSlot');
        final contents = await DiaryTxReads(db, tx).liveInSlot(op.id);
        // Membership must precede version checks: deletion or replacement is
        // a changed source, never a partial move of the remaining rows (PA1).
        if (!_sameIds(
              contents.entries.map((r) => r.id),
              op.expected.entries.map((v) => v.id),
            ) ||
            !_sameIds(
              contents.groups.map((r) => r.id),
              op.expected.groups.map((v) => v.id),
            )) {
          _reject('sourceChanged');
        }
        final entryVersions = {
          for (final v in op.expected.entries) v.id: v.expectedVersion,
        };
        final groupVersions = {
          for (final v in op.expected.groups) v.id: v.expectedVersion,
        };
        for (final entry in contents.entries) {
          checkVersion(
            diaryEntryEntity,
            entry.id,
            entry.version,
            entryVersions[entry.id]!,
          );
        }
        for (final group in contents.groups) {
          checkVersion(
            dishGroupEntity,
            group.id,
            group.version,
            groupVersions[group.id]!,
          );
        }
        if (!op.expected.isEmpty && op.moveTo == null) _reject('slotNotEmpty');
        if (op.moveTo case final target?) {
          final dest = all.where((s) => s.id == target.id).firstOrNull;
          if (dest == null ||
              !dest.active ||
              dest.mode != 'normal' ||
              dest.id == row.id) {
            _reject('badTarget');
          }
          checkVersion(
            mealSlotEntity,
            dest.id,
            dest.version,
            target.expectedVersion,
          );
          for (final entry in contents.entries) {
            rows.add(
              UpdateRow(
                db.diaryEntries,
                entry.id,
                DiaryEntriesCompanion(slotId: Value(dest.id)),
                expectedVersion: entry.version,
              ),
            );
          }
          for (final group in contents.groups) {
            rows.add(
              UpdateRow(
                db.dishGroups,
                group.id,
                DishGroupsCompanion(slotId: Value(dest.id)),
                expectedVersion: group.version,
              ),
            );
          }
        }
        // Logging into a group does not edit its row version. Guard membership
        // separately so the inverse cannot split a group across meals (UX-030).
        final members = await DiaryTxReads(
          db,
          tx,
        ).members(contents.groups.map((g) => g.id));
        final membership = <String, Set<String>>{
          for (final group in contents.groups)
            group.id: members
                .where((e) => e.dishGroupId == group.id)
                .map((e) => e.id)
                .toSet(),
        };
        revertGuards.add((reader, inverseRows) async {
          final reads = DiaryTxReads(db, TxReader(reader));
          final currentMembers = await reads.members(membership.keys);
          for (final group in membership.entries) {
            if (!_sameIds(
              currentMembers
                  .where((e) => e.dishGroupId == group.key)
                  .map((e) => e.id),
              group.value,
            )) {
              _reject('sourceChanged');
            }
          }
          // Count the whole inverse, including multiple removals and additions.
          // Per-op checks alone could each pass and together exceed the cap.
          final activeIds = (await reads.slots())
              .where((s) => s.active && s.mode == SlotMode.normal)
              .map((s) => s.id)
              .toSet();
          for (final inverse in inverseRows) {
            if (inverse.table != db.mealSlots) continue;
            if (inverse is RestoreRow &&
                inverse.snapshot['active'] == 1 &&
                inverse.snapshot['mode'] == 'normal' &&
                inverse.snapshot['deleted_at'] == null) {
              activeIds.add(inverse.id);
            } else {
              activeIds.remove(inverse.id);
            }
          }
          if (activeIds.length > MealSlotRules.maxActive) {
            _reject('tooManySlots');
          }
        });
        planSlotUpdate(row, const MealSlotsCompanion(active: Value(false)));
        if (!op.expected.isEmpty) {
          events.add(
            EntryChanged(contents.entries.map((r) => r.id), {
              ...contents.entries.map((r) => LocalDate.parse(r.localDate)),
              ...contents.groups.map((r) => LocalDate.parse(r.localDate)),
            }),
          );
        }
    }
    final emitted = [
      if (changed.isNotEmpty) MealSlotsChanged(changed),
      ...events,
    ];
    return OpPlan(
      rows,
      events: emitted,
      revertEvents: emitted,
      revertGuards: revertGuards,
    );
  }
}

Never _reject(String code) => throw ChangeRejected(InvalidOp(code));
bool _sameIds(Iterable<String> actual, Iterable<String> expected) {
  final a = actual.toSet();
  final b = expected.toSet();
  return a.length == b.length && a.containsAll(b);
}
