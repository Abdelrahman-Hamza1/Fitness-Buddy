import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/changes/change_providers.dart';
import 'package:fb_mobile/core/changes/change_set_applier.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/ids/id_generator.dart';
import 'package:fb_mobile/core/settings/settings_op_handler.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/db/support/db_support.dart';
import '../today/presentation/support/today_support.dart' show phoneApp;

// Ramadan 1448: 2027-02-08 … 2027-03-08. Day 3.
final _day3 = LocalDate(2027, 2, 10);

const _profile = ProfileRecord(
  sex: FormulaSex.male,
  birthYear: 1990,
  heightCm: 180,
  heightInputUnit: HeightInputUnit.centimeter,
  activity: ActivityLevel.sedentary,
);

/// Today's targets from one version: generated, or the user's own number.
DayTargets? _targets(LocalDate date, {required bool manual}) =>
    TargetsTimeline.day(
      date: date,
      settings: [
        TargetSettingsRecord(
          id: '0199e3c2-5b1a-7000-8000-00000000a001',
          revision: 1,
          effectiveFrom: LocalDate(2027, 1, 1),
          baseKcal: 2200,
          basisWeightKg: 80,
          manual: manual,
          mode: TargetMode.fixed,
        ),
      ],
      profile: _profile,
    );

final class _Rig {
  new() {
    addTearDown(bus.close);
    applier = ChangeSetApplier(
      db: db,
      tables: db.syncedTables,
      handlers: (db) => [SettingsOpHandler(db.settingsKv)],
      clock: clock,
      ids: ids,
      deviceId: () async => testDevice,
      events: bus,
    );
    undo = UndoStack(revert: applier.revert, clock: clock);
    addTearDown(undo.dispose);
  }

  final AppDatabase db = memoryDatabase();
  final DomainEventBus bus = DomainEventBus();
  final ManualClock clock = ManualClock(
    DateTime.utc(2027, 2, 10, 10),
    offsetMinutes: 120,
  );
  final SequenceIdGenerator ids = SequenceIdGenerator();
  late final ChangeSetApplier<AppDatabase> applier;
  late final UndoStack undo;

  List<Override> overrides({bool manual = false, LocalDate? today}) => [
    appDatabaseProvider.overrideWithValue(db),
    changeSetApplierProvider.overrideWithValue(applier),
    clockProvider.overrideWithValue(clock),
    idGeneratorProvider.overrideWithValue(ids),
    undoStackProvider.overrideWithValue(undo),
    todayProvider.overrideWith((ref) => Stream.value(today ?? _day3)),
    dayTargetsProvider.overrideWith(
      (ref, date) async => _targets(date, manual: manual),
    ),
  ];

  ProviderContainer container({bool manual = false, LocalDate? today}) {
    final c = ProviderContainer(
      overrides: overrides(manual: manual, today: today),
    );
    addTearDown(c.dispose);
    c.listen(ramadanTargetsOfferProvider, (_, _) {});
    return c;
  }

  Future<RamadanSeason?> stored() async => (await SettingsStore(
    db: db,
    applier: applier,
  ).read(AppSettings.ramadanSeasons))[1448];
}

void main() {
  test('TG-060 J9 the offer is due in the first Ramadan week for generated '
      'targets, not manual ones, not before the season is on, not after an '
      'answer', () async {
    final r = _Rig();
    var c = r.container();
    expect(await c.read(ramadanTargetsOfferProvider.future), isNull);
    await c
        .read(settingsActionsProvider)
        .setRamadanSeason(RamadanSeason(hijriYear: 1448, on: true));
    c = r.container();
    expect((await c.read(ramadanTargetsOfferProvider.future))?.hijriYear, 1448);
    c = r.container(manual: true);
    expect(await c.read(ramadanTargetsOfferProvider.future), isNull);
    c = r.container(today: LocalDate(2027, 2, 15));
    expect(await c.read(ramadanTargetsOfferProvider.future), isNull);
  });

  testWidgets('TG-060 J9 the weekly-summary card: Maintain is stored with '
      'Undo, Undo brings the offer back, Keep my goal is stored too', (
    tester,
  ) async {
    final r = _Rig();
    await tester.runAsync(
      () => SettingsStore(db: r.db, applier: r.applier).put(
        AppSettings.ramadanSeasons,
        RamadanSettings([RamadanSeason(hijriYear: 1448, on: true)]),
        origin: Origin.direct,
      ),
    );
    Future<void> settle() async {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: r.overrides(),
        child: phoneApp(
          Scaffold(body: ListView(children: const [RamadanTargetsOfferCard()])),
        ),
      ),
    );
    await settle();
    final card = find.byKey(const ValueKey('ramadan-targets-offer'));
    expect(card, findsOneWidget);

    await tester.tap(find.text('Maintain during Ramadan'));
    await settle();
    var season = (await tester.runAsync<RamadanSeason?>(r.stored))!;
    expect((season.maintain, season.targetsAnswered), (true, true));
    expect(card, findsNothing);

    await tester.tap(find.text('Undo'));
    await settle();
    season = (await tester.runAsync<RamadanSeason?>(r.stored))!;
    expect((season.maintain, season.targetsAnswered), (false, false));
    expect(card, findsOneWidget);

    await tester.tap(find.text('Keep my goal'));
    await settle();
    season = (await tester.runAsync<RamadanSeason?>(r.stored))!;
    expect((season.maintain, season.targetsAnswered), (false, true));
    expect(card, findsNothing);

    r.undo.dispose();
    await tester.pumpWidget(const SizedBox());
    for (var i = 0; i < 3; i++) {
      await tester.pump(const Duration(seconds: 6));
    }
  });
}
