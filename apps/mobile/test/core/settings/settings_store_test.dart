import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/settings/setting_key.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_phone.dart';
import '../db/support/db_support.dart';

enum _Units { metric, imperial }

const _proposal = '0199e3c2-5b1a-7c3d-8e4f-0000000000b1';

final SettingKey<_Units> _units = SettingKey.enumeration(
  'units.system',
  _Units.values,
  defaultValue: _Units.metric,
);
final SettingKey<int> _goal = SettingKey.integer(
  'profile.goalKcal',
  defaultValue: 2000,
);

/// A store over an in-memory profile database, its applier and its bus.
final class _Setup {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [SettingsOpHandler(db.settingsKv)],
      clock: ManualClock.millis(1792195200000),
      ids: SequenceIdGenerator(),
      deviceId: () async => testDevice,
      events: bus,
    );
    store = SettingsStore(db: db, applier: applier);
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();
  late final ChangeSetApplier<AppDatabase> applier;
  late final SettingsStore store;

  Future<List<SettingRow>> rows() => db.select(db.settingsKv).get();
}

Future<Applied> _applied(Future<ApplyResult> result) async {
  final r = await result;
  if (r is! Applied) fail('expected Applied, got $r');
  return r;
}

void main() {
  group('settings', () {
    test('put/read typed values; unset keys read as their default', () async {
      final s = _Setup();
      expect(await s.store.read(_units), _Units.metric);
      expect(await s.store.read(_goal), 2000);

      await _applied(
        s.store.put(_units, _Units.imperial, origin: Origin.direct),
      );
      await _applied(s.store.put(_goal, 1800, origin: Origin.direct));

      expect(await s.store.read(_units), _Units.imperial);
      expect(await s.store.read(_goal), 1800);
    });

    test('natural id setting:<key>, entity setting, value as JSON, one row '
        'after two puts', () async {
      final s = _Setup();
      await _applied(s.store.put(_goal, 1800, origin: Origin.direct));
      await _applied(s.store.put(_goal, 1900, origin: Origin.direct));

      final row = (await s.rows()).single;
      expect(row.id, naturalId('setting', 'profile.goalKcal'));
      expect(row.id, settingRowId('profile.goalKcal'));
      expect((row.valueJson, row.version, row.origin), ('1900', 2, 'direct'));
      expect((await outbox(s.db)).map((o) => (o.$1, o.$2)), [
        ('setting', row.id),
        ('setting', row.id),
      ]);
    });

    test('watch emits the current value, then each change, without '
        'repeats', () async {
      final s = _Setup();
      final seen = <int>[];
      final sub = s.store.watch(_goal).listen(seen.add);
      addTearDown(sub.cancel);
      await pumpEventQueue();

      await _applied(s.store.put(_goal, 1800, origin: Origin.direct));
      await pumpEventQueue();
      // Another key's write re-runs the query; the value didn't change.
      await _applied(
        s.store.put(_units, _Units.imperial, origin: Origin.direct),
      );
      await pumpEventQueue();
      await _applied(s.store.reset(_goal, origin: Origin.direct));
      await pumpEventQueue();

      expect(seen, [2000, 1800, 2000]);
    });

    test('reset tombstones the row and reads the default; a put revives '
        'it; resetting an unset key writes nothing', () async {
      final s = _Setup();
      final none = await _applied(s.store.reset(_goal, origin: Origin.direct));
      expect(await s.rows(), isEmpty);
      expect(none.events.whereType<SettingsChanged>(), isEmpty);

      await _applied(s.store.put(_goal, 1800, origin: Origin.direct));
      await _applied(s.store.reset(_goal, origin: Origin.direct));
      var row = (await s.rows()).single;
      expect(row.deletedAt, isNotNull);
      expect(await s.store.read(_goal), 2000);
      expect((await outbox(s.db)).last.$4, isTrue, reason: 'tombstone syncs');

      final again = await _applied(s.store.reset(_goal, origin: Origin.direct));
      expect(again.inverse.rows, isEmpty, reason: 'already reset');

      await _applied(s.store.put(_goal, 1700, origin: Origin.direct));
      row = (await s.rows()).single;
      expect((row.deletedAt, row.valueJson), (null, '1700'));
      expect(await s.store.read(_goal), 1700);
    });

    test('SettingsChanged is emitted for put, reset and their undo', () async {
      final s = _Setup();
      final heard = <SettingsChanged>[];
      s.bus.on<SettingsChanged>().listen(heard.add);

      final put = await _applied(
        s.store.put(_goal, 1800, origin: Origin.direct),
      );
      expect(put.events.first, SettingsChanged({'profile.goalKcal'}));
      await _applied(s.applier.revert(put.inverse));
      await _applied(s.store.put(_goal, 1900, origin: Origin.direct));
      await _applied(s.store.reset(_goal, origin: Origin.direct));
      await pumpEventQueue();

      expect(heard, List.filled(4, SettingsChanged({'profile.goalKcal'})));
    });

    test('undo restores the previous value: of a put, of a reset', () async {
      final s = _Setup();
      await _applied(s.store.put(_goal, 1800, origin: Origin.direct));
      final put = await _applied(
        s.store.put(_goal, 1900, origin: Origin.direct),
      );
      await _applied(s.applier.revert(put.inverse));
      expect(await s.store.read(_goal), 1800);

      final reset = await _applied(s.store.reset(_goal, origin: Origin.direct));
      await _applied(s.applier.revert(reset.inverse));
      expect(await s.store.read(_goal), 1800);
      expect((await s.rows()).single.origin, startsWith('undo:'));
    });

    test('the origin is recorded', () async {
      final s = _Setup();
      await _applied(
        s.store.put(_goal, 1800, origin: Origin.proposal(_proposal)),
      );
      expect((await s.rows()).single.origin, 'proposal:$_proposal');
    });

    test('a stored value the key cannot read reads as the default', () async {
      final s = _Setup();
      await _applied(
        s.applier.apply(
          ChangeSet([
            SettingsOp.put('profile.goalKcal', '"lots"'),
          ], origin: Origin.direct),
        ),
      );
      expect(await s.store.read(_goal), 2000);
    });

    test('several settings in one change set apply together', () async {
      final s = _Setup();
      await _applied(
        s.applier.apply(
          ChangeSet([
            SettingsOp.put('profile.goalKcal', '1500'),
            SettingsOp.put('units.system', '"imperial"'),
          ], origin: Origin.direct),
        ),
      );
      expect(await s.store.read(_goal), 1500);
      expect(await s.store.read(_units), _Units.imperial);
    });

    test('appOverrides registers the settings handler: settingsStoreProvider '
        'writes through the app applier', () async {
      final db = memoryDatabase();
      final container = ProviderContainer.test(
        overrides: [
          ...TestPhone().overrides(),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      expect(
        container.read(changeOpHandlersProvider)(db).map((h) => h.family),
        [
          SettingsOp.familyName,
          DiaryOp.familyName,
          MealSlotOp.familyName,
          PersonalFoodOp.familyName,
          TargetsOp.familyName,
          WeighInOp.familyName,
          ChatMessageOp.familyName,
          ProposalOp.familyName,
          WorkoutOp.familyName,
        ],
      );
      final store = container.read(settingsStoreProvider);
      await _applied(store.put(_goal, 1600, origin: Origin.direct));
      expect(await store.read(_goal), 1600);
      expect((await db.select(db.settingsKv).getSingle()).valueJson, '1600');
    });
  });
}
