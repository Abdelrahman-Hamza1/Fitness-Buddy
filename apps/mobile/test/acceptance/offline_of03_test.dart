import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart' show SequenceIdGenerator;
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/sync/drift_sync_store.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/sync/earlier_versions.dart';
import 'package:fb_mobile/core/sync/restore_version.dart';
import 'package:fb_mobile/features/diary/data/diary_op_handler.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../core/db/support/db_support.dart';
import '../core/db/sync/sync_support.dart';
import '../features/diary/support/diary_fixtures.dart' show fixtureId;
import '../features/diary/support/diary_harness.dart' show newEntry;

/// One phone: its own profile database, the app's single writer with the
/// diary and restore handlers, and the sync engine over the app's drift
/// store, all against one shared server and clock.
final class _Phone {
  new(String deviceId, SimClock clock, FakeSyncServer server) {
    final bus = DomainEventBus();
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (d) => [
        DiaryOpHandler(d),
        RestoreVersionHandler(d, appCodecs(d)),
      ],
      clock: clock,
      ids: SequenceIdGenerator(),
      deviceId: () async => deviceId,
      events: bus,
    );
    store = driftStore(
      db,
      clock: clock,
      deviceId: deviceId,
      exclusive: applier.runExclusive,
    );
    engine = SyncEngine(store: store, transport: server);
  }

  final AppDatabase db = memoryDatabase();
  late final ChangeSetApplier<AppDatabase> applier;
  late final DriftSyncStore store;
  late final SyncEngine engine;

  Future<Applied> apply(ChangeOp op) async {
    final result = await applier.apply(ChangeSet([op], origin: Origin.direct));
    expect(result, isA<Applied>(), reason: '$result');
    return result as Applied;
  }

  Future<DiaryEntryRow> entry() => (db.select(
    db.diaryEntries,
  )..where((t) => t.id.equals(fixtureId(1)))).getSingle();

  /// Changes the entry's amount to [grams] g at its current version.
  Future<void> setGrams(double grams) async {
    final row = await entry();
    await apply(
      UpdateDiaryEntry(
        row.id,
        row.version,
        EntryPatch(
          amount: EntryAmount(
            input: Quantity(grams, 'g'),
            amount: grams,
            basis: NutrientBasis.per100g,
          ),
        ),
      ),
    );
  }
}

void main() {
  // covers: OF-03, AC-012
  for (final laterSyncsFirst in [false, true]) {
    final first = laterSyncsFirst ? 'later' : 'earlier';
    test('OF-03 AC-012 the same entry edited offline on two phones: after '
        'sync both show the later edit, and the earlier one is recoverable '
        'in its history and restores ($first edit syncs first)', () async {
      final clock = SimClock(DateTime.utc(2026, 10, 17, 14));
      final server = FakeSyncServer(clock);
      final a = _Phone('0199e3c2-5b1a-7c3d-8e4f-00000000000a', clock, server);
      final b = _Phone('0199e3c2-5b1a-7c3d-8e4f-00000000000b', clock, server);

      // Logged on A, synced to both.
      await a.apply(LogEntries([newEntry(1)]));
      await a.engine.run();
      await b.engine.run();
      expect((await b.entry()).amount, 150);

      // Both offline: A changes it to 200 g, then (a minute later) B to 300 g.
      clock.now = clock.now.add(const Duration(minutes: 1));
      await a.setGrams(200);
      clock.now = clock.now.add(const Duration(minutes: 1));
      await b.setGrams(300);

      // Back online, in either order, then once more each.
      final order = laterSyncsFirst ? [b, a, b, a] : [a, b, a, b];
      for (final phone in order) {
        clock.now = clock.now.add(const Duration(seconds: 5));
        await phone.engine.run();
      }

      // The latest change wins on both phones.
      expect((await a.entry()).amount, 300);
      expect((await b.entry()).amount, 300);

      // A's overwritten 200 g is in the entry's history, on either phone.
      for (final phone in [a, b]) {
        final versions = await readEarlierVersions(
          server,
          phone.store,
          'diaryEntry',
          fixtureId(1),
        );
        expect(
          [for (final v in versions) v.payload['amount']],
          contains(200),
          reason: 'the earlier edit stays recoverable',
        );
      }

      // And restoring it on A is a new edit that wins everywhere.
      final versions = await readEarlierVersions(
        server,
        a.store,
        'diaryEntry',
        fixtureId(1),
      );
      final earlier = versions.firstWhere((v) => v.payload['amount'] == 200);
      await a.apply(
        RestoreVersionOp(
          entity: 'diaryEntry',
          id: fixtureId(1),
          payload: earlier.payload,
          deleted: earlier.deleted,
          expectedVersion: earlier.localVersion,
        ),
      );
      clock.now = clock.now.add(const Duration(seconds: 5));
      await a.engine.run();
      await b.engine.run();
      expect((await a.entry()).amount, 200);
      expect((await b.entry()).amount, 200);
    });
  }
}
