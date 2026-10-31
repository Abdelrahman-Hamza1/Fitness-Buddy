import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/isolate.dart' show DriftRemoteException;
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/migrations/from_13_to_14.dart'
    show dayFactorsSinceKey;
import 'package:fb_mobile/core/db/sync/sync_codec.dart';
import 'package:fb_mobile/core/db/synced_tables.dart';
import 'package:fb_mobile/core/db/write_guard.dart';
import 'package:fb_mobile/core/sync/sync_status.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:sqlite3/common.dart' show SqliteException;

/// Runs a remote apply in the single writer's serial queue (the
/// `ChangeSetApplier.runExclusive` of the open profile, A34 D9).
typedef ExclusiveWrite = Future<T> Function<T>(Future<T> Function() body);

/// The app's [SyncStore] over `user.db` (A34 D3–D9): the outbox the
/// triggers fill, the synced tables, `sync_parked`, `sync_deferred` and the
/// `sync.*` keys of `sync_state`. Every method is one SQLite transaction.
///
/// It lives in `core/db/` because it writes rows outside the
/// `ChangeSetApplier` (A01 D11): remote apply is sync's own write path, run
/// inside the applier's serial queue ([ExclusiveWrite]) with outbox capture
/// off, so it never races a local change set and never re-enqueues a
/// pulled version.
final class DriftSyncStore implements SyncStore {
  /// A store over [_db] with one codec per synced entity (`codecs`),
  /// reading time from [_clock]; [_deviceId] is this install's id (the HLC
  /// node) and [_exclusive] the applier's serial queue.
  new(
    this._db, {
    required this._codecs,
    required this._clock,
    required this._deviceId,
    required this._exclusive,
  }) : _tables = {for (final t in _db.syncedTables) t.entity: t};

  final AppDatabase _db;
  final Map<String, SyncEntityCodec> _codecs;
  final Clock _clock;
  final Future<String> Function() _deviceId;
  final ExclusiveWrite _exclusive;
  final Map<String, SyncedTable<Table, Object?>> _tables;

  static const _cursorKey = 'sync.cursor';
  static const _datasetKey = 'sync.dataset';
  static const _resetKey = 'sync.reset';
  static const _successKey = 'sync.lastSuccessMs';
  static const _parkedRetryKey = 'sync.parkedRetryMs';
  static const _appVersionKey = 'sync.appVersion';

  /// Rows per `IN (…)` query (under SQLite's variable limit).
  static const int _chunk = 500;

  // ---- reads ----------------------------------------------------------

  Future<Map<String, String>> _state() async {
    final rows = await _db
        .customSelect(
          "SELECT key, value FROM sync_state WHERE key LIKE 'sync.%'",
          readsFrom: {_db.syncState},
        )
        .get();
    return {
      for (final r in rows) r.read<String>('key'): r.read<String>('value'),
    };
  }

  @override
  Future<SyncCheckpoint> checkpoint() async {
    final state = await _state();
    return SyncCheckpoint(
      cursor: state[_cursorKey] ?? '0',
      datasetId: state[_datasetKey],
      resetActive: state[_resetKey] == '1',
    );
  }

  /// The local `version` of row [id] of [entity], or `null` when absent.
  Future<int?> localVersion(String entity, String id) async {
    final table = _tables[entity];
    if (table == null) return null;
    final row = await _db
        .customSelect(
          'SELECT version FROM "${table.sqlName}" WHERE id = ?',
          variables: [Variable.withString(id)],
          readsFrom: {table.table},
        )
        .getSingleOrNull();
    return row?.read<int>('version');
  }

