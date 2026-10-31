import 'package:dio/dio.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/update/update_required_screen.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/api/problem_types.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../core/session/session_fakes.dart';
import '../helpers/fake_http.dart';
import '../helpers/pump_app.dart';

/// The shell is on screen at Today.
void _expectShell() {
  expect(find.byType(NavigationBar), findsOneWidget);
  expect(find.byType(TodayScreen), findsOneWidget);
  expect(find.byType(UpdateRequiredScreen), findsNothing);
}

/// The update screen is on screen, instead of the shell.
void _expectUpdateScreen() {
  expect(find.byType(UpdateRequiredScreen), findsOneWidget);
  expect(find.byType(NavigationBar), findsNothing);
}

void main() {
  testWidgets('UX-001 nothing is requested before the first frame; '
      '/v1/config is requested after it', (tester) async {
    final phone = TestPhone()..adapter.respond = config('0.0.0');
    final container = ProviderContainer.test(
      overrides: [...phone.overrides(), ...todayOverrides()],
    );
    // Registered before the app's own callback, so it runs first: at the end
    // of the first frame, before any deferred work.
    tester.binding.addPostFrameCallback(
      (_) => phone.events.add(
        tester.any(find.byType(TodayScreen))
            ? 'first frame: shell'
            : 'first frame: empty',
      ),
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const FitnessBuddyApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Nothing (no request, no preferences, no package info) before the
    // first frame, and that frame already shows the shell.
    expect(phone.events.first, 'first frame: shell');
    expect(
      phone.events,
      containsAllInOrder([
        'first frame: shell',
        'prefs get ${PreferenceKeys.clientConfig}',
        'GET /v1/config',
        'prefs set ${PreferenceKeys.clientConfig}',
      ]),
    );
    expect(phone.adapter.requests, hasLength(1));
    _expectShell();
  });

  for (final (name, failure) in [('offline', offline)]) {
    testWidgets('config fetch failure ($name) keeps the defaults and the '
        'shell stays usable', (tester) async {
      final phone = TestPhone()..adapter.respond = failure;
      final container = await pumpApp(tester, phone: phone);

      expect(phone.adapter.requests.single.path, '/v1/config');
      expect(
        container.read(clientConfigProvider),
        ClientConfigRepository.defaults,
      );
      _expectShell();
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      expect(find.text('Food & meals'), findsOneWidget);
    });
  }

  testWidgets('cached config is used on the next start, offline', (
    tester,
  ) async {
    final phone = TestPhone()..adapter.respond = config('0.0.5');
    await pumpApp(tester, phone: phone);
    await tester.pumpWidget(const SizedBox());

    // Restart without network: the cached config applies.
    phone.adapter.respond = offline;
    final container = await pumpApp(tester, phone: phone);

    expect(container.read(clientConfigProvider).minimumAppVersion, '0.0.5');
    _expectShell();
  });

  testWidgets('a cached minimumAppVersion above the app version shows the '
      'update screen on the next start, offline', (tester) async {
    final phone = TestPhone()..adapter.respond = offline;
    await phone.seedPreference(
      PreferenceKeys.clientConfig,
      '{"minimumAppVersion":"0.2.0","featureFlags":{},"thresholds":{}}',
    );

    await pumpApp(tester, phone: phone);

    _expectUpdateScreen();
  });

  testWidgets('426 on any later request shows the update screen', (
    tester,
  ) async {
    final phone = TestPhone()..adapter.respond = config('0.0.0');
    final session = Fixture();
    await session.service.startAfterFirstFrame();
    final container = await pumpApp(
      tester,
      phone: phone,
      overrides: [sessionServiceProvider.overrideWithValue(session.service)],
    );
    _expectShell();

    phone.adapter.respond = problem(ProblemTypes.upgradeRequired, 426);
    final call = expectLater(
      container.read(dioProvider).get<void>('/v1/anything'),
      throwsA(isA<DioException>()),
    );
    // dio runs its interceptors on timers: let the fake clock move.
    await tester.pumpAndSettle();
    await call;
    // Today went with the gate: drift closes its query streams on a zero
    // timer, which moving the fake clock runs.
    await tester.pump(Duration.zero);

    _expectUpdateScreen();
  });

  testWidgets('Check again lifts the gate when the fresh config allows the '
      'version', (tester) async {
    final phone = TestPhone()
      ..adapter.respond = problem(ProblemTypes.upgradeRequired, 426);
    await pumpApp(tester, phone: phone);
    _expectUpdateScreen();

    // Still offline: nothing changes.
    phone.adapter.respond = offline;
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    _expectUpdateScreen();

    // Still too old: the gate stays.
    phone.adapter.respond = config('0.2.0');
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    _expectUpdateScreen();

    // The server lowered its minimum: back to the app.
    phone.adapter.respond = config('0.1.0');
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();
    _expectShell();
  });
}
