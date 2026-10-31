import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/presentation/below_limit_screen.dart';
import 'package:fb_mobile/features/targets/presentation/day_target_sheet.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import 'targets_screens_support.dart';

/// The version in effect today.
Future<TargetSettingsRecord> _current(TargetsScreenRig rig) async {
  final data = await rig.data();
  return TargetsTimeline.versionOn([
    for (final s in data.settings) s.value,
  ], rig.today)!;
}

String _n(num kcal) => NumberFormat.decimalPattern('en').format(kcal);

/// Taps weekday bar [index] (Saturday week: 0 is Saturday, 6 Friday).
Future<void> _tapBar(WidgetTester tester, int index) async {
  await tester.tap(
    find
        .descendant(of: find.byType(FbWeekBars), matching: find.byType(InkWell))
        .at(index),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('D-090 a tap on Friday opens its sheet; +250 and Save store '
      "Friday's number as a factor of the suggestion, with Undo", (
    tester,
  ) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    final base = (await _current(rig)).baseKcal;
    final suggested = DisplayRounding.kcal(base);
    expect(find.text('Same every day'), findsOneWidget);
    expect(find.text('Tap a day to change its number'), findsOneWidget);
    expect(find.text('How is this worked out?'), findsOneWidget);

    await _tapBar(tester, 6);
    expect(find.byType(DayTargetSheet), findsOneWidget);
    expect(find.text('Usual ${_n(suggested)}'), findsOneWidget);
    await rig.tap('+250');
    expect(
      find.textContaining(
        'Every Friday. Suggested: ${_n(suggested)} · your week becomes '
        '${_n(DisplayRounding.kcal(base * 6 + suggested + 250))}.',
      ),
      findsOneWidget,
    );
    await rig.tapAndSettle('Save');

    final version = await _current(rig);
    expect(
      version.dayFactors[DayOfWeek.friday],
      closeTo((suggested + 250) / base, 1e-9),
    );
    expect(version.dayFactors.keys, [DayOfWeek.friday]);
    expect(find.text('Targets updated'), findsOneWidget);
    expect(find.text(_n(suggested + 250)), findsOneWidget, reason: 'the bar');
    // Undo restores the usual Friday.
    await rig.tapAndSettle('Undo');
    expect((await _current(rig)).dayFactors, isEmpty);
    await rig.close();
  });

  testWidgets('D-090 − / + step by 50 and the typed number saves; typing '
      'the suggestion clears the factor', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    final base = (await _current(rig)).baseKcal;
    final suggested = DisplayRounding.kcal(base);
    await _tapBar(tester, 1);
    await tester.tap(find.byTooltip('50 kcal more'));
    await tester.pump();
    await tester.tap(find.byTooltip('50 kcal more'));
    await tester.pump();
    expect(find.text(_n(suggested + 100)), findsWidgets);
    await rig.tapAndSettle('Save');
    expect(
      (await _current(rig)).dayFactors[DayOfWeek.sunday],
      closeTo((suggested + 100) / base, 1e-9),
    );

    await _tapBar(tester, 1);
    await tester.tap(find.byKey(const ValueKey('day-target-number')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '$suggested');
    await tester.pumpAndSettle();
    await rig.tapAndSettle('Save');
    expect((await _current(rig)).dayFactors, isEmpty);
    await rig.close();
  });

  testWidgets('D-090 "Same every day" puts every day back to the suggestion, '
      'with Undo', (tester) async {
    final rig = await TargetsScreenRig.open(tester);
    final row = (await rig.data()).settings.single;
    await rig.run(
      (a) => a.setDayTarget(
        VersionedId(row.value.id, row.version),
        DayOfWeek.friday,
        2600,
        suggestionKcal: row.value.baseKcal,
      ),
    );
    await rig.show(const TargetsRoute());
    final segmented = tester.widget<FbSegmented<bool>>(
      find.byType(FbSegmented<bool>),
    );
    expect(segmented.selected, isTrue, reason: 'different by day');
    await rig.tapAndSettle('Same every day');
    expect((await _current(rig)).dayFactors, isEmpty);
    expect(
      find.text(
        'Every day is back to '
        '${_n(DisplayRounding.kcal(row.value.baseKcal))} kcal',
      ),
      findsOneWidget,
    );
    await rig.tapAndSettle('Undo');
    expect((await _current(rig)).dayFactors.keys, [DayOfWeek.friday]);
    await rig.close();
  });

  testWidgets('A53 D4 a day below the floor asks first, names the day, and '
      'stays as set with a calm banner', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    await _tapBar(tester, 6);
    await tester.tap(find.byKey(const ValueKey('day-target-number')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1200');
    await tester.pumpAndSettle();
    await rig.tapAndSettle('Save');
    expect(find.byType(BelowLimitScreen), findsOneWidget);
    expect(
      find.text(
        'This applies every Friday. The other days keep their numbers.',
      ),
      findsOneWidget,
    );
    await rig.tap('I understand and want to use 1,200 kcal a day');
    await rig.tapAndSettle('Use 1,200 kcal');
    final version = await _current(rig);
    expect(
      version.dayFactors[DayOfWeek.friday]! * version.baseKcal,
      closeTo(1200, 1e-6),
    );
    expect(version.manual, isFalse);
    expect(
      find.textContaining('Some days are below your safety floor'),
      findsOneWidget,
    );
    await rig.close();
  });

  testWidgets('TG-054 More options › Macro targets: protein 140 g, fat 25 % '
      'and fiber 30 g save', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    await rig.tap('More options');
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
    await rig.close();
  });

  testWidgets('TG-041 More options › the balancing switch turns rebalancing '
      'off', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    await rig.tap('More options');
    await rig.tapAndSettle('Balance over/under across the week');
    expect((await _current(rig)).rebalancing, isFalse);
    expect(tester.widget<FbSwitchRow>(find.byType(FbSwitchRow)).value, isFalse);
    await rig.close();
  });

  testWidgets('D5 TG-021 the how sheet explains in steps and recalculates '
      "with today's weight", (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      overrides: [
        bodyWeightProvider.overrideWith((ref, date) async => 78),
        bodyWeightReaderProvider.overrideWithValue((date) async => 78),
      ],
    );
    await rig.show(const TargetsRoute());
    await rig.tap('How is this worked out?');
    expect(find.text('How your target is worked out'), findsOneWidget);
    expect(find.textContaining('About '), findsOneWidget);
    expect(
      find.text(
        'After 2–3 weeks of weigh-ins, the app adjusts this to what your '
        'body actually does.',
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'Your target was worked out at 80 kg. Your current '
        'weight is 78 kg.',
      ),
      findsOneWidget,
    );
    await rig.tapAndSettle("Recalculate with today's weight");

    final version = await _current(rig);
    expect(version.basisWeightKg, 78);
    expect(version.manual, isFalse);
    expect(find.text('Targets updated'), findsOneWidget);
    await rig.close();
  });
}