  /// The indicator's numbers.
  Future<LocalSyncCounts> counts() async {
    final row = await _db
        .customSelect(
          'SELECT '
          '(SELECT count(*) FROM (SELECT 1 FROM sync_outbox '
          'GROUP BY entity, row_id)) + (SELECT count(*) FROM sync_displaced '
          'WHERE parked_reason IS NULL) AS pending, '
          '(SELECT count(*) FROM sync_parked) + (SELECT count(*) FROM '
          'sync_displaced WHERE parked_reason IS NOT NULL) AS parked, '
          '(SELECT min(hlc) FROM (SELECT hlc FROM sync_outbox UNION ALL '
          'SELECT hlc FROM sync_displaced WHERE parked_reason IS NULL)) '
          'AS oldest, '
          "(SELECT value FROM sync_state WHERE key = '$_successKey') "
          'AS success',
          readsFrom: {
            _db.syncOutbox,
            _db.syncParked,
            _db.syncDisplaced,
            _db.syncState,
          },
        )
        .getSingle();
    final oldest = row.readNullable<String>('oldest');
    return LocalSyncCounts(
      pendingRows: row.read<int>('pending'),
      parked: row.read<int>('parked'),
      oldestPendingMs: oldest == null ? null : Hlc.tryParse(oldest)?.wallMs,
      lastSuccessMs: int.tryParse(row.readNullable<String>('success') ?? ''),
    );
  }

  /// [counts], again whenever the outbox, the parked or displaced sets or
  /// the sync keys change (the applier and this store notify them).
  ///
  /// Driven by drift's table-update notifications rather than a query
  /// stream: Riverpod 3 pauses an unlistened provider's subscription, and a
  /// drift query stream treats a pause like a cancel (closing the query
  /// and scheduling a cleanup timer each time a watcher rebuilds). This
  /// controller buffers while paused.
  Stream<LocalSyncCounts> watchCounts() {
    StreamSubscription<Set<TableUpdate>>? updates;
    late final StreamController<LocalSyncCounts> controller;
    Future<void> emit() async {
      try {
        final value = await counts();
        if (!controller.isClosed) controller.add(value);
      } on Object {
        // A closing database: the stream ends with its listener.
      }
    }

    controller = StreamController<LocalSyncCounts>(
      onListen: () {
        unawaited(emit());
        updates = _db
            .tableUpdates(
              TableUpdateQuery.onAllTables([
                _db.syncOutbox,
                _db.syncParked,
                _db.syncDisplaced,
                _db.syncState,
              ]),
            )
            .listen((_) => unawaited(emit()));
      },
      // Not awaited: a listener's cancel never waits on the database.
      onCancel: () {
        unawaited(updates?.cancel());
        updates = null;
      },
    );
    return controller.stream;
  }

  @override
  Future<PendingRead> pending({required int limit}) async {
    final changes = <SyncChange>[];
    final refused = <ParkedVersion>[];
    // Displaced versions first (A34 fix 1): they are older than the rows.
    final displaced = await _db
        .customSelect(
          'SELECT entity, row_id, row_json FROM sync_displaced '
          'WHERE parked_reason IS NULL ORDER BY rowid LIMIT ?',
          variables: [Variable.withInt(limit)],
          readsFrom: {_db.syncDisplaced},
        )
        .get();
    for (final d in displaced) {
      _encodeInto(
        d.read<String>('entity'),
        d.read<String>('row_id'),
        jsonDecode(d.read<String>('row_json')) as Map<String, Object?>,
        changes,
        refused,
      );
    }
    final room = limit - displaced.length;
    final heads = room <= 0
        ? const <QueryRow>[]
        : await _db
              .customSelect(
                'SELECT entity, row_id, min(seq) AS first FROM sync_outbox '
                'GROUP BY entity, row_id ORDER BY first LIMIT ?',
                variables: [Variable.withInt(room)],
                readsFrom: {_db.syncOutbox},
              )
              .get();
    final byEntity = <String, List<String>>{};
    for (final h in heads) {
      (byEntity[h.read<String>('entity')] ??= []).add(h.read<String>('row_id'));
    }
    final rows = <String, Map<String, Object?>>{};
    for (final MapEntry(key: entity, value: ids) in byEntity.entries) {
      final table = _tables[entity];
      if (table == null) continue;
      for (var i = 0; i < ids.length; i += _chunk) {
        final chunk = ids.sublist(i, (i + _chunk).clamp(0, ids.length));
        final found = await _db
            .customSelect(
              'SELECT * FROM "${table.sqlName}" '
              'WHERE id IN (${List.filled(chunk.length, '?').join(', ')})',
              variables: [for (final id in chunk) Variable.withString(id)],
              readsFrom: {table.table},
            )
            .get();
        for (final r in found) {
          rows['$entity/${r.read<String>('id')}'] = r.data;
        }
      }
    }
    final orphans = <(String, String)>[];
    for (final h in heads) {
      final entity = h.read<String>('entity');
      final id = h.read<String>('row_id');
      final row = rows['$entity/$id'];
      if (row == null) {
        // No row behind the outbox entry (never expected: synced rows are
        // tombstoned, not deleted): nothing to push.
        orphans.add((entity, id));
        continue;
      }
      _encodeInto(entity, id, row, changes, refused);
    }
    if (refused.isNotEmpty || orphans.isNotEmpty) {
      await _write(() async {
        for (final (entity, id) in orphans) {
          await _db.customStatement(
            'DELETE FROM sync_outbox WHERE entity = ? AND row_id = ?',
            [entity, id],
          );
        }
        await _park(refused);
      });
    }
    return PendingRead(changes, parkedNow: refused);
  }

