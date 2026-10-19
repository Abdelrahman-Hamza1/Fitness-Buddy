import 'dart:convert';
import 'dart:math';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';

import 'package:sync_sim/src/engine.dart';
import 'package:sync_sim/src/transports.dart';

final class SimClock implements Clock {
  new(this.now);
  DateTime now;
  @override
  DateTime nowUtc() => now;
  @override
  int offsetMinutesAt(DateTime utc) => 0;
}

String syntheticId(int value) =>
    '00000000-0000-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';

// Assertion helper mirrors assert/test expect.
// ignore: avoid_positional_boolean_parameters
void require(bool condition, String message) {
  if (!condition) throw StateError(message);
}

/// Seed is printed on failure; expected winners come from the generated local
/// events rather than from either server implementation.
Future<void> runScenario(
  SyncTransport transport,
  int seed,
  DateTime base,
) async {
  final random = Random(seed);
  final count = 2 + random.nextInt(4);
  final clocks = List.generate(count, (_) => SimClock(base));
  final stores = List.generate(count, (_) => SimStore());
  final engines = List.generate(
    count,
    (i) => PrototypeSyncEngine(
      store: stores[i],
      transport: transport,
      deviceId: syntheticId(i + 1),
      clock: clocks[i],
    ),
  );
  final versions = <SyncChange>[];
  final winners = <String, SyncChange>{};
  try {
    for (var step = 0; step < 100; step++) {
      final device = random.nextInt(count);
      clocks[device].now = base.add(
        Duration(milliseconds: random.nextInt(2000) - 1000),
      );
      final row = engines[device].confirmSynthetic(
        entity: random.nextBool() ? 'diaryEntry' : 'weighIn',
        id: syntheticId(10000 + seed * 100 + random.nextInt(12)),
        payload: {'value': step, 'seed': seed},
        deleted: random.nextInt(4) == 0,
      );
      versions.add(row);
      final previous = winners[rowKey(row)];
      if (previous == null || row.hlc.compareTo(previous.hlc) > 0) {
        winners[rowKey(row)] = row;
      }
      if (random.nextInt(5) == 0) await engines[random.nextInt(count)].sync();
    }
    engines.shuffle(random);
    await Future.wait(engines.map((engine) => engine.pushPending()));
    final fresh = SimStore();
    engines.add(
      PrototypeSyncEngine(
        store: fresh,
        transport: transport,
        deviceId: syntheticId(99),
        clock: SimClock(base),
      ),
    );
    for (final engine in engines) {
      await engine.pull();
      require(engine.store.outbox.isEmpty, 'outbox not drained');
      for (final entry in winners.entries) {
        require(
          engine.store.rows[entry.key] == entry.value,
          'wrong winner for ${entry.key}',
        );
      }
    }
    final history = await allHistory(transport);
    final keys = history.map(versionKey).toSet();
    require(keys.length == history.length, 'duplicate history versions');
    final recoverable = {
      for (final version in [...history, ...fresh.rows.values])
        versionKey(version): version,
    };
    for (final version in versions) {
      require(
        recoverable[versionKey(version)] == version,
        'silent lost or corrupted version',
      );
    }
  } on Object catch (error, stack) {
    Error.throwWithStackTrace(StateError('seed $seed: $error'), stack);
  }
}

