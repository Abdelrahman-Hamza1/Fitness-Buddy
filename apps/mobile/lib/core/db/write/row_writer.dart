import 'dart:math' show min;

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/op_handler.dart' show idColumnOf;
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/synced_tables.dart';
import 'package:fb_mobile/core/db/tables/sync_columns.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/db/write_guarded.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// The only writer of user data (A01 D2, D3, D11): runs [RowOp]s and stamps
/// the sync metadata. Restricted: only `core/changes/change_set_applier.dart`
/// imports it (`tools/app_check` rule `db-write-api`, A01 D12).
///
/// One [RowWriteSession] per change set, inside its transaction, which
/// batches the writes (see there).
final class RowWriter {
  /// A writer over `db` for its synced `tables`.
  new(this._db, Iterable<SyncedTable<Table, Object?>> tables)
    : _tables = {for (final t in tables) t.sqlName: t};

  final WriteGuarded _db;
  final Map<String, SyncedTable<Table, Object?>> _tables;

  /// A session for one change set: its writes are stamped with HLCs from
  /// [hlc] (whose device ID they carry), [origin] (text form) and the
  /// instant [nowMs] (UTC ms).
  RowWriteSession session({
    required HybridLogicalClock hlc,
    required String origin,
    required int nowMs,
  }) => RowWriteSession._(this, hlc, origin, nowMs);
}

/// A row's version and whether it's a tombstone.
typedef _RowState = ({int version, bool deleted});

/// One statement of a batch.
typedef _Statement = void Function(Batch batch);

/// The writes of one change set: runs each [RowOp] and keeps the first
/// snapshot of every row it touches, for the inverse (A01 D2).
///
/// Writes are queued by [write] and run at the next [flush] (A01 WP5): one
/// snapshot query per table for the rows not touched yet, the checks in
/// Dart, then one batch, so a change set costs a handful of round trips to
/// the database isolate instead of two per row. The outcome is the same as
/// running each write when it's queued: the checks and statements keep
/// their order, a check that fails first runs the writes queued before it
/// (whose failure comes first), and reads inside [planning] flush first
/// (through the read barrier of `WriteGuard`, which is why the database
/// must be [WriteGuarded]). Only the batch runs in a `runAuthorizedWrite`
/// scope, so the handlers that plan the writes can't write.
final class RowWriteSession {
  new _(this._writer, this._hlc, this._origin, this._nowMs);

  /// Rows per snapshot query (well under SQLite's variable limit).
  static const int _chunk = 500;

  final RowWriter _writer;
  final HybridLogicalClock _hlc;
  final String _origin;
  final int _nowMs;

  final Map<(String, String), _Touch> _touched = {};
  final List<RowOp> _queued = [];
  Future<void>? _flushing;
  (Object, StackTrace)? _failure;
  Hlc? _lastHlc;

  WriteGuarded get _db => _writer._db;

  /// The newest HLC written, or `null` if nothing was.
  Hlc? get lastHlc => _lastHlc;

  /// The entity wire names of the rows written.
  Set<String> get entities => {for (final t in _touched.values) t.table.entity};

  /// Queues [op]; it runs at the next [flush] (or [finish]), which throws
  /// [ChangeRejected] if a precondition fails.
  void write(RowOp op) => _queued.add(op);

  /// Runs [plan] (an op handler's planning) so that every read it makes
  /// first runs the queued writes.
  Future<T> planning<T>(Future<T> Function() plan) =>
      runWithReadBarrier(flush, plan);

  /// Runs the queued writes. Throws [ChangeRejected] if a precondition
  /// fails; after a failure every later call throws it again.
  Future<void> flush() => _drain(finish: false);

  /// Runs the queued writes, then upserts `sync_state['hlc.last']` (A01
  /// D10) if anything was written. The last call of a session.
  Future<void> finish() => _drain(finish: true);

  Future<void> _drain({required bool finish}) async {
    // Reads made in parallel wait for the flush already running.
    for (var running = _flushing; running != null; running = _flushing) {
      await running;
    }
    if (_failure case (final error, final stack)) {
      Error.throwWithStackTrace(error, stack);
    }
    if (_queued.isEmpty && !(finish && _lastHlc != null)) return;
    final ops = List.of(_queued);
    _queued.clear();
    final running = _flushing = _run(ops, finish: finish);
    try {
      await running;
    } on Object catch (error, stack) {
      _failure = (error, stack);
      rethrow;
    } finally {
      _flushing = null;
    }
  }

