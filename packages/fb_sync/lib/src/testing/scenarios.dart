import 'dart:convert';
import 'dart:math';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_sync/src/engine.dart';
import 'package:fb_sync/src/model.dart';
import 'package:fb_sync/src/testing/memory_store.dart';
import 'package:fb_sync/src/transport.dart';

/// A simulated process death at a commit point (thrown from
/// `MemorySyncStore.crash`).
final class InjectedCrash implements Exception {
  /// A crash.
  const new();
}

/// A settable test clock.
final class SimClock implements Clock {
  /// A clock at [now].
  new(this.now);

  /// The current instant (UTC).
  DateTime now;

  @override
  DateTime nowUtc() => now;

  @override
  int offsetMinutesAt(DateTime utc) => 0;
}

/// A synthetic lowercase UUIDv7-shaped id for [value].
String syntheticId(int value) =>
    '00000000-0000-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';

/// Throws a [StateError] with [message] unless [condition].
// Mirrors `expect`, usable outside package:test (the real-API harness).
// ignore: avoid_positional_boolean_parameters
void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

/// A canonical synthetic `weighIn` v1 payload (valid under the B19 wire
/// rules); [event] is kept in the note for the oracle. Synthetic data only.
Map<String, Object?> syntheticWeighIn(
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

/// One simulated phone: the in-memory store and the production engine.
final class SimDevice {
  /// Device [n] on [transport] at [clock]. Its requests go through
  /// [faulty], so a test can inject a local edit while one is in flight.
  new(int n, SyncTransport transport, this.clock)
    : faulty = FaultyTransport(transport),
      store = MemorySyncStore(clock: clock, deviceId: syntheticId(n)) {
    engine = SyncEngine(store: store, transport: faulty);
  }

  /// This device's transport wrapper (fault and edit injection).
  final FaultyTransport faulty;

  /// The device clock.
  final SimClock clock;

  /// The device's store.
  MemorySyncStore store;

  /// The device's engine (rebuilt by [restart]).
  late SyncEngine engine;

  /// The newest local version of each row since this device's last run.
  final Map<String, SyncChange> pendingLatest = {};

  /// A confirmed local write of a synthetic weigh-in.
  SyncChange write(
    int rowId,
    Map<String, Object?> event, {
    bool deleted = false,
  }) {
    final row = store.confirm(
      entity: 'weighIn',
      id: syntheticId(rowId),
      payload: syntheticWeighIn(event, clock.now),
      deleted: deleted,
    );
    pendingLatest['weighIn/${row.id}'] = row;
    return row;
  }

  /// Restarts the app: the durable state survives, memory doesn't.
  void restart(SyncTransport transport) {
    store = store.restarted();
    engine = SyncEngine(store: store, transport: transport);
  }

  /// The engine on this device's own [faulty] wrapper again.
  void restartOwn() {
    store = store.restarted();
    engine = SyncEngine(store: store, transport: faulty);
  }
}

/// A randomized multi-device run (seed printed on failure): random offline
/// writes and tombstones on 2–5 devices, syncs at random moments, then every
/// device and a fresh one converge to the winners computed from the
/// generated events. **Oracle** (A34 plan §2): every version that was a
/// row's newest local version when its device started a run, and every
/// final winner, is recoverable (a live row or server history). Returns the
/// last cursor (the real-API harness starts the next scenario there).
Future<String> runScenario(
  SyncTransport transport,
  int seed,
  DateTime base, {
  String startCursor = '0',
  String? datasetId,
  Future<List<SyncVersion>> Function()? history,
}) async {
  final random = Random(seed);
  final count = 2 + random.nextInt(4);
  final devices = [
    for (var i = 0; i < count; i++) SimDevice(i + 1, transport, SimClock(base)),
  ];
  if (datasetId != null) {
    for (final d in devices) {
      d.store.startAt(startCursor, datasetId);
    }
  }
  final winners = <String, SyncChange>{};
  final required = <String, SyncChange>{};
  Future<void> runDevice(SimDevice d) async {
    for (final v in d.pendingLatest.values) {
      required['${v.entity}/${v.id}/${v.hlc}'] = v;
    }
    d.pendingLatest.clear();
    await d.engine.run();
  }

  try {
    for (var step = 0; step < 100; step++) {
      final d = devices[random.nextInt(count)];
      d.clock.now = base.add(
        Duration(milliseconds: random.nextInt(2000) - 1000),
      );
      final row = d.write(10000 + seed * 100 + random.nextInt(12), {
        'value': step,
        'seed': seed,
      }, deleted: random.nextInt(4) == 0);
      final previous = winners['weighIn/${row.id}'];
      if (previous == null || row.hlc.compareTo(previous.hlc) > 0) {
        winners['weighIn/${row.id}'] = row;
      }
      if (random.nextInt(5) == 0) {
        final d = devices[random.nextInt(count)];
        // A34 fix 1: sometimes the user edits while a request is in
        // flight, with a clock that may be behind the other phones.
        if (random.nextInt(3) == 0) {
          final row = 10000 + seed * 100 + random.nextInt(12);
          final skew = random.nextInt(2000) - 1500;
          void edit() {
            d.clock.now = base.add(Duration(milliseconds: skew));
            final v = d.write(row, {'value': 'during', 'seed': seed});
            final previous = winners['weighIn/${v.id}'];
            if (previous == null || v.hlc.compareTo(previous.hlc) > 0) {
              winners['weighIn/${v.id}'] = v;
            }
          }

          if (random.nextBool()) {
            d.faulty.duringPull = edit;
          } else {
            d.faulty.duringPush = edit;
          }
        }
        await runDevice(d);
      }
    }
    for (final d in devices) {
      d.faulty
        ..duringPull = null
        ..duringPush = null;
    }
    devices.shuffle(random);
    await Future.wait(devices.map(runDevice));
    final fresh = SimDevice(99, transport, SimClock(base));
    if (datasetId != null) fresh.store.startAt(startCursor, datasetId);
    for (final d in [...devices, fresh]) {
      await runDevice(d);
      require(
        d.store.outboxLength == 0 && d.store.displaced.isEmpty,
        'outbox not drained',
      );
      for (final MapEntry(:key, :value) in winners.entries) {
        require(d.store.rows[key] == value, 'wrong winner for $key');
      }
    }
    final archived = {
      for (final v in await (history ?? () async => <SyncVersion>[])())
        '${v.rowKey}/${v.hlc}',
    };
    final live = {
      for (final r in fresh.store.rows.values) '${r.entity}/${r.id}/${r.hlc}',
    };
    for (final key in {
      ...required.keys,
      ...winners.values.map((w) => '${w.entity}/${w.id}/${w.hlc}'),
    }) {
      require(
        archived.contains(key) || live.contains(key),
        'silently lost version ${key.substring(key.length - 60)}',
      );
    }
    return (await fresh.store.checkpoint()).cursor;
  } on Object catch (error, stack) {
    Error.throwWithStackTrace(StateError('seed $seed: $error'), stack);
  }
}

/// OF-03: the same entry edited offline on two devices; after both sync the
/// later edit wins everywhere and the other is an earlier version of the
/// row on the server. [firstSyncsFirst] decides which device syncs first.
Future<void> runOf03(
  SyncTransport transport,
  DateTime base,
  int rowId, {
  required bool firstSyncsFirst,
  String startCursor = '0',
  String? datasetId,
}) async {
  final a = SimDevice(1, transport, SimClock(base));
  final b = SimDevice(2, transport, SimClock(base));
  if (datasetId != null) {
    a.store.startAt(startCursor, datasetId);
    b.store.startAt(startCursor, datasetId);
  }
  a.write(rowId, {'of03': 'original'});
  await a.engine.run();
  await b.engine.run();
  a.clock.now = base.add(const Duration(seconds: 1));
  final older = a.write(rowId, {'of03': 'phone A, offline'});
  b.clock.now = base.add(const Duration(seconds: 2));
  final newer = b.write(rowId, {'of03': 'phone B, offline, later'});
  final order = firstSyncsFirst ? [a, b, a] : [b, a, b];
  for (final d in order) {
    await d.engine.run();
  }
  final key = 'weighIn/${syntheticId(rowId)}';
  require(a.store.rows[key] == newer, 'OF-03: phone A has the later edit');
  require(b.store.rows[key] == newer, 'OF-03: phone B has the later edit');
  final page = await transport.itemHistory(
    'weighIn',
    syntheticId(rowId),
    cursor: '0',
    limit: 100,
    datasetId: (await a.store.checkpoint()).datasetId,
  );
  require(
    page.changes.any((d) => d.hlc == older.hlc),
    'OF-03: the other edit is an earlier version',
  );
}

/// Faults that run unchanged against the fake and the real API: a dropped
/// push before and after the server committed, a crash before the local
/// acknowledgement, a duplicate push, a local edit while a push is in
/// flight, a crash mid-page, then convergence of a fresh device.
Future<void> runFaults(
  SyncTransport transport,
  DateTime base, {
  required FaultyTransport faulty,
  String startCursor = '0',
  String? datasetId,
  int rowBase = 9000001,
}) async {
  final device = SimDevice(1, faulty, SimClock(base));
  if (datasetId != null) device.store.startAt(startCursor, datasetId);
  final original = device.write(rowBase, {'value': 1});
  for (final after in [false, true]) {
    faulty
      ..dropBefore = !after
      ..dropAfter = after;
    var failed = false;
    try {
      await device.engine.run();
    } on SyncFailure catch (f) {
      failed = f.kind == SyncFailureKind.offline;
    }
    require(
      failed && device.store.outboxLength == 1,
      'a dropped connection acknowledged a version',
    );
    device.restart(faulty);
  }
  // Crash after the server accepted, before the local acknowledgement.
  device.store.crash = (point) {
    if (point == 'settle') throw const InjectedCrash();
  };
  try {
    await device.engine.run();
  } on InjectedCrash {
    // The process died; restart below.
  }
  device
    ..store.crash = null
    ..restart(faulty);
  require(device.store.outboxLength == 1, 'a crash deleted a pending write');
  // A confirmed edit arrives while the batch is in flight.
  SyncChange? concurrent;
  faulty.duringPush = () {
    faulty.duringPush = null;
    concurrent = device.write(rowBase, {'value': 2});
  };
  await device.engine.run();
  // The in-flight version was acknowledged; the concurrent edit has a newer
  // HLC, so it stayed pending and the same run pushed it too.
  require(
    concurrent != null &&
        device.store.outboxLength == 0 &&
        device.store.rows['weighIn/${original.id}'] == concurrent,
    'the acknowledgement erased a concurrent local edit',
  );
  // A crash while committing a pulled page commits nothing.
  final other = SimDevice(2, faulty, SimClock(base));
  if (datasetId != null) other.store.startAt(startCursor, datasetId);
  other.store.crash = (point) {
    if (point == 'applyPage') throw const InjectedCrash();
  };
  await device.engine.run();
  try {
    await other.engine.run();
  } on InjectedCrash {
    // Restart below.
  }
  require(other.store.rows.isEmpty, 'a partial page was committed');
  other
    ..store.crash = null
    ..restart(faulty);
  await other.engine.run();
  require(
    other.store.rows['weighIn/${original.id}'] ==
        device.store.rows['weighIn/${original.id}'],
    'retry did not converge',
  );
  // A local edit made while a pull is in flight, older than the version
  // that pull brings, is kept and reaches the server's history (A34 fix 1).
  final ahead = SimDevice(
    3,
    faulty,
    SimClock(base.add(const Duration(seconds: 30))),
  );
  if (datasetId != null) ahead.store.startAt(startCursor, datasetId);
  final aheadRow = ahead.write(rowBase + 5, {'value': 'other phone, newer'});
  await ahead.engine.run();
  SyncChange? older;
  device.restartOwn();
  device.faulty.duringPull = () {
    device.clock.now = base.add(const Duration(seconds: 1));
    older = device.write(rowBase + 5, {'value': 'during pull, older'});
  };
  await device.engine.run();
  final key = 'weighIn/${aheadRow.id}';
  require(
    older != null && device.store.rows[key] == aheadRow,
    'the newer version wins on the phone that edited during the pull',
  );
  await device.engine.run();
  final edited = await transport.itemHistory(
    'weighIn',
    aheadRow.id,
    cursor: '0',
    limit: 100,
    datasetId: (await device.store.checkpoint()).datasetId,
  );
  require(
    edited.changes.any((d) => d.hlc == older!.hlc),
    'an edit made during a pull was lost',
  );
  // A duplicate push of the same immutable version is harmless.
  final current = device.store.rows['weighIn/${original.id}']!;
  final dup = await transport.push([
    current,
    current,
  ], datasetId: (await device.store.checkpoint()).datasetId);
  require(
    dup.results.every((r) => r.status == 'accepted'),
    'a duplicate push was not idempotent',
  );
}

/// A transport wrapper that drops a connection before the request or after
/// the server committed it, and runs a hook while a push is in flight.
final class FaultyTransport implements SyncTransport {
  /// Wraps [inner].
  new(this.inner);

  /// The real transport.
  final SyncTransport inner;

  /// The next push fails before it reaches the server.
  bool dropBefore = false;

  /// The next push is committed, then its response is lost.
  bool dropAfter = false;

  /// Runs once while the next push is in flight (a concurrent local edit).
  void Function()? duringPush;

  /// Runs once while the next bound pull is in flight (a concurrent local
  /// edit before the page is applied, A34 fix 1).
  void Function()? duringPull;

  @override
  Future<SyncPushResponse> push(
    List<SyncChange> changes, {
    required String? datasetId,
  }) async {
    if (dropBefore) {
      dropBefore = false;
      throw const SyncFailure(SyncFailureKind.offline);
    }
    final hook = duringPush;
    duringPush = null;
    hook?.call();
    final response = await inner.push(changes, datasetId: datasetId);
    if (dropAfter) {
      dropAfter = false;
      throw const SyncFailure(SyncFailureKind.offline);
    }
    return response;
  }

  @override
  Future<SyncPage> pull({
    required String cursor,
    required int limit,
    required String? datasetId,
  }) async {
    final page = await inner.pull(
      cursor: cursor,
      limit: limit,
      datasetId: datasetId,
    );
    // Not on the unbound discovery pull: an edit then still comes before
    // the run's push (ordinary coalescing), not during a pull.
    if (datasetId != null) {
      final hook = duringPull;
      duringPull = null;
      hook?.call();
    }
    return page;
  }

  @override
  Future<SyncPage> itemHistory(
    String entity,
    String id, {
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => inner.itemHistory(
    entity,
    id,
    cursor: cursor,
    limit: limit,
    datasetId: datasetId,
  );
}
