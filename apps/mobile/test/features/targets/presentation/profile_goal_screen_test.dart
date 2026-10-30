import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'targets_screens_support.dart';

Finder _row(String title) => find.widgetWithText(FbListRow, title);

void main() {
  testWidgets('TG-001 editing activity recomputes the generated target and '
      'the undo message names it', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const ProfileRoute(),
    );
    expect(
      find.descendant(
        of: _row('Activity'),
        matching: find.text('Moderately active'),
      ),
      findsOneWidget,
    );
    await rig.tap('Activity');
    await rig.tap('Lightly active');
    await rig.tapAndSettle('Save');

    final data = await rig.data();
    expect(data.profile!.value.activity, ActivityLevel.light);
    final latest = TargetsTimeline.versionOn([
      for (final s in data.settings) s.value,
    ], rig.today)!;
    expect(latest.baseKcal, lessThan(2162.5));
    expect(find.textContaining('Profile updated. Target now'), findsOneWidget);
    expect(
      find.descendant(
        of: _row('Activity'),
        matching: find.text('Lightly active'),
      ),
      findsOneWidget,
    );
    await rig.close();
  });

  testWidgets('TG-012 starting a new goal ends the current one yesterday and '
      'lists it under Past goals', (tester) async {
    final rig = await TargetsScreenRig.open(tester);
    rig.advanceDays(3);
    await rig.show(const ProfileRoute());
    expect(find.text('Goals you finish show up here.'), findsOneWidget);

    await rig.tap('Start a new goal');
    expect(find.text('New goal from today'), findsOneWidget);
    await rig.tap('Maintain weight');
    await rig.tapAndSettle('Save');

    final phases = (await rig.data()).phases;
    expect(phases, hasLength(2));
    final ended = phases.firstWhere((p) => p.value.type == GoalType.lose);
    expect(ended.value.end, rig.today.plusDays(-1));
    expect(find.textContaining('New goal started'), findsOneWidget);
    expect(find.text('Goals you finish show up here.'), findsNothing);
    expect(_row('Lose weight'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(FbCard),
        matching: find.text('Maintain weight'),
      ),
      findsOneWidget,
    );
    await rig.close();
  });

  testWidgets('UX-052 a profile changed elsewhere while the sheet is open '
      'shows "This changed. Reload." and keeps the typed value', (
    tester,
  ) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const ProfileRoute(),
    );
    await rig.tap('Birth year');
    await tester.enterText(find.byType(TextField), '1991');
    await tester.pumpAndSettle();

    final version = (await rig.data()).profile!.version;
    await rig.run(
      (a) => a.saveProfile(
        const ProfilePatch(activity: ActivityLevel.high),
        version,
      ),
    );
    expect(find.text('This changed. Reload.'), findsOneWidget);
    expect(find.text('1991'), findsOneWidget);
    final save = find.widgetWithText(FbButton, 'Save');
    expect(tester.widget<FbButton>(save).onPressed, isNull);

    await rig.tap('Reload');
    expect(find.text('This changed. Reload.'), findsNothing);
    expect(find.text('1991'), findsOneWidget);
    await rig.tapAndSettle('Save');
    final profile = (await rig.data()).profile!.value;
    expect(profile.birthYear, 1991);
    expect(profile.activity, ActivityLevel.high);
    await rig.close();
  });

  testWidgets('UX-052 a failed save keeps the sheet and what was typed, says '
      'what happened, and Save can be tried again', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const ProfileRoute(),
    );
    await rig.tap('Birth year');
    await tester.enterText(find.byType(TextField), '1991');
    await tester.pumpAndSettle();
    rig.failWrites = true;
    await rig.tapAndSettle('Save');

    expect(
      find.text(
        "Couldn't save just now. Nothing you entered was lost. Try again.",
      ),
      findsOneWidget,
    );
    expect(find.text('1991'), findsOneWidget);
    expect((await rig.data()).profile!.value.birthYear, 1990);

    rig.failWrites = false;
    await rig.tapAndSettle('Save');
    expect((await rig.data()).profile!.value.birthYear, 1991);
    expect(find.textContaining('Profile updated'), findsOneWidget);
    await rig.close();
  });

  test('TG-011 goalDraftOf reads every stored expression back in its typed '
      'unit', () {
    final today = LocalDate(2026, 10, 17);
    GoalPhaseRecord phase(GoalInput goal) =>
        goal.toRecord(id: '01890abc-def0-7123-8abc-0123456789ab', start: today);
    for (final goal in [
      GoalInput(type: GoalType.lose, expression: GoalExpression.weekly(-.5)),
      GoalInput(
        type: GoalType.gain,
        expression: GoalExpression.monthly(1.5, LocalDate(2026, 10, 1)),
      ),
      GoalInput(
        type: GoalType.lose,
        expression: GoalExpression.targetDate(75, LocalDate(2027, 3, 1)),
      ),
      GoalInput(
        type: GoalType.lose,
        expression: GoalExpression.targetRate(75, .4),
        weightInputUnit: MassUnit.pound,
      ),
      GoalInput.maintain(),
    ]) {
      final read = goalDraftOf(phase(goal)).read(today).input!;
      expect(read.type, goal.type);
      expect(read.weightInputUnit, goal.weightInputUnit);
      switch ((read.expression, goal.expression)) {
        case (WeeklyGoal(kgPerWeek: final a), WeeklyGoal(kgPerWeek: final b)):
          expect(a, closeTo(b, 1e-9));
        case (MonthlyGoal(kg: final a), MonthlyGoal(kg: final b)):
          expect(a, closeTo(b, 1e-9));
        case (
          TargetDateGoal(targetKg: final a, date: final d1),
          TargetDateGoal(targetKg: final b, date: final d2),
        ):
          expect(a, closeTo(b, 1e-9));
          expect(d1, d2);
        case (
          TargetRateGoal(targetKg: final a, kgPerWeek: final r1),
          TargetRateGoal(targetKg: final b, kgPerWeek: final r2),
        ):
          // Typed in lb (one decimal for the weight, two for the pace).
          expect(a, closeTo(b, .05));
          expect(r1, closeTo(r2, .005));
        default:
          fail('expression kind changed: $goal');
      }
    }
  });
}