  /// Encodes stored [row] (raw SQL values) of [entity] as a change into
  /// [changes], or a refusal into [refused].
  void _encodeInto(
    String entity,
    String id,
    Map<String, Object?> row,
    List<SyncChange> changes,
    List<ParkedVersion> refused,
  ) {
    final version = SyncVersion(entity, id, row['updated_hlc']! as String);
    final codec = _codecs[entity];
    if (codec == null) {
      refused.add(ParkedVersion(version, 'noCodec'));
      return;
    }
    try {
      final deletedAt = row['deleted_at'] as int?;
      changes.add(
        SyncChange(
          entity: entity,
          id: id,
          schemaVersion: codec.uploadVersion,
          hlc: version.hlc,
          deviceId: row['device_id']! as String,
          deletedAt: deletedAt == null
              ? null
              : DateTime.fromMillisecondsSinceEpoch(deletedAt, isUtc: true),
          payload: codec.encode(row),
        ),
      );
    } on SyncEncodeRefused catch (refusal) {
      refused.add(ParkedVersion(version, refusal.code));
    } on Object {
      refused.add(ParkedVersion(version, 'encodeFailed'));
    }
  }

  /// When this install began storing weekday factors (the v14 step's
  /// marker, UTC ms), or null for a fresh install (A53 D2).
  Future<int?> dayFactorsSinceMs() async {
    final row = await _db
        .customSelect(
          'SELECT value FROM sync_state WHERE key = ?',
          variables: [Variable.withString(dayFactorsSinceKey)],
        )
        .getSingleOrNull();
    return int.tryParse(row?.read<String>('value') ?? '');
  }

  // ---- writes ---------------------------------------------------------

  /// One authorized transaction (sync's bookkeeping; no synced row).
  Future<T> _write<T>(Future<T> Function() body) async {
    final result = await runAuthorizedWrite(() => _db.transaction(body));
    _db.notifyUpdates({
      const TableUpdate('sync_outbox'),
      const TableUpdate('sync_parked'),
      const TableUpdate('sync_displaced'),
      const TableUpdate('sync_state'),
    });
    return result;
  }

  Future<void> _setState(String key, String? value) => value == null
      ? _db.customStatement('DELETE FROM sync_state WHERE key = ?', [key])
      : _db.customStatement(
          'INSERT INTO sync_state (key, value) VALUES (?, ?) '
          'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
          [key, value],
        );

  Future<void> _park(List<ParkedVersion> parked) async {
    final now = _clock.nowUtc().millisecondsSinceEpoch;
    for (final p in parked) {
      final v = p.version;
      // A displaced version is parked where it is, payload kept.
      final displaced = await _db
          .customSelect(
            'SELECT 1 FROM sync_displaced '
            'WHERE entity = ? AND row_id = ? AND hlc = ?',
            variables: [
              for (final x in [v.entity, v.id, v.hlc]) Variable.withString(x),
            ],
            readsFrom: {_db.syncDisplaced},
          )
          .getSingleOrNull();
      if (displaced != null) {
        await _db.customStatement(
          'UPDATE sync_displaced SET parked_reason = ? '
          'WHERE entity = ? AND row_id = ? AND hlc = ?',
          [p.reason, v.entity, v.id, v.hlc],
        );
        continue;
      }
      await _db.customStatement(
        'DELETE FROM sync_outbox WHERE entity = ? AND row_id = ? AND hlc <= ?',
        [v.entity, v.id, v.hlc],
      );
      // One parked version per row: the newest.
      await _db.customStatement(
        'DELETE FROM sync_parked WHERE entity = ? AND row_id = ? AND hlc < ?',
        [v.entity, v.id, v.hlc],
      );
      await _db.customStatement(
        'INSERT INTO sync_parked (entity, row_id, hlc, reason, parked_at) '
        'SELECT ?, ?, ?, ?, ? WHERE NOT EXISTS (SELECT 1 FROM sync_parked '
        'WHERE entity = ? AND row_id = ? AND hlc >= ?)',
        [v.entity, v.id, v.hlc, p.reason, now, v.entity, v.id, v.hlc],
      );
    }
  }