  Future<void> _run(List<RowOp> ops, {required bool finish}) async {
    final prefetch = await _prefetch(ops);
    final statements = <_Statement>[];
    final updated = <(String, String)>{};
    (Object, StackTrace)? failed;
    for (final op in ops) {
      try {
        _plan(op, prefetch, statements, updated);
      } on Object catch (error, stack) {
        // The writes queued before it run first: their failure comes first.
        failed = (error, stack);
        break;
      }
    }
    if (finish && failed == null) {
      if (_lastHlc case final last?) {
        statements.add(
          (batch) => batch.customStatement(
            "INSERT INTO sync_state (key, value) VALUES ('hlc.last', ?) "
            'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
            [last.toString()],
          ),
        );
      }
    }
    if (statements.isNotEmpty) {
      await _guarded(
        () => _db.batch((batch) {
          for (final statement in statements) {
            statement(batch);
          }
        }),
      );
    }
    if (updated.isNotEmpty) await _checkUpdated(updated);
    if (failed case (final error, final stack)) {
      Error.throwWithStackTrace(error, stack);
    }
  }

  /// Checks [op] against the rows as the earlier writes left them, adds its
  /// statement to [statements] and records the touch. Throws
  /// [ChangeRejected] if a precondition fails (and drift's error if the row
  /// is invalid).
  void _plan(
    RowOp op,
    _Prefetch prefetch,
    List<_Statement> statements,
    Set<(String, String)> updated,
  ) {
    final synced = _writer._tables[op.table.actualTableName];
    if (synced == null) throw const ChangeRejected(InvalidOp('unsyncedTable'));
    final key = (synced.sqlName, op.id);
    final touch = _touched[key];
    // The row now: as this session left it, or as it was before.
    final snapshot = touch == null ? prefetch.rows[key] : null;
    final current = switch ((touch, snapshot)) {
      (final _Touch t?, _) => (version: t.version, deleted: t.deleted),
      (null, final Map<String, Object?> row?) => (
        version: _version(row),
        deleted: row['deleted_at'] != null,
      ),
      (null, null) => null,
    };
    void update(int from, Map<String, Expression<Object>> values) {
      statements.add(_update(synced, op.id, from, values));
      updated.add(key);
    }

    final int version;
    final bool deleted;
    switch (op) {
      case InsertRow(:final row):
        final content = _content(synced, row, allowId: true);
        if (current != null || prefetch.existing.contains(key)) {
          throw const ChangeRejected(ConstraintViolation('duplicateId'));
        }
        statements.add(_insert(synced, op.id, content));
        version = 1;
        deleted = false;
      case UpsertRow(:final row):
        final content = _content(synced, row, allowId: true);
        if (current == null) {
          statements.add(_insert(synced, op.id, content));
          version = 1;
        } else {
          content.remove('id');
          update(current.version, {
            ...content,
            'deleted_at': const Variable<int>(null),
          });
          version = current.version + 1;
        }
        deleted = false;
      case UpdateRow(:final changes, :final expectedVersion):
        final content = _content(synced, changes, allowId: false);
        final from = _live(synced, op.id, current, expectedVersion);
        update(from, content);
        version = from + 1;
        deleted = false;
      case TombstoneRow(:final expectedVersion):
        final from = _live(synced, op.id, current, expectedVersion);
        update(from, {'deleted_at': Variable<int>(_nowMs)});
        version = from + 1;
        deleted = true;
      case RestoreRow(snapshot: final restored, :final expectedVersion):
        if (current == null) {
          throw ChangeRejected(RowNotFound(entity: synced.entity, id: op.id));
        }
        _checkVersion(synced, op.id, expectedVersion, current.version);
        final columns = synced.table.columnsByName;
        update(expectedVersion, {
          for (final c in [
            ...synced.contentColumns,
            columns['deleted_at']!,
            columns['edited_by_user']!,
          ])
            // Raw SQL values back to Dart values (a bool is 0/1 in SQL).
            c.name: Variable<Object>(
              _db.typeMapping.read(c.type, restored[c.name]),
            ),
        });
        version = expectedVersion + 1;
        deleted = restored['deleted_at'] != null;
    }
    (touch ?? (_touched[key] = _Touch(synced, op.id, snapshot)))
      ..version = version
      ..deleted = deleted;
  }

  /// The row writes that undo this session's (A01 D2, D3), newest first: a
  /// row that existed is restored to its first snapshot, a new row is
  /// tombstoned (unless it already is).
  List<RowOp> inverseRows() => [
    for (final t in _touched.values.toList().reversed)
      if (t.before case final before?)
        RestoreRow(t.table.table, t.id, before, expectedVersion: t.version)
      else if (!t.deleted)
        TombstoneRow(t.table.table, t.id, expectedVersion: t.version),
  ];

