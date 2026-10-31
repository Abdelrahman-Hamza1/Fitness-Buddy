import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_sync/src/model.dart';
import 'package:fb_sync/src/store.dart';

/// A row as the in-memory store holds it: the current version of one
/// synced row (its envelope and payload).
typedef MemoryRow = SyncChange;

final class _Outbox {
  new(this.seq, this.entity, this.id, this.hlc);
  final int seq;
  final String entity;
  final String id;
  final String hlc;
}

final class _State {
  new();

  new copy(_State other)
    : rows = Map.of(other.rows),
      outbox = List.of(other.outbox),
      parked = Map.of(other.parked),
      deferred = Map.of(other.deferred),
      displaced = Map.of(other.displaced),
      compacted = Set.of(other.compacted),
      cursor = other.cursor,
      datasetId = other.datasetId,
      resetActive = other.resetActive,
      lastHlc = other.lastHlc,
      lastSuccess = other.lastSuccess,
      seq = other.seq;

  Map<String, MemoryRow> rows = {};
  List<_Outbox> outbox = [];
  Map<String, ParkedVersion> parked = {};
  Map<String, SyncDocument> deferred = {};

  /// Pending or parked local versions a pulled version replaced (A34 fix
  /// 1): kept whole until the server has them. Value: the version and its
  /// parked reason (`null` = pending).
  Map<String, (SyncChange, String?)> displaced = {};
  Set<String> compacted = {};
  String cursor = '0';
  String? datasetId;
  bool resetActive = false;
  String? lastHlc;
  DateTime? lastSuccess;
  int seq = 0;
}

/// The in-memory [SyncStore] (tests, tools/sync_sim): the same semantics as
/// the app's drift store, on maps. Every method stages its changes on a
/// copy and commits by swapping it in, so an injected [crash] before a
/// commit leaves the previous state, like a rolled-back transaction.
///
/// Local writes go through [confirm] (the app's applier + outbox trigger).
final class MemorySyncStore implements SyncStore {
  /// A store for the device [deviceId] reading time from [clock].
  /// [readable] says which `(entity, schemaVersion)` this "app version"
  /// reads (default all); [refuseEncode] makes the encoder refuse a row
  /// with a reason (default never).
  new({
    required this.clock,
    required this.deviceId,
    this.readable = _all,
    this.refuseEncode = _never,
  });

  static bool _all(String entity, int version) => true;
  static String? _never(MemoryRow row) => null;

  /// The device clock.
  final Clock clock;

  /// This device.
  final String deviceId;

  /// Which documents this app reads (version skew, A34 D7).
  bool Function(String entity, int version) readable;

  /// A codec refusal for a row (e.g. `tooLarge`), or `null`.
  String? Function(MemoryRow row) refuseEncode;

  /// Called with a commit point name (`settle`, `applyPage`, `beginReset`,
  /// `confirm`) just before that commit; a throw there is a crash.
  void Function(String point)? crash;

  _State _state = _State();

  /// The rows by `entity/id` (read-only view).
  Map<String, MemoryRow> get rows => Map.unmodifiable(_state.rows);

  /// Pending outbox entries (one per written version).
  int get outboxLength => _state.outbox.length;

  /// The `(entity/id)` keys with outbox entries.
  Set<String> get pendingKeys => {
    for (final e in _state.outbox) '${e.entity}/${e.id}',
  };

  /// Parked versions by `entity/id`.
  Map<String, ParkedVersion> get parked => Map.unmodifiable(_state.parked);

  /// Deferred documents by version key.
  Map<String, SyncDocument> get deferred => Map.unmodifiable(_state.deferred);

  /// Displaced local versions waiting to be pushed (or parked).
  Map<String, (SyncChange, String?)> get displaced =>
      Map.unmodifiable(_state.displaced);

  /// When the last run succeeded.
  DateTime? get lastSuccess => _state.lastSuccess;

  /// A copy of the durable state, as a restarted app would find it.
  MemorySyncStore restarted() => MemorySyncStore(
    clock: clock,
    deviceId: deviceId,
    readable: readable,
    refuseEncode: refuseEncode,
  ).._state = _State.copy(_state);

  HybridLogicalClock _clock(_State state) => HybridLogicalClock(
    clock: clock,
    deviceId: deviceId,
    last: state.lastHlc == null ? null : Hlc.parse(state.lastHlc!),
  );

  void _commit(String point, _State staged) {
    crash?.call(point);
    _state = staged;
  }

  /// A confirmed local write (the applier + trigger): a new version of row
  /// [id] with [payload] (a tombstone if [deleted]), at a fresh HLC.
  MemoryRow confirm({
    required String entity,
    required String id,
    required Map<String, Object?> payload,
    int schemaVersion = 1,
    bool deleted = false,
  }) {
    final staged = _State.copy(_state);
    final hlc = _clock(staged).now().toString();
    final row = SyncChange(
      entity: entity,
      id: id,
      schemaVersion: schemaVersion,
      hlc: hlc,
      deviceId: deviceId,
      deletedAt: deleted ? clock.nowUtc() : null,
      payload: payload,
    );
    staged
      ..rows['$entity/$id'] = row
      ..compacted.remove('$entity/$id')
      ..outbox.add(_Outbox(++staged.seq, entity, id, hlc))
      ..lastHlc = hlc;
    _commit('confirm', staged);
    return row;
  }