  @override
  Future<void> settle({
    List<SyncVersion> acknowledged = const [],
    List<ParkedVersion> parked = const [],
  }) {
    if (acknowledged.isEmpty && parked.isEmpty) return Future.value();
    return _write(() async {
      for (final v in acknowledged) {
        for (final table in ['sync_outbox', 'sync_parked']) {
          await _db.customStatement(
            'DELETE FROM $table WHERE entity = ? AND row_id = ? AND hlc <= ?',
            [v.entity, v.id, v.hlc],
          );
        }
        // A displaced version leaves only with its own acknowledgement.
        await _db.customStatement(
          'DELETE FROM sync_displaced '
          'WHERE entity = ? AND row_id = ? AND hlc = ?',
          [v.entity, v.id, v.hlc],
        );
      }
      await _park(parked);
    });
  }

  @override
  Future<void> bindDataset(String datasetId) => _write(() async {
    final cp = await checkpoint();
    if (cp.datasetId != null || cp.cursor != '0') return;
    await _setState(_datasetKey, datasetId);
  });

  @override
  Future<void> beginReset() => _write(() async {
    await _setState(_cursorKey, '0');
    await _setState(_datasetKey, null);
    await _setState(_resetKey, '1');
    for (final table in _tables.values) {
      // Entity and table names are the registry's own, never input.
      await _db.customStatement(
        'INSERT INTO sync_outbox (entity, row_id, hlc, deleted) '
        "SELECT '${table.entity}', id, updated_hlc, deleted_at IS NOT NULL "
        'FROM "${table.sqlName}"',
      );
    }
  });

  @override
  Future<void> recordSuccess(DateTime at) =>
      _write(() => _setState(_successKey, '${at.millisecondsSinceEpoch}'));

  @override
  Future<int> retryParked() => _write(() async {
    final count = await _db
        .customSelect(
          'SELECT (SELECT count(*) FROM sync_parked) + (SELECT count(*) '
          'FROM sync_displaced WHERE parked_reason IS NOT NULL) AS n',
          readsFrom: {_db.syncParked, _db.syncDisplaced},
        )
        .getSingle();
    await _db.customStatement(
      'INSERT INTO sync_outbox (entity, row_id, hlc, deleted) '
      'SELECT entity, row_id, hlc, 0 FROM sync_parked',
    );
    await _db.customStatement('DELETE FROM sync_parked');
    await _db.customStatement('UPDATE sync_displaced SET parked_reason = NULL');
    return count.read<int>('n');
  });

  /// Moves parked versions back to the outbox once per [appVersion] and at
  /// most once a day (A34 D5: an app or server update may have fixed the
  /// cause). Returns how many were retried.
  Future<int> retryParkedIfDue({
    required int nowMs,
    required String appVersion,
  }) async {
    final state = await _state();
    final last = int.tryParse(state[_parkedRetryKey] ?? '') ?? 0;
    final versionChanged = state[_appVersionKey] != appVersion;
    if (!versionChanged &&
        nowMs - last < const Duration(days: 1).inMilliseconds) {
      return 0;
    }
    return await _write(() async {
      await _setState(_parkedRetryKey, '$nowMs');
      await _setState(_appVersionKey, appVersion);
      final count = await _db
          .customSelect(
            'SELECT (SELECT count(*) FROM sync_parked) + (SELECT count(*) '
            'FROM sync_displaced WHERE parked_reason IS NOT NULL) AS n',
            readsFrom: {_db.syncParked, _db.syncDisplaced},
          )
          .getSingle();
      await _db.customStatement(
        'INSERT INTO sync_outbox (entity, row_id, hlc, deleted) '
        'SELECT entity, row_id, hlc, 0 FROM sync_parked',
      );
      await _db.customStatement('DELETE FROM sync_parked');
      await _db.customStatement(
        'UPDATE sync_displaced SET parked_reason = NULL',
      );
      return count.read<int>('n');
    });
  }

