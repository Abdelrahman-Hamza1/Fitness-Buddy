import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart' show SequenceIdGenerator;
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:fb_sync/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/db/support/db_support.dart';
import '../../core/db/sync/sync_support.dart';

// Ramadan 1448: 2027-02-08 … 2027-03-08.
final _d1 = LocalDate(2027, 2, 10);
final _d2 = LocalDate(2027, 2, 11);

/// One phone: its database, clock, writer, settings commands and sync.
final class _Phone {
  new(this.device, FakeSyncServer server) {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [SettingsOpHandler(db.settingsKv)],
      clock: clock,
      ids: SequenceIdGenerator(),
      deviceId: () async => device,
      events: bus,
    );
    undo = UndoStack(revert: applier.revert, clock: clock);
    addTearDown(undo.dispose);
    store = SettingsStore(db: db, applier: applier);
    actions = SettingsActions(store: store, undoStack: undo);
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
  late final UndoStack undo;
  late final SettingsStore store;
  late final SettingsActions actions;
  late final SyncEngine engine;

  void tick() => clock.now = clock.now.add(const Duration(seconds: 1));

  /// What the phone's calendar says: the season and the not-fasting days.
  Future<(RamadanSeason?, Set<LocalDate>)> view() async {
    final seasons = await store.read(AppSettings.ramadanSeasons);
    final notFasting = {
      for (final d in [_d1, _d2])
        if (await store.read(AppSettings.fastingMark(d)) ==
            FastingMark.notFasting)
          d,
    };
    return (seasons[1448], notFasting);
  }
}

void main() {
  test('A41a fix round 2: two offline phones mark different days and one '
      'changes a season preference; after syncing both agree on everything '
      '(per-key last writer wins), and "fasting again" wins over an older '
      'mark', () async {
    final server = FakeSyncServer(SimClock(syncBase));
    final a = _Phone(testDevice, server);
    final b = _Phone(syntheticId(2), server);
    Future<void> syncAll() async {
      for (final p in [a, b, a, b]) {
        p.tick();
        await p.engine.run();
      }
    }

    a.tick();
    expect(
      await a.actions.setRamadanSeason(
        RamadanSeason(hijriYear: 1448, on: true),
      ),
      isA<SettingsDone>(),
    );
    await syncAll();
    expect((await b.view()).$1?.on, isTrue);

    // Offline: A marks day 1, B marks day 2 and chooses maintain.
    a.tick();
    expect(
      await a.actions.setNotFasting(_d1, notFasting: true),
      isA<SettingsDone>(),
    );
    b
      ..tick()
      ..tick();
    expect(
      await b.actions.setNotFasting(_d2, notFasting: true),
      isA<SettingsDone>(),
    );
    final season = (await b.view()).$1!;
    b.tick();
    expect(
      await b.actions.setRamadanSeason(season.copyWith(maintain: true)),
      isA<SettingsDone>(),
    );
    await syncAll();
    for (final p in [a, b]) {
      final (s, notFasting) = await p.view();
      expect(notFasting, {_d1, _d2}, reason: p.device);
      expect((s!.on, s.maintain), (true, true), reason: p.device);
    }

    // B switches day 1 back to fasting (an explicit value), later than A's
    // mark: both phones converge on fasting.
    b
      ..tick()
      ..tick();
    final back = await b.actions.setNotFasting(_d1, notFasting: false);
    expect(back, isA<SettingsDone>());
    await syncAll();
    for (final p in [a, b]) {
      expect((await p.view()).$2, {_d2}, reason: p.device);
    }

    // Undo on B restores day 1's mark, and it syncs like any edit.
    b.tick();
    expect(
      await b.undo.undo((back as SettingsDone).undoEntryId),
      UndoOutcome.undone,
    );
    await syncAll();
    for (final p in [a, b]) {
      expect((await p.view()).$2, {_d1, _d2}, reason: p.device);
    }
  });
}
