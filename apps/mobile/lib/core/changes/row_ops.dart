import 'package:drift/drift.dart';

/// One row write, as inert data (A01 D1b): what an op handler plans and the
/// row writer (`core/db/write/`) executes. Handlers in any feature may build
/// them; only the applier runs them.
///
/// Row values ([InsertRow.row], [UpdateRow.changes], …) give the row's
/// content columns, plus `id` for inserts and, when the op means it,
/// `edited_by_user` (A01 PA3). The writer stamps every other sync column
/// (`version`, `updated_hlc`, `device_id`, `origin`, `created_at`,
/// `deleted_at`); a row value that sets one is rejected (`InvalidOp`).
sealed class RowOp {
  const new _();

  /// The table written. It must be one of the database's synced tables.
  TableInfo<Table, Object?> get table;

  /// The row's ID.
  String get id;
}

/// Insert a new row. Its ID must not exist yet, not even as a tombstone
/// (`ConstraintViolation('duplicateId')`).
final class InsertRow<T extends Table, D> extends RowOp {
  /// Insert [row] (with its `id`) into [table].
  new(this.table, this.row) : id = _idOf(row), super._();

  @override
  final TableInfo<T, D> table;

  /// The row's `id` and content columns.
  final Insertable<D> row;

  @override
  final String id;
}

/// Insert the row, or overwrite the content columns of the existing one
/// with the same ID, reviving it if it's a tombstone. For natural IDs
/// (A01 D6), like a setting.
final class UpsertRow<T extends Table, D> extends RowOp {
  /// Upsert [row] (with its `id`) into [table].
  new(this.table, this.row) : id = _idOf(row), super._();

  @override
  final TableInfo<T, D> table;

  /// The row's `id` and content columns.
  final Insertable<D> row;

  @override
  final String id;
}

/// Change some content columns of a live row. Fails with `RowNotFound` if
/// there is none, and with `VersionConflict` if [expectedVersion] is given
/// and isn't the row's version.
final class UpdateRow<T extends Table, D> extends RowOp {
  /// Set [changes] on row [id] of [table].
  const new(this.table, this.id, this.changes, {this.expectedVersion})
    : super._();

  @override
  final TableInfo<T, D> table;

  @override
  final String id;

  /// The columns to set (absent ones are kept).
  final Insertable<D> changes;

  /// The version the row must be at, if the op read it earlier.
  final int? expectedVersion;
}

/// Tombstone a live row (synced rows are never deleted). Fails like
/// [UpdateRow].
final class TombstoneRow<T extends Table, D> extends RowOp {
  /// Tombstone row [id] of [table].
  const new(this.table, this.id, {this.expectedVersion}) : super._();

  @override
  final TableInfo<T, D> table;

  @override
  final String id;

  /// The version the row must be at, if the op read it earlier.
  final int? expectedVersion;
}

/// Put a row back as it was (A01 D3): its content columns, `deleted_at` and
/// `edited_by_user` from [snapshot]. **Inverse only**: the applier makes
/// these and rejects them in a handler's plan (`InvalidOp('restoreInPlan')`).
final class RestoreRow<T extends Table, D> extends RowOp {
  /// Restore row [id] of [table] to [snapshot] (raw SQL values by column
  /// name), if it is still at [expectedVersion].
  new(
    this.table,
    this.id,
    Map<String, Object?> snapshot, {
    required this.expectedVersion,
  }) : snapshot = Map.unmodifiable(snapshot),
       super._();

  @override
  final TableInfo<T, D> table;

  @override
  final String id;

  /// The row as it was, every column, raw SQL values. Unmodifiable. Holds
  /// user content: never log it.
  final Map<String, Object?> snapshot;

  /// The version the change set being undone left the row at.
  final int expectedVersion;
}

String _idOf(Insertable<Object?> row) {
  final id = row.toColumns(false)['id'];
  if (id is Variable<Object> && id.value is String) return id.value! as String;
  throw ArgumentError('An inserted row gives its id');
}