  // ---- remote apply -----------------------------------------------------

  @override
  Future<PageApplied> applyPage(
    SyncPage page, {
    required String requestedCursor,
  }) async {
    var previous = BigInt.tryParse(requestedCursor);
    if (previous == null) throw const SyncFailure(SyncFailureKind.protocol);
    for (final document in page.changes) {
      final seq = BigInt.tryParse(document.serverSeq);
      if (seq == null || seq <= previous!) {
        throw const SyncFailure(SyncFailureKind.protocol);
      }
      previous = seq;
    }
    final expected = page.changes.isEmpty
        ? requestedCursor
        : page.changes.last.serverSeq;
    if (page.nextCursor != expected) {
      throw const SyncFailure(SyncFailureKind.protocol);
    }
    return await _remote((apply) async {
      final reset = (await checkpoint()).resetActive;
      final result = await apply(page.changes, fromDeferred: false);
      if (reset) {
        for (final d in page.changes) {
          await _db.customStatement(
            'DELETE FROM sync_outbox '
            'WHERE entity = ? AND row_id = ? AND hlc <= ?',
            [d.entity, d.id, d.hlc],
          );
        }
        if (page.changes.isEmpty) await _setState(_resetKey, null);
      }
      await _setState(_cursorKey, page.nextCursor);
      await _setState(_datasetKey, page.datasetId);
      return result;
    });
  }

  @override
  Future<PageApplied> retryDeferred() async {
    final stored = await _db
        .customSelect(
          'SELECT document_json FROM sync_deferred',
          readsFrom: {_db.syncDeferred},
        )
        .get();
    if (stored.isEmpty) return const PageApplied();
    final documents = [
      for (final r in stored)
        SyncDocument.fromJson(
          jsonDecode(r.read<String>('document_json')) as Map<String, Object?>,
        ),
    ];
    return await _remote((apply) => apply(documents, fromDeferred: true));
  }

  /// Runs [body] as one remote-apply transaction in the applier's serial
  /// queue, with capture off and the clock restored from and saved to
  /// `hlc.last`; notifies the written tables after the commit.
  Future<PageApplied> _remote(
    Future<PageApplied> Function(
      Future<PageApplied> Function(
        List<SyncDocument> documents, {
        required bool fromDeferred,
      })
      apply,
    )
    body,
  ) async {
    final deviceId = await _deviceId();
    final touched = <String>{};
    final result = await _exclusive(
      () => runAuthorizedWrite(
        () => _db.transaction(() async {
          await _setCapture(on: false);
          final stored = await _db
              .customSelect(
                "SELECT value FROM sync_state WHERE key = 'hlc.last'",
                readsFrom: {_db.syncState},
              )
              .getSingleOrNull();
          final clock = HybridLogicalClock(
            clock: _clock,
            deviceId: deviceId,
            last: stored == null
                ? null
                : Hlc.tryParse(stored.read<String>('value')),
          );
          final outcome = await body(
            (documents, {required fromDeferred}) =>
                _applyDocuments(documents, clock, touched, fromDeferred),
          );
          if (clock.last case final last?) {
            await _db.customStatement(
              "INSERT INTO sync_state (key, value) VALUES ('hlc.last', ?) "
              'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
              [last.toString()],
            );
          }
          await _setCapture(on: true);
          return outcome;
        }),
      ),
    );
    _db.notifyUpdates({
      for (final sql in touched) TableUpdate(sql),
      const TableUpdate('sync_outbox'),
      const TableUpdate('sync_parked'),
      const TableUpdate('sync_displaced'),
      const TableUpdate('sync_state'),
      const TableUpdate('sync_deferred'),
    });
    return result;
  }

