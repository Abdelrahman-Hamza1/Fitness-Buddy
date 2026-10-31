import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/today/presentation/today_numbers.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/today_support.dart';
import 'support/today_targets_support.dart';

FbBigNumber _big(WidgetTester tester) =>
    tester.widget<FbBigNumber>(find.byType(FbBigNumber));

TodayNumbers _block(LocalDate date, double kcal, {bool isToday = true}) =>
    TodayNumbers(date: date, isToday: isToday, totals: eatenTotals(kcal));

void main() {
  testWidgets('UX-050 without targets today shows kcal eaten and the setup '
      'row; past days show kcal eaten only', (tester) async {
    final navigator = RecordingNavigator();
    final overrides = [
      ...numbersOverrides(weekSat, null, setup: SetupStatus.notSetUp),
      appNavigatorProvider.overrideWithValue(navigator),
    ];
    await pumpBlock(tester, _block(weekSat, 1239.6), overrides);
    expect((_big(tester).value, _big(tester).caption), ('1,240', 'kcal eaten'));
    expect(find.text('Protein 82 g'), findsOneWidget);
    expect(find.text('Set up your targets'), findsOneWidget);
    expect(find.text('About 2 minutes'), findsOneWidget);
    expect(find.byType(FbProgressBar), findsNothing);
    expect(find.textContaining('This week'), findsNothing);
    await tester.tap(find.text('Set up your targets'));
    expect(navigator.pushed, [const SetupRoute()]);

    await pumpBlock(tester, _block(weekSat, 1239.6, isToday: false), overrides);
    expect(_big(tester).caption, 'kcal eaten');
    expect(find.text('Set up your targets'), findsNothing);

    // Once set up, today shows no row even on a day without a version.
    await pumpBlock(
      tester,
      _block(weekSat, 1239.6),
      numbersOverrides(weekSat, null),
    );
    expect(find.text('Set up your targets'), findsNothing);
  });

  testWidgets("A13a security #3 a profile this version can't read shows "
      '"Update the app" instead of the setup row', (tester) async {
    final navigator = RecordingNavigator();
    await pumpBlock(tester, _block(weekSat, 300), [
      ...numbersOverrides(weekSat, null, setup: SetupStatus.profileUnreadable),
      appNavigatorProvider.overrideWithValue(navigator),
    ]);
    expect(find.text('Set up your targets'), findsNothing);
    expect(find.text('Update the app'), findsOneWidget);
    expect(find.text('Your profile needs a newer version'), findsOneWidget);
    await tester.tap(find.text('Update the app'));
    expect(navigator.pushed, [const SetupRoute()]);
  });

  testWidgets('UX-051 the numbers skeleton shows until targets load; UX-052 '
      'a targets read error keeps kcal eaten and shows the banner with Try '
      'again', (tester) async {
    final pending = Completer<DayTargets?>();
    await pumpBlock(tester, _block(weekSat, 1240), [
      dayTargetsProvider.overrideWith((ref, date) => pending.future),
      setupStatusProvider.overrideWith((ref) => SetupStatus.setUp),
    ]);
    expect(find.byType(FbSkeleton), findsWidgets);
    expect(find.byType(FbBigNumber), findsNothing);

    pending.complete(targetsOn(weekSat));
    await tester.pump();
    await tester.pump();
    expect(find.byType(FbSkeleton), findsNothing);
    expect(_big(tester).caption, 'kcal left today');

    // A first read that fails (a fresh scope).
    var fail = true;
    await pumpBlock(tester, _block(weekSat, 1240), [
      dayTargetsProvider.overrideWith((ref, date) {
        if (fail) throw StateError('targets unreadable (test)');
        return targetsOn(weekSat);
      }),
      setupStatusProvider.overrideWith((ref) => SetupStatus.setUp),
    ]);
    await tester.pump();
    expect((_big(tester).value, _big(tester).caption), ('1,240', 'kcal eaten'));
    expect(find.text("Couldn't load your targets."), findsOneWidget);
    fail = false;
    await tester.tap(find.text('Try again'));
    await tester.pump();
    await tester.pump();
    expect(find.text("Couldn't load your targets."), findsNothing);
    expect(_big(tester).caption, 'kcal left today');
  });

  testWidgets('#259 A41a D8 a Ramadan day of a "maintain" season says the '
      'target is maintenance; other days say nothing', (tester) async {
    final maintain = targetsOn(
      weekSat,
      settings: [sampleVersion(mode: TargetMode.fixed)],
      goals: [sampleLoseGoal()],
      ramadanMaintain: true,
    );
    expect(maintain.ramadanMaintain, isTrue);
    await pumpBlock(tester, _block(weekSat, 900), [
      dayTargetsProvider.overrideWith((ref, date) async => maintain),
      setupStatusProvider.overrideWith((ref) => SetupStatus.setUp),
    ]);
    expect(find.text('Maintaining during Ramadan'), findsOneWidget);

    await pumpBlock(tester, _block(weekSat, 900), [
      dayTargetsProvider.overrideWith(
        (ref, date) async => targetsOn(
          weekSat,
          settings: [sampleVersion(mode: TargetMode.fixed)],
          goals: [sampleLoseGoal()],
        ),
      ),
      setupStatusProvider.overrideWith((ref) => SetupStatus.setUp),
    ]);
    expect(find.text('Maintaining during Ramadan'), findsNothing);
  });
}
