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

/// Versions the server (or the app's own encoder) refused permanently
/// (A34 D5): moved out of the outbox, kept for "Try again". One row per
/// parked version; the synced row itself is untouched. Local only.
@DataClassName('SyncParkedRow')
class SyncParked extends Table {
  /// The entity wire name.
  TextColumn get entity => text()();

  /// The row id.
  TextColumn get rowId => text()();

  /// The parked version's HLC.
  TextColumn get hlc => text()();

  /// A fixed reason code (`unsupported`, `invalidPayload`, `tooLarge`, a
  /// codec code, `unknown`), never a message.
  TextColumn get reason => text()();

  /// When it was parked, UTC ms.
  IntColumn get parkedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {entity, rowId, hlc};
}

/// Pulled documents this app version can't apply yet (A34 D7): an unknown
/// entity, a newer `schemaVersion` or an unreadable payload. Kept whole and
/// retried on every run, so an app update applies them. Local only.
@DataClassName('SyncDeferredRow')
class SyncDeferred extends Table {
  /// The entity wire name.
  TextColumn get entity => text()();

  /// The row id.
  TextColumn get rowId => text()();

  /// The document's HLC.
  TextColumn get hlc => text()();

  /// The document as pulled (JSON).
  TextColumn get documentJson => text()();

  /// `unknownEntity`, `newerSchema` or `unreadable`.
  TextColumn get reason => text()();

  @override
  Set<Column<Object>> get primaryKey => {entity, rowId, hlc};
}

/// Local versions a pulled version replaced while they were still pending
/// or parked (A34 fix 1): the outbox holds no payload, so the row is kept
/// whole here (its raw SQL values) until the server acknowledges exactly
/// this version, which then lands in `row_history` as a loser. Local only.
@DataClassName('SyncDisplacedRow')
class SyncDisplaced extends Table {
  /// The entity wire name.
  TextColumn get entity => text()();

  /// The row id.
  TextColumn get rowId => text()();

  /// The displaced version's HLC.
  TextColumn get hlc => text()();

  /// The row as it was (SQL column → raw value, JSON).
  TextColumn get rowJson => text()();

  /// The parked reason when the server or the encoder refused it; `null`
  /// while it waits to be pushed.
  TextColumn get parkedReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {entity, rowId, hlc};
}