  Future<void> _setCapture({required bool on}) => _db.customStatement(
    "INSERT INTO sync_state (key, value) VALUES ('outbox.capture', ?) "
    'ON CONFLICT (key) DO UPDATE SET value = excluded.value',
    [if (on) '1' else '0'],
  );

  Future<PageApplied> _applyDocuments(
    List<SyncDocument> documents,
    HybridLogicalClock clock,
    Set<String> touched,
    bool fromDeferred,
  ) async {
    var applied = 0;
    final entities = <String>{};
    final deferred = <DeferredDocument>[];
    for (final d in documents) {
      final hlc = Hlc.tryParse(d.hlc);
      if (hlc == null) throw const SyncFailure(SyncFailureKind.protocol);
      if (clock.receive(hlc) is HlcDriftRejected) {
        throw const SyncFailure(SyncFailureKind.clockBehind);
      }
      final version = SyncVersion.ofDocument(d);
      final outcome = await _applyOne(d);
      if (fromDeferred && outcome is! _Deferred) {
        await _db.customStatement(
          'DELETE FROM sync_deferred '
          'WHERE entity = ? AND row_id = ? AND hlc = ?',
          [d.entity, d.id, d.hlc],
        );
      }
      switch (outcome) {
        case _Written(:final sqlName):
          applied++;
          entities.add(d.entity);
          touched.add(sqlName);
        case _Deferred(:final reason):
          if (!fromDeferred) {
            await _db.customStatement(
              'INSERT OR REPLACE INTO sync_deferred '
              '(entity, row_id, hlc, document_json, reason) '
              'VALUES (?, ?, ?, ?, ?)',
              [d.entity, d.id, d.hlc, jsonEncode(d.toJson()), reason],
            );
            deferred.add(DeferredDocument(version, reason));
          }
        case _Skipped():
          break;
      }
    }
    return PageApplied(
      applied: applied,
      entities: entities,
      deferred: deferred,
    );
  }

  Future<_Outcome> _applyOne(SyncDocument d) async {
    final table = _tables[d.entity];
    final codec = _codecs[d.entity];
    if (table == null || codec == null) return const _Deferred('unknownEntity');
    final sql = table.sqlName;
    final local = await _db
        .customSelect(
          'SELECT updated_hlc, version, deleted_at FROM "$sql" WHERE id = ?',
          variables: [Variable.withString(d.id)],
          readsFrom: {table.table},
        )
        .getSingleOrNull();
    if (local != null &&
        d.hlc.compareTo(local.read<String>('updated_hlc')) <= 0) {
      return const _Skipped();
    }
    final deletedAtMs = d.deletedAt?.millisecondsSinceEpoch;
    if (d.compacted) {
      // A deletion fence (B05): tombstone an older local row, meta only.
      if (local == null) return const _Skipped();
      await _displace(table, d.id, local.read<String>('updated_hlc'));
      final fenceMs =
          deletedAtMs ??
          local.readNullable<int>('deleted_at') ??
          Hlc.parse(d.hlc).wallMs;
      await _update(table, d.id, {
        'updated_hlc': Variable<String>(d.hlc),
        'device_id': Variable<String>(d.deviceId),
        'deleted_at': Variable<int>(fenceMs),
        'version': Variable<int>(local.read<int>('version') + 1),
        ...codec.tombstoneLocalColumns,
      });
      return _Written(sql);
    }
    final payload = SyncDocumentUpgraders.upgrade(
      d.entity,
      d.schemaVersion,
      d.payload,
    );
    if (payload == null) {
      return _Deferred(
        d.schemaVersion > SyncDocumentUpgraders.currentVersionOf(d.entity)
            ? 'newerSchema'
            : 'unreadable',
      );
    }
    final Map<String, Expression<Object>> columns;
    try {
      columns = codec.decode(payload, id: d.id, deleted: d.deletedAt != null);
    } on SyncDecodeFailure {
      return const _Deferred('unreadable');
    }
    if (local != null) {
      await _displace(table, d.id, local.read<String>('updated_hlc'));
    }
    final values = {
      ...columns,
      'updated_hlc': Variable<String>(d.hlc),
      'device_id': Variable<String>(d.deviceId),
      'deleted_at': Variable<int>(deletedAtMs),
      if (d.deletedAt != null) ...codec.tombstoneLocalColumns,
    };
    try {
      if (local == null) {
        await _db
            .into(table.table)
            .insert(
              table.rawRow({
                ...values,
                'id': Variable<String>(d.id),
                'version': const Variable<int>(1),
              }),
            );
      } else {
        await _update(table, d.id, {
          ...values,
          'version': Variable<int>(local.read<int>('version') + 1),
        });
      }
    } on Exception catch (error) {
      // A local CHECK refusing a server-accepted row (never expected: the
      // shared corpora pin the tables) defers it instead of failing the
      // page. Only that statement rolled back.
      final sqlite = switch (error) {
        SqliteException() => error,
        DriftRemoteException(:final SqliteException remoteCause) => remoteCause,
        _ => null,
      };
      if (sqlite == null) rethrow;
      return const _Deferred('unreadable');
    }
    return _Written(sql);
  }

