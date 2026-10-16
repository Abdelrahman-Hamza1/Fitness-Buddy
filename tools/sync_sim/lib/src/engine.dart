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
      ..cursor = data['cursor'] as String
      ..lastHlc = data['lastHlc'] as String?;
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
  String? lastHlc;

  String checkpoint() => jsonEncode({
    'rows': rows.values.toList(),
    'outbox': outbox,
    'cursor': cursor,
    'lastHlc': lastHlc,
  });

  void confirmSynthetic(SyncChange row) {
    rows[rowKey(row)] = row;
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
  }) {
    final staged = Map<String, SyncChange>.of(rows);
    var previous = BigInt.parse(cursor);
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
      }
    }
    final expected = page.changes.isEmpty
        ? cursor
        : page.changes.last.serverSeq;
    if (page.nextCursor != expected) {
      throw StateError('cursor skips undelivered versions');
    }
    beforeCommit?.call();
    // One atomic state replacement models rows + cursor + clock committed
    // together.
    rows = staged;
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
      entity: entity,
      id: id,
      schemaVersion: 1,
      hlc: _logicalClock().now().toString(),
      deviceId: deviceId,
      deletedAt: deleted ? clock.nowUtc() : null,
      payload: payload,
    );
    store.confirmSynthetic(row);
    return row;
  }

  @override
  Future<void> sync() async {
    await pushPending();
    await pull();
  }

  @override
  Future<void> pushPending() async {
    final pending = List<SyncChange>.of(store.outbox);
    var offset = 0;
    while (offset < pending.length) {
      final batch = <SyncChange>[];
      var batchBytes =
          14; // UTF-8 bytes in {"changes":[]} plus elements/commas.
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
      beforeAcknowledge?.call();
      store.acknowledge(batch, response.results);
      if (response.results.any((result) => result.status == 'invalid')) {
        throw const SyncRejected();
      }
    }
  }

  @override
  Future<void> pull() async {
    while (true) {
      final page = await transport.pull(store.cursor, 100);
      store.apply(page, _logicalClock(), beforeCommit: beforePullCommit);
      if (page.changes.isEmpty) return;
    }
  }
}

final class SyncRejected implements Exception {
  const new();
}
