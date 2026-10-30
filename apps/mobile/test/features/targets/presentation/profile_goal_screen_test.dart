import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/targets/presentation/profile_edit_sheet.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/pump_app.dart' show settleWrites;
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

  testWidgets('PA1 the Current weight row shows the trend and opens the '
      'weigh-in sheet', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const ProfileRoute(),
    );
    expect(
      find.descendant(of: _row('Current weight'), matching: find.text('80 kg')),
      findsOneWidget,
    );
    await rig.tap('Current weight');
    expect(find.byType(WeighInSheet), findsOneWidget);
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

  testWidgets('PA3 a passed goal date shows the neutral line with Start a new '
      'goal', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      goal: GoalInput(
        type: GoalType.lose,
        expression: GoalExpression.targetDate(78, LocalDate(2026, 11, 30)),
      ),
    );
    rig.advanceDays(60);
    await rig.show(const ProfileRoute());
    expect(find.text('Your goal date has passed.'), findsOneWidget);
    expect(find.text('Edit goal'), findsNothing);
    expect(find.text('Start a new goal'), findsOneWidget);
    await rig.close();
  });

  testWidgets('TG-012 a phase without a name shows the default label; rename '
      'stores the name', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const ProfileRoute(),
    );
    final card = find.byType(FbCard);
    expect(
      find.descendant(of: card, matching: find.text('Lose weight')),
      findsOneWidget,
    );
    await rig.tap('Rename');
    await tester.enterText(find.byType(TextField), 'Summer cut');
    await tester.pumpAndSettle();
    await rig.tapAndSettle('Save');

    expect((await rig.data()).phases.single.value.name, 'Summer cut');
    expect(
      find.descendant(of: card, matching: find.text('Summer cut')),
      findsOneWidget,
    );
    expect(find.text('Goal renamed'), findsOneWidget);
    await rig.close();
  });

  testWidgets('UX-052 a goal renamed elsewhere: Reload takes the stored row '
      'and keeps the typed name', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const ProfileRoute(),
    );
    await rig.tap('Rename');
    await tester.enterText(find.byType(TextField), 'Summer cut');
    await tester.pumpAndSettle();

    final phase = (await rig.data()).phases.single;
    await rig.run(
      (a) => a.renamePhase(
        VersionedId(phase.value.id, phase.version),
        'Elsewhere',
      ),
    );
    expect(find.text('This changed. Reload.'), findsOneWidget);
    final save = find.widgetWithText(FbButton, 'Save');
    expect(tester.widget<FbButton>(save).onPressed, isNull);

    await rig.tap('Reload');
    expect(find.text('This changed. Reload.'), findsNothing);
    expect(find.text('Summer cut'), findsOneWidget);
    await rig.tapAndSettle('Save');
    expect((await rig.data()).phases.single.value.name, 'Summer cut');
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

  testWidgets('UX-030 dismissing the sheet during Save still shows the '
      'result with Undo', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const ProfileRoute(),
    );
    await rig.tap('Activity');
    await rig.tap('Lightly active');
    final hold = rig.holdWrites();
    await tester.tap(find.widgetWithText(FbButton, 'Save'));
    await tester.pump();
    // Dismiss the sheet (tap the barrier above it) while the write waits.
    await tester.tapAt(const Offset(180, 20));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileEditSheet), findsNothing);

    hold.complete();
    await settleWrites(tester);
    expect(find.textContaining('Profile updated'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
    expect((await rig.data()).profile!.value.activity, ActivityLevel.light);
    await rig.close();
  });

  testWidgets('UX-052 a failed goal save keeps the typed goal', (tester) async {
    final rig = await TargetsScreenRig.open(
      tester,
      route: const ProfileRoute(),
    );
    await rig.tap('Start a new goal');
    await rig.tap('Maintain weight');
    rig.failWrites = true;
    await rig.tapAndSettle('Save');
    expect(find.text('New goal from today'), findsOneWidget);
    expect(
      find.text(
        "Couldn't save just now. Nothing you entered was lost. Try again.",
      ),
      findsOneWidget,
    );
    expect((await rig.data()).phases, hasLength(1));
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