  /// What [ops] need to know about the rows this session hasn't touched
  /// yet: whether a row an [InsertRow] writes exists (one query over every
  /// table), and the other rows as raw SQL values (one query per table).
  /// Untouched rows aren't changed by the queued writes, so reading them
  /// before those run is the same as reading them in order.
  Future<_Prefetch> _prefetch(List<RowOp> ops) async {
    final full = <String, Set<String>>{};
    final inserted = <String, Set<String>>{};
    for (final op in ops) {
      final synced = _writer._tables[op.table.actualTableName];
      if (synced == null || _touched.containsKey((synced.sqlName, op.id))) {
        continue;
      }
      final ids = op is InsertRow ? inserted : full;
      (ids[synced.sqlName] ??= {}).add(op.id);
    }
    final prefetch = _Prefetch();
    for (final MapEntry(key: table, value: ids) in full.entries) {
      inserted[table]?.removeAll(ids);
      for (final chunk in _chunks(ids.toList())) {
        final rows = await _db
            .customSelect(
              'SELECT * FROM "$table" WHERE id IN (${_marks(chunk.length)})',
              variables: [for (final id in chunk) Variable.withString(id)],
              readsFrom: {_writer._tables[table]!.table},
            )
            .get();
        for (final row in rows) {
          prefetch.rows[(table, row.read<String>('id'))] = row.data;
        }
      }
    }
    final pairs = [
      for (final MapEntry(key: table, value: ids) in inserted.entries)
        for (final id in ids) (table, id),
    ];
    for (var i = 0; i < pairs.length; i += _chunk) {
      final chunk = pairs.sublist(i, min(i + _chunk, pairs.length));
      final byTable = <String, List<String>>{};
      for (final (table, id) in chunk) {
        (byTable[table] ??= []).add(id);
      }
      // Table names are the synced tables' own, never input.
      final rows = await _db
          .customSelect(
            [
              for (final MapEntry(key: table, value: ids) in byTable.entries)
                _existing(table, ids.length),
            ].join(' UNION ALL '),
            variables: [
              for (final ids in byTable.values)
                for (final id in ids) Variable.withString(id),
            ],
            readsFrom: {
              for (final table in byTable.keys) _writer._tables[table]!.table,
            },
          )
          .get();
      for (final row in rows) {
        prefetch.existing.add((row.read<String>('t'), row.read<String>('id')));
      }
    }
    return prefetch;
  }

  /// Checks that each row in [updated] is at the version this session left
  /// it (a batch doesn't report what each update changed).
  Future<void> _checkUpdated(Set<(String, String)> updated) async {
    final byTable = <String, List<String>>{};
    for (final (table, id) in updated) {
      (byTable[table] ??= []).add(id);
    }
    for (final MapEntry(key: table, value: ids) in byTable.entries) {
      final synced = _writer._tables[table]!;
      for (final chunk in _chunks(ids)) {
        final rows = await _db
            .customSelect(
              'SELECT id, version FROM "$table" '
              'WHERE id IN (${_marks(chunk.length)})',
              variables: [for (final id in chunk) Variable.withString(id)],
              readsFrom: {synced.table},
            )
            .get();
        final versions = {
          for (final row in rows)
            row.read<String>('id'): row.read<int>('version'),
        };
        for (final id in chunk) {
          if (versions[id] != _touched[(table, id)]!.version) {
            // The snapshot was read in this transaction, so this is a bug.
            throw StateError(
              'a ${synced.entity} row changed inside its transaction',
            );
          }
        }
      }
    }
  }

  /// The version of the live row [current], after checking it exists and
  /// is at [expected] (when given).
  int _live(
    SyncedTable<Table, Object?> synced,
    String id,
    _RowState? current,
    int? expected,
  ) {
    if (current == null || current.deleted) {
      throw ChangeRejected(RowNotFound(entity: synced.entity, id: id));
    }
    if (expected != null) {
      _checkVersion(synced, id, expected, current.version);
    }
    return current.version;
  }

  void _checkVersion(
    SyncedTable<Table, Object?> synced,
    String id,
    int expected,
    int actual,
  ) {
    if (expected != actual) {
      throw ChangeRejected(
        VersionConflict(
          entity: synced.entity,
          id: id,
          expected: expected,
          actual: actual,
        ),
      );
    }
  }

  static int _version(Map<String, Object?> snapshot) =>
      snapshot['version']! as int;

  /// The content columns [row] sets (and its `id` if [allowId]); sync
  /// metadata other than `edited_by_user` is the writer's.
  static Map<String, Expression<Object>> _content(
    SyncedTable<Table, Object?> synced,
    Insertable<Object?> row, {
    required bool allowId,
  }) {
    final columns = row.toColumns(false);
    for (final name in columns.keys) {
      if (!synced.table.columnsByName.containsKey(name)) {
        throw const ChangeRejected(InvalidOp('unknownColumn'));
      }
      final isMeta = syncColumnNames.contains(name);
      if (isMeta && name != 'edited_by_user' && !(allowId && name == 'id')) {
        throw const ChangeRejected(InvalidOp('metaColumn'));
      }
    }
    return Map.of(columns);
  }

