import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/local_identity_store.dart';
import 'package:fb_mobile/core/ui/load_states.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/account/application/local_identity.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';
import '../settings/presentation/settings_support.dart';
import '../today/presentation/support/today_support.dart' show phoneApp;

Finder _row(String title) => find.widgetWithText(FbListRow, title);

const _name = 'عبود';
const _email = 'canary-me@example.invalid';

/// The setup state read through [read] (A63 T-S6).
List<Override> _setupOverrides(Future<SetupStatus> Function() read) => [
  setupStatusProvider.overrideWith((ref) => read()),
];

/// The stored targets failing while [fail] says so; setup status is the
/// real provider over them (A63 review).
List<Override> _failingTargets(bool Function() fail) => [
  targetsDataProvider.overrideWith(
    (ref) => fail()
        ? Stream<TargetsData>.error(StateError('targets'))
        : Stream.value(TargetsData()),
  ),
];

/// A signed-in profile with a stored name and email.
final class _Known extends MeIdentity {
  @override
  Future<({String profileKey, LocalIdentity identity})?> build() async => (
    profileKey: 'acct-me',
    identity: const LocalIdentity(name: _name, email: _email),
  );
}

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
    for (final title in ['Units', 'Theme', 'Week starts on']) {
      expect(_row(title), findsOneWidget, reason: title);
    }
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

  testWidgets('UX-048 S1 A T-M5 Preferences has no Energy or Language row and '
      'shows the facts line', (tester) async {
    final c = await pumpAt(tester);
    await openMePage(tester, 'Preferences');
    expect(_row('Energy'), findsNothing);
    expect(_row('Language'), findsNothing);
    expect(find.byKey(const ValueKey('prefs-fixed-facts')), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets("AC-005 UX-010 M1 A T-M3 Me shows who's signed in: the letter "
      'from the name (an Arabic name), the name and email, the sync line; a '
      'tap opens Account & data with the Name row', (tester) async {
    final c = await pumpAt(
      tester,
      overrides: [
        accountStatusProvider.overrideWith(
          (ref) async => AccountStatus.signedIn,
        ),
        meIdentityProvider.overrideWith(_Known.new),
      ],
    );
    await openMe(tester);
    final card = find.byKey(const ValueKey('account-card'));
    expect(card, findsOneWidget);
    expect(
      tester
          .widget<FbLetterAvatar>(
            find.byKey(const ValueKey('account-card-letter')),
          )
          .source,
      _name,
    );
    expect(FbLetterAvatar.letterOf(_name), 'ع');
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('account-card-title')))
          .data,
      _name,
    );
    expect(
      find.descendant(of: card, matching: find.text(_email)),
      findsOneWidget,
    );
    await _tap(tester, card);
    expect(find.byType(MeAccountScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('account-name')), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('AC-005 T-M3 a guest sees the person icon, no letter, and Sign '
      'in', (tester) async {
    final c = await pumpAt(tester);
    await openMe(tester);
    expect(find.byKey(const ValueKey('account-card-letter')), findsNothing);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('account-card')),
        matching: find.byIcon(FbIcons.me),
      ),
      findsOneWidget,
    );
    await unmountApp(tester, c);
  });

  testWidgets('UX-052 T-S9 the account card shows an error with Try again '
      'when the status read fails', (tester) async {
    var fail = true;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          accountStatusProvider.overrideWith((ref) async {
            if (fail) throw StateError('registry');
            return AccountStatus.guest;
          }),
        ],
        child: phoneApp(const Scaffold(body: AccountCard())),
      ),
    );
    await tester.pumpAndSettle();
    final error = find.byKey(const ValueKey('account-card-error'));
    expect(error, findsOneWidget);
    expect(find.byKey(const ValueKey('account-card-loading')), findsNothing);
    fail = false;
    await tester.tap(
      find.descendant(of: error, matching: find.byType(TextButton)),
    );
    await tester.pumpAndSettle();
    expect(error, findsNothing);
    expect(find.byKey(const ValueKey('account-card')), findsOneWidget);
  });

  testWidgets('UX-051 UX-052 A63 T-S6 Me › Targets & goal shows rows while '
      'loading and an error with Try again, never a blank page', (
    tester,
  ) async {
    var fail = true;
    final pending = Completer<SetupStatus>();
    Widget screen(Future<SetupStatus> Function() read) => ProviderScope(
      key: UniqueKey(),
      retry: (_, _) => null,
      overrides: [..._setupOverrides(read)],
      child: phoneApp(const MeTargetsGoalScreen()),
    );
    await tester.pumpWidget(screen(() => pending.future));
    await tester.pump();
    expect(find.byType(LoadingRows), findsOneWidget);

    await tester.pumpWidget(
      screen(() async {
        if (fail) throw StateError('profile');
        return SetupStatus.setUp;
      }),
    );
    await tester.pumpAndSettle();
    final failed = find.byKey(const ValueKey('me-targets-failed'));
    expect(failed, findsOneWidget);
    fail = false;
    await tester.tap(
      find.descendant(of: failed, matching: find.byType(TextButton)),
    );
    await tester.pumpAndSettle();
    expect(failed, findsNothing);
    expect(_row('Targets'), findsOneWidget);
    pending.complete(SetupStatus.setUp);
  });

  testWidgets('UX-052 A63 T-S6 Try again on Me › Targets & goal re-reads the '
      'failed stored targets beneath the real setup status', (tester) async {
    var fail = true;
    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [..._failingTargets(() => fail)],
        child: phoneApp(const MeTargetsGoalScreen()),
      ),
    );
    await tester.pumpAndSettle();
    final failed = find.byKey(const ValueKey('me-targets-failed'));
    expect(failed, findsOneWidget);
    fail = false;
    await tester.tap(
      find.descendant(of: failed, matching: find.byType(TextButton)),
    );
    await tester.pumpAndSettle();
    expect(failed, findsNothing);
    expect(_row('Set up profile & targets'), findsOneWidget);
  });
}
