import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_mobile/core/db/synced_tables.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';

/// Restores an earlier version of one row (G7, A34 D14): a direct action
/// with undo. [payload] is the version's payload at the current schema
/// version (already upgraded); [deleted] whether that version was a
/// tombstone. [expectedVersion] is the local version shown (a change made
/// meanwhile refuses the restore).
final class RestoreVersionOp implements ChangeOp {
  /// Restore [payload] into row [id] of [entity].
  const new({
    required this.entity,
    required this.id,
    required this.payload,
    required this.deleted,
    this.expectedVersion,
  });

  /// The op family.
  static const String familyName = 'syncRestore';

  /// The entity wire name.
  final String entity;

  /// The row id.
  final String id;

  /// The version's payload (user content: never log it).
  final Map<String, Object?> payload;

  /// The version was a tombstone.
  final bool deleted;

  /// The local version the user saw, if known.
  final int? expectedVersion;

  @override
  String get family => familyName;

  // No values: payloads hold user content.
  @override
  String toString() => 'RestoreVersionOp($entity)';
}

/// Plans [RestoreVersionOp]: the version's content columns through the
/// entity codec, upserted by the row writer (new HLC, version + 1, origin
/// `direct`), then tombstoned again if the version was a tombstone.
final class RestoreVersionHandler extends ChangeOpHandler<RestoreVersionOp> {
  /// A handler over [db] with its sync `codecs`.
  new(AppDatabase db, this._codecs)
    : _tables = {for (final t in db.syncedTables) t.entity: t};

  final Map<String, SyncEntityCodec> _codecs;
  final Map<String, SyncedTable<Table, Object?>> _tables;

  @override
  String get family => RestoreVersionOp.familyName;

  @override
  Future<OpPlan> plan(
    RestoreVersionOp op,
    TxReader tx,
    ApplyContext context,
  ) async {
    final table = _tables[op.entity];
    final codec = _codecs[op.entity];
    if (table == null || codec == null) {
      throw const ChangeRejected(InvalidOp('unknownEntity'));
    }
    final Map<String, Expression<Object>> columns;
    try {
      columns = codec.decode(op.payload, id: op.id, deleted: op.deleted);
    } on SyncDecodeFailure {
      throw const ChangeRejected(InvalidOp('unreadableVersion'));
    }
    final meta = await tx.meta(table.table, op.id);
    if (meta == null) {
      throw ChangeRejected(RowNotFound(entity: op.entity, id: op.id));
    }
    if (op.expectedVersion case final expected? when expected != meta.version) {
      throw ChangeRejected(
        VersionConflict(
          entity: op.entity,
          id: op.id,
          expected: expected,
          actual: meta.version,
        ),
      );
    }
    final content = {
      for (final MapEntry(:key, :value) in columns.entries)
        if (!syncColumnNames.contains(key) || key == 'edited_by_user')
          key: value,
      'id': Variable<String>(op.id),
    };
    return OpPlan([
      UpsertRow(table.table, table.rawRow(content)),
      if (op.deleted) TombstoneRow(table.table, op.id),
    ]);
  }
}
