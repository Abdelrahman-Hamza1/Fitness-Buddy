import 'dart:convert';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';

import 'package:sync_sim/src/transports.dart';

String rowKey(SyncChange row) => '${row.entity}/${row.id}';
String versionKey(SyncChange row) => '${rowKey(row)}/${row.hlc}';

SyncChange fromDocument(SyncDocument row) => SyncChange(
  entity: row.entity,
  id: row.id,
  schemaVersion: row.schemaVersion,
  hlc: row.hlc,
  deviceId: row.deviceId,
  deletedAt: row.deletedAt,
  payload: row.payload,
);

/// Simulated persistent state: engine restarts use a serialized checkpoint.
/// A01/A34 must implement these boundaries with real SQLite transactions.
final class SimStore {
  new();
  factory restore(String checkpoint) {
    final data = jsonDecode(checkpoint) as Map<String, dynamic>;
    final store = SimStore()
      ..needsReupload = data['needsReupload'] as bool? ?? false
      ..datasetId = data['datasetId'] as String?
      ..cursor = data['cursor'] as String
      ..lastHlc = data['lastHlc'] as String?;
    store.compacted.addAll(
      (data['compacted'] as List<dynamic>? ?? []).cast<String>(),
    );
    for (final row in data['rows'] as List<dynamic>) {
      final change = SyncChange.fromJson(row as Map<String, dynamic>);
      store.rows[rowKey(change)] = change;
    }
    for (final row in data['outbox'] as List<dynamic>) {
      store.outbox.add(SyncChange.fromJson(row as Map<String, dynamic>));
    }
    return store;
  }

  Map<String, SyncChange> rows = {};
  final List<SyncChange> outbox = [];
  String cursor = '0';
  String? datasetId;
  bool needsReupload = false;
  Set<String> compacted = {};
  String? lastHlc;

  String checkpoint() => jsonEncode({
    'rows': rows.values.toList(),
    'outbox': outbox,
    'cursor': cursor,
    'datasetId': datasetId,
    'needsReupload': needsReupload,
    'compacted': compacted.toList(),
    'lastHlc': lastHlc,
  });

  void confirmSynthetic(SyncChange row) {
    rows[rowKey(row)] = row;
    compacted.remove(rowKey(row));
    outbox.add(row);
    lastHlc = row.hlc;
  }

  void acknowledge(List<SyncChange> sent, List<SyncPushResult> results) {
    if (sent.length != results.length) {
      throw StateError('incomplete acknowledgement');
    }
    final acknowledged = <String>{};
    for (var i = 0; i < sent.length; i++) {
      final result = results[i];
      if (result.entity != sent[i].entity ||
          result.id != sent[i].id ||
          result.hlc != sent[i].hlc ||
          !{'accepted', 'stale', 'invalid'}.contains(result.status)) {
        throw StateError('mismatched acknowledgement');
      }
      if (result.status != 'invalid') acknowledged.add(versionKey(sent[i]));
    }
    // Only those immutable versions were sent. A newer edit during await stays
    // pending.
    outbox.removeWhere((row) => acknowledged.contains(versionKey(row)));
  }

  void apply(
    SyncPage page,
    HybridLogicalClock clock, {
    void Function()? beforeCommit,
    bool reset = false,
  }) {
    final staged = Map<String, SyncChange>.of(rows);
    final stagedCompacted = Set<String>.of(compacted);
    var previous = BigInt.parse(reset ? '0' : cursor);
    for (final document in page.changes) {
      final seq = BigInt.parse(document.serverSeq);
      if (seq <= previous) throw StateError('unordered page');
      previous = seq;
      final row = fromDocument(document);
      if (clock.receive(Hlc.parse(row.hlc)) is HlcDriftRejected) {
        throw StateError('remote clock drift; cursor unchanged');
      }
      final local = staged[rowKey(row)];
      if (local == null || row.hlc.compareTo(local.hlc) > 0) {
        staged[rowKey(row)] = row;
        if (document.compacted) {
          stagedCompacted.add(rowKey(row));
        } else {
          stagedCompacted.remove(rowKey(row));
        }
      }
    }
    final expected = page.changes.isEmpty
        ? (reset ? '0' : cursor)
        : page.changes.last.serverSeq;
    if (page.nextCursor != expected) {
      throw StateError('cursor skips undelivered versions');
    }
    beforeCommit?.call();
    // One atomic state replacement models rows + cursor + clock committed
    // together.
    rows = staged;
    compacted = stagedCompacted;
    needsReupload = needsReupload || reset;
    datasetId = page.datasetId;
    cursor = page.nextCursor;
    lastHlc = clock.last?.toString() ?? lastHlc;
  }
}

