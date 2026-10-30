import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/presentation/targets_screen.dart'
    show TargetsBody;
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../today/presentation/support/today_support.dart' show phoneApp;
import 'targets_screens_support.dart';

/// The version in effect today.
Future<TargetSettingsRecord> _current(TargetsScreenRig rig) async {
  final data = await rig.data();
  return TargetsTimeline.versionOn([
    for (final s in data.settings) s.value,
  ], rig.today)!;
}

/// Targets' content on Friday 2026-10-23 (Saturday week, base 2,162.5,
/// 80 kg) after [eaten] kcal on each earlier day.
TargetsView _fridayView(double eaten) {
  const profile = ProfileRecord(
    sex: FormulaSex.male,
    birthYear: 1990,
    heightCm: 180,
    heightInputUnit: HeightInputUnit.centimeter,
    activity: ActivityLevel.moderate,
  );
  final friday = LocalDate(2026, 10, 23);
  final version = TargetSettingsRecord(
    id: '01890abc-def0-7123-8abc-0123456789ad',
    revision: 1,
    effectiveFrom: LocalDate(2026, 10, 17),
    baseKcal: 2162.5,
    basisWeightKg: 80,
  );
  final day = TargetsTimeline.day(
    date: friday,
    settings: [version],
    profile: profile,
    intake: [
      for (var i = 0; i < 6; i++)
        DayIntake(
          date: LocalDate(2026, 10, 17).plusDays(i),
          kcal: eaten,
          entryCount: 3,
        ),
    ],
  )!;
  return TargetsView(
    today: friday,
    shown: VersionedId(version.id, 1),
    day: day,
    profile: profile,
    units: UnitSystem.metric,
    calendar: const WeekCalendar(),
    explanation: null,
    trendKg: null,
  );
}

const String _carryNote =
    'The rest of this week is already at its limit (25% above or below your '
    'usual target), so not all of the difference can be spread out.';

