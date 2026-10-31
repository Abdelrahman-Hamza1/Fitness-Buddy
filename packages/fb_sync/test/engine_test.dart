import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';
import 'package:test/test.dart';

import 'support.dart';

/// A device on a shared fake server.
({SimDevice device, FakeSyncServer server}) _setup() {
  final server = FakeSyncServer(SimClock(base));
  return (device: SimDevice(1, server, SimClock(base)), server: server);
}

Future<SyncFailure> _failure(Future<void> Function() run) async {
  try {
    await run();
  } on SyncFailure catch (failure) {
    return failure;
  }
  fail('no SyncFailure');
}

void main() {
  // covers: AC-010, AC-012
  group('SyncEngine push:', () {
    test('a first run binds the dataset, pushes, then pulls', () async {
      final (:device, :server) = _setup();
      device.write(1, {'v': 1});
      final report = await device.engine.run();
      expect(report.pushed, 1);
      expect(report.firstSync, isTrue);
      expect(device.store.outboxLength, 0);
      expect(server.documents, hasLength(1));
      final cp = await device.store.checkpoint();
      expect(cp.datasetId, server.datasetId);
      expect(cp.cursor, '1');
      expect(
        device.store.lastSuccess,
        isNull,
        reason: 'the scheduler records it',
      );
    });

    test(
      'stale and versionConflict acknowledge; the stale loser is history',
      () async {
        final (:device, :server) = _setup();
        final other = SimDevice(2, server, SimClock(base));
        device.write(1, {'v': 'older'});
        other.clock.now = base.add(const Duration(seconds: 1));
        other.write(1, {'v': 'newer'});
        await other.engine.run();
        final report = await device.engine.run();
        expect(report.pushed, 1, reason: 'stale is acknowledged');
        expect(device.store.outboxLength, 0);
        expect(server.history, hasLength(1));
        expect(
          device.store.rows['weighIn/${syntheticId(1)}']!.payload,
          server.documents['weighIn/${syntheticId(1)}']!.payload,
        );
      },
    );

    test(
      'a version the server already holds with other content is acknowledged '
      '(versionConflict)',
      () async {
        final (:device, :server) = _setup();
        final row = device.write(1, {'v': 1});
        await device.engine.run();
        // The same immutable version, re-sent with a different payload (an
        // upgraded v1 re-uploaded after a reset).
        final response = await server.push([
          row.copyWith(payload: {...row.payload, 'kg': 80}),
        ], datasetId: server.datasetId);
        expect(response.results.single.reason, 'versionConflict');
        device.store.confirm(
          entity: 'weighIn',
          id: syntheticId(2),
          payload: row.payload,
        );
        await device.engine.run();
        expect(device.store.outboxLength, 0);
      },
    );

    test(
      'permanent rejections are parked, reported and never retried in a loop',
      () async {
        final (:device, :server) = _setup();
        server
          ..validate = ((c) => c.id == syntheticId(1) ? 'invalidPayload' : null)
          ..supports = ((entity, _) => entity == 'weighIn');
        device
          ..write(1, {'v': 1})
          ..write(2, {'v': 2});
        device.store.confirm(
          entity: 'futureThing',
          id: syntheticId(3),
          payload: const {},
        );
        final parked = <ParkedVersion>[];
        final engine = SyncEngine(
          store: device.store,
          transport: server,
          onParked: parked.addAll,
        );
        final report = await engine.run();
        expect(report.pushed, 1);
        expect(
          {for (final p in parked) p.reason},
          {'invalidPayload', 'unsupported'},
        );
        expect(device.store.parked, hasLength(2));
        expect(device.store.outboxLength, 0);
        final calls = server.calls['push'];
        await engine.run();
        expect(server.calls['push'], calls, reason: 'nothing left to push');
        expect(device.store.rows, hasLength(3), reason: 'parked rows are kept');
        // A server fix + Try again.
        server
          ..validate = ((_) => null)
          ..supports = ((_, _) => true);
        expect(await device.store.retryParked(), 2);
        await engine.run();
        expect(device.store.parked, isEmpty);
        expect(server.documents, hasLength(3));
      },
    );

    test('a codec refusal is parked while reading, with its reason', () async {
      final (:device, :server) = _setup();
      device.store.refuseEncode = (row) =>
          row.id == syntheticId(1) ? 'tooLarge' : null;
      device
        ..write(1, {'v': 1})
        ..write(2, {'v': 2});
      final report = await device.engine.run();
      expect(report.parked.single.reason, 'tooLarge');
      expect(server.documents.keys, ['weighIn/${syntheticId(2)}']);
    });

    test(
      '413 splits the batch; a single row still too large is parked',
      () async {
        final (:device, :server) = _setup();
        for (var i = 0; i < 6; i++) {
          device.write(i, {'v': i});
        }
        device.store.confirm(
          entity: 'weighIn',
          id: syntheticId(50),
          payload: {'note': 'x' * 4000},
        );
        server.maxBodyBytes = 3000;
        final report = await device.engine.run();
        expect(report.pushed, 6);
        expect(report.parked.single.reason, 'tooLarge');
        expect(server.documents, hasLength(6));
      },
    );

    test('batches stay under 500 changes and the byte budget', () {
      final changes = [
        for (var i = 0; i < 1203; i++)
          SyncChange(
            entity: 'weighIn',
            id: syntheticId(i),
            schemaVersion: 1,
            hlc: '1760351234567-00000-${syntheticId(1)}',
            deviceId: syntheticId(1),
            deletedAt: null,
            payload: {'note': 'é' * (i == 7 ? 250000 : 10)},
          ),
      ];
      final batches = pushBatches(changes);
      expect(batches.expand((b) => b), changes, reason: 'order kept');
      for (final batch in batches) {
        expect(batch.length, lessThanOrEqualTo(500));
        final bytes = batch.fold<int>(
          PushLimits.envelopeBytes,
          (n, c) => n + encodedChangeBytes(c) + 1,
        );
        if (batch.length > 1) {
          expect(bytes, lessThanOrEqualTo(PushLimits.maxBodyBytes));
        }
      }
      expect(
        batches.where((b) => b.length == 1 && b.single.id == syntheticId(7)),
        hasLength(1),
        reason: 'an oversize row goes alone',
      );
    });

    test(
      'clockDrift keeps the version pending and stops with clockAhead',
      () async {
        final (:device, :server) = _setup();
        device.clock.now = base.add(const Duration(minutes: 30));
        device.write(1, {'v': 1});
        final failure = await _failure(device.engine.run);
        expect(failure.kind, SyncFailureKind.clockAhead);
        expect(device.store.outboxLength, 1);
        expect(device.store.parked, isEmpty);
        // The server clock catches up: the same version is admitted.
        (server.clock as SimClock).now = base.add(const Duration(minutes: 30));
        await device.engine.run();
        expect(device.store.outboxLength, 0);
      },
    );

    test(
      'auth, rate limit and server failures stop the run and keep everything',
      () async {
        for (final kind in [
          SyncFailureKind.unauthorized,
          SyncFailureKind.forbidden,
          SyncFailureKind.rateLimited,
          SyncFailureKind.server,
          SyncFailureKind.offline,
        ]) {
          final (:device, :server) = _setup();
          device.write(1, {'v': 1});
          await device.engine.run();
          device.write(1, {'v': 2});
          server.failNextPush = SyncFailure(kind);
          expect((await _failure(device.engine.run)).kind, kind);
          expect(device.store.outboxLength, 1);
          await device.engine.run();
          expect(device.store.outboxLength, 0);
        }
      },
    );

    test(
      'mismatched results break the protocol and acknowledge nothing',
      () async {
        final (:device, :server) = _setup();
        device.write(1, {'v': 1});
        final transport = _Rewriting(
          server,
          (r) => r.copyWith(
            results: r.results.reversed.toList()..add(r.results.first),
          ),
        );
        final engine = SyncEngine(store: device.store, transport: transport);
        expect((await _failure(engine.run)).kind, SyncFailureKind.protocol);
        expect(device.store.outboxLength, 1);
      },
    );
  });

  group('SyncEngine pull:', () {
    test('a fresh device restores every row with progress (AC-011)', () async {
      final (:device, :server) = _setup();
      for (var i = 0; i < 250; i++) {
        device.write(i, {'v': i});
      }
      await device.engine.run();
      final progress = <SyncProgress>[];
      final fresh = SimDevice(9, server, SimClock(base));
      final engine = SyncEngine(
        store: fresh.store,
        transport: server,
        onProgress: progress.add,
      );
      final report = await engine.run();
      expect(report.firstSync, isTrue);
      expect(report.pulled, 250);
      expect(fresh.store.rows, device.store.rows);
      expect(
        progress.where((p) => p.phase == SyncPhase.pulling).last.pulledRows,
        250,
      );
      expect(
        server.calls['pull'],
        greaterThanOrEqualTo(4),
        reason: 'pages of 100',
      );
    });

    test(
      'a newer local pending edit survives a pull (LWW), then wins',
      () async {
        final (:device, :server) = _setup();
        final other = SimDevice(2, server, SimClock(base));
        device.write(1, {'v': 'a'});
        await device.engine.run();
        await other.engine.run();
        other.write(1, {'v': 'other, older'});
        device.clock.now = base.add(const Duration(seconds: 5));
        final mine = device.write(1, {'v': 'mine, newer'});
        await other.engine.run();
        await device.engine.run();
        await other.engine.run();
        expect(device.store.rows['weighIn/${syntheticId(1)}'], mine);
        expect(other.store.rows['weighIn/${syntheticId(1)}'], mine);
      },
    );

    test('a compacted fence tombstones the row on another device', () async {
      final (:device, :server) = _setup();
      final other = SimDevice(2, server, SimClock(base));
      device.write(1, {'v': 1});
      await device.engine.run();
      await other.engine.run();
      device.write(1, {'v': 1}, deleted: true);
      await device.engine.run();
      server.compact('weighIn', syntheticId(1));
      await other.engine.run();
      expect(
        other.store.rows['weighIn/${syntheticId(1)}']!.deletedAt,
        isNotNull,
      );
    });

    test(
      'a pulled version 2 days ahead stops with clockBehind, cursor kept',
      () async {
        final (:device, :server) = _setup();
        final ahead = SimDevice(
          2,
          server,
          SimClock(base.add(const Duration(days: 2))),
        );
        (server.clock as SimClock).now = base.add(const Duration(days: 2));
        ahead.write(1, {'v': 1});
        await ahead.engine.run();
        expect(
          (await _failure(device.engine.run)).kind,
          SyncFailureKind.clockBehind,
        );
        expect((await device.store.checkpoint()).cursor, '0');
      },
    );

    test('version skew: a newer document is deferred, then applied after '
        'an update', () async {
      final (:device, :server) = _setup();
      final newer = SimDevice(2, server, SimClock(base));
      newer.store.confirm(
        entity: 'weighIn',
        id: syntheticId(1),
        schemaVersion: 3,
        payload: const {'kg': 70},
      );
      await newer.engine.run();
      device.store.readable = (_, version) => version <= 2;
      final deferred = <DeferredDocument>[];
      await SyncEngine(
        store: device.store,
        transport: server,
        onDeferred: deferred.addAll,
      ).run();
      expect(deferred.single.reason, 'newerSchema');
      expect(device.store.rows, isEmpty);
      expect(device.store.deferred, hasLength(1));
      expect((await device.store.checkpoint()).cursor, '1');
      // The app is updated: the next run applies it.
      device.store.readable = (_, _) => true;
      final applied = <Set<String>>[];
      await SyncEngine(
        store: device.store,
        transport: server,
        onApplied: applied.add,
      ).run();
      expect(device.store.rows, hasLength(1));
      expect(device.store.deferred, isEmpty);
      expect(applied.first, {'weighIn'});
    });
  });

  group('SyncEngine dataset reset (TD-066):', () {
    test('a reset server gets back every surviving local row', () async {
      final (:device, :server) = _setup();
      device
        ..write(1, {'v': 1})
        ..write(2, {'v': 2}, deleted: true);
      await device.engine.run();
      final old = (await device.store.checkpoint()).datasetId;
      server.resetDataset(syntheticId(778));
      device.restart(server);
      final report = await device.engine.run();
      expect(report.firstSync, isTrue);
      final cp = await device.store.checkpoint();
      expect(cp.datasetId, isNot(old));
      expect(cp.resetActive, isFalse);
      expect(device.store.outboxLength, 0);
      final fresh = SimDevice(3, server, SimClock(base));
      await fresh.engine.run();
      expect(fresh.store.rows, device.store.rows);
    });

    test(
      'a rollback keeps newer server winners and re-uploads only what it lacks',
      () async {
        final (:device, :server) = _setup();
        final other = SimDevice(2, server, SimClock(base));
        device
          ..write(1, {'v': 'mine'})
          ..write(2, {'v': 'kept'});
        await device.engine.run();
        // The new dataset already has row 1 newer (another phone re-uploaded).
        server.resetDataset(syntheticId(779));
        other.clock.now = base.add(const Duration(seconds: 3));
        final winner = other.write(1, {'v': 'theirs, newer'});
        await other.engine.run();
        final pushes = server.calls['push']!;
        await device.engine.run();
        expect(device.store.rows['weighIn/${syntheticId(1)}'], winner);
        expect(server.documents, hasLength(2));
        expect(server.calls['push'], pushes + 1, reason: 'one push for row 2');
      },
    );

    test('a crash mid-reset resumes without losing the re-upload', () async {
      final (:device, :server) = _setup();
      for (var i = 0; i < 150; i++) {
        device.write(i, {'v': i});
      }
      await device.engine.run();
      server.resetDataset(syntheticId(780));
      // Another phone filled the new dataset first: the reset pull has pages.
      final other = SimDevice(2, server, SimClock(base));
      for (var i = 1000; i < 1150; i++) {
        other.write(i, {'v': i});
      }
      await other.engine.run();
      var pages = 0;
      device.store.crash = (point) {
        if (point == 'applyPage' && ++pages == 2) throw const InjectedCrash();
      };
      await expectLater(device.engine.run(), throwsA(isA<InjectedCrash>()));
      device
        ..store.crash = null
        ..restart(server);
      expect((await device.store.checkpoint()).resetActive, isTrue);
      await device.engine.run();
      expect(server.documents, hasLength(300));
      expect(device.store.outboxLength, 0);
      expect(device.store.rows, hasLength(300));
    });

    test(
      'a crash before the re-upload is acknowledged keeps it pending',
      () async {
        final (:device, :server) = _setup();
        for (var i = 0; i < 20; i++) {
          device.write(i, {'v': i});
        }
        await device.engine.run();
        server.resetDataset(syntheticId(781));
        device.store.crash = (point) {
          if (point == 'settle') throw const InjectedCrash();
        };
        await expectLater(device.engine.run(), throwsA(isA<InjectedCrash>()));
        device
          ..store.crash = null
          ..restart(server);
        expect(device.store.outboxLength, 20);
        await device.engine.run();
        expect(server.documents, hasLength(20));
        expect(device.store.outboxLength, 0);
      },
    );
  });

  // covers: AC-012 (A34 fix round 1, finding 1)
  group('SyncEngine never loses a confirmed edit to a pull:', () {
    test(
      'an older edit made while a pull is in flight reaches history',
      () async {
        final (:device, :server) = _setup();
        final other = SimDevice(
          2,
          server,
          SimClock(base.add(const Duration(seconds: 30))),
        );
        final newer = other.write(1, {'v': 'other phone'});
        await other.engine.run();
        SyncChange? mine;
        device.faulty.duringPull = () {
          mine = device.write(1, {'v': 'mine, older clock'});
        };
        await device.engine.run();
        expect(device.store.rows['weighIn/${syntheticId(1)}'], newer);
        expect(device.store.displaced, hasLength(1));
        await device.engine.run();
        expect(device.store.displaced, isEmpty);
        expect(server.history.map((d) => d.hlc), contains(mine!.hlc));
        expect(server.documents['weighIn/${syntheticId(1)}']!.hlc, newer.hlc);
      },
    );

    test(
      'a newer edit made while a pull is in flight wins everywhere',
      () async {
        final (:device, :server) = _setup();
        final other = SimDevice(2, server, SimClock(base))
          ..write(1, {'v': 'other phone'});
        await other.engine.run();
        SyncChange? mine;
        device.faulty.duringPull = () {
          device.clock.now = base.add(const Duration(seconds: 30));
          mine = device.write(1, {'v': 'mine, newer'});
        };
        await device.engine.run();
        await device.engine.run();
        await other.engine.run();
        expect(device.store.rows['weighIn/${syntheticId(1)}'], mine);
        expect(other.store.rows['weighIn/${syntheticId(1)}'], mine);
      },
    );

    test(
      'a deferred document applied before the push keeps the pending edit',
      () async {
        final (:device, :server) = _setup();
        final newerApp = SimDevice(
          2,
          server,
          SimClock(base.add(const Duration(seconds: 30))),
        );
        await device.engine.run();
        // The newer app's document arrives while the user edits the row on
        // this phone (an older clock); this app can't read it yet.
        newerApp.store.confirm(
          entity: 'weighIn',
          id: syntheticId(1),
          schemaVersion: 3,
          payload: const {'kg': 70},
        );
        await newerApp.engine.run();
        device.store.readable = (_, version) => version <= 2;
        late SyncChange mine;
        device.faulty.duringPull = () {
          mine = device.write(1, {'v': 'edit during pull'});
        };
        await device.engine.run();
        expect(device.store.deferred, hasLength(1));
        // The app is updated: the deferred document is applied before the
        // push and must not erase the pending edit.
        device.store.readable = (_, _) => true;
        await device.engine.run();
        expect(
          device.store.rows['weighIn/${syntheticId(1)}']!.schemaVersion,
          3,
        );
        expect(server.history.map((d) => d.hlc), contains(mine.hlc));
        expect(device.store.displaced, isEmpty);
      },
    );

    test('a fence over a pending edit keeps it and pushes it', () async {
      final (:device, :server) = _setup();
      final other = SimDevice(
        2,
        server,
        SimClock(base.add(const Duration(seconds: 30))),
      )..write(1, {'v': 'x'});
      await other.engine.run();
      other.write(1, {'v': 'x'}, deleted: true);
      await other.engine.run();
      server.compact('weighIn', syntheticId(1));
      SyncChange? mine;
      device.faulty.duringPull = () {
        mine = device.write(1, {'v': 'mine, older'});
      };
      await device.engine.run();
      expect(
        device.store.rows['weighIn/${syntheticId(1)}']!.deletedAt,
        isNotNull,
      );
      await device.engine.run();
      expect(device.store.displaced, isEmpty);
      expect(server.calls['push'], greaterThanOrEqualTo(1));
      expect(mine, isNotNull);
    });
  });

  // A34 fix round 1, finding 4.
  test(
    'more than 500 refused rows never hide a valid row behind them',
    () async {
      final (:device, :server) = _setup();
      device.store.refuseEncode = (row) =>
          row.payload['note'] == 'refused' ? 'tooLarge' : null;
      for (var i = 0; i < 520; i++) {
        device.store.confirm(
          entity: 'weighIn',
          id: syntheticId(i),
          payload: const {'note': 'refused'},
        );
      }
      device.write(9999, {'v': 'valid'});
      final report = await device.engine.run();
      expect(report.parked, hasLength(520));
      expect(server.documents.keys, ['weighIn/${syntheticId(9999)}']);
    },
  );
}

final class _Rewriting implements SyncTransport {
  new(this.inner, this.rewrite);
  final SyncTransport inner;
  final SyncPushResponse Function(SyncPushResponse) rewrite;

  @override
  Future<SyncPushResponse> push(
    List<SyncChange> changes, {
    required String? datasetId,
  }) async => rewrite(await inner.push(changes, datasetId: datasetId));

  @override
  Future<SyncPage> pull({
    required String cursor,
    required int limit,
    required String? datasetId,
  }) => inner.pull(cursor: cursor, limit: limit, datasetId: datasetId);

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
