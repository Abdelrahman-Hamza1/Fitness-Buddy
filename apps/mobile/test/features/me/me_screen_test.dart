import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../settings/presentation/settings_support.dart';

Finder _row(String title) => find.widgetWithText(FbListRow, title);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _back(WidgetTester tester) async {
  await tester.pageBack();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('UX-010 D-088 every destination of the old Me list is '
      'reachable from the new Me and its subpages', (tester) async {
    final c = await pumpAt(tester);
    await openMe(tester);
    // The account card and the setup entry come first.
    expect(find.text('Data on this phone only, not backed up'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(_row('Set up profile & targets'), findsOneWidget);

    // Your plan.
    await _tap(tester, _row('Targets & goal'));
    await _tap(tester, _row('Set up profile & targets'));
    expect(find.byType(SetupScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Close setup'));
    await tester.pumpAndSettle();
    await _back(tester);

    await _tap(tester, _row('Food & meals'));
    for (final (title, screen) in [
      ('Your foods', PersonalFoodsScreen),
      ('Saved meals', SavedMealsScreen),
      ('Meal times', MealSlotsScreen),
    ]) {
      await _tap(tester, _row(title));
      expect(find.byType(screen), findsOneWidget, reason: title);
      await _back(tester);
    }
    expect(find.text('Halal food'), findsOneWidget);
    await _back(tester);

    await _tap(tester, _row('Ramadan'));
    expect(find.byType(RamadanScreen), findsOneWidget);
    // The city lives here now (D-088).
    expect(_row('City'), findsOneWidget);
    await _back(tester);

    // App.
    await _tap(tester, _row('Preferences'));
    for (final title in ['Units', 'Theme', 'Week starts on', 'Language']) {
      expect(_row(title), findsOneWidget, reason: title);
    }
    expect(_row('Energy'), findsOneWidget);
    await _back(tester);

    await _tap(tester, _row('Notifications'));
    expect(find.byType(NotificationSettingsScreen), findsOneWidget);
    await _back(tester);

    await _tap(tester, _row('Account & data'));
    expect(find.byType(MeAccountScreen), findsOneWidget);
    expect(_row('Export your data'), findsOneWidget);
    expect(_row('Delete data on this phone'), findsOneWidget);
    await _tap(tester, find.text('Sign in'));
    expect(find.byType(SignInScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await _back(tester);

    await _tap(tester, _row('Help & about'));
    expect(find.byType(AboutScreen), findsOneWidget);
    await _back(tester);

    // Workouts open in their own tab.
    await _tap(tester, _row('Workouts'));
    await _tap(tester, _row('Weekly plan'));
    expect(find.byType(WeeklyPlanScreen), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('A13a security #3 Me offers "Update the app" for a profile '
      "this version can't read", (tester) async {
    final c = await pumpAt(
      tester,
      overrides: [
        setupStatusProvider.overrideWith(
          (ref) async => SetupStatus.profileUnreadable,
        ),
      ],
    );
    await openMePage(tester, 'Targets & goal');
    expect(_row('Set up profile & targets'), findsNothing);
    await _tap(tester, _row('Update the app'));
    expect(find.byType(SetupScreen), findsOneWidget);
    expect(find.text('What brings you here?'), findsNothing);
    await unmountApp(tester, c);
  });
}
