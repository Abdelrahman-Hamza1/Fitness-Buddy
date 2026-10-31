import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/features/onboarding/data/first_run_store.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../foods/presentation/support/personal_food_support.dart'
    show aFood, seed;

/// The gate as the app builds it, but enabled (the test phone turns it off
/// for every other test).
FirstRunGate _gate(ProviderContainer c) => FirstRunGate(
  c.read(firstRunStoreProvider),
  c.read(profileRegistryProvider),
  enabled: true,
);

void main() {
  testWidgets('UX-060 D-088 a fresh install opens on the welcome after the '
      'first frame; "Skip setup" goes to Today and it never shows again', (
    tester,
  ) async {
    final phone = TestPhone(firstRun: true);
    var c = await pumpApp(tester, phone: phone);
    await settleWrites(tester);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.text('Food and training, tracked your way.'), findsOneWidget);

    await tester.tap(find.text("Skip setup, I'll look around"));
    await settleWrites(tester);
    expect(find.byType(TodayScreen), findsOneWidget);
    expect(find.text('Set up your targets'), findsOneWidget);
    expect(
      (await tester.runAsync(
        phone.storedPreferences,
      ))![PreferenceKeys.firstRun],
      isTrue,
    );
    await unmountApp(tester, c);

    // The next start: Today, no welcome.
    c = await pumpApp(tester, phone: phone);
    await settleWrites(tester);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(find.byType(TodayScreen), findsOneWidget);
    await unmountApp(tester, c);
  });

  testWidgets('D-088 "Get started" opens the questions with the account '
      'step', (tester) async {
    final c = await pumpApp(tester, phone: TestPhone(firstRun: true));
    await settleWrites(tester);
    await tester.tap(find.text('Get started'));
    await tester.pumpAndSettle();
    expect(find.text('What brings you here?'), findsOneWidget);
    expect(
      c.read(setupFlowProvider(SetupMode.firstRun)).value!.pages.last,
      SetupPage.account,
    );
    await unmountApp(tester, c);
  });

  testWidgets('TD-110 an install that already holds data never sees the '
      'first run, and is marked at once', (tester) async {
    final c = await pumpApp(tester);
    final gate = _gate(c);
    final empty = await tester.runAsync(gate.shouldShow);
    expect(empty, isTrue, reason: 'a fresh guest with no data');

    await seed(tester, c, aFood(1));
    final withData = await tester.runAsync(gate.shouldShow);
    expect(withData, isFalse);
    expect(
      await tester.runAsync(() => c.read(firstRunStoreProvider).seen()),
      isTrue,
    );
    await unmountApp(tester, c);
  });

  testWidgets('TD-110 the gate is off in tests that start the app for '
      'something else', (tester) async {
    final c = await pumpApp(tester);
    await settleWrites(tester);
    expect(find.byType(WelcomeScreen), findsNothing);
    expect(
      await tester.runAsync(c.read(firstRunGateProvider).shouldShow),
      isFalse,
    );
    await unmountApp(tester, c);
  });
}