  /// Keeps row [id]'s current version [localHlc] whole in `sync_displaced`
  /// if it is still pending (outbox) or parked, before a pulled version
  /// replaces it (A34 fix 1): the outbox holds no payload, so without this
  /// the confirmed edit would be lost. Inside the remote-apply transaction.
  Future<void> _displace(
    SyncedTable<Table, Object?> table,
    String id,
    String localHlc,
  ) async {
    final state = await _db
        .customSelect(
          'SELECT EXISTS (SELECT 1 FROM sync_outbox WHERE entity = ? '
          'AND row_id = ? AND hlc <= ?) AS pending, (SELECT reason FROM '
          'sync_parked WHERE entity = ? AND row_id = ? AND hlc = ?) AS parked',
          variables: [
            for (final v in [table.entity, id, localHlc])
              Variable.withString(v),
            for (final v in [table.entity, id, localHlc])
              Variable.withString(v),
          ],
          readsFrom: {_db.syncOutbox, _db.syncParked},
        )
        .getSingle();
    final pending = state.read<bool>('pending');
    final parked = state.readNullable<String>('parked');
    if (!pending && parked == null) return;
    final row = await _db
        .customSelect(
          'SELECT * FROM "${table.sqlName}" WHERE id = ?',
          variables: [Variable.withString(id)],
          readsFrom: {table.table},
        )
        .getSingle();
    await _db.customStatement(
      'INSERT OR REPLACE INTO sync_displaced '
      '(entity, row_id, hlc, row_json, parked_reason) VALUES (?, ?, ?, ?, ?)',
      [
        table.entity,
        id,
        localHlc,
        jsonEncode(row.data),
        if (pending) null else parked,
      ],
    );
    await _db.customStatement(
      'DELETE FROM sync_outbox WHERE entity = ? AND row_id = ? AND hlc <= ?',
      [table.entity, id, localHlc],
    );
    await _db.customStatement(
      'DELETE FROM sync_parked WHERE entity = ? AND row_id = ? AND hlc <= ?',
      [table.entity, id, localHlc],
    );
  }

  Future<void> _update(
    SyncedTable<Table, Object?> table,
    String id,
    Map<String, Expression<Object>> values,
  ) {
    final names = values.keys.toList();
    // Column names are the table's own (codec and envelope), never input.
    return _db.customUpdate(
      'UPDATE "${table.sqlName}" SET '
      '${names.map((n) => '"$n" = ?').join(', ')} WHERE id = ?',
      variables: [
        for (final n in names) _variableOf(values[n]!),
        Variable.withString(id),
      ],
      updates: {table.table},
    );
  }

  /// [expression] as a bound variable (codecs and the envelope give
  /// [Variable]s only).
  static Variable<Object> _variableOf(Expression<Object> expression) =>
      expression is Variable<Object>
      ? expression
      : throw ArgumentError.value(expression, 'expression', 'not a Variable');
}

sealed class _Outcome {
  const new();
}

final class _Written extends _Outcome {
  const new(this.sqlName);
  final String sqlName;
}

final class _Deferred extends _Outcome {
  const new(this.reason);
  final String reason;
}

final class _Skipped extends _Outcome {
  const new();
}
