import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/presentation/below_limit_screen.dart';
import 'package:fb_mobile/features/targets/presentation/daily_target_sheet.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart' show settleWrites;
import 'targets_screens_support.dart';

/// The version in effect today.
Future<TargetSettingsRecord> _current(TargetsScreenRig rig) async {
  final data = await rig.data();
  return TargetsTimeline.versionOn([
    for (final s in data.settings) s.value,
  ], rig.today)!;
}

/// The version in effect today at its row version (what Targets shows).
Future<VersionedId> _shown(TargetsScreenRig rig) async {
  final current = await _current(rig);
  final row = (await rig.data()).settings.firstWhere(
    (s) => s.value.id == current.id,
  );
  return VersionedId(current.id, row.version);
}

String _n(num kcal) => NumberFormat.decimalPattern('en').format(kcal);

String _g(double grams) => '${DisplayRounding.macroTargetGrams(grams)} g';

Future<void> _openChange(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('targets-daily-change')));
  await tester.pumpAndSettle();
  expect(find.byType(DailyTargetSheet), findsOneWidget);
}

// Covers: TG-046, TG-050, TG-051, TG-053
void main() {
  testWidgets('TG-046 the daily target leads; Change −200 previews the '
      'macros against the current ones and "Use N every day" sets the own '
      'number with Undo', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    final base = (await _current(rig)).baseKcal;
    final suggested = DisplayRounding.kcal(base);
    expect(find.text('Daily target · every day'), findsOneWidget);
    expect(find.text('${_n(suggested)} kcal'), findsWidgets);
    expect(find.text('Suggested for your goal'), findsOneWidget);
    expect(find.text('Days of the week'), findsOneWidget);

    await _openChange(tester);
    await rig.tap('−200');
    await tester.pumpAndSettle();
    final kcal = suggested - 200;
    // The preview is the domain's (same maths as the stored plan).
    final view = rig.container.read(targetsViewProvider).value!;
    final preview = view.previewDaily(kcal.toDouble());
    final sheet = find.byType(DailyTargetSheet);
    for (final grams in [
      preview.macros.carbsGrams!,
      preview.macros.fatGrams!,
      preview.macros.fiberGrams,
    ]) {
      expect(
        find.descendant(of: sheet, matching: find.textContaining(_g(grams))),
        findsWidgets,
      );
    }
    final wasCarbs = preview.currentMacros.carbsGrams!;
    expect(
      find.descendant(
        of: sheet,
        matching: find.textContaining('was ${_g(wasCarbs)}'),
      ),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('daily-target-rate')), findsOneWidget);

    await rig.tapAndSettle('Use ${_n(kcal)} every day');
    final version = await _current(rig);
    expect((version.manual, version.baseKcal), (true, kcal.toDouble()));
    expect(version.dayFactors, isEmpty);
    expect(find.text('Your own number · suggested ${_n(suggested)}'), findsOne);
    // The card's macros follow the new number.
    final fat = MacroPlan.calculate(
      baseKcal: kcal.toDouble(),
      weightKg: view.day.macroWeightKg,
    ).fatGrams!;
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('targets-daily')),
        matching: find.text(_g(fat)),
      ),
      findsOneWidget,
    );

    await rig.tapAndSettle('Undo');
    expect((await _current(rig)).manual, isFalse);
    await rig.close();
  });

  testWidgets('TG-046 "Suggested" in the sheet goes back to the calculated '
      'target', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    final base = (await _current(rig)).baseKcal;
    final suggested = DisplayRounding.kcal(base);
    await rig.settle(
      rig.actions.setManualTarget(
        VersionedId((await _current(rig)).id, 1),
        1900,
        everyDay: true,
      ),
    );
    await settleWrites(tester);
    await _openChange(tester);
    await rig.tap('Suggested ${_n(suggested)}');
    await tester.pumpAndSettle();
    await rig.tapAndSettle('Use ${_n(suggested)} every day');
    final version = await _current(rig);
    expect((version.manual, version.baseKcal), (false, base));
    expect(find.text('Suggested for your goal'), findsOneWidget);
    await rig.close();
  });

  // Review major 1: "Suggested N" is the calculation the save stores.
  for (final (name, goal, weighIn) in [
    ('a changed weight', null, 70.0),
    (
      'a target-date goal',
      GoalInput(
        type: GoalType.lose,
        expression: GoalExpression.targetDate(74, LocalDate(2027, 2, 1)),
      ),
      null,
    ),
  ]) {
    testWidgets('TG-046 TG-021 with $name, "Suggested" shows and saves '
        "today's calculation, not the own number's old one", (tester) async {
      final rig = await TargetsScreenRig.open(tester, goal: goal);
      await rig.settle(
        rig.actions.setManualTarget(await _shown(rig), 1900, everyDay: true),
      );
      rig.clock.advance(const Duration(days: 20));
      if (weighIn != null) {
        await rig.settle(
          rig.container
              .read(weighInActionsProvider.notifier)
              .log(
                WeighInDraft(
                  time: EntryTime.now(rig.clock),
                  input: WeighInInput(weighIn, MassUnit.kilogram),
                ),
              ),
        );
      }
      await settleWrites(tester);
      await rig.show(const TargetsRoute());
      final data = await rig.data();
      final trend = TrendWeight()
          .compute(await rig.container.read(weighInsProvider.future))
          .trendOn(rig.today)!;
      final expected = TargetsTimeline.generated(
        profile: data.profile!.value,
        goals: [for (final p in data.phases) p.value],
        weightKg: trend,
        date: rig.today,
      )!.kcal;
      final old = rig.container.read(targetsViewProvider).value!;
      expect(
        (old.explanation!.calculated.kcal - expected).abs(),
        greaterThan(1),
        reason: 'the old explanation differs, so the test can tell',
      );
      final shown = DisplayRounding.kcal(expected);
      expect(
        find.text('Your own number · suggested ${_n(shown)}'),
        findsOneWidget,
      );
      await _openChange(tester);
      await rig.tap('Suggested ${_n(shown)}');
      await tester.pumpAndSettle();
      await rig.tapAndSettle('Use ${_n(shown)} every day');
      final version = await _current(rig);
      expect(version.manual, isFalse);
      expect(version.baseKcal, closeTo(expected, 1e-9));
      await rig.close();
    });
  }

  // Review major 2: seven equal day numbers + Use = the own target.
  testWidgets('TG-046 seven equal day numbers: Use stores the own daily '
      'target (no day numbers), with Undo', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    final base = (await _current(rig)).baseKcal;
    for (final day in DayOfWeek.values) {
      final shown = await _shown(rig);
      await rig.settle(
        rig.actions.setDayTarget(shown, day, 1900, suggestionKcal: base),
      );
    }
    await settleWrites(tester);
    expect((await _current(rig)).dayFactors, hasLength(7));
    await _openChange(tester);
    // 1,900: within the floor and the 1 %/week rate (no warning).
    await rig.tapAndSettle('Use 1,900 every day');
    final version = await _current(rig);
    expect((version.manual, version.baseKcal), (true, 1900.0));
    expect(version.dayFactors, isEmpty);
    await rig.tapAndSettle('Undo');
    final back = await _current(rig);
    expect((back.manual, back.dayFactors.length), (false, 7));
    await rig.close();
  });

  testWidgets('TG-046 SF-012 seven equal days below the floor: Use asks '
      'first, then stores the acknowledged fixed own target', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const TargetsRoute(),
    );
    final base = (await _current(rig)).baseKcal;
    for (final day in DayOfWeek.values) {
      final shown = await _shown(rig);
      await rig.settle(
        rig.actions.setDayTarget(
          shown,
          day,
          1200,
          suggestionKcal: base,
          acknowledged: true,
        ),
      );
    }
    await settleWrites(tester);
    await _openChange(tester);
    await rig.tapAndSettle('Use 1,200 every day');
    expect(find.byType(BelowLimitScreen), findsOneWidget);
    await rig.tap('I understand and want to use 1,200 kcal a day');
    await rig.tapAndSettle('Use 1,200 kcal');
    final version = await _current(rig);
    expect((version.manual, version.acknowledged), (true, true));
    expect(version.mode, TargetMode.fixed);
    expect(version.dayFactors, isEmpty);
    await rig.close();
  });

  // Review minor 3: the keyboard never covers the pinned button.
  for (final scale in const [1.0, 2.0]) {
    testWidgets('TG-046 UX-070 typing with the keyboard up keeps "Use" above '
        'it at text scale $scale', (tester) async {
      final rig = await TargetsScreenRig.open(
        tester,
        route: const TargetsRoute(),
      );
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      await _openChange(tester);
      await tester.tap(find.byKey(const ValueKey('daily-target-number')));
      await tester.pumpAndSettle();
      const keyboard = 300.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboard);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final button = find.ancestor(
        of: find.textContaining('every day'),
        matching: find.byType(FilledButton),
      );
      final screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(
        tester.getBottomLeft(button).dy,
        lessThanOrEqualTo(screen - keyboard / tester.view.devicePixelRatio),
      );
      await rig.close();
    });
  }
}
