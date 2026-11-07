import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/db/tables/chat_tables.dart';

/// The one row of memory [kind] + [key]: every phone writes the same row,
/// so an overwrite (or the same statement on two phones) merges.
String memoryItemId(String kind, String key) =>
    naturalId(memoryItemEntity, '$kind\u001f$key');

/// Plans `memory_items` rows inside the applier's transaction (A67 D10).
final class MemoryItemOpHandler extends ChangeOpHandler<MemoryItemOp> {
  /// Bound to the applier's database.
  const new(this.db);

  /// Profile database.
  final AppDatabase db;

  static const _scrub = MemoryItemsCompanion(
    memoryKey: Value(''),
    memoryValue: Value(''),
  );

  @override
  String get family => MemoryItemOp.familyName;

  @override
  Future<OpPlan> plan(
    MemoryItemOp op,
    TxReader tx,
    ApplyContext context,
  ) async {
    switch (op) {
      case SaveMemoryItem():
        if (op.validate() case final invalid?) {
          throw ChangeRejected(InvalidOp(invalid.code));
        }
        if (op.checked) {
          final id = memoryItemId(op.kind, op.key);
          final live =
              await (tx.db.select(db.memoryItems)
                    ..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
                  .getSingleOrNull();
          if (live?.version != op.expectedVersion) {
            throw ChangeRejected(InvalidOp(InvalidMemoryItem.stale.code));
          }
        }
        return OpPlan([
          // Written or revived after a delete; an overwrite keeps the row.
          UpsertRow(
            db.memoryItems,
            MemoryItemsCompanion(
              id: Value(memoryItemId(op.kind, op.key)),
              kind: Value(op.kind),
              memoryKey: Value(op.key),
              memoryValue: Value(op.value),
              createdFrom: Value(op.origin.code),
            ),
          ),
        ]);
      case DeleteMemoryItem():
        final row =
            await (tx.db.select(db.memoryItems)
                  ..where((t) => t.id.equals(op.id) & t.deletedAt.isNull()))
                .getSingleOrNull();
        if (row == null || row.version != op.expectedVersion) {
          throw ChangeRejected(InvalidOp(InvalidMemoryItem.stale.code));
        }
        return OpPlan([
          TombstoneRow(
            db.memoryItems,
            row.id,
            expectedVersion: row.version,
            scrub: _scrub,
          ),
        ]);
      case ClearMemoryItems():
        final live = await (tx.db.select(
          db.memoryItems,
        )..where((t) => t.deletedAt.isNull())).get();
        return OpPlan([
          for (final row in live)
            TombstoneRow(
              db.memoryItems,
              row.id,
              expectedVersion: row.version,
              scrub: _scrub,
            ),
        ]);
    }
  }
}
