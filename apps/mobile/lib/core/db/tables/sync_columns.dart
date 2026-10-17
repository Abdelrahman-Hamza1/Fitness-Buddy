import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show immutable;

/// The sync metadata every synced table carries (A01 D5, `05` §1, AC-012).
///
/// Times are integer UTC milliseconds, not drift `DateTime` columns (those
/// store whole seconds). `updated_hlc` is compared with SQLite's default
/// `BINARY` collation (TD-049). The row writer (`core/db/write/`) stamps every
/// column except [editedByUser], which only ops set (A01 PA3).
mixin SyncColumns on Table {
  /// UUIDv7 for user-created rows, a deterministic UUIDv5 for natural keys
  /// (`core/db/natural_id.dart`). Lowercase canonical text.
  TextColumn get id => text()();

  /// When the row was first written, UTC ms (0 for seeds).
  IntColumn get createdAt => integer()();

  /// The hybrid logical clock of the last write (`fb_domain` `Hlc` text).
  TextColumn get updatedHlc => text()();

  /// 1 on insert, +1 per write: the local optimistic concurrency check.
  IntColumn get version => integer()();

  /// The tombstone, UTC ms. Synced rows are never hard-deleted.
  IntColumn get deletedAt => integer().nullable()();

  /// The install that made the last write (the HLC's node id, TD-053).
  TextColumn get deviceId => text()();

  /// `direct`, `proposal:<uuid>`, `undo:<changeSetId>` or `system`.
  TextColumn get origin => text()();

  /// Provenance: the user overrode a value that came from another source
  /// (AI-072, the "edited by you" badge). Set only by ops.
  BoolColumn get editedByUser => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// The SQL names of the [SyncColumns] columns, in declaration order.
const List<String> syncColumnNames = [
  'id',
  'created_at',
  'updated_hlc',
  'version',
  'deleted_at',
  'device_id',
  'origin',
  'edited_by_user',
];

/// The sync metadata of one row, read from its SQL columns (the read side of
/// [SyncColumns]).
@immutable
final class SyncMeta {
  /// The metadata values.
  const new({
    required this.id,
    required this.createdAtMs,
    required this.updatedHlc,
    required this.version,
    required this.deletedAtMs,
    required this.deviceId,
    required this.origin,
    required this.editedByUser,
  });

  /// Reads the metadata from a row keyed by SQL column name, like the maps
  /// `customSelect` returns.
  factory fromSqlRow(Map<String, Object?> row) => SyncMeta(
    id: row['id']! as String,
    createdAtMs: row['created_at']! as int,
    updatedHlc: row['updated_hlc']! as String,
    version: row['version']! as int,
    deletedAtMs: row['deleted_at'] as int?,
    deviceId: row['device_id']! as String,
    origin: row['origin']! as String,
    editedByUser: row['edited_by_user'] == 1 || row['edited_by_user'] == true,
  );

  /// See [SyncColumns.id].
  final String id;

  /// See [SyncColumns.createdAt].
  final int createdAtMs;

  /// See [SyncColumns.updatedHlc].
  final String updatedHlc;

  /// See [SyncColumns.version].
  final int version;

  /// See [SyncColumns.deletedAt].
  final int? deletedAtMs;

  /// See [SyncColumns.deviceId].
  final String deviceId;

  /// See [SyncColumns.origin].
  final String origin;

  /// See [SyncColumns.editedByUser].
  final bool editedByUser;

  /// Whether the row is a tombstone.
  bool get isDeleted => deletedAtMs != null;

  @override
  bool operator ==(Object other) =>
      other is SyncMeta &&
      other.id == id &&
      other.createdAtMs == createdAtMs &&
      other.updatedHlc == updatedHlc &&
      other.version == version &&
      other.deletedAtMs == deletedAtMs &&
      other.deviceId == deviceId &&
      other.origin == origin &&
      other.editedByUser == editedByUser;

  @override
  int get hashCode => Object.hash(
    id,
    createdAtMs,
    updatedHlc,
    version,
    deletedAtMs,
    deviceId,
    origin,
    editedByUser,
  );

  // No values in the text: rows may hold user content (no user content in
  // logs).
  @override
  String toString() => 'SyncMeta($id, v$version)';
}