void main() {
  testWidgets('TG-042 a carry note shows when the remaining days are at '
      'their limit, and not otherwise', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 1600)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    for (final (eaten, shown) in [(3500.0, true), (2200.0, false)]) {
      final view = _fridayView(eaten);
      expect(view.day.day.week!.carryKcal != 0, shown, reason: '$eaten');
      await tester.pumpWidget(
        ProviderScope(
          child: phoneApp(Scaffold(body: TargetsBody(view: view))),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(_carryNote), shown ? findsOneWidget : findsNothing);
    }
  });

  testWidgets('TG-044 switching to Same every day hides rebalancing and '
      'shifting', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    expect(find.text('Rebalancing'), findsOneWidget);
    expect(find.text('Higher-calorie days'), findsOneWidget);
    await rig.tapAndSettle('Same every day');

    expect((await _current(rig)).mode, TargetMode.fixed);
    expect(find.text('Rebalancing'), findsNothing);
    expect(find.text('Higher-calorie days'), findsNothing);
    expect(find.text('Targets updated'), findsOneWidget);
    await rig.close();
  });

  testWidgets('TG-032 HM-002 the weekly line names the earlier days not '
      'counted', (tester) async {
    final rig = await TargetsScreenRig.open(tester);
    // Monday: Saturday and Sunday (since setup) have no entries.
    rig.advanceDays(2);
    await rig.show(const TargetsRoute());
    expect(
      find.text('This week: on track · 2 days not counted'),
      findsOneWidget,
    );
    await rig.close();
  });

  testWidgets('TG-043 choosing Friday "More" previews Friday higher and the '
      'other days lower with the same weekly total', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    await rig.tap('Higher-calorie days');
    expect(find.text('Friday: 2,163 kcal'), findsOneWidget);
    // Friday is the 7th day of a Saturday week: its row's "More" chip.
    await tester.tap(find.widgetWithText(FbChoiceChip, 'More').at(6));
    await tester.pumpAndSettle();
    expect(find.text('Friday: 2,163 kcal'), findsNothing);
    expect(find.textContaining(RegExp('^Friday: 2,[5-9]')), findsOneWidget);
    expect(find.textContaining(RegExp('^Saturday: 2,0')), findsOneWidget);
    await rig.tapAndSettle('Save');

    final version = await _current(rig);
    expect(version.shifts, {DayOfWeek.friday: 1.3});
    expect(find.text('Friday: More'), findsOneWidget);
    await rig.close();
  });

  testWidgets('TG-043 the sheet submits only the changed weekdays; an '
      'untouched synced weight (1.8) stays exact', (tester) async {
    final rig = await TargetsScreenRig.open(tester);
    final row = (await rig.data()).settings.single;
    await rig.run(
      (a) => a.setShifting(VersionedId(row.value.id, row.version), {
        DayOfWeek.friday: 1.8,
      }),
    );
    await rig.show(const TargetsRoute());
    await rig.tap('Higher-calorie days');
    // Sunday is the 2nd day of a Saturday week: its row's "More" chip.
    await tester.tap(find.widgetWithText(FbChoiceChip, 'More').at(1));
    await tester.pumpAndSettle();
    await rig.tapAndSettle('Save');

    expect((await _current(rig)).shifts, {
      DayOfWeek.friday: 1.8,
      DayOfWeek.sunday: 1.3,
    });
    await rig.close();
  });

  testWidgets('UX-052 TG-043 Reload after a change elsewhere refreshes the '
      'preview and untouched days, keeping the changed day', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    await rig.tap('Higher-calorie days');
    // Sunday "More" (2nd day of a Saturday week).
    await tester.tap(find.widgetWithText(FbChoiceChip, 'More').at(1));
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp('^Friday: 2,0')), findsOneWidget);

    final row = (await rig.data()).settings.single;
    await rig.run(
      (a) => a.setShifting(VersionedId(row.value.id, row.version), {
        DayOfWeek.friday: 1.8,
      }),
    );
    await rig.tapAndSettle('Save');
    expect(find.text('This changed. Reload.'), findsOneWidget);
    await rig.tap('Reload');
    // Friday now previews its synced 1.8 (the engine's 2,703 kcal); Sunday
    // keeps "More".
    expect(find.text('Friday: 2,703 kcal'), findsOneWidget);
    expect(find.text('Sunday: 2,566 kcal'), findsOneWidget);
    await rig.tapAndSettle('Save');

    expect((await _current(rig)).shifts, {
      DayOfWeek.friday: 1.8,
      DayOfWeek.sunday: 1.3,
    });
    await rig.close();
  });

  testWidgets('TG-054 protein 140 g, fat 25 % and fiber 30 g save', (
    tester,
  ) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    await rig.tap('Macro targets');
    final grams = find.widgetWithText(FbChoiceChip, 'Grams');
    await tester.tap(grams.first);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Protein'), '140');
    await tester.tap(find.widgetWithText(FbChoiceChip, '% of calories').at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Fat'), '25');
    await tester.ensureVisible(grams.last);
    await tester.tap(grams.last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Fiber'), '30');
    await tester.pumpAndSettle();
    await rig.tapAndSettle('Save');

    final macros = (await _current(rig)).macros;
    expect(macros.protein?.value, 140);
    expect(macros.protein?.isPercent, isFalse);
    expect(macros.fat?.value, 25);
    expect(macros.fat?.isPercent, isTrue);
    expect(macros.fiberGrams, 30);
    expect(find.text('Your own settings'), findsOneWidget);
    await rig.close();
  });

  testWidgets('TG-054 calories and protein only ignores an unusable fat '
      'amount', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    await rig.tap('Macro targets');
    await tester.tap(find.widgetWithText(FbChoiceChip, 'Grams').at(1));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Fat'), '5000');
    await tester.pumpAndSettle();
    await rig.tap('Calories and protein only');
    await rig.tapAndSettle('Save');

    final macros = (await _current(rig)).macros;
    expect(macros.caloriesProteinOnly, isTrue);
    expect(macros.fat, isNull);
    expect(find.text('Targets updated'), findsOneWidget);
    await rig.close();
  });

  testWidgets('PA7 with an acknowledged below-floor manual target, mode, '
      'rebalancing and shifting are disabled with the note', (tester) async {
    final rig = await TargetsScreenRig.open(tester);
    final data = await rig.data();
    final row = data.settings.single;
    final outcome = await rig.run(
      (a) => a.setManualTarget(
        VersionedId(row.value.id, row.version),
        1000,
        acknowledged: true,
      ),
    );
    expect(outcome, isA<TargetsDone>());
    await rig.show(const TargetsRoute());

    expect(
      find.text(
        'Below the safety floor the same target applies every day and '
        'weekly rebalancing is off.',
      ),
      findsNWidgets(2),
    );
    expect(find.byType(FbOptionList<TargetMode>), findsNothing);
    final rebalancing = tester.widget<FbSwitchRow>(
      find.widgetWithText(FbSwitchRow, 'Rebalancing'),
    );
    expect(rebalancing.onChanged, isNull);
    await rig.close();
  });

  testWidgets('D5 Recalculate with your current weight writes a new '
      'generated target with undo', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      overrides: [
        bodyWeightProvider.overrideWith((ref, date) async => 78),
        bodyWeightReaderProvider.overrideWithValue((date) async => 78),
      ],
    );
    await rig.show(const TargetsRoute());
    expect(
      find.text(
        'Your target was worked out at 80 kg. Your current '
        'weight is 78 kg.',
      ),
      findsOneWidget,
    );
    await rig.tapAndSettle('Recalculate with your current weight');

    final version = await _current(rig);
    expect(version.basisWeightKg, 78);
    expect(version.manual, isFalse);
    expect(find.text('Targets updated'), findsOneWidget);
    expect(find.text('Recalculate with your current weight'), findsNothing);
    await rig.close();
  });
}