  @override
  Future<SyncCheckpoint> checkpoint() async => SyncCheckpoint(
    cursor: _state.cursor,
    datasetId: _state.datasetId,
    resetActive: _state.resetActive,
  );

  @override
  Future<PendingRead> pending({required int limit}) async {
    final order = <String, int>{};
    for (final e in _state.outbox) {
      order.putIfAbsent('${e.entity}/${e.id}', () => e.seq);
    }
    final keys = order.keys.toList()
      ..sort((a, b) => order[a]!.compareTo(order[b]!));
    final changes = <SyncChange>[];
    final refused = <ParkedVersion>[];
    final missing = <String>{};
    for (final (row, reason) in _state.displaced.values) {
      if (reason != null) continue;
      if (changes.length + refused.length >= limit) break;
      final refusal = refuseEncode(row);
      if (refusal != null) {
        refused.add(ParkedVersion(SyncVersion.ofChange(row), refusal));
      } else {
        changes.add(row);
      }
    }
    for (final key in keys) {
      if (changes.length + refused.length >= limit) break;
      final row = _state.rows[key];
      if (row == null) {
        missing.add(key);
        continue;
      }
      final reason = refuseEncode(row);
      if (reason != null) {
        refused.add(ParkedVersion(SyncVersion.ofChange(row), reason));
      } else {
        changes.add(row);
      }
    }
    if (refused.isNotEmpty || missing.isNotEmpty) {
      final staged = _State.copy(_state);
      staged.outbox.removeWhere((e) => missing.contains('${e.entity}/${e.id}'));
      _park(staged, refused);
      _commit('settle', staged);
    }
    return PendingRead(changes, parkedNow: refused);
  }

  void _park(_State staged, List<ParkedVersion> parked) {
    for (final p in parked) {
      final v = p.version;
      final key = '${v.rowKey}/${v.hlc}';
      if (staged.displaced[key] case (final row, _)) {
        staged.displaced[key] = (row, p.reason);
        continue;
      }
      staged.outbox.removeWhere(
        (e) =>
            e.entity == v.entity && e.id == v.id && e.hlc.compareTo(v.hlc) <= 0,
      );
      final previous = staged.parked[v.rowKey];
      if (previous == null || previous.version.hlc.compareTo(v.hlc) < 0) {
        staged.parked[v.rowKey] = p;
      }
    }
  }

  @override
  Future<void> settle({
    List<SyncVersion> acknowledged = const [],
    List<ParkedVersion> parked = const [],
  }) async {
    final staged = _State.copy(_state);
    for (final v in acknowledged) {
      staged.outbox.removeWhere(
        (e) =>
            e.entity == v.entity && e.id == v.id && e.hlc.compareTo(v.hlc) <= 0,
      );
      final p = staged.parked[v.rowKey];
      if (p != null && p.version.hlc.compareTo(v.hlc) <= 0) {
        staged.parked.remove(v.rowKey);
      }
      // A displaced version leaves only when the server has exactly it.
      staged.displaced.remove('${v.rowKey}/${v.hlc}');
    }
    _park(staged, parked);
    _commit('settle', staged);
  }

  @override
  Future<PageApplied> applyPage(
    SyncPage page, {
    required String requestedCursor,
  }) async {
    var previous = BigInt.parse(requestedCursor);
    for (final document in page.changes) {
      final seq = BigInt.parse(document.serverSeq);
      if (seq <= previous) throw const SyncFailure(SyncFailureKind.protocol);
      previous = seq;
    }
    final expected = page.changes.isEmpty
        ? requestedCursor
        : page.changes.last.serverSeq;
    if (page.nextCursor != expected) {
      throw const SyncFailure(SyncFailureKind.protocol);
    }
    final staged = _State.copy(_state);
    final clock = _clock(staged);
    final result = _apply(staged, clock, page.changes);
    staged
      ..cursor = page.nextCursor
      ..datasetId = page.datasetId
      ..lastHlc = clock.last?.toString() ?? staged.lastHlc;
    if (staged.resetActive) {
      for (final document in page.changes) {
        staged.outbox.removeWhere(
          (e) =>
              e.entity == document.entity &&
              e.id == document.id &&
              e.hlc.compareTo(document.hlc) <= 0,
        );
      }
      if (page.changes.isEmpty) staged.resetActive = false;
    }
    _commit('applyPage', staged);
    return result;
  }

