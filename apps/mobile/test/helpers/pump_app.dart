import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'test_phone.dart';

export 'test_phone.dart' show TestPhone, testConfig;

/// The whole app, wired like `main` does, on a fresh offline [TestPhone],
/// plus [overrides].
Widget testApp({List<Override> overrides = const []}) => ProviderScope(
  overrides: [...TestPhone().overrides(), ...overrides],
  child: const FitnessBuddyApp(),
);

/// Starts the app with the upgrade signal already tripped, so it opens on
/// the update screen.
final Override tripped = upgradeSignalProvider.overrideWithBuild(
  (ref, notifier) => true,
);

/// Starts the app on [phone] (a fresh offline one by default) and settles
/// after the deferred startup work. Returns the provider container
/// (disposed at the end of the test).
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  TestPhone? phone,
}) async {
  final container = ProviderContainer.test(
    overrides: (phone ?? TestPhone()).overrides(),
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FitnessBuddyApp(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}

/// Shows [route] in the app of [container] (pump to see it). The update
/// screen is reached only through the update gate, so for it the gate is
/// raised; for the others it is lowered and the router goes there.
void showRoute(ProviderContainer container, AppRoute route) {
  final gate = container.read(upgradeSignalProvider.notifier);
  if (route is UpdateRequiredRoute) {
    gate.trip();
  } else {
    gate.clear();
    container.read(appRouterProvider).go(route);
  }
}
