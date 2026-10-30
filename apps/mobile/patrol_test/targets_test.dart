import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/targets/presentation/targets_screen.dart'
    show TargetsBody;
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';
import 'support/today_test_support.dart';

/// The tab labelled [label] in the bottom navigation.
Finder _tab(String label) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(label));

/// Taps the last widget showing [text] and lets it settle.
Future<void> _tap(WidgetTester tester, String text) async {
  await tapExactly(tester, find.text(text).last, '"$text"');
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// The version in effect on [today], read from the database.
Future<TargetSettingsRecord> _current(
  TargetsRepository repository,
  LocalDate today,
) async {
  final data = await repository.read();
  return TargetsTimeline.versionOn([
    for (final s in data.settings) s.value,
  ], today)!;
}

/// Set my own target 1,000 kcal from the Targets screen: the warning, "Use"
/// disabled until the acknowledgement is checked, then applied (manual,
/// acknowledged, fixed).
Future<void> _setOwnTarget(
  WidgetTester tester,
  TargetsRepository repository,
  LocalDate today,
) async {
  // The screen may still be reloading (e.g. right after Undo): let it settle
  // before looking for the row.
  await pumpFor(tester, const Duration(seconds: 1));
  await waitUntil(
    tester,
    () => find.byType(TargetsBody).evaluate().isNotEmpty,
    'the Targets screen',
  );
  // The row sits at the end of the lazily built list: scroll to it.
  final own = find.text('Set my own target');
  await tester.scrollUntilVisible(
    own,
    300,
    scrollable: find
        .descendant(
          of: find.byType(TargetsBody),
          matching: find.byType(Scrollable),
        )
        .first,
  );
  await pumpFor(tester, const Duration(milliseconds: 300));
  await waitUntil(
    tester,
    () => own.hitTestable().evaluate().length == 1,
    '"Set my own target" on screen',
  );
  await tapExactly(tester, own, '"Set my own target"');
  await pumpFor(tester, const Duration(milliseconds: 400));
  final field = find.widgetWithText(TextField, 'Daily target');
  await waitUntil(
    tester,
    () => field.evaluate().isNotEmpty,
    'the own-target sheet',
  );
  await tester.enterText(field, '1000');
  FocusManager.instance.primaryFocus?.unfocus();
  await pumpFor(tester, const Duration(milliseconds: 400));
  await _tap(tester, 'Use this target');

  // The warning: Use stays off until the acknowledgement is checked.
  final use = find.widgetWithText(FbButton, 'Use 1,000 kcal');
  await waitUntil(
    tester,
    () => use.evaluate().isNotEmpty,
    'the below-floor warning',
  );
  expect(tester.widget<FbButton>(use).onPressed, isNull);
  expect((await _current(repository, today)).manual, isFalse);
  await _tap(tester, 'I understand and want to use 1,000 kcal a day');
  expect(tester.widget<FbButton>(use).onPressed, isNotNull);
  await tapExactly(tester, use, '"Use 1,000 kcal"');
  await waitUntilAsync(
    tester,
    () async => (await _current(repository, today)).manual,
    'the manual target stored',
  );
  final version = await _current(repository, today);
  expect(version.acknowledged, isTrue);
  expect(version.mode, TargetMode.fixed);
  expect(version.baseKcal, 1000);
}

/// SF-012 on the device (A13c WP12, exit 3): a throw-away profile set up
/// through `TargetsActions` (male, 1990, 180 cm, 80 kg, moderate, lose
/// 0.5 kg a week: floor 1,750 kcal), Me › Targets, own target 1,000 kcal,
/// the warning with "Use" disabled until the box is checked, apply; Undo
/// on the Targets screen restores the calculated target; applied again,
/// Today shows the 1,000 kcal target and no weekly line (fixed).
void main() {
  patrolTest('A13 manual target below floor needs acknowledgement', ($) async {
    final container = await bootApp($, 'it-targets', rootName: 'fb_tgt_it');
    final tester = $.tester;
    final today = EntryTime.now(container.read(clockProvider)).localDate;
    final repository = TargetsRepository(container.read(appDatabaseProvider));

    final setup = await container
        .read(targetsActionsProvider)
        .completeSetup(
          SetupInput(
            sex: FormulaSex.male,
            birthYear: 1990,
            height: Length.centimeters(180),
            heightInputUnit: HeightInputUnit.centimeter,
            weightValue: 80,
            weightUnit: MassUnit.kilogram,
            activity: ActivityLevel.moderate,
            goal: GoalInput(
              type: GoalType.lose,
              expression: GoalExpression.weekly(-.5),
            ),
            preferences: const SetupPreferences(
              unitSystem: UnitSystem.metric,
              weekStart: DayOfWeek.saturday,
              halal: true,
            ),
          ),
        );
    expect(setup, isA<TargetsDone>());

    // Me › Targets › Set my own target: 1,000 kcal.
    await tapExactly(tester, _tab('Me'), 'the Me tab');
    await pumpFor(tester, const Duration(milliseconds: 600));
    await _tap(tester, 'Targets');
    await waitUntil(
      tester,
      () => find.byType(TargetsBody).evaluate().isNotEmpty,
      'the Targets screen',
    );
    await _setOwnTarget(tester, repository, today);

    // Undo on the Targets screen (the snackbar is checked where it was
    // shown, not after navigating) restores the calculated target.
    await tapExactly(tester, find.text('Undo').last, '"Undo"');
    await waitUntilAsync(
      tester,
      () async => !(await _current(repository, today)).manual,
      'the calculated target back',
    );

    // Again, then Today.
    await _setOwnTarget(tester, repository, today);

    // Today: the 1,000 kcal target, no weekly line in fixed mode (TG-044).
    await tapExactly(tester, _tab('Today'), 'the Today tab');
    final big = find.descendant(
      of: dayPage(today),
      matching: find.byType(FbBigNumber),
    );
    await waitUntil(
      tester,
      () =>
          big.evaluate().isNotEmpty &&
          tester.widget<FbBigNumber>(big).value == '1,000',
      'Today showing 1,000 kcal left',
    );
    expect(
      find.descendant(
        of: dayPage(today),
        matching: find.textContaining('This week'),
      ),
      findsNothing,
    );
  }, timeout: const Timeout(Duration(minutes: 4)));
}
