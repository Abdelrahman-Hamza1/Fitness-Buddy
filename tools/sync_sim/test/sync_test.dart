import 'dart:convert';
import 'dart:io';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:sync_sim/sync_sim.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

final _base = DateTime.fromMillisecondsSinceEpoch(1760351234567, isUtc: true);

void main() {
  // covers: AC-010, AC-011, AC-012, OF-03
  test(
    '1000 randomized multi-device runs converge with every version recoverable',
    () async {
      for (var seed = 0; seed < 1000; seed++) {
        await runScenario(FakeSyncTransport(SimClock(_base)), seed, _base);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test('drops, retries and crashes preserve outbox and cursor', () async {
    await runFaults(FakeSyncTransport(SimClock(_base)), _base);
  });

  test('dataset reset restores missing acknowledged local rows', () async {
    final clock = SimClock(_base);
    final server = FakeSyncTransport(clock);
    var store = SimStore();
    PrototypeSyncEngine engine() => PrototypeSyncEngine(
      store: store,
      transport: server,
      deviceId: syntheticId(1),
      clock: clock,
    );
    engine().confirmSynthetic(
      entity: 'weighIn',
      id: syntheticId(3),
      payload: {'value': 3},
    );
    await engine().sync();
    expect(store.outbox, isEmpty);
    final oldDataset = store.datasetId;
    store = SimStore.restore(store.checkpoint());
    server.resetDataset(syntheticId(778));
    await engine().sync();
    expect(store.datasetId, isNot(oldDataset));
    expect(store.outbox, isEmpty);
    final fresh = SimStore();
    await PrototypeSyncEngine(
      store: fresh,
      transport: server,
      deviceId: syntheticId(2),
      clock: clock,
    ).pull();
    expect(fresh.rows, store.rows);
  });

  test(
    'clock correction retries exact versions and keeps concurrent edits',
    () async {
      final serverClock = SimClock(_base);
      final phoneClock = SimClock(_base.add(const Duration(minutes: 6)));
      final store = SimStore();
      final engine = PrototypeSyncEngine(
        store: store,
        transport: FakeSyncTransport(serverClock),
        deviceId: syntheticId(1),
        clock: phoneClock,
      );
      final original = engine.confirmSynthetic(
        entity: 'weighIn',
        id: syntheticId(20),
        payload: {'value': 1},
      );
      await expectLater(engine.pushPending(), throwsA(isA<SyncRejected>()));
      expect(store.outbox.single, original);
      serverClock.now = _base.add(const Duration(minutes: 6, seconds: 1));
      phoneClock.now = serverClock.now;
      engine.beforeAcknowledge = () {
        engine
          ..beforeAcknowledge = null
          ..confirmSynthetic(
            entity: 'weighIn',
            id: original.id,
            payload: {'value': 2},
          );
      };
      await engine.pushPending();
      expect(store.outbox.single.hlc, isNot(original.hlc));
      await engine.pushPending();
      expect(store.outbox, isEmpty);
    },
  );

  test('shared TD-049 vectors parse and compare as bytes', () {
    final yaml = loadYaml(
      File('../../contracts/testdata/sync/hlc_cases.yaml').readAsStringSync(),
    ) as YamlMap;
    final valid = (yaml['valid'] as YamlList).cast<String>();
    for (final text in valid) {
      expect(Hlc.parse(text).toString(), text);
    }
    for (final text in (yaml['invalid'] as YamlList).cast<String>()) {
      expect(Hlc.tryParse(text.replaceAll(r'\n', '\n')), isNull);
    }
    for (var i = 1; i < valid.length; i++) {
      expect(
        Hlc.parse(valid[i - 1]).compareTo(Hlc.parse(valid[i])),
        lessThan(0),
      );
      expect(valid[i - 1].compareTo(valid[i]), lessThan(0));
    }
  });
  test('batching respects rows and UTF-8 bytes', () async {
    final transport = _Recording(FakeSyncTransport(SimClock(_base)));
    final engine = PrototypeSyncEngine(
      store: SimStore(),
      transport: transport,
      deviceId: syntheticId(1),
      clock: SimClock(_base),
    );
    for (var i = 0; i < 1001; i++) {
      engine.confirmSynthetic(
        entity: 'diaryEntry',
        id: syntheticId(i),
        payload: {'text': List.filled(400, 'ع').join()},
      );
    }
    await engine.pushPending();
    expect(engine.store.outbox, isEmpty);
    expect(transport.batches.length, greaterThan(3));
    for (final batch in transport.batches) {
      expect(batch.length, lessThanOrEqualTo(500));
      expect(
        utf8.encode(jsonEncode(SyncPushRequest(changes: batch))).length,
        lessThanOrEqualTo(240 * 1024),
      );
    }
  });

  test(
    'malformed acknowledgement and skipped cursor preserve durable state',
    () async {
      final transport = _Recording(FakeSyncTransport(SimClock(_base)))
        ..corrupt = true;
      final store = SimStore();
      final engine =
          PrototypeSyncEngine(
            store: store,
            transport: transport,
            deviceId: syntheticId(1),
            clock: SimClock(_base),
          )..confirmSynthetic(
            entity: 'diaryEntry',
            id: syntheticId(1),
            payload: {},
          );
      await engine.pull();
      final before = store.checkpoint();
      await expectLater(engine.pushPending(), throwsStateError);
      expect(store.checkpoint(), before);
      expect(
        () => store.apply(
          SyncPage(
            changes: [],
            nextCursor: '100',
            datasetId: syntheticId(777),
            serverTime: _base,
            reason: null,
          ),
          HybridLogicalClock(clock: SimClock(_base), deviceId: syntheticId(1)),
        ),
        throwsStateError,
      );
      expect(store.checkpoint(), before);
    },
  );
}

final class _Recording implements SyncTransport {
  new(this.inner);
  final SyncTransport inner;
  @override
  String? get datasetId => inner.datasetId;
  @override
  set datasetId(String? value) => inner.datasetId = value;
  final List<List<SyncChange>> batches = [];
  bool corrupt = false;
  @override
  Future<SyncPushResponse> push(List<SyncChange> changes) async {
    batches.add(changes);
    final result = await inner.push(changes);
    return corrupt ? result.copyWith(results: []) : result;
  }

  @override
  Future<SyncPage> pull(String cursor, int limit) => inner.pull(cursor, limit);
  @override
  Future<SyncPage> history(String cursor, int limit) =>
      inner.history(cursor, limit);
}
