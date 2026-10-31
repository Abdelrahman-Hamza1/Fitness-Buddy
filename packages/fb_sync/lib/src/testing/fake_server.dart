import 'dart:convert';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_sync/src/model.dart';
import 'package:fb_sync/src/transport.dart';

/// An independent in-memory model of the B05 server rules (test oracle,
/// not a SQL emulator): append-only immutable versions, each row's maximum
/// as its document, displaced and stale cross-version losers in history,
/// dataset binding, the five-minute clock bound, version identity, 413 by
/// body size, deletion-fence compaction. Shared by every device in a test.
final class FakeSyncServer implements SyncTransport {
  /// A server reading time from [clock].
  new(this.clock);

  /// The server clock (admission bound).
  final Clock clock;

  /// The current dataset (TD-066).
  String datasetId = '00000000-0000-7000-8000-000000000777';

  /// Which `(entity, schemaVersion)` the server admits (default all).
  bool Function(String entity, int version) supports = _all;

  /// A semantic rejection for a change (`invalidPayload`), or `null`.
  String? Function(SyncChange change) validate = _valid;

  /// Requests over this many UTF-8 bytes answer 413.
  int maxBodyBytes = 256 * 1024;

  /// The next call of each kind throws this instead (then clears).
  SyncFailure? failNextPush;

  /// Like [failNextPush], but the push commits first (a lost response).
  SyncFailure? loseNextPushResponse;

  /// The next pull throws this (then clears).
  SyncFailure? failNextPull;

  static bool _all(String entity, int version) => true;
  static String? _valid(SyncChange change) => null;

  final Map<String, SyncChange> _versions = {};
  final Map<String, SyncDocument> _documents = {};
  final Map<String, SyncDocument> _history = {};
  int _seq = 0;
  int _historySeq = 0;

  /// Requests served, by kind (`push`, `pull`, `history`).
  final Map<String, int> calls = {};

  static String _row(String entity, String id) => '$entity/$id';
  static String _version(SyncChange c) => '${c.entity}/${c.id}/${c.hlc}';

  /// Every stored document, by `entity/id`.
  Map<String, SyncDocument> get documents => Map.unmodifiable(_documents);

  /// Every archived version (history), in archive order.
  List<SyncDocument> get history => _history.values.toList();

  /// Starts a new empty dataset [id] (a laptop reset or rollback restore).
  void resetDataset(String id) {
    datasetId = id;
    _versions.clear();
    _documents.clear();
    _history.clear();
  }

  /// Compacts the tombstone of row `entity/id` into a deletion fence (an
  /// empty payload, `compacted: true`, a new sequence).
  void compact(String entity, String id) {
    final current = _documents[_row(entity, id)];
    if (current == null || current.deletedAt == null) return;
    _documents[_row(entity, id)] = current.copyWith(
      payload: const {},
      compacted: true,
      serverSeq: '${++_seq}',
    );
  }

  SyncDocument _stored(SyncChange c, int seq) => SyncDocument(
    entity: c.entity,
    id: c.id,
    schemaVersion: c.schemaVersion,
    hlc: c.hlc,
    deviceId: c.deviceId,
    deletedAt: c.deletedAt,
    payload: c.payload,
    serverSeq: '$seq',
    compacted: false,
  );

  void _archive(SyncChange c) =>
      _history.putIfAbsent(_version(c), () => _stored(c, ++_historySeq));

  static SyncChange _change(SyncDocument d) => SyncChange(
    entity: d.entity,
    id: d.id,
    schemaVersion: d.schemaVersion,
    hlc: d.hlc,
    deviceId: d.deviceId,
    deletedAt: d.deletedAt,
    payload: d.payload,
  );

  @override
  Future<SyncPushResponse> push(
    List<SyncChange> changes, {
    required String? datasetId,
  }) async {
    calls.update('push', (n) => n + 1, ifAbsent: () => 1);
    if (failNextPush case final failure?) {
      failNextPush = null;
      throw failure;
    }
    final body = jsonEncode(
      SyncPushRequest(changes: changes, datasetId: datasetId).toJson(),
    );
    if (utf8.encode(body).length > maxBodyBytes) {
      throw const SyncFailure(SyncFailureKind.payloadTooLarge);
    }
    final results = <SyncPushResult>[];
    for (final c in changes) {
      String? reason;
      final hlc = Hlc.tryParse(c.hlc);
      if (datasetId != this.datasetId) {
        reason = 'datasetMismatch';
      } else if (!supports(c.entity, c.schemaVersion) ||
          hlc == null ||
          hlc.deviceId != c.deviceId) {
        reason = 'unsupported';
      } else if (hlc.wallMs >
          clock.nowUtc().millisecondsSinceEpoch + 5 * 60000) {
        reason = 'clockDrift';
      } else if (validate(c) case final invalid?) {
        reason = invalid;
      } else if (_versions[_version(c)] case final known? when known != c) {
        reason = 'versionConflict';
      }
      var status = 'invalid';
      if (reason == null) {
        _versions[_version(c)] = c;
        final current = _documents[_row(c.entity, c.id)];
        if (current == null || c.hlc.compareTo(current.hlc) > 0) {
          if (current != null && !current.compacted) _archive(_change(current));
          _documents[_row(c.entity, c.id)] = _stored(c, ++_seq);
          status = 'accepted';
        } else if (current.hlc == c.hlc) {
          status = 'accepted';
        } else {
          _archive(c);
          status = 'stale';
        }
      }
      results.add(
        SyncPushResult(
          entity: c.entity,
          id: c.id,
          hlc: c.hlc,
          status: status,
          reason: reason,
        ),
      );
    }
    if (loseNextPushResponse case final failure?) {
      loseNextPushResponse = null;
      throw failure;
    }
    return SyncPushResponse(
      results: results,
      serverTime: clock.nowUtc(),
      datasetId: this.datasetId,
    );
  }

  SyncPage _page(
    Iterable<SyncDocument> documents,
    String cursor,
    int limit,
    String? bound,
  ) {
    final mismatch =
        (bound != null && bound != datasetId) ||
        (bound == null && cursor != '0');
    final after = BigInt.parse(cursor);
    final rows =
        documents.where((d) => BigInt.parse(d.serverSeq) > after).toList()
          ..sort(
            (a, b) =>
                BigInt.parse(a.serverSeq).compareTo(BigInt.parse(b.serverSeq)),
          );
    final page = mismatch ? <SyncDocument>[] : rows.take(limit).toList();
    return SyncPage(
      datasetId: datasetId,
      serverTime: clock.nowUtc(),
      reason: mismatch ? 'datasetMismatch' : null,
      changes: page,
      nextCursor: page.isEmpty ? cursor : page.last.serverSeq,
    );
  }

  @override
  Future<SyncPage> pull({
    required String cursor,
    required int limit,
    required String? datasetId,
  }) async {
    calls.update('pull', (n) => n + 1, ifAbsent: () => 1);
    if (failNextPull case final failure?) {
      failNextPull = null;
      throw failure;
    }
    return _page(_documents.values, cursor, limit, datasetId);
  }

  @override
  Future<SyncPage> itemHistory(
    String entity,
    String id, {
    required String cursor,
    required int limit,
    required String? datasetId,
  }) async {
    calls.update('history', (n) => n + 1, ifAbsent: () => 1);
    return _page(
      _history.values.where((d) => d.entity == entity && d.id == id),
      cursor,
      limit,
      datasetId,
    );
  }

  /// Every archived version of every row (the oracle's no-loss check).
  List<SyncVersion> get historyVersions => [
    for (final d in _history.values) SyncVersion.ofDocument(d),
  ];
}
