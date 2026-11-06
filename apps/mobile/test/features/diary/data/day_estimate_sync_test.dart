import 'package:drift/drift.dart' show Variable;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart' show SequenceIdGenerator;
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/features/adaptive/application/adaptive_inputs.dart';
import 'package:fb_mobile/features/diary/data/diary_op_handler.dart';
import 'package:fb_mobile/features/diary/data/diary_reads.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../core/db/support/db_support.dart';
import '../../../core/db/sync/sync_support.dart';
import '../support/diary_harness.dart' show atDay, newEntry;

/// Two days before [syncBase]'s date (2025-10-13).
final LocalDate _past = LocalDate(2025, 10, 11);

/// One phone: its database, clock, single writer and sync.
final class _Phone {
  new(this.device, FakeSyncServer server) {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [DiaryOpHandler(db)],
      clock: clock,
      ids: SequenceIdGenerator(),
      deviceId: () async => device,
      events: bus,
    );
    engine = SyncEngine(
      store: driftStore(db, clock: clock, deviceId: device),
      transport: server,
    );
  }

  final String device;
  final AppDatabase db = memoryDatabase();
  final SimClock clock = SimClock(syncBase);
  final DomainEventBus bus = DomainEventBus();
  late final ChangeSetApplier<AppDatabase> applier;
  late final SyncEngine engine;
  late final DiaryReads reads = DiaryReads(db);

  void tick() => clock.now = clock.now.add(const Duration(seconds: 1));

  Future<void> apply(DiaryOp op) async {
    tick();
    final result = await applier.apply(ChangeSet([op], origin: Origin.direct));
    expect(result, isA<Applied>(), reason: device);
  }

  Future<void> logFood() => apply(
    LogEntries([newEntry(1, when: atDay(_past), slotId: DefaultSlots.lunchId)]),
  );

  Future<void> estimate(double kcal) => apply(
    SetDayEstimate(
      _past,
      kcal: kcal,
      expectedVersion: null,
      expectEstimate: false,
    ),
  );
}

void main() {
  for (final aFirst in [true, false]) {
    final order = aFirst ? 'A first' : 'B first';
    test('DY-006 D13 two offline devices: food on A + estimate on B → food '
        'wins in totals, the estimate stays stored, the day is left out of '
        'adaptive ($order)', () async {
      final server = FakeSyncServer(SimClock(syncBase));
      final a = _Phone(testDevice, server);
      final b = _Phone(syntheticId(2), server);
      await a.logFood();
      // B saw an empty day.
      await b.estimate(2300);
      final phones = aFirst ? [a, b, a, b] : [b, a, b, a];
      for (final p in phones) {
        p.tick();
        await p.engine.run();
      }
      for (final p in [a, b]) {
        final day = (await p.reads.dailyTotals(_past, _past)).single;
        expect(
          (day.entryCount, day.dayEstimate, day.hasDayEstimate),
          (1, false, true),
          reason: p.device,
        );
        expect(day.intake.sum.kcal, 300, reason: '${p.device}: food wins');
        expect(day.intake.dayEstimate, isFalse);
        expect((await p.reads.markOn(_past))!.estimateKcal, 2300);
        final adaptive = intakeDaysOf(
          totals: [day],
          marks: await p.reads.marksBetween(_past, _past),
        ).single;
        expect(adaptive.incomplete, isTrue, reason: p.device);
        expect(adaptive.logged, isTrue);
      }
    });
  }

  test('DY-006 two devices setting the same day estimate converge on one '
      'day-mark row (natural ID, last writer wins)', () async {
    final server = FakeSyncServer(SimClock(syncBase));
    final a = _Phone(testDevice, server);
    final b = _Phone(syntheticId(2), server);
    await a.estimate(2300);
    b.tick();
    await b.estimate(2500);
    for (final p in [a, b, a, b]) {
      p.tick();
      await p.engine.run();
    }
    for (final p in [a, b]) {
      final rows = await p.db
          .customSelect(
            'SELECT id, estimate_kcal FROM day_marks WHERE local_date = ?',
            variables: [Variable.withString('$_past')],
          )
          .get();
      expect(rows, hasLength(1), reason: p.device);
      expect(rows.single.read<String>('id'), dayMarkRowId(_past));
      expect(rows.single.read<double>('estimate_kcal'), 2500);
    }
  });
}
