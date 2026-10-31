import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show TableUpdate, Value, Variable;
import 'package:fb_api_client/fb_api_client.dart' hide LocalDate;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart' show SequenceIdGenerator;
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../changes/support/test_db.dart' show ScriptHandler, ScriptOp;
import '../support/db_support.dart';
import 'sync_support.dart';

Map<String, Object?> _json(String path) =>
    jsonDecode(File('../../$path').readAsStringSync()) as Map<String, Object?>;

const _dataset = '00000000-0000-7000-8000-000000000777';

SyncDocument _doc(
  String entity,
  String id,
  Map<String, Object?> payload, {
  required int seq,
  int schemaVersion = 1,
  String? hlc,
  bool deleted = false,
}) => SyncDocument(
  entity: entity,
  id: id,
  schemaVersion: schemaVersion,
  hlc: hlc ?? '1760351230000-00000-${syntheticId(2)}',
  deviceId: syntheticId(2),
  deletedAt: deleted ? syncBase : null,
  payload: payload,
  serverSeq: '$seq',
  compacted: false,
);

SyncPage _page(List<SyncDocument> docs, {required String next}) => SyncPage(
  changes: docs,
  nextCursor: next,
  datasetId: _dataset,
  serverTime: syncBase,
  reason: null,
);

/// The current-version fixture payload of every entity.
Map<String, Map<String, Object?>> _fixtures() {
  final v1 = _json('contracts/testdata/sync/entity-payloads.json');
  final v2 = _json('contracts/testdata/sync/entity-payloads-v2.json');
  return {
    for (final MapEntry(:key, :value) in v1.entries)
      key: ((key == 'weighIn' ? v2[key] : value)! as Map)
          .cast<String, Object?>(),
  };
}

