import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';

import 'package:sync_sim/src/engine.dart';

abstract interface class SyncTransport {
  String? get datasetId;
  set datasetId(String? value);
  Future<SyncPushResponse> push(List<SyncChange> changes);
  Future<SyncPage> pull(String cursor, int limit);
  Future<SyncPage> history(String cursor, int limit);
}

final class ApiSyncTransport implements SyncTransport {
  new({
    required String baseUrl,
    required String accessToken,
    required String deviceId,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: baseUrl,
           connectTimeout: const Duration(seconds: 5),
           receiveTimeout: const Duration(seconds: 30),
           headers: {
             'Authorization': 'Bearer $accessToken',
             'X-App-Version': '0.1.0',
             'X-Platform': 'android',
             'X-Device-Id': deviceId,
           },
         ),
       );
  final Dio dio;
  @override
  String? datasetId;
  final Map<String, List<int>> _durations = {};
  Map<String, ({int requests, double p95Ms})> latencySummary() => {
    for (final entry in _durations.entries)
      entry.key: (
        requests: entry.value.length,
        p95Ms:
            (List<int>.of(entry.value)
              ..sort())[(entry.value.length * .95).ceil() - 1] /
            1000,
      ),
  };
  Future<T> _timed<T>(String operation, Future<T> Function() send) async {
    final timer = Stopwatch()..start();
    try {
      return await send();
    } finally {
      _durations
          .putIfAbsent(operation, () => [])
          .add(timer.elapsedMicroseconds);
    }
  }

  UserDataClient get _client => UserDataClient(dio);
  @override
  Future<SyncPushResponse> push(List<SyncChange> changes) => _timed(
    'push',
    () => _client.pushSync(
      body: SyncPushRequest(changes: changes, datasetId: datasetId),
    ),
  );
  @override
  Future<SyncPage> pull(String cursor, int limit) => _timed(
    'pull',
    () => _client.pullSync(cursor: cursor, limit: limit, datasetId: datasetId),
  );
  @override
  Future<SyncPage> history(String cursor, int limit) => _timed(
    'history',
    () => _client.getSyncHistory(
      cursor: cursor,
      limit: limit,
      datasetId: datasetId,
    ),
  );
  void close() => dio.close(force: true);
}

/// Deliberately different storage implementation from SQL: append-only version
/// sets, then choose each row's maximum. This is a test oracle, not a SQL
/// emulator.
final class FakeSyncTransport implements SyncTransport {
  new(this.clock);
  final Clock clock;
  @override
  String? datasetId;
  String serverDataset = '00000000-0000-7000-8000-000000000777';
  final Map<String, SyncChange> _versions = {};
  final Map<String, SyncDocument> _documents = {};
  final Map<String, SyncDocument> _history = {};
  int _documentSeq = 0;
  int _historySeq = 0;

  void resetDataset(String id) {
    serverDataset = id;
    _versions.clear();
    _documents.clear();
    _history.clear();
    _documentSeq = 0;
    _historySeq = 0;
  }

  SyncDocument _stored(SyncChange row, int seq) => SyncDocument(
    entity: row.entity,
    id: row.id,
    schemaVersion: row.schemaVersion,
    hlc: row.hlc,
    deviceId: row.deviceId,
    deletedAt: row.deletedAt,
    payload: row.payload,
    serverSeq: '$seq',
    compacted: false,
  );
  void _archive(SyncChange row) =>
      _history.putIfAbsent(versionKey(row), () => _stored(row, ++_historySeq));

  @override
  Future<SyncPushResponse> push(List<SyncChange> changes) async {
    final results = <SyncPushResult>[];
    for (final row in changes) {
      String? reason;
      final hlc = Hlc.tryParse(row.hlc);
      if (datasetId != serverDataset) {
        reason = 'datasetMismatch';
      } else if (!{'diaryEntry', 'weighIn'}.contains(row.entity) ||
          row.schemaVersion != 1 ||
          hlc == null ||
          hlc.deviceId != row.deviceId) {
        reason = 'unsupported';
      } else if (hlc.wallMs > clock.nowUtc().millisecondsSinceEpoch + 300000) {
        reason = 'clockDrift';
      } else if (_versions[versionKey(row)] case final known?
          when known != row) {
        reason = 'versionConflict';
      }
      var status = 'invalid';
      if (reason == null) {
        _versions[versionKey(row)] = row;
        final current = _documents[rowKey(row)];
        if (current == null || row.hlc.compareTo(current.hlc) > 0) {
          if (current != null) _archive(fromDocument(current));
          _documents[rowKey(row)] = _stored(row, ++_documentSeq);
          status = 'accepted';
        } else if (current.hlc == row.hlc) {
          status = 'accepted';
        } else {
          _archive(row);
          status = 'stale';
        }
      }
      results.add(
        SyncPushResult(
          entity: row.entity,
          id: row.id,
          hlc: row.hlc,
          status: status,
          reason: reason,
        ),
      );
    }
    return SyncPushResponse(
      results: results,
      serverTime: clock.nowUtc(),
      datasetId: serverDataset,
    );
  }

  SyncPage _page(Iterable<SyncDocument> documents, String cursor, int limit) {
    final after = BigInt.parse(cursor);
    final rows =
        documents.where((row) => BigInt.parse(row.serverSeq) > after).toList()
          ..sort(
            (a, b) =>
                BigInt.parse(a.serverSeq).compareTo(BigInt.parse(b.serverSeq)),
          );
    final page = rows.take(limit).toList();
    return SyncPage(
      datasetId: serverDataset,
      serverTime: clock.nowUtc(),
      reason: datasetId != null && datasetId != serverDataset
          ? 'datasetMismatch'
          : null,
      changes: datasetId != null && datasetId != serverDataset ? [] : page,
      nextCursor: page.isEmpty ? cursor : page.last.serverSeq,
    );
  }

  @override
  Future<SyncPage> pull(String cursor, int limit) async =>
      _page(_documents.values, cursor, limit);
  @override
  Future<SyncPage> history(String cursor, int limit) async =>
      _page(_history.values, cursor, limit);
}

/// Simulates a transport losing a connection either before send or after the
/// server committed, before the engine can acknowledge its outbox.
final class FaultTransport implements SyncTransport {
  new(this.inner);
  final SyncTransport inner;
  @override
  String? get datasetId => inner.datasetId;
  @override
  set datasetId(String? value) => inner.datasetId = value;
  bool dropBefore = false;
  bool dropAfter = false;
  @override
  Future<SyncPushResponse> push(List<SyncChange> changes) async {
    if (dropBefore) {
      dropBefore = false;
      throw const FormatException('injected connection drop before push');
    }
    final response = await inner.push(changes);
    if (dropAfter) {
      dropAfter = false;
      throw const FormatException('injected lost acknowledgement');
    }
    return response;
  }

  @override
  Future<SyncPage> pull(String cursor, int limit) => inner.pull(cursor, limit);
  @override
  Future<SyncPage> history(String cursor, int limit) =>
      inner.history(cursor, limit);
}

Future<List<SyncChange>> allHistory(SyncTransport transport) async {
  var cursor = '0';
  final history = <SyncChange>[];
  while (true) {
    final page = await transport.history(cursor, 500);
    if (page.changes.isEmpty) return history;
    history.addAll(page.changes.map(fromDocument));
    cursor = page.nextCursor;
  }
}

String canonical(SyncChange row) => jsonEncode(row.toJson());
