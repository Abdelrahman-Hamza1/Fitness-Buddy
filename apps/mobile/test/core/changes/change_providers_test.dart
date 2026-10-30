import 'package:drift/drift.dart' hide isNotNull;
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/system.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/row_ops.dart';
import 'package:fb_mobile/core/changes/write_gate.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/db/natural_id.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/test_phone.dart';
import '../db/support/db_support.dart';
import 'support/test_db.dart';

void main() {
  test('the providers: the applier writes the profile database with the '
      'install id and announces on the bus; undo goes through it', () async {
    final db = memoryDatabase();
    final container = ProviderContainer.test(
      overrides: [
        // Like appOverrides, with a test handler instead of the app's.
        clockProvider.overrideWithValue(const SystemClock()),
        idGeneratorProvider.overrideWithValue(systemUuidV7Generator()),
        sharedPreferencesProvider.overrideWith((ref) {
          SharedPreferencesAsyncPlatform.instance =
              InMemorySharedPreferencesAsync.empty();
          return SharedPreferencesAsync();
        }),
        appDatabaseProvider.overrideWithValue(db),
        changeOpHandlersProvider.overrideWithValue(
          (_) => const [ScriptHandler()],
        ),
      ],
    );
    final heard = <DomainEvent>[];
    container.read(domainEventBusProvider).events.listen(heard.add);
    final id = naturalId('setting', 'units.system');

    final result = await container
        .read(changeSetApplierProvider)
        .apply(
          ChangeSet([
            ScriptOp.rows([
              UpsertRow(
                db.settingsKv,
                SettingsKvCompanion(
                  id: Value(id),
                  valueJson: const Value('"metric"'),
                ),
              ),
            ]),
          ], origin: Origin.direct),
        );

    final applied = result as Applied;
    final row = await db.select(db.settingsKv).getSingle();
    final device = await container.read(deviceIdStoreProvider).deviceId();
    expect((row.id, row.valueJson, row.deviceId), (id, '"metric"', device));
    expect(await outbox(db), hasLength(1));
    expect(heard.single, isA<ChangeSetApplied>());

    final stack = container.read(undoStackProvider);
    final entry = stack.record(applied, UndoLabel('settingChanged'));
    expect(await stack.undo(entry.id), UndoOutcome.undone);
    expect((await db.select(db.settingsKv).getSingle()).deletedAt, isNotNull);
  });

  test(
    'DY-010 appOverrides wires the clock and composes the handlers (settings '
    'from WP4); without it the handler list is unset',
    () async {
      final container = ProviderContainer.test(
        overrides: [
          ...TestPhone().overrides(),
          appDatabaseProvider.overrideWithValue(memoryDatabase()),
        ],
      );
      expect(
        container
            .read(changeOpHandlersProvider)(container.read(appDatabaseProvider))
            .map((h) => h.family),
        [
          SettingsOp.familyName,
          DiaryOp.familyName,
          MealSlotOp.familyName,
          PersonalFoodOp.familyName,
          TargetsOp.familyName,
          WeighInOp.familyName,
          MeasurementOp.familyName,
          ChatMessageOp.familyName,
          ProposalOp.familyName,
          WorkoutOp.familyName,
        ],
      );
      expect(container.read(clockProvider), isA<SystemClock>());
      final result = await container
          .read(changeSetApplierProvider)
          .apply(ChangeSet([ScriptOp.rows([])], origin: Origin.direct));
      expect((result as Rejected).failure, const InvalidOp('unknownFamily'));

      final bare = ProviderContainer.test();
      expect(() => bare.read(changeOpHandlersProvider), throwsA(anything));
      expect(() => bare.read(clockProvider), throwsA(anything));
    },
  );

  test('AC-004 the write gate rejects apply and revert inside the serialized '
      'entry, bound to the profile of the database', () async {
    final db = memoryDatabase();
    final gate = _FakeGate();
    final container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(const SystemClock()),
        idGeneratorProvider.overrideWithValue(systemUuidV7Generator()),
        sharedPreferencesProvider.overrideWith((ref) {
          SharedPreferencesAsyncPlatform.instance =
              InMemorySharedPreferencesAsync.empty();
          return SharedPreferencesAsync();
        }),
        appDatabaseProvider.overrideWithValue(db),
        changeOpHandlersProvider.overrideWithValue(
          (_) => const [ScriptHandler()],
        ),
        profileWriteGateProvider.overrideWithValue(gate),
        activeProfileResolverProvider.overrideWithValue(() async => 'local'),
      ],
    );
    final applier = container.read(changeSetApplierProvider);
    final applied = await applier.apply(
      ChangeSet([
        ScriptOp.rows([
          UpsertRow(
            db.settingsKv,
            SettingsKvCompanion(
              id: Value(naturalId('setting', 'units.system')),
              valueJson: const Value('"metric"'),
            ),
          ),
        ]),
      ], origin: Origin.direct),
    ) as Applied;
    expect(gate.seen, ['local']);

    gate.reason = 'readOnlyProfile';
    final reverted = await applier.revert(applied.inverse);
    expect((reverted as Rejected).failure, const InvalidOp('readOnlyProfile'));
    final again = await applier.apply(
      ChangeSet([ScriptOp.rows([])], origin: Origin.direct),
    );
    expect((again as Rejected).failure, const InvalidOp('readOnlyProfile'));
    expect(await db.select(db.settingsKv).get(), hasLength(1));

    // A denial decided at the queue head: a write queued before the gate
    // closes is still checked when its turn comes.
    gate.reason = null;
    final queued = applier.apply(
      ChangeSet([ScriptOp.rows([])], origin: Origin.direct),
    );
    gate.reason = 'transition';
    expect(((await queued) as Rejected).failure, const InvalidOp('transition'));
    await applier.idle();
  });

  test('AC-004 a pinned database (explicit switch, tests) is gated without '
      'an active-profile comparison', () async {
    final db = memoryDatabase();
    final gate = _FakeGate();
    final container = ProviderContainer.test(
      overrides: [
        clockProvider.overrideWithValue(const SystemClock()),
        idGeneratorProvider.overrideWithValue(systemUuidV7Generator()),
        sharedPreferencesProvider.overrideWith((ref) {
          SharedPreferencesAsyncPlatform.instance =
              InMemorySharedPreferencesAsync.empty();
          return SharedPreferencesAsync();
        }),
        appDatabaseProvider.overrideWithValue(db),
        changeOpHandlersProvider.overrideWithValue(
          (_) => const [ScriptHandler()],
        ),
        profileWriteGateProvider.overrideWithValue(gate),
      ],
    );
    await container
        .read(changeSetApplierProvider)
        .apply(ChangeSet([ScriptOp.rows([])], origin: Origin.direct));
    expect(gate.seen, ['pinned']);
  });
}

final class _FakeGate implements WriteGate {
  String? reason;
  final seen = <String>[];

  @override
  Future<String?> denial(String? profileKey, {int? generation}) async {
    seen.add(profileKey ?? 'pinned');
    return reason;
  }
}
