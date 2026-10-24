import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fb_mobile/app/app.dart';
import 'package:fb_mobile/app/bootstrap/app_bootstrap.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/catalog/catalog.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../core/session/session_fakes.dart';
import '../helpers/fake_http.dart';
import '../helpers/pump_app.dart';

void main() {
  for (final hung in ['Sentry', 'config', 'auth', 'all']) {
    testWidgets('UX-001 AC-002 post-frame isolation: hung $hung leaves '
        'Today and independent startup usable', (tester) async {
      final f = Fixture();
      final phone = TestPhone();
      final sentry = Completer<void>();
      final auth = Completer<void>();
      final configResponse = Completer<ResponseBody>();
      final catalog = Completer<List<int>>();
      var sentryStarts = 0;
      var catalogStarts = 0;
      f.auth.create = () async {
        if (hung == 'auth' || hung == 'all') await auth.future;
        return tokens();
      };
      phone.adapter.respond = (request) {
        if (hung == 'config' || hung == 'all') return configResponse.future;
        return config('0.0.0')(request);
      };
      final container = ProviderContainer.test(
        overrides: [
          ...phone.overrides(),
          ...todayOverrides(),
          secureSessionStoreProvider.overrideWithValue(f.store),
          authTransportProvider.overrideWithValue(f.auth),
          sessionClockProvider.overrideWithValue(f.clock),
          catalogPackInstallerProvider.overrideWithValue(
            CatalogPackInstaller(
              root: () async => throw StateError('unused root'),
              loadAsset: (_) {
                catalogStarts++;
                return catalog.future;
              },
            ),
          ),
          errorReportingProvider.overrideWithValue(
            ErrorReporting(
              config: AppConfig(
                flavor: AppFlavor.dev,
                apiBaseUrl: phone.config.apiBaseUrl,
                sentryDsn: 'https://public@example.test/1',
              ),
              packageInfo: () async => PackageInfo(
                appName: 'test',
                packageName: 'test',
                version: '1.0.0',
                buildNumber: '1',
              ),
              start: (_) async {
                sentryStarts++;
                if (hung == 'Sentry' || hung == 'all') await sentry.future;
              },
            ),
          ),
        ],
      );
      // Registered before the root widget's own post-frame callback. The
      // actual Today has been laid out when this runs, with zero deferred I/O.
      var firstFrame = false;
      tester.binding.addPostFrameCallback((_) {
        firstFrame = true;
        expect(find.byType(TodayScreen), findsOneWidget);
        expect(f.secrets.reads, 0);
        expect(f.auth.creates, 0);
        expect(phone.events, isEmpty);
        expect(sentryStarts, 0);
        expect(catalogStarts, 0);
        expect(container.exists(sessionServiceProvider), isFalse);
        expect(container.exists(sessionLifecycleProvider), isFalse);
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const FitnessBuddyApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(firstFrame, isTrue);
      expect(sentryStarts, 1);
      expect(catalogStarts, 1);
      expect(f.secrets.reads, greaterThan(0));
      expect(f.auth.creates, 1);
      expect(phone.adapter.requests.single.path, '/v1/config');
      if (hung != 'config' && hung != 'all') {
        expect(container.read(clientConfigProvider).minimumAppVersion, '0.0.0');
        expect(phone.events, contains('prefs set fb.client_config.v1'));
      }
      if (hung != 'auth' && hung != 'all') {
        expect(
          container.read(sessionStateProvider).readiness,
          SessionReadiness.ready,
        );
      }
      // Starting twice cannot duplicate SDK, config, catalog or auth work.
      await container.read(appBootstrapProvider).afterFirstFrame();
      expect(sentryStarts, 1);
      expect(catalogStarts, 1);
      expect(f.auth.creates, 1);
      await tester.tap(find.text('Me'));
      await tester.pumpAndSettle();
      expect(find.text('Your foods'), findsOneWidget);
      await tester.tap(find.text('Today'));
      await tester.pumpAndSettle();
      expect(find.byType(TodayScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      container.dispose();
      sentry.complete();
      auth.complete();
      configResponse.complete(await config('0.0.0')(RequestOptions()));
      // Leave the optional catalog asset held: disposal must not await it.
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('UX-001 AC-002 synchronous deferred-provider failures stay '
      'contained and leave offline Today usable', (tester) async {
    final f = Fixture();
    final started = <String>[];
    Never fail(String task) {
      started.add(task);
      throw StateError('synthetic failure');
    }

    await pumpApp(
      tester,
      overrides: [
        secureSessionStoreProvider.overrideWithValue(f.store),
        errorReportingProvider.overrideWith((_) => fail('Sentry')),
        catalogPackInstallerProvider.overrideWith((_) => fail('catalog')),
        clientConfigRepositoryProvider.overrideWith((_) => fail('config')),
        authTransportProvider.overrideWith((_) => fail('auth')),
      ],
    );
    expect(started, containsAll(['Sentry', 'catalog', 'config', 'auth']));
    expect(find.byType(TodayScreen), findsOneWidget);
    await tester.tap(find.text('Me'));
    await tester.pumpAndSettle();
    expect(find.text('Your foods'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('AC-002 successful public transport before bootstrap cannot '
      'instantiate sessions or read secure storage', (tester) async {
    final f = Fixture();
    final phone = TestPhone()..adapter.respond = config('0.0.0');
    final container = ProviderContainer.test(
      overrides: [
        ...phone.overrides(),
        secureSessionStoreProvider.overrideWithValue(f.store),
        authTransportProvider.overrideWithValue(f.auth),
      ],
    );
    final result = container.read(dioProvider).get<Object?>('/v1/config');
    await tester.pumpAndSettle();
    await result;
    expect(container.exists(sessionLifecycleProvider), isFalse);
    expect(container.exists(sessionServiceProvider), isFalse);
    expect(f.secrets.reads, 0);
    expect(f.auth.creates, 0);
  });
}
