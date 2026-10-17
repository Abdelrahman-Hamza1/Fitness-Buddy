import 'package:drift/drift.dart';

/// Local sync bookkeeping (A01 D9): `outbox.capture` (the trigger gate),
/// `hlc.last` (the HLC across restarts, D10) and A34's cursors. Local only,
/// never synced, no triggers.
@DataClassName('SyncStateRow')
class SyncState extends Table {
  /// A dot-separated key, like `outbox.capture`.
  TextColumn get key => text()();

  /// The value as text.
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// The outbox (A01 D9, `05` §5.4): one row per written version of a synced
/// row, appended by the SQL triggers in `sync_triggers.drift`. The payload is
/// not copied: the push reads the row itself, coalesces per
/// `(entity, row_id)` to the newest [hlc], and on acknowledgement deletes
/// `WHERE entity = ? AND row_id = ? AND hlc <= ackedHlc`. Local only.
@DataClassName('SyncOutboxRow')
class SyncOutbox extends Table {
  /// The append order.
  IntColumn get seq => integer().autoIncrement()();

  /// The entity wire name, like `setting`.
  TextColumn get entity => text()();

  /// The written row's id.
  TextColumn get rowId => text()();

  /// The written version's `updated_hlc`.
  TextColumn get hlc => text()();

  /// Whether the written version is a tombstone.
  BoolColumn get deleted => boolean()();
}
