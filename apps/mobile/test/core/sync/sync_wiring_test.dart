import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart' show SequenceIdGenerator;
import 'package:fb_mobile/core/api/request_guard.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/sync/earlier_versions.dart';
import 'package:fb_mobile/core/sync/restore_version.dart';
import 'package:fb_mobile/core/sync/sync_guard.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../changes/support/test_db.dart' show ScriptHandler, ScriptOp;
import '../db/support/db_support.dart';
import '../db/sync/sync_support.dart';

final class _Adapter implements HttpClientAdapter {
  final List<String> sent = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    sent.add('${options.method} ${options.path}');
    return ResponseBody.fromString(
      '{"changes":[],"nextCursor":"0","datasetId":"$_dataset",'
      '"serverTime":"2026-10-30T00:00:00Z","reason":null}',
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

const _dataset = '00000000-0000-7000-8000-000000000777';

void main() {
  // covers: AC-012 (A34 D12)
  test('the guard refuses a sync request once its run is stale, after the '
      'bearer is attached', () async {
    final adapter = _Adapter();
    var attached = 0;
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1'))
      ..httpClientAdapter = adapter
      ..interceptors.addAll([
        InterceptorsWrapper(
          onRequest: (o, h) {
            attached++;
            h.next(o);
          },
        ),
        const RequestGuardInterceptor(),
      ]);
    var generation = 1;
    final transport = GuardedSyncTransport(
      ApiSyncTransport(dio),
      () => generation == 1,
    );
    await transport.pull(cursor: '0', limit: 1, datasetId: null);
    expect(adapter.sent, hasLength(1));
    // A transition switches the profile while the next request waits for
    // its credentials: the guard runs after them and refuses.
    final guardedLater = GuardedSyncTransport(ApiSyncTransport(dio), () {
      return attached < 2 || generation == 1;
    });
    generation = 2;
    await expectLater(
      guardedLater.pull(cursor: '0', limit: 1, datasetId: null),
      throwsA(isA<SyncFailure>()),
    );
    expect(adapter.sent, hasLength(1), reason: 'never sent');
    await expectLater(
      transport.pull(cursor: '0', limit: 1, datasetId: null),
      throwsA(isA<SyncFailure>()),
    );
    // Requests outside a sync run pass untouched.
    await dio.get<Object>('/v1/config');
    expect(adapter.sent.last, 'GET /v1/config');
  });

  group('earlier versions (G7):', () {
    late AppDatabase db;
    late ChangeSetApplier<AppDatabase> applier;
    late SimClock clock;
    setUp(() {
      clock = SimClock(syncBase);
      db = memoryDatabase();
      applier = ChangeSetApplier(
        db: db,
        tables: db.syncedTables,
        handlers: (d) => [
          const ScriptHandler(),
          RestoreVersionHandler(d, appCodecs(d)),
        ],
        clock: clock,
        ids: SequenceIdGenerator(),
        deviceId: () async => testDevice,
        events: DomainEventBus(),
      );
    });

    Future<void> put(String value) => applier.apply(
      ChangeSet([
        ScriptOp.rows([
          UpsertRow(
            db.settingsKv,
            SettingsKvCompanion(
              id: Value(syntheticId(1)),
              valueJson: Value(value),
            ),
          ),
        ]),
      ], origin: Origin.direct),
    );

    test(
      'read from the server newest first, then restored with undo',
      () async {
        final server = FakeSyncServer(SimClock(syncBase));
        final store = driftStore(
          db,
          clock: clock,
          exclusive: applier.runExclusive,
        );
        final engine = SyncEngine(store: store, transport: server);
        for (final v in ['"one"', '"two"', '"three"']) {
          clock.now = clock.now.add(const Duration(seconds: 1));
          await put(v);
          await engine.run();
        }
        final versions = await readEarlierVersions(
          server,
          store,
          'setting',
          syntheticId(1),
        );
        expect(
          [for (final v in versions) v.payload['valueJson']],
          ['"two"', '"one"'],
        );
        final restored = await applier.apply(
          ChangeSet([
            RestoreVersionOp(
              entity: 'setting',
              id: syntheticId(1),
              payload: versions.last.payload,
              deleted: versions.last.deleted,
            ),
          ], origin: Origin.direct),
        ) as Applied;
        var row = await db.select(db.settingsKv).getSingle();
        expect(row.valueJson, '"one"');
        expect(row.origin, 'direct');
        expect(
          (await db.select(db.syncOutbox).get()).last.hlc,
          row.updatedHlc,
          reason: 'the restore is a new local version that syncs',
        );
        await applier.revert(restored.inverse);
        row = await db.select(db.settingsKv).getSingle();
        expect(row.valueJson, '"three"');
      },
    );

    // A34 fix round 1, finding 5.
    test('a restore expects the version shown: an edit meanwhile refuses '
        'it and writes nothing', () async {
      final server = FakeSyncServer(SimClock(syncBase));
      final store = driftStore(
        db,
        clock: clock,
        exclusive: applier.runExclusive,
      );
      final engine = SyncEngine(store: store, transport: server);
      for (final v in ['"one"', '"two"']) {
        clock.now = clock.now.add(const Duration(seconds: 1));
        await put(v);
        await engine.run();
      }
      final versions = await readEarlierVersions(
        server,
        store,
        'setting',
        syntheticId(1),
      );
      expect(versions.single.localVersion, isNotNull);
      await put('"edited meanwhile"');
      final result = await applier.apply(
        ChangeSet([
          RestoreVersionOp(
            entity: 'setting',
            id: syntheticId(1),
            payload: versions.single.payload,
            deleted: versions.single.deleted,
            expectedVersion: versions.single.localVersion,
          ),
        ], origin: Origin.direct),
      );
      expect(result, isA<Rejected>());
      expect(
        (await db.select(db.settingsKv).getSingle()).valueJson,
        '"edited meanwhile"',
      );
    });

    test(
      'a restore refuses an unknown entity or an unreadable payload',
      () async {
        await put('"x"');
        for (final op in [
          RestoreVersionOp(
            entity: 'nope',
            id: syntheticId(1),
            payload: const {},
            deleted: false,
          ),
          RestoreVersionOp(
            entity: 'setting',
            id: syntheticId(1),
            payload: const {'valueJson': 3},
            deleted: false,
          ),
        ]) {
          final result = await applier.apply(
            ChangeSet([op], origin: Origin.direct),
          );
          expect(result, isA<Rejected>());
        }
      },
    );
  });

  // A34 fix round 1, finding 6: no further pages once backgrounded.
  test('a run stops requesting pages when its guard turns false', () async {
    final clock = SimClock(syncBase);
    final server = FakeSyncServer(clock);
    final writer = memoryDatabase();
    for (var i = 0; i < 250; i++) {
      await localSetting(writer, clock, syntheticId(100 + i), value: i);
    }
    await SyncEngine(
      store: driftStore(writer, clock: clock),
      transport: server,
    ).run();
    final db = memoryDatabase();
    var foreground = true;
    final pulls = server.calls['pull'] ?? 0;
    final engine = SyncEngine(
      store: driftStore(db, clock: clock, deviceId: syntheticId(3)),
      transport: GuardedSyncTransport(server, () => foreground),
      onProgress: (p) {
        if (p.pulledRows > 0) foreground = false;
      },
    );
    await expectLater(engine.run(), throwsA(isA<SyncFailure>()));
    expect(server.calls['pull']! - pulls, 2, reason: 'discovery + one page');
    expect(await db.select(db.settingsKv).get(), hasLength(100));
  });
}