/// These run unchanged against the fake and the Docker API.
Future<void> runFaults(SyncTransport transport, DateTime base) async {
  final clock = SimClock(base);
  var store = SimStore();
  final faulty = FaultTransport(transport);
  PrototypeSyncEngine engine() => PrototypeSyncEngine(
    store: store,
    transport: faulty,
    deviceId: syntheticId(1),
    clock: clock,
  );
  final id = syntheticId(9000001);
  var current = engine();
  final original = current.confirmSynthetic(
    entity: 'diaryEntry',
    id: id,
    payload: {'value': 1},
  );
  for (final after in [false, true]) {
    faulty
      ..dropBefore = !after
      ..dropAfter = after;
    var failed = false;
    try {
      await current.pushPending();
    } on FormatException {
      failed = true;
    }
    require(
      failed && store.outbox.length == 1,
      'dropped connection acknowledged a version',
    );
    store = SimStore.restore(store.checkpoint());
    current = engine();
  }
  // Crash after success, before local acknowledgement.
  current.beforeAcknowledge = () =>
      throw const FormatException('injected crash');
  try {
    await current.pushPending();
  } on FormatException {
    /* restart below */
  }
  require(store.outbox.length == 1, 'crash deleted pending write');
  store = SimStore.restore(store.checkpoint());
  current = engine();
  // A new confirmed edit arrives while the old immutable batch is in flight.
  current.beforeAcknowledge = () {
    current
      ..beforeAcknowledge = null
      ..confirmSynthetic(entity: 'diaryEntry', id: id, payload: {'value': 2});
  };
  await current.pushPending();
  require(
    store.outbox.length == 1 && store.outbox.single.hlc != original.hlc,
    'ack erased a concurrent local edit',
  );
  await current.pushPending();
  // Pull changes and cursor must survive a crash together.
  final before = store.checkpoint();
  current.beforePullCommit = () =>
      throw const FormatException('injected apply crash');
  try {
    await current.pull();
  } on FormatException {
    /* restart below */
  }
  require(before == store.checkpoint(), 'partial pull was committed');
  store = SimStore.restore(store.checkpoint());
  current = engine();
  await current.sync();
  require(
    store.outbox.isEmpty &&
        (jsonDecode(store.rows[rowKey(original)]!.payload['note']! as String)
                as Map<String, dynamic>)['value'] ==
            2,
    'retry did not converge',
  );
  await transport.push([original, original]);
  final history = await allHistory(transport);
  require(
    history.where((row) => versionKey(row) == versionKey(original)).length == 1,
    'duplicate push duplicated history',
  );
  final fresh = SimStore();
  await PrototypeSyncEngine(
    store: fresh,
    transport: transport,
    deviceId: syntheticId(99),
    clock: clock,
  ).pull();
  require(
    fresh.rows[rowKey(original)] == store.rows[rowKey(original)],
    'fresh restore differs',
  );
  final invalid = current
      .confirmSynthetic(
        entity: 'weighIn',
        id: syntheticId(9000002),
        payload: {'value': 3},
      )
      .copyWith(
        hlc:
            '${base.millisecondsSinceEpoch + 86400000}-00000-${syntheticId(1)}',
      );
  store.outbox
    ..clear()
    ..add(invalid);
  var rejected = false;
  try {
    await current.pushPending();
  } on SyncRejected {
    rejected = true;
  }
  require(
    rejected && store.outbox.single == invalid,
    'invalid future version was lost',
  );
}

Future<({int pushMs, int pullMs})> benchmark(
  SyncTransport transport,
  DateTime base,
) async {
  final store = SimStore();
  final engine = PrototypeSyncEngine(
    store: store,
    transport: transport,
    deviceId: syntheticId(1),
    clock: SimClock(base),
  );
  for (var i = 0; i < 10000; i++) {
    engine.confirmSynthetic(
      entity: i.isEven ? 'diaryEntry' : 'weighIn',
      id: syntheticId(10000000 + i),
      payload: {'value': i},
    );
  }
  final timer = Stopwatch()..start();
  await engine.pushPending();
  final pushMs = timer.elapsedMilliseconds;
  timer.reset();
  final fresh = SimStore();
  await PrototypeSyncEngine(
    store: fresh,
    transport: transport,
    deviceId: syntheticId(99),
    clock: SimClock(base),
  ).pull();
  final pullMs = timer.elapsedMilliseconds;
  timer.stop();
  require(
    fresh.rows.values
            .where(
              (row) =>
                  row.payload.containsKey('note') &&
                  row.id.compareTo(syntheticId(10000000)) >= 0 &&
                  row.id.compareTo(syntheticId(10010000)) < 0,
            )
            .length ==
        10000,
    'benchmark fresh pull lost rows',
  );
  return (pushMs: pushMs, pullMs: pullMs);
}