abstract interface class SyncEngine {
  Future<void> sync();
  Future<void> pushPending();
  Future<void> pull();
}

final class PrototypeSyncEngine implements SyncEngine {
  new({
    required this.store,
    required this.transport,
    required this.deviceId,
    required this.clock,
  });

  final SimStore store;
  final SyncTransport transport;
  final String deviceId;
  final Clock clock;
  void Function()? beforeAcknowledge;
  void Function()? beforePullCommit;

  HybridLogicalClock _logicalClock() => HybridLogicalClock(
    clock: clock,
    deviceId: deviceId,
    last: store.lastHlc == null ? null : Hlc.parse(store.lastHlc!),
  );

  SyncChange confirmSynthetic({
    required String entity,
    required String id,
    required Map<String, Object?> payload,
    bool deleted = false,
  }) {
    final row = SyncChange(
      entity: 'weighIn',
      id: id,
      schemaVersion: 1,
      hlc: _logicalClock().now().toString(),
      deviceId: deviceId,
      deletedAt: deleted ? clock.nowUtc() : null,
      payload: syntheticPayload({'kind': entity, ...payload}, clock.nowUtc()),
    );
    store.confirmSynthetic(row);
    return row;
  }

  @override
  Future<void> sync() async {
    await pull();
    await pushPending();
    await pull();
  }

  @override
  Future<void> pushPending() async {
    if (store.datasetId == null || store.needsReupload) await pull();
    transport.datasetId = store.datasetId;
    final pending = List<SyncChange>.of(store.outbox);
    var offset = 0;
    while (offset < pending.length) {
      final batch = <SyncChange>[];
      var batchBytes =
          128; // Envelope and optional dataset UUID, excluding elements/commas.
      // Stay below Kestrel's 256 KiB cap as well as the protocol's 500-row
      // bound.
      while (offset < pending.length && batch.length < 500) {
        final rowBytes = utf8.encode(jsonEncode(pending[offset])).length;
        final nextBytes = batchBytes + rowBytes + (batch.isEmpty ? 0 : 1);
        if (nextBytes > 240 * 1024) {
          if (batch.isEmpty) {
            throw StateError('one change exceeds the request byte budget');
          }
          break;
        }
        batchBytes = nextBytes;
        batch.add(pending[offset++]);
      }
      final response = await transport.push(batch);
      if (response.datasetId != store.datasetId) {
        await pull();
        throw const SyncRejected();
      }
      beforeAcknowledge?.call();
      store.acknowledge(batch, response.results);
      if (response.results.any((result) => result.status == 'invalid')) {
        throw const SyncRejected();
      }
    }
  }

  @override
  Future<void> pull() async {
    var reset = false;
    String? discovered;
    while (true) {
      transport.datasetId = reset ? discovered : store.datasetId;
      final page = await transport.pull(reset ? '0' : store.cursor, 100);
      if (page.reason != null ||
          store.datasetId != null &&
              page.datasetId != store.datasetId &&
              !reset) {
        if (reset && page.reason != null) throw const SyncRejected();
        reset = true;
        discovered = page.datasetId;
        continue;
      }
      store.apply(
        page,
        _logicalClock(),
        beforeCommit: beforePullCommit,
        reset: reset,
      );
      reset = false;
      transport.datasetId = store.datasetId;
      if (page.changes.isEmpty) {
        if (store.needsReupload) {
          final pending = store.outbox.map(versionKey).toSet();
          for (final row in store.rows.values) {
            if (!store.compacted.contains(rowKey(row)) &&
                pending.add(versionKey(row))) {
              store.outbox.add(row);
            }
          }
          store.needsReupload = false;
        }
        return;
      }
    }
  }
}

final class SyncRejected implements Exception {
  const new();
}

/// Canonical synthetic production payload. The note retains the random event
/// for the independent oracle.
Map<String, Object?> syntheticPayload(
  Map<String, Object?> event,
  DateTime now,
) => {
  'createdAtMs': now.millisecondsSinceEpoch,
  'origin': 'direct',
  'editedByUser': false,
  'measuredAtUtc': now.millisecondsSinceEpoch,
  'localDate': now.toIso8601String().substring(0, 10),
  'kg': 75,
  'note': jsonEncode(event),
};
