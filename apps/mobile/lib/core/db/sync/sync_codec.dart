import 'package:drift/drift.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/synced_tables.dart';

/// The app's encoder refused to push a row (A34 D5, A23 D15/D16): the store
/// parks it with [code] (`tooLarge`, `unscrubbedTombstone`, `encodeFailed`).
final class SyncEncodeRefused implements Exception {
  /// A refusal with a fixed [code].
  const new(this.code);

  /// The fixed reason code.
  final String code;

  @override
  String toString() => 'SyncEncodeRefused($code)';
}

/// A pulled payload this app can't map to its table (A34 D7): deferred.
final class SyncDecodeFailure implements Exception {
  /// A failure without the value (payloads hold user content).
  const new();

  @override
  String toString() => 'SyncDecodeFailure';
}

/// Maps one entity between its table row and its wire payload (A34 D16).
/// The store owns the envelope (`id`, `updated_hlc`, `device_id`,
/// `deleted_at`, `version`); a codec owns the payload: the content fields
/// plus `createdAtMs`, `origin` and `editedByUser`.
abstract interface class SyncEntityCodec {
  /// The entity wire name.
  String get entity;

  /// The `schemaVersion` this app uploads.
  int get uploadVersion;

  /// The payload of a stored row ([sqlRow]: SQL column → raw SQL value, as
  /// `customSelect` returns it). Throws [SyncEncodeRefused] for a row that
  /// must stay local. Holds user content: never log it.
  Map<String, Object?> encode(Map<String, Object?> sqlRow);

  /// The columns to write for a current-version [payload] of row [id]
  /// (`created_at`, `origin`, `edited_by_user` and the content columns;
  /// never a local-only column). Throws [SyncDecodeFailure].
  Map<String, Expression<Object>> decode(
    Map<String, Object?> payload, {
    required String id,
    required bool deleted,
  });

  /// Local-only columns a pulled tombstone resets (A23: the chat's request
  /// and answer JSON go with the message).
  Map<String, Expression<Object>> get tombstoneLocalColumns;
}

/// The generic codec (A34 D16): the table's content columns 1:1 as
/// camelCase payload fields, after `createdAtMs`, `origin` and
/// `editedByUser`. Contract tests pin the 1:1 shape per entity.
final class ColumnSyncCodec implements SyncEntityCodec {
  /// The codec of [table], uploading [uploadVersion] (the newest version
  /// `fb_domain` upgrades to by default).
  new(this.table, {int? uploadVersion})
    : uploadVersion =
          uploadVersion ?? SyncDocumentUpgraders.currentVersionOf(table.entity),
      _columns = [
        for (final c in table.contentColumns) (c.name, camelOf(c.name), c),
      ];

  /// The synced table.
  final SyncedTable<Table, Object?> table;

  @override
  final int uploadVersion;

  final List<(String, String, GeneratedColumn<Object>)> _columns;

  @override
  String get entity => table.entity;

  /// `snake_case` → `camelCase`.
  static String camelOf(String snake) =>
      snake.replaceAllMapped(RegExp('_([a-z0-9])'), (m) => m[1]!.toUpperCase());

  @override
  Map<String, Object?> encode(Map<String, Object?> sqlRow) => {
    'createdAtMs': sqlRow['created_at'],
    'origin': sqlRow['origin'],
    'editedByUser': _bool(sqlRow['edited_by_user']),
    for (final (name, camel, column) in _columns)
      camel: _wire(column.type, sqlRow[name]),
  };

  static bool _bool(Object? sql) => sql == 1 || sql == true;

  static Object? _wire(Object type, Object? sql) {
    if (sql == null) return null;
    return switch (type) {
      DriftSqlType.bool => _bool(sql),
      DriftSqlType.double => (sql as num).toDouble(),
      _ => sql,
    };
  }

  @override
  Map<String, Expression<Object>> decode(
    Map<String, Object?> payload, {
    required String id,
    required bool deleted,
  }) {
    final createdAt = _int(payload['createdAtMs']);
    final origin = payload['origin'];
    final edited = payload['editedByUser'];
    if (createdAt == null || origin is! String || edited is! bool) {
      throw const SyncDecodeFailure();
    }
    return {
      'created_at': Variable<int>(createdAt),
      'origin': Variable<String>(origin),
      'edited_by_user': Variable<bool>(edited),
      for (final (name, camel, column) in _columns)
        name: _variable(column, payload.containsKey(camel), payload[camel]),
    };
  }

  /// A whole JSON number as an int (the server admits `1990.0`, B19).
  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is double && value.isFinite && value == value.truncate()) {
      return value.toInt();
    }
    return null;
  }

  static Expression<Object> _variable(
    GeneratedColumn<Object> column,
    bool present,
    Object? value,
  ) {
    if (value == null) {
      if (!column.$nullable) throw const SyncDecodeFailure();
      return const Variable<Object>(null);
    }
    if (!present) throw const SyncDecodeFailure();
    return switch (column.type) {
      DriftSqlType.bool when value is bool => Variable<bool>(value),
      DriftSqlType.int when _int(value) != null => Variable<int>(_int(value)),
      DriftSqlType.double when value is num => Variable<double>(
        value.toDouble(),
      ),
      DriftSqlType.string when value is String => Variable<String>(value),
      _ => throw const SyncDecodeFailure(),
    };
  }

  @override
  Map<String, Expression<Object>> get tombstoneLocalColumns => const {};
}

/// The generic codec of every synced table of [tables], by entity: the
/// starting point the app overrides per entity (`app/app_scope.dart`).
Map<String, SyncEntityCodec> columnSyncCodecs(
  Iterable<SyncedTable<Table, Object?>> tables,
) => {for (final t in tables) t.entity: ColumnSyncCodec(t)};