  PageApplied _apply(
    _State staged,
    HybridLogicalClock clock,
    List<SyncDocument> documents,
  ) {
    var applied = 0;
    final entities = <String>{};
    final deferred = <DeferredDocument>[];
    for (final document in documents) {
      final hlc = Hlc.tryParse(document.hlc);
      if (hlc == null) throw const SyncFailure(SyncFailureKind.protocol);
      if (clock.receive(hlc) is HlcDriftRejected) {
        throw const SyncFailure(SyncFailureKind.clockBehind);
      }
      final key = '${document.entity}/${document.id}';
      final local = staged.rows[key];
      if (local != null && document.hlc.compareTo(local.hlc) <= 0) continue;
      final unreadable =
          !document.compacted &&
          !readable(document.entity, document.schemaVersion);
      if (local != null && !unreadable) {
        _displace(staged, key, local);
      }
      if (document.compacted) {
        if (local == null) continue;
        staged.rows[key] = local.copyWith(
          hlc: document.hlc,
          deviceId: document.deviceId,
          deletedAt:
              document.deletedAt ?? local.deletedAt ?? _fenceTime(document),
        );
        staged.compacted.add(key);
      } else if (unreadable) {
        final version = SyncVersion.ofDocument(document);
        staged.deferred['${version.rowKey}/${version.hlc}'] = document;
        deferred.add(DeferredDocument(version, 'newerSchema'));
        continue;
      } else {
        staged.rows[key] = SyncChange(
          entity: document.entity,
          id: document.id,
          schemaVersion: document.schemaVersion,
          hlc: document.hlc,
          deviceId: document.deviceId,
          deletedAt: document.deletedAt,
          payload: document.payload,
        );
        staged.compacted.remove(key);
      }
      applied++;
      entities.add(document.entity);
    }
    return PageApplied(
      applied: applied,
      entities: entities,
      deferred: deferred,
    );
  }

  /// Keeps [local] whole if it is a pending or parked local version (A34
  /// fix 1): a pulled version is about to replace it, and the outbox holds
  /// no payload. It is pushed later (the server archives it as a loser).
  static void _displace(_State staged, String key, MemoryRow local) {
    final pending = staged.outbox.any(
      (e) => '${e.entity}/${e.id}' == key && e.hlc.compareTo(local.hlc) <= 0,
    );
    final parked = staged.parked[key];
    final parkedHere = parked != null && parked.version.hlc == local.hlc;
    if (!pending && !parkedHere) return;
    staged.displaced['$key/${local.hlc}'] = (
      local,
      pending ? null : parked!.reason,
    );
    staged.outbox.removeWhere(
      (e) => '${e.entity}/${e.id}' == key && e.hlc.compareTo(local.hlc) <= 0,
    );
    if (parkedHere) staged.parked.remove(key);
  }

  /// A fence without a deletion time: the HLC's wall time.
  static DateTime _fenceTime(SyncDocument document) =>
      DateTime.fromMillisecondsSinceEpoch(
        Hlc.parse(document.hlc).wallMs,
        isUtc: true,
      );

  @override
  Future<void> bindDataset(String datasetId) async {
    if (_state.datasetId != null || _state.cursor != '0') return;
    final staged = _State.copy(_state)..datasetId = datasetId;
    _commit('bindDataset', staged);
  }

  /// Starts this store at [cursor] of [datasetId] (the real-API harness:
  /// a scenario's devices skip the documents of earlier scenarios).
  void startAt(String cursor, String datasetId) {
    _state
      ..cursor = cursor
      ..datasetId = datasetId;
  }

  @override
  Future<void> beginReset() async {
    final staged = _State.copy(_state)
      ..cursor = '0'
      ..datasetId = null
      ..resetActive = true;
    for (final row in staged.rows.values) {
      staged.outbox.add(_Outbox(++staged.seq, row.entity, row.id, row.hlc));
    }
    _commit('beginReset', staged);
  }

  @override
  Future<PageApplied> retryDeferred() async {
    if (_state.deferred.isEmpty) return const PageApplied();
    final staged = _State.copy(_state);
    final ready = [
      for (final MapEntry(:key, :value) in staged.deferred.entries)
        if (readable(value.entity, value.schemaVersion)) key,
    ];
    if (ready.isEmpty) return const PageApplied();
    final documents = [for (final key in ready) staged.deferred.remove(key)!];
    final clock = _clock(staged);
    final result = _apply(staged, clock, documents);
    staged.lastHlc = clock.last?.toString() ?? staged.lastHlc;
    _commit('retryDeferred', staged);
    return result;
  }

  @override
  Future<int> retryParked() async {
    final staged = _State.copy(_state);
    var count = 0;
    for (final p in staged.parked.values) {
      final v = p.version;
      staged.outbox.add(_Outbox(++staged.seq, v.entity, v.id, v.hlc));
      count++;
    }
    staged.parked.clear();
    for (final MapEntry(:key, value: (row, reason))
        in staged.displaced.entries.toList()) {
      if (reason == null) continue;
      staged.displaced[key] = (row, null);
      count++;
    }
    _commit('retryParked', staged);
    return count;
  }

  @override
  Future<void> recordSuccess(DateTime at) async {
    final staged = _State.copy(_state)..lastSuccess = at;
    _commit('recordSuccess', staged);
  }
}