  Hlc _nextHlc() => _lastHlc = _hlc.now();

  /// The insert of row [id] with [content], stamped.
  _Statement _insert(
    SyncedTable<Table, Object?> synced,
    String id,
    Map<String, Expression<Object>> content,
  ) {
    final row = synced.rawRow({
      ...content,
      'id': Variable<String>(id),
      'created_at': Variable<int>(_nowMs),
      'updated_hlc': Variable<String>(_nextHlc().toString()),
      'version': const Variable<int>(1),
      'deleted_at': const Variable<int>(null),
      'device_id': Variable<String>(_hlc.deviceId),
      'origin': Variable<String>(_origin),
    });
    // drift's checks run in op order, like the statements.
    _checkValid(synced.table.validateIntegrity(row, isInserting: true));
    return (batch) => batch.insert(synced.table, row);
  }

  /// The update of row [id], at version [from], with [values], stamped (to
  /// version `from + 1`).
  _Statement _update(
    SyncedTable<Table, Object?> synced,
    String id,
    int from,
    Map<String, Expression<Object>> values,
  ) {
    final table = synced.table;
    final version = table.columnsByName['version']! as GeneratedColumn<int>;
    final row = synced.rawRow({
      ...values,
      'updated_hlc': Variable<String>(_nextHlc().toString()),
      'version': Variable<int>(from + 1),
      'device_id': Variable<String>(_hlc.deviceId),
      'origin': Variable<String>(_origin),
    });
    _checkValid(table.validateIntegrity(row));
    return (batch) => batch.update(
      table,
      row,
      where: (_) => idColumnOf(table).equals(id) & version.equals(from),
    );
  }

  /// Rejects a row drift's checks find invalid (`InvalidOp('invalidRow')`)
  /// without drift's message, which quotes the row's values.
  static void _checkValid(VerificationContext checks) {
    if (!checks.dataValid) throw const ChangeRejected(InvalidOp('invalidRow'));
  }

  /// Runs write statements as the single writer, mapping SQLite constraint
  /// errors to [ConstraintViolation] and other SQLite errors to a
  /// [DatabaseWriteException] (SQLite's message quotes the statement's
  /// arguments: the row values).
  static Future<R> _guarded<R>(Future<R> Function() write) async {
    try {
      return await runAuthorizedWrite(write);
    } on Exception catch (error, stack) {
      final sqlite = switch (error) {
        SqliteException() => error,
        DriftRemoteException(:final SqliteException remoteCause) => remoteCause,
        _ => null,
      };
      if (sqlite == null) rethrow;
      if (sqlite.resultCode == _sqliteConstraint) {
        throw ChangeRejected(
          ConstraintViolation(_constraintKind(sqlite.extendedResultCode)),
        );
      }
      Error.throwWithStackTrace(
        DatabaseWriteException(sqlite.extendedResultCode, debugCause: error),
        stack,
      );
    }
  }

  static const int _sqliteConstraint = 19;

  static String _constraintKind(int extendedCode) => switch (extendedCode) {
    2067 => 'unique',
    1555 => 'primaryKey',
    1299 => 'notNull',
    275 => 'check',
    787 => 'foreignKey',
    _ => 'constraint',
  };
}

/// [count] SQL parameter marks: `?, ?, ?`.
String _marks(int count) => List.filled(count, '?').join(', ');

/// The `(t, id)` of the rows of [table] among [count] ids.
String _existing(String table, int count) =>
    "SELECT '$table' AS t, id FROM \"$table\" WHERE id IN (${_marks(count)})";

/// What a flush read before checking its writes.
final class _Prefetch {
  /// The rows of the non-insert writes that exist, by table and id.
  final Map<(String, String), Map<String, Object?>> rows = {};

  /// The rows of the inserts that already exist (not in [rows]).
  final Set<(String, String)> existing = {};
}

/// [ids] in runs of at most `RowWriteSession._chunk`.
Iterable<List<String>> _chunks(List<String> ids) sync* {
  for (var i = 0; i < ids.length; i += RowWriteSession._chunk) {
    yield ids.sublist(i, min(i + RowWriteSession._chunk, ids.length));
  }
}

final class _Touch {
  new(this.table, this.id, this.before);

  final SyncedTable<Table, Object?> table;
  final String id;

  /// The row before the change set's first write to it (`null`: new row).
  final Map<String, Object?>? before;

  /// The version the change set's last write to it left.
  int version = 0;

  /// Whether that write left a tombstone.
  bool deleted = false;
}
