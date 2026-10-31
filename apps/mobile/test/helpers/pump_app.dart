import 'package:fb_domain/fb_domain.dart'
    show DayOfWeek, EntryTime, FoodNameLanguage;
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/router/app_router.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/core/undo/undo_stack.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../core/db/support/db_support.dart' show memoryDatabase;
import 'quick_add_context.dart';
import 'ramadan_off.dart';
import 'test_phone.dart';

export 'test_phone.dart' show TestPhone, testConfig;

/// And for the confirmed below-floor days (A53).
final Override _noFloorAcks = dayFloorAcksProvider.overrideWith(
  (ref) => Stream.value(const <DayOfWeek, double>{}),
);

/// What the app's Today needs in a widget test: an empty in-memory profile
/// (no platform channel for the app-support folder), and today without the
/// midnight timer (and the quick-add context's 30-minute one), which a widget
/// test would find pending at its end.
List<Override> todayOverrides() => [
  appDatabaseProvider.overrideWith((ref) => memoryDatabase()),
  todayProvider.overrideWith(
    (ref) => Stream.value(EntryTime.now(ref.watch(clockProvider)).localDate),
  ),
  quickAddContextWithoutTimer(),
  // Today's workout row (A37 D20) is the workouts tests' business (R7).
  todayWorkoutProvider.overrideWith((ref, date) => null),
  // No Ramadan decision: no settings stream for the day's meals (A41a).
  ramadanOff,
  // No settings stream for the confirmed below-floor days (A53).
  _noFloorAcks,
  // Nor for the food-name language every food row reads (A53, D-091).
  foodNameSettingProvider.overrideWith(
    (ref) => Stream.value(FoodNameLanguage.phone),
  ),
];

/// This app's scope closes with the widget tree, inside fake async: no
/// database stream for the theme (a test of the theme uses `pumpApp`).
final Override _systemTheme = themePreferenceProvider.overrideWith(
  (ref) => Stream.value(ThemePreference.system),
);

/// Nor for the week start, which Today's numbers read (A13).
final Override _saturdayWeek = weekStartProvider.overrideWith(
  (ref) => Stream.value(DayOfWeek.saturday),
);

/// The whole app, wired like `main` does, on a fresh offline [TestPhone],
/// plus [overrides].
/// An override in [overrides] replaces the base one of the same provider.
Widget testApp({List<Override> overrides = const []}) => ProviderScope(
  overrides: [
    ...[
      ...TestPhone().overrides(),
      ...todayOverrides(),
      _systemTheme,
      _saturdayWeek,
    ].where((base) => !overrides.any((o) => o.origin == base.origin)),
    ...overrides,
  ],
  child: const FitnessBuddyApp(),
);

/// Starts the app with the upgrade signal already tripped, so it opens on
/// the update screen.
final Override tripped = upgradeSignalProvider.overrideWithBuild(
  (ref, notifier) => true,
);

/// Starts the app on [phone] (a fresh offline one by default), plus
/// [overrides], and settles
/// after the deferred startup work. Returns the provider container
/// (disposed at the end of the test).
Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  TestPhone? phone,
  List<Override> overrides = const [],
}) async {
  final container = ProviderContainer.test(
    overrides: [
      ...[
        ...(phone ?? TestPhone()).overrides(),
        ...todayOverrides(),
      ].where((base) => !overrides.any((o) => o.origin == base.origin)),
      ...overrides,
    ],
  );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const FitnessBuddyApp(),
    ),
  );
  await tester.pumpAndSettle();
  // A screen the startup replaced (Today, by the update screen) disposes its
  // providers in the last settled frame; drift closes a query stream on a
  // zero timer, which this pump (moving the fake clock) runs.
  await tester.pump(Duration.zero);
  // The database is closed by a teardown registered while the app first read
  // it; closing it waits for every open query stream, so the container (and
  // with it every provider's stream) goes first. Teardowns run in reverse.
  addTearDown(container.dispose);
  return container;
}

/// Lets the database and the undo stack finish what a tap started (the
/// writes run on the real event loop), then settles the frames.
Future<void> settleWrites(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 100)),
  );
  await tester.pumpAndSettle();
}

/// Takes the app down at the end of a test, and lets the providers that were
/// only watched by its screens close their database streams (drift closes a
/// stream on a timer, which a widget test must not leave pending).
Future<void> unmountApp(
  WidgetTester tester, [
  ProviderContainer? container,
]) async {
  // The undo stack runs its expiry timers off the app clock, which a widget
  // test does not advance: stop it, as the rigs do.
  container?.read(undoStackProvider).dispose();
  // Undo entries and snackbars expire first (5 s each, one after the other):
  // their timers must not outlive the app.
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(seconds: 6));
  }
  await tester.pumpWidget(const SizedBox());
  // Two rounds: the first closes the streams, the second runs their timers.
  await tester.pump(const Duration(seconds: 1));
  await tester.pump(const Duration(seconds: 1));
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
