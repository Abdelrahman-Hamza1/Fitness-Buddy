import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:fb_mobile/features/onboarding/onboarding.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_support.dart';

/// Integration tests on a real device or emulator (S06 plan D18), run by
/// `make test-it` with the dev flavor and `config/dev.json`.
///
/// Unlike the widget tests, nothing is faked: the real plugins (shared
/// preferences, package info), the real dio client and the dev API URL
/// (127.0.0.1:5198). Without `adb reverse` nothing listens there, so the
/// app runs with no API reachable, as on the CI emulator.
void main() {
  patrolTest(
    'UX-010 app launches with no API reachable and switches through the four '
    'tabs',
    ($) async {
      // Wired like lib/main.dart, from the flavor's compile-time config.
      final config = AppConfig.fromEnvironment();
      expect(config.flavor, AppFlavor.dev);
      final container = ProviderContainer(
        overrides: [
          ...appOverrides(config),
          // A51 TD-110: this run is about the tabs, not the first run.
          firstRunEnabledProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      // Loading skeletons pulse continuously, so settling could stall; wait
      // for Today and its input bar instead.
      await $.tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FitnessBuddyApp(),
        ),
      );
      await waitUntil(
        $.tester,
        () =>
            find.byType(TodayScreen).evaluate().isNotEmpty &&
            find
                .textContaining('Tell Buddy what you ate')
                .evaluate()
                .isNotEmpty,
        'Today and its input bar',
        timeout: const Duration(seconds: 60),
      );

      // The shell is up at Today, not waiting on the network.
      expect($(NavigationBar), findsOneWidget);
      expect($(TodayScreen), findsOneWidget);

      // The /v1/config refresh started after the first frame; join it. It
      // can't reach the API, so the app keeps the defaults (no update gate).
      final fetched = await container
          .read(clientConfigProvider.notifier)
          .refresh();
      expect(fetched, isFalse, reason: 'the API must not be reachable here');
      expect(
        container.read(clientConfigProvider),
        ClientConfigRepository.defaults,
      );

      // Every tab works offline, and Today comes back as it was.
      final tabs = {
        'Progress': (ProgressScreen, 'Charts appear after'),
        'Workouts': (WorkoutsScreen, 'Your workouts will show up'),
        'Me': (MeScreen, 'Food & meals'),
        'Today': (TodayScreen, 'Tell Buddy what you ate'),
      };
      for (final MapEntry(key: label, value: (screen, text)) in tabs.entries) {
        await $(NavigationBar).$(label).tap();

        expect($(screen), findsOneWidget, reason: label);
        expect(find.textContaining(text), findsOneWidget, reason: label);
        expect($(NavigationBar), findsOneWidget, reason: label);
      }
    },
    timeout: const Timeout(Duration(minutes: 4)),
  );
}