void main() {
  late SimClock clock;
  setUp(() => clock = SimClock(syncBase));

  // covers: AC-011, AT-006
  test(
    'every registered entity round-trips: pull, encode at its upload '
    'version with the contract fields, push, restore on a fresh phone',
    () async {
      final db = memoryDatabase();
      final store = driftStore(db, clock: clock);
      final entities =
          _json('contracts/openapi/sync-entities.json')['entities']!
              as Map<String, Object?>;
      final fixtures = _fixtures();
      expect(fixtures.keys.toSet(), {
        for (final t in db.syncedTables) t.entity,
      }, reason: 'a fixture per registered entity');
      final ids = <String, String>{};
      var seq = 0;
      final docs = [
        for (final MapEntry(key: entity, value: payload) in fixtures.entries)
          _doc(
            entity,
            ids[entity] = syntheticId(++seq),
            payload,
            seq: seq,
            schemaVersion: SyncDocumentUpgraders.currentVersionOf(entity),
          ),
      ];
      final applied = await store.applyPage(
        _page(docs, next: '$seq'),
        requestedCursor: '0',
      );
      expect(applied.deferred, isEmpty);
      expect(applied.applied, fixtures.length);
      await store.beginReset();
      final pending = (await store.pending(limit: 1000)).changes;
      for (final MapEntry(key: entity, value: payload) in fixtures.entries) {
        final change = pending.singleWhere((c) => c.id == ids[entity]);
        final version = SyncDocumentUpgraders.currentVersionOf(entity);
        expect(change.schemaVersion, version, reason: entity);
        final schema =
            ((entities[entity]! as Map)['$version']! as Map)['properties']!
                as Map;
        expect(
          change.payload.keys.toSet(),
          schema.keys.toSet(),
          reason: entity,
        );
        expect(change.payload, payload, reason: '$entity payload round trip');
        expect(change.hlc, docs.first.hlc);
        expect(change.deviceId, syntheticId(2));
      }
      // Push everything to a server, restore on a fresh database.
      final server = FakeSyncServer(SimClock(syncBase));
      await server.push([
        for (final c in pending)
          if (ids.values.contains(c.id)) c,
      ], datasetId: server.datasetId);
      final fresh = memoryDatabase();
      await SyncEngine(
        store: driftStore(fresh, clock: clock, deviceId: syntheticId(3)),
        transport: server,
      ).run();
      for (final table in db.syncedTables) {
        final id = ids[table.entity]!;
        Future<Map<String, Object?>> row(AppDatabase d) async {
          final r = await d
              .customSelect(
                'SELECT * FROM "${table.sqlName}" WHERE id = ?',
                variables: [Variable.withString(id)],
              )
              .getSingle();
          return {...r.data}..remove('version');
        }

        expect(await row(fresh), await row(db), reason: table.entity);
      }
    },
  );

  test('a weighIn v1 document is upgraded on pull (A14 D7)', () async {
    final db = memoryDatabase();
    final store = driftStore(db, clock: clock);
    final v1 =
        _json('contracts/testdata/sync/entity-payloads.json')['weighIn']!
            as Map<String, Object?>;
    await store.applyPage(
      _page([_doc('weighIn', syntheticId(1), v1, seq: 1)], next: '1'),
      requestedCursor: '0',
    );
    final row = await db.select(db.weighIns).getSingle();
    expect(row.inputValue, (v1['kg']! as num).toDouble());
    expect(row.inputUnit, 'kg');
    expect(row.preferredForDay, isFalse);
    expect(
      row.tzOffsetMin,
      SyncDocumentUpgraders.impliedOffsetMinutes(
        (v1['measuredAtUtc']! as num).toInt(),
        LocalDate.parse(v1['localDate']! as String),
      ),
    );
    await store.beginReset();
    final change = (await store.pending(limit: 100)).changes
        .singleWhere((c) => c.entity == 'weighIn');
    expect(change.schemaVersion, 2, reason: 'upload v2 only');
  });

  test('chat: a pull never touches request/answer JSON; a pulled tombstone '
      'clears them (A23)', () async {
    final db = memoryDatabase();
    final store = driftStore(db, clock: clock);
    final payload = _fixtures()['chatMessage']!;
    final id = syntheticId(1);
    await store.applyPage(
      _page([_doc('chatMessage', id, payload, seq: 1)], next: '1'),
      requestedCursor: '0',
    );
    await writeRaw(
      db,
      "UPDATE chat_messages SET request_json = '{}', answer_json = '{}'",
    );
    await store.applyPage(
      _page([
        _doc(
          'chatMessage',
          id,
          {...payload, 'status': 'done'},
          seq: 2,
          hlc: '1760351231000-00000-${syntheticId(2)}',
        ),
      ], next: '2'),
      requestedCursor: '1',
    );
    var row = await db.select(db.chatMessages).getSingle();
    expect(row.requestJson, '{}');
    expect(row.answerJson, '{}');
    await store.applyPage(
      _page([
        _doc(
          'chatMessage',
          id,
          {...payload, 'text': '', 'budgetJson': null},
          seq: 3,
          hlc: '1760351232000-00000-${syntheticId(2)}',
          deleted: true,
        ),
      ], next: '3'),
      requestedCursor: '2',
    );
    row = await db.select(db.chatMessages).getSingle();
    expect(row.deletedAt, isNotNull);
    expect(row.requestJson, isNull);
    expect(row.answerJson, isNull);
  });

  test(
    'an unscrubbed chat tombstone is parked, never pushed (A23 D16)',
    () async {
      final db = memoryDatabase();
      final store = driftStore(db, clock: clock);
      final payload = _fixtures()['chatMessage']!;
      await store.applyPage(
        _page([
          _doc('chatMessage', syntheticId(1), payload, seq: 1),
        ], next: '1'),
        requestedCursor: '0',
      );
      await writeRaw(
        db,
        "UPDATE chat_messages SET deleted_at = 1, message_text = 'x', "
        "updated_hlc = '1760351239999-00000-$testDevice'",
      );
      await store.beginReset();
      final read = await store.pending(limit: 100);
      expect(read.changes.where((c) => c.entity == 'chatMessage'), isEmpty);
      expect(read.parkedNow.single.reason, 'unscrubbedTombstone');
    },
  );

  group('with the real applier:', () {
    late AppDatabase db;
    late ChangeSetApplier<AppDatabase> applier;
    late DriftSyncStore store;
    setUp(() {
      db = memoryDatabase();
      applier = ChangeSetApplier(
        db: db,
        tables: db.syncedTables,
        handlers: (_) => const [ScriptHandler()],
        clock: clock,
        ids: SequenceIdGenerator(),
        deviceId: () async => testDevice,
        events: DomainEventBus(),
      );
      store = driftStore(db, clock: clock, exclusive: applier.runExclusive);
    });

    Future<ApplyResult> put(String id, String value) => applier.apply(
      ChangeSet([
        ScriptOp.rows([
          UpsertRow(
            db.settingsKv,
            SettingsKvCompanion(id: Value(id), valueJson: Value(value)),
          ),
        ]),
      ], origin: Origin.direct),
    );

    test('a local write after a pull is after the pulled version '
        '(D9)', () async {
      await put(syntheticId(1), '"a"');
      // Another phone's clock is a minute ahead.
      final remote =
          '${syncBase.millisecondsSinceEpoch + 60000}-00007-${syntheticId(2)}';
      await store.applyPage(
        _page([
          _doc(
            'setting',
            syntheticId(1),
            {
              'createdAtMs': 0,
              'origin': 'direct',
              'editedByUser': false,
              'valueJson': '"b"',
            },
            seq: 1,
            hlc: remote,
          ),
        ], next: '1'),
        requestedCursor: '0',
      );
      await put(syntheticId(1), '"c"');
      final row = await db.select(db.settingsKv).getSingle();
      expect(row.valueJson, '"c"');
      expect(row.updatedHlc.compareTo(remote), greaterThan(0));
      final outbox = await db.select(db.syncOutbox).get();
      expect(
        outbox.where((o) => o.hlc == remote),
        isEmpty,
        reason: 'capture off',
      );
    });

    test('a pulled version makes an older undo a version conflict', () async {
      final applied = await put(syntheticId(1), '"a"') as Applied;
      await store.applyPage(
        _page([
          _doc(
            'setting',
            syntheticId(1),
            {
              'createdAtMs': 0,
              'origin': 'direct',
              'editedByUser': false,
              'valueJson': '"remote"',
            },
            seq: 1,
            hlc:
                '${syncBase.millisecondsSinceEpoch + 1000}-00000-'
                '${syntheticId(2)}',
          ),
        ], next: '1'),
        requestedCursor: '0',
      );
      final undo = await applier.revert(applied.inverse);
      expect(undo, isA<Rejected>());
      expect(
        (await db.select(db.settingsKv).getSingle()).valueJson,
        '"remote"',
      );
    });
  });

  // covers: AC-010, AC-012
  test('two drift phones and a server converge (25 seeded runs)', () async {
    for (var seed = 0; seed < 25; seed++) {
      final random = Random(seed);
      final server = FakeSyncServer(SimClock(syncBase));
      final phones = [
        for (final device in [testDevice, syntheticId(2)])
          (db: memoryDatabase(), clock: SimClock(syncBase), device: device),
      ];
      final engines = [
        for (final p in phones)
          SyncEngine(
            store: driftStore(p.db, clock: p.clock, deviceId: p.device),
            transport: server,
          ),
      ];
      for (var step = 0; step < 40; step++) {
        final i = random.nextInt(2);
        final p = phones[i];
        p.clock.now = p.clock.now.add(
          Duration(milliseconds: random.nextInt(50)),
        );
        await localSetting(
          p.db,
          p.clock,
          syntheticId(100 + random.nextInt(6)),
          value: step,
          deleted: random.nextInt(5) == 0,
          deviceId: p.device,
        );
        if (random.nextInt(4) == 0) await engines[random.nextInt(2)].run();
      }
      for (final e in [...engines, ...engines]) {
        await e.run();
      }
      Future<List<Map<String, Object?>>> rows(AppDatabase d) async => [
        for (final r
            in await d
                .customSelect(
                  'SELECT id, updated_hlc, deleted_at, value_json '
                  'FROM settings_kv ORDER BY id',
                )
                .get())
          r.data,
      ];
      expect(
        await rows(phones[1].db),
        await rows(phones[0].db),
        reason: 'seed $seed',
      );
      for (final p in phones) {
        expect(
          await p.db.select(p.db.syncOutbox).get(),
          isEmpty,
          reason: 'seed $seed',
        );
      }
    }
  });

  // covers: AC-012 (A34 fix round 1, finding 1)
  test('drift: an older edit made while a pull is in flight reaches the '
      "server's history; a newer one wins", () async {
    for (final older in [true, false]) {
      final server = FakeSyncServer(SimClock(syncBase));
      final a = memoryDatabase();
      final b = memoryDatabase();
      final aClock = SimClock(syncBase);
      final bClock = SimClock(syncBase.add(const Duration(seconds: 30)));
      final faulty = FaultyTransport(server);
      final aEngine = SyncEngine(
        store: driftStore(a, clock: aClock),
        transport: faulty,
      );
      final bEngine = SyncEngine(
        store: driftStore(b, clock: bClock, deviceId: syntheticId(2)),
        transport: server,
      );
      await aEngine.run();
      await localSetting(
        b,
        bClock,
        syntheticId(1),
        value: 1,
        deviceId: syntheticId(2),
      );
      await bEngine.run();
      late String mine;
      faulty.duringPull = () {
        if (!older) aClock.now = syncBase.add(const Duration(minutes: 2));
        // Not awaited by the transport: the write is queued on the database
        // before the page's transaction.
        unawaited(
          localSetting(
            a,
            aClock,
            syntheticId(1),
            value: 2,
          ).then((h) => mine = h),
        );
      };
      await aEngine.run();
      await aEngine.run();
      await bEngine.run();
      final aRow = await a.select(a.settingsKv).getSingle();
      final bRow = await b.select(b.settingsKv).getSingle();
      expect(aRow.valueJson, bRow.valueJson, reason: 'converged');
      if (older) {
        expect(aRow.valueJson, '1');
        expect(server.history.map((d) => d.hlc), contains(mine));
      } else {
        expect(aRow.valueJson, '2');
      }
      expect(await a.select(a.syncDisplaced).get(), isEmpty);
    }
  });

  test('the counts stream follows the outbox and settles', () async {
    final db = memoryDatabase();
    final store = driftStore(db, clock: clock);
    final seen = <int>[];
    final sub = store.watchCounts().listen((c) => seen.add(c.pendingRows));
    addTearDown(sub.cancel);
    await pumpEventQueue();
    await localSetting(db, clock, syntheticId(1), value: 1);
    db.notifyUpdates({const TableUpdate('sync_outbox')});
    await pumpEventQueue();
    final change = (await store.pending(limit: 10)).changes.single;
    await store.settle(acknowledged: [SyncVersion.ofChange(change)]);
    await pumpEventQueue();
    expect(seen.first, 0);
    expect(seen, contains(1));
    expect(seen.last, 0);
  });
}
