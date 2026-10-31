import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';

/// The real-API side of the harness (A34 D20): the production
/// [ApiSyncTransport] on a bearer-authenticated [Dio] (loopback only,
/// synthetic data), with request timings and the global history the
/// oracle reads (B05's owner-only `GET /v1/sync/history`).
final class HarnessTransport implements SyncTransport {
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
       ) {
    _inner = ApiSyncTransport(dio);
  }

  final Dio dio;
  late final ApiSyncTransport _inner;
  final Map<String, List<int>> _durations = {};
  String _historyCursor = '0';
  final List<SyncVersion> _history = [];

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

  @override
  Future<SyncPushResponse> push(
    List<SyncChange> changes, {
    required String? datasetId,
  }) => _timed('push', () => _inner.push(changes, datasetId: datasetId));

  @override
  Future<SyncPage> pull({
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => _timed(
    'pull',
    () => _inner.pull(cursor: cursor, limit: limit, datasetId: datasetId),
  );

  @override
  Future<SyncPage> itemHistory(
    String entity,
    String id, {
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => _timed(
    'history',
    () => _inner.itemHistory(
      entity,
      id,
      cursor: cursor,
      limit: limit,
      datasetId: datasetId,
    ),
  );

  /// Every archived version so far, read incrementally (its own history
  /// cursor, never a document cursor).
  Future<List<SyncVersion>> allHistory(String datasetId) async {
    final client = UserDataClient(dio);
    while (true) {
      final page = await _timed(
        'history',
        () => client.getSyncHistory(
          cursor: _historyCursor,
          limit: 500,
          datasetId: datasetId,
        ),
      );
      if (page.changes.isEmpty) return List.unmodifiable(_history);
      _history.addAll(page.changes.map(SyncVersion.ofDocument));
      _historyCursor = page.nextCursor;
    }
  }

  void close() => dio.close(force: true);
}

/// The current dataset and last document cursor, from a throwaway device
/// that pulls everything (each scenario then starts there).
Future<({String cursor, String datasetId})> serverPosition(
  SyncTransport transport,
  DateTime base,
) async {
  final probe = SimDevice(98, transport, SimClock(base));
  await probe.engine.run();
  final checkpoint = await probe.store.checkpoint();
  return (cursor: checkpoint.cursor, datasetId: checkpoint.datasetId!);
}

/// 10,000 rows pushed by one device, then pulled from cursor `0` by a fresh
/// one (AC-011 at scale). Ids 10,000,000…10,009,999 (sync-spike.sh counts
/// them in Postgres).
Future<({int pushMs, int pullMs})> benchmark(
  SyncTransport transport,
  DateTime base,
) async {
  final device = SimDevice(1, transport, SimClock(base));
  final position = await serverPosition(transport, base);
  device.store.startAt(position.cursor, position.datasetId);
  for (var i = 0; i < 10000; i++) {
    device.write(10000000 + i, {'value': i});
  }
  final timer = Stopwatch()..start();
  await device.engine.run();
  final pushMs = timer.elapsedMilliseconds;
  timer.reset();
  final fresh = SimDevice(99, transport, SimClock(base));
  await fresh.engine.run();
  final pullMs = timer.elapsedMilliseconds;
  final restored = fresh.store.rows.values.where(
    (row) =>
        row.id.compareTo(syntheticId(10000000)) >= 0 &&
        row.id.compareTo(syntheticId(10010000)) < 0,
  );
  require(restored.length == 10000, 'benchmark fresh pull lost rows');
  return (pushMs: pushMs, pullMs: pullMs);
}
