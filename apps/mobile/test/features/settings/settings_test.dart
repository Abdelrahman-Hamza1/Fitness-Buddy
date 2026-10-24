import 'dart:async';
import 'dart:convert';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/changes/apply_result.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/changes/op_handler.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/settings/setting_key.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../core/catalog/support/catalog_support.dart';
import '../../core/db/support/db_support.dart';
import '../../helpers/test_phone.dart';
import '../foods/presentation/support/sheet_support.dart';

final class Rig {
  new({Future<void> Function()? beforePlan}) {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [
        GateHandler(SettingsOpHandler(db.settingsKv), beforePlan),
      ],
      clock: clock,
      ids: SequenceIdGenerator(),
      deviceId: () async => testDevice,
      events: bus,
    );
    store = SettingsStore(db: db, applier: applier);
    stack = UndoStack(revert: applier.revert, clock: clock);
    addTearDown(stack.dispose);
    actions = SettingsActions(store: store, undoStack: stack);
  }
  final AppDatabase db = memoryDatabase();
  final bus = DomainEventBus();
  final clock = ManualClock(DateTime.utc(2026, 10, 22));
  late final ChangeSetApplier<AppDatabase> applier;
  late final SettingsStore store;
  late final UndoStack stack;
  late final SettingsActions actions;
  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        ...TestPhone().overrides(),
        settingsStoreProvider.overrideWithValue(store),
        undoStackProvider.overrideWithValue(stack),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  Future<String> raw() async => jsonEncode({
    for (final table in ['settings_kv', 'sync_outbox'])
      table: [
        for (final row
            in await db.customSelect('SELECT * FROM $table ORDER BY 1').get())
          row.data,
      ],
  });
}

final class GateHandler extends ChangeOpHandler<SettingsOp> {
  new(this.delegate, this.before);
  final SettingsOpHandler delegate;
  final Future<void> Function()? before;
  @override
  String get family => SettingsOp.familyName;
  @override
  Future<OpPlan> plan(SettingsOp op, TxReader tx, ApplyContext context) async {
    await before?.call();
    return await delegate.plan(op, tx, context);
  }
}

void main() {
  test('LC-010 LC-021 FD-080 UX-040 setting keys: names pinned '
      '(units.system, calendar.weekStart, food.halal, '
      'appearance.theme, location.cityId) and defaults metric, '
      'saturday, true, system, unset', () async {
    expect(
      [
        AppSettings.unitSystem.name,
        AppSettings.weekStart.name,
        AppSettings.halal.name,
        AppSettings.theme.name,
        AppSettings.cityId.name,
      ],
      [
        'units.system',
        'calendar.weekStart',
        'food.halal',
        'appearance.theme',
        'location.cityId',
      ],
    );
    final r = Rig();
    expect(await r.store.read(AppSettings.unitSystem), UnitSystem.metric);
    expect(await r.store.read(AppSettings.weekStart), DayOfWeek.saturday);
    expect(await r.store.read(AppSettings.halal), isTrue);
    expect(await r.store.read(AppSettings.theme), ThemePreference.system);
    expect(await r.store.read(AppSettings.cityId), isNull);
    final c = r.container();
    final units = c.listen(unitSystemProvider, (_, _) {});
    final halal = c.listen(halalProvider, (_, _) {});
    final theme = c.listen(themePreferenceProvider, (_, _) {});
    final city = c.listen(cityIdProvider, (_, _) {});
    addTearDown(units.close);
    addTearDown(halal.close);
    addTearDown(theme.close);
    addTearDown(city.close);
    expect(await c.read(unitSystemProvider.future), UnitSystem.metric);
    expect(await c.read(halalProvider.future), isTrue);
    expect(
      await c.read(themePreferenceProvider.future),
      ThemePreference.system,
    );
    expect(await c.read(cityIdProvider.future), isNull);
    expect(c.read(settingsActionsProvider), isA<SettingsActions>());
  });
  test(
    'optionalString codec: round-trip, null, a malformed value reads as unset',
    () async {
      final key = SettingKey.optionalString('test.optional');
      expect(key.codec.decode(key.codec.encode('city:282615')), 'city:282615');
      expect(SettingCodec.optionalString.encode(null), 'null');
      expect(SettingCodec.optionalString.decode('null'), isNull);
      for (final malformed in ['1', '{}', 'true', '["x"]', 'not json']) {
        expect(key.valueOf(malformed), isNull);
      }
    },
  );
  test(
    'LC-033 location.cityId not matching city:<digits> reads as unset',
    () async {
      for (final input in [
        '"city:x"',
        r'"city:123\n"',
        '"CITY:123"',
        '"123"',
        '""',
        '12',
        '{}',
        'null',
        'bad',
      ]) {
        expect(AppSettings.cityId.valueOf(input), isNull);
      }
      expect(AppSettings.cityId.valueOf('"city:282615"'), 'city:282615');
      final r = Rig();
      expect(
        await r.actions.setCity('private invalid city'),
        isA<SettingsFailed>(),
      );
      expect(await r.db.select(r.db.settingsKv).get(), isEmpty);
    },
  );
  test('UX-030 SettingsActions.setUnitSystem: one settings put, '
      'origin direct, undo recorded; undo restores the default '
      '(row tombstoned)', () async {
    final r = Rig();
    final outcome =
        await r.actions.setUnitSystem(UnitSystem.imperial) as SettingsDone;
    final row = (await r.db.select(r.db.settingsKv).get()).single;
    expect(row.id, settingRowId('units.system'));
    expect(row.valueJson, '"imperial"');
    expect(row.origin, 'direct');
    expect(await outbox(r.db), hasLength(1));
    expect(outcome.kind, SettingsKind.settingChanged);
    expect(r.stack.latest!.id, outcome.undoEntryId);
    expect(r.stack.latest!.label.args, {'key': 'units.system'});
    expect(await r.stack.undo(outcome.undoEntryId), UndoOutcome.undone);
    expect(await r.store.read(AppSettings.unitSystem), UnitSystem.metric);
    expect(
      (await r.db.select(r.db.settingsKv).get()).single.deletedAt,
      isNotNull,
    );
  });
  test('same value → Unchanged, nothing written', () async {
    final r = Rig();
    final before = await r.raw();
    expect(
      await r.actions.setUnitSystem(UnitSystem.metric),
      isA<SettingsUnchanged>(),
    );
    expect(
      await r.actions.setWeekStart(DayOfWeek.saturday),
      isA<SettingsUnchanged>(),
    );
    expect(await r.actions.setHalal(true), isA<SettingsUnchanged>());
    expect(
      await r.actions.setTheme(ThemePreference.system),
      isA<SettingsUnchanged>(),
    );
    expect(await r.actions.clearCity(), isA<SettingsUnchanged>());
    expect(await r.raw(), before);
    expect(r.stack.entries, isEmpty);
  });
  test('LC-021 weekCalendarProvider: default week of Thu 2026-10-22 '
      'starts Sat 2026-10-17; with monday it starts Mon '
      '2026-10-19; follows a change without restart', () async {
    final r = Rig();
    final c = r.container();
    final sub = c.listen(weekCalendarProvider, (_, _) {});
    addTearDown(sub.close);
    await c.read(weekStartProvider.future);
    final date = LocalDate(2026, 10, 22);
    expect(
      c.read(weekCalendarProvider).weekStartOf(date),
      LocalDate(2026, 10, 17),
    );
    final changed = Completer<void>();
    final listener = c.listen(weekCalendarProvider, (_, next) {
      if (next.weekStart == DayOfWeek.monday && !changed.isCompleted) {
        changed.complete();
      }
    });
    addTearDown(listener.close);
    await r.actions.setWeekStart(DayOfWeek.monday);
    await changed.future;
    expect(
      c.read(weekCalendarProvider).weekStartOf(date),
      LocalDate(2026, 10, 19),
    );
  });
  test('LC-033 OfflineCatalog.cities() returns every fixture city; '
      'city(id) unknown → null; no pack → empty', () async {
    final (_, catalog) = fixtureCatalog();
    addTearDown(catalog.dispose);
    final cities = await catalog.cities();
    expect(cities, hasLength(10));
    expect(cities.map((c) => c.id).toSet(), {
      'city:282615',
      'city:282239',
      'city:285066',
      'city:7303419',
      'city:281577',
      'city:250441',
      'city:250624',
      'city:6946409',
      'city:246330',
      'city:360630',
    });
    final nablus = (await catalog.city('city:282615'))!;
    expect(
      (
        nablus.nameEn,
        nablus.nameAr,
        nablus.countryCode,
        nablus.population,
        nablus.timezone,
      ),
      ('Nablus', 'نابلس', 'PS', 130326, 'Asia/Hebron'),
    );
    expect((nablus.latitude, nablus.longitude), (32.22111, 35.25444));
    expect(await catalog.city('city:0'), isNull);
    final empty = OfflineCatalog(memoryDatabase());
    addTearDown(empty.dispose);
    expect(await empty.cities(), isEmpty);
    expect(await empty.city('city:282615'), isNull);
  });
  test('LC-033 city search: "nablus" and "نابلس" find Nablus; '
      '"عمان" finds عمّان (tashkeel folded); "karak" returns both '
      'Karak records; a population-0 village is found', () async {
    final (_, catalog) = fixtureCatalog();
    addTearDown(catalog.dispose);
    final c = ProviderContainer(
      overrides: [offlineCatalogProvider.overrideWithValue(catalog)],
    );
    addTearDown(c.dispose);
    final sub = c.listen(citySearchProvider, (_, _) {});
    addTearDown(sub.close);
    final search = await c.read(citySearchProvider.future);
    expect(await c.read(citySearchProvider.future), same(search));
    for (final q in ['nablus', 'نابلس']) {
      expect(search.query(q).first.city.id, 'city:282615');
    }
    expect(search.query('عمان').first.city.nameAr, 'عمّان');
    expect(search.query('karak').map((r) => r.city.id), [
      'city:250624',
      'city:6946409',
    ]);
    expect(search.query('umm ar rasas').single.city.population, 0);
    expect(search.suggestions('city:360630').first.city.nameEn, 'Cairo');
    expect(search.query('no match'), isEmpty);
  });
  test(
    'LC-033 city search perf p95 < 5 ms over 2,300 rows (printed)',
    () async {
      final cities = [
        for (var i = 0; i < 2300; i++)
          CatalogCity(
            id: 'city:$i',
            nameEn: 'City $i',
            nameAr: 'مدينة $i',
            countryCode: i.isEven ? 'PS' : 'JO',
            population: i,
            timezone: 'Asia/Hebron',
            latitude: 32,
            longitude: 35,
          ),
      ];
      final search = CitySearch(cities);
      for (var i = 0; i < 100; i++) {
        search.query('city');
      }
      final samples = <int>[];
      for (var i = 0; i < 300; i++) {
        final watch = Stopwatch()..start();
        final results = search.query(i.isEven ? 'city' : 'مدينة 1');
        watch.stop();
        expect(results, isNotEmpty);
        samples.add(watch.elapsedMicroseconds);
      }
      samples.sort();
      final p95 = samples[(samples.length * .95).ceil() - 1];
      // The WP1 gate requires the measured distribution in the test output.
      // ignore: avoid_print
      print(
        'LC-033 city search: rows=2300 runs=300 '
        'p50=${samples[149]}us p95=${p95}us max=${samples.last}us',
      );
      expect(p95, lessThan(5000));
    },
    // A timing gate: the parallel suite's load can push one run over.
    retry: 2,
  );
  test('D14 about info: only active credits (USDA, GeoNames), never '
      'note; no pack → null credits', () async {
    final credits = [
      for (final name in ['USDA', 'GeoNames', 'Open Food Facts'])
        {
          'id': name,
          'name': name,
          'credit': '$name credit',
          'licence': 'not displayed',
          'note': 'private note',
          'url': '',
          'used_for': '',
          'status': name == 'Open Food Facts' ? 'planned' : 'active',
        },
    ];
    final (_, catalog) = fixtureCatalog(
      extraSql:
          "UPDATE meta SET value = '${jsonEncode(credits)}' "
          "WHERE key = 'attribution';",
    );
    addTearDown(catalog.dispose);
    final c = ProviderContainer(
      overrides: [
        ...TestPhone().overrides(),
        offlineCatalogProvider.overrideWithValue(catalog),
      ],
    );
    addTearDown(c.dispose);
    final info = await c.read(aboutInfoProvider.future);
    expect(info.version, '0.1.0');
    expect(info.build, '1');
    expect(info.packVersion, 1);
    expect(info.activeCredits!.map((c) => c.name), ['USDA', 'GeoNames']);
    expect(info.activeCredits!.map((c) => c.credit), [
      'USDA credit',
      'GeoNames credit',
    ]);
    final empty = OfflineCatalog(memoryDatabase());
    addTearDown(empty.dispose);
    final noPack = ProviderContainer(
      overrides: [
        ...TestPhone().overrides(),
        offlineCatalogProvider.overrideWithValue(empty),
      ],
    );
    addTearDown(noPack.dispose);
    expect((await noPack.read(aboutInfoProvider.future)).activeCredits, isNull);
    expect((await noPack.read(aboutInfoProvider.future)).packVersion, isNull);
  });
  test("FD-022 the food sheet's unit chips and default follow the "
      'setting', () async {
    final r = Rig();
    final choice = catalogChoice(foodOf('usda:test', 'Test'));
    final ref = FoodChoiceRef(choice.ref);
    // Keep the actual settings stream while replacing food IO.
    final scoped = ProviderContainer(
      overrides: [
        settingsStoreProvider.overrideWithValue(r.store),
        foodChoiceProvider(ref).overrideWith((ref) async => choice),
        foodSlotsProvider.overrideWith((ref) => Stream.value(DefaultSlots.all)),
        // The clock always comes from the application port.
        clockProvider.overrideWithValue(r.clock),
      ],
    );
    addTearDown(scoped.dispose);
    final provider = foodAmountControllerProvider(ref, LocalDate(2026, 10, 22));
    final sub = scoped.listen(provider, (_, _) {});
    addTearDown(sub.close);
    final metric = await scoped.read(provider.future);
    expect(metric.input, Quantity(100, 'g'));
    expect(metric.units.first, 'g');
    final changed = Completer<void>();
    final updates = scoped.listen(provider, (_, next) {
      if (next.value?.system == UnitSystem.imperial && !changed.isCompleted) {
        changed.complete();
      }
    });
    addTearDown(updates.close);
    scoped.read(provider.notifier).setAmount('137.25');
    await r.actions.setUnitSystem(UnitSystem.imperial);
    await changed.future;
    expect(scoped.read(provider).requireValue.amountBuffer, '137.25');
    expect(scoped.read(provider).requireValue.unit, 'g');
    expect(scoped.read(provider).requireValue.units.take(4), [
      'oz',
      'lb',
      'g',
      'kg',
    ]);
    final fresh = foodAmountControllerProvider(ref, LocalDate(2026, 10, 23));
    final freshSub = scoped.listen(fresh, (_, _) {});
    addTearDown(freshSub.close);
    expect((await scoped.read(fresh.future)).input, Quantity(4, 'oz'));
  });
  test('UX-030 every setting action and clear has undo; defaults '
      'and existing rows restore', () async {
    final r = Rig();
    for (final action in [
      () => r.actions.setWeekStart(DayOfWeek.monday),
      () => r.actions.setHalal(false),
      () => r.actions.setTheme(ThemePreference.dark),
      () => r.actions.setCity('city:282615'),
    ]) {
      final outcome = await action() as SettingsDone;
      expect(await r.stack.undo(outcome.undoEntryId), UndoOutcome.undone);
    }
    await r.actions.setCity('city:282615');
    final clear = await r.actions.clearCity() as SettingsDone;
    expect(await r.store.read(AppSettings.cityId), isNull);
    expect(await r.stack.undo(clear.undoEntryId), UndoOutcome.undone);
    expect(await r.store.read(AppSettings.cityId), 'city:282615');
    final change = await r.actions.setCity('city:360630') as SettingsDone;
    expect(await r.stack.undo(change.undoEntryId), UndoOutcome.undone);
    expect(await r.store.read(AppSettings.cityId), 'city:282615');
  });

  test(
    'UX-030 SettingsActions pending, rejection and unexpected failure clean up',
    () async {
      final gate = Completer<void>();
      final entered = Completer<void>();
      var first = true;
      final r = Rig(
        beforePlan: () async {
          if (first) {
            first = false;
            entered.complete();
            await gate.future;
          }
        },
      );
      final writing = r.actions.setHalal(false);
      await entered.future;
      expect(await r.actions.setHalal(false), isA<SettingsPending>());
      gate.complete();
      expect(await writing, isA<SettingsDone>());
      expect(await r.actions.setHalal(false), isA<SettingsUnchanged>());

      Exception? rejection = const ChangeRejected(InvalidOp('test'));
      var unexpected = false;
      final failed = Rig(
        beforePlan: () async {
          if (unexpected) throw StateError('unexpected test error');
          if (rejection case final failure?) throw failure;
        },
      );
      final before = await failed.raw();
      expect(await failed.actions.setHalal(false), isA<SettingsFailed>());
      expect(await failed.raw(), before);
      rejection = null;
      unexpected = true;
      await expectLater(failed.actions.setHalal(false), throwsStateError);
      expect(await failed.raw(), before);
      unexpected = false;
      expect(await failed.actions.setHalal(false), isA<SettingsDone>());
    },
  );

  test(
    'LC-033 selectedCity follows valid, unknown and unset identities',
    () async {
      final r = Rig();
      final (_, catalog) = fixtureCatalog();
      addTearDown(catalog.dispose);
      final c = ProviderContainer(
        overrides: [
          settingsStoreProvider.overrideWithValue(r.store),
          offlineCatalogProvider.overrideWithValue(catalog),
        ],
      );
      addTearDown(c.dispose);
      final sub = c.listen(selectedCityProvider, (_, _) {});
      addTearDown(sub.close);
      expect(await c.read(selectedCityProvider.future), isNull);
      Future<void> change(
        Future<SettingsOutcome> Function() action,
        String? id,
      ) async {
        final ready = Completer<void>();
        final listener = c.listen(cityIdProvider, (_, next) {
          if (next.value == id && !ready.isCompleted) ready.complete();
        });
        await action();
        await ready.future;
        listener.close();
      }

      await change(() => r.actions.setCity('city:282615'), 'city:282615');
      expect((await c.read(selectedCityProvider.future))!.nameEn, 'Nablus');
      await change(() => r.actions.setCity('city:0'), 'city:0');
      expect(await c.read(selectedCityProvider.future), isNull);
      await change(r.actions.clearCity, null);
      expect(await c.read(selectedCityProvider.future), isNull);
    },
  );
  test('UX-051 city read errors propagate for retry; About keeps '
      'version with unavailable credits', () async {
    final (_, broken) = fixtureCatalog(
      extraSql: 'DROP TABLE cities; DROP TABLE meta;',
    );
    addTearDown(broken.dispose);
    final c = ProviderContainer(
      overrides: [
        ...TestPhone().overrides(),
        offlineCatalogProvider.overrideWithValue(broken),
      ],
    );
    addTearDown(c.dispose);
    final sub = c.listen(citySearchProvider, (_, _) {});
    addTearDown(sub.close);
    await expectLater(
      c.read(citySearchProvider.future),
      throwsA(isA<Exception>()),
    );
    c.invalidate(citySearchProvider);
    await expectLater(
      c.read(citySearchProvider.future),
      throwsA(isA<Exception>()),
    );
    final info = await c.read(aboutInfoProvider.future);
    expect(info.version, '0.1.0');
    expect(info.activeCredits, isNull);
  });
}
