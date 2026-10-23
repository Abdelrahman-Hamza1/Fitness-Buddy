import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/api/problem_types.dart';
import 'package:fb_mobile/core/config/client_config.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/config/update_gate.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/test_phone.dart';
import '../session/session_fakes.dart';

/// One app start on [phone] (disposed after the test).
ProviderContainer _start(TestPhone phone) =>
    ProviderContainer.test(overrides: phone.overrides());

// Resource-response tests need a ready session now that the API is protected.
Future<ProviderContainer> _startAuthenticated(TestPhone phone) async {
  final f = Fixture();
  await f.service.startAfterFirstFrame();
  return ProviderContainer.test(
    overrides: [
      ...phone.overrides(),
      sessionServiceProvider.overrideWithValue(f.service),
    ],
  );
}

/// The update gate once the installed version is known.
Future<bool> _updateRequired(ProviderContainer app) => app
    .read(packageInfoProvider.future)
    .then((_) => app.read(updateRequiredProvider));

/// The failures a `/v1/config` fetch can meet.
final Map<String, FakeResponder> _failures = {
  'offline': offline,
  'timeout': timeout,
  '500': problem('https://tools.ietf.org/html/rfc9110#section-15.6.1', 500),
  '426': problem(ProblemTypes.upgradeRequired, 426),
  'not JSON': (_) => ResponseBody.fromString('<html>', 502),
  'malformed body': json({'minimumAppVersion': 1}),
};

void main() {
  group('client config', () {
    test('UX-001 starts from the defaults without any I/O', () {
      final phone = TestPhone();
      final app = _start(phone);

      expect(app.read(clientConfigProvider), ClientConfigRepository.defaults);
      expect(app.read(updateRequiredProvider), isFalse);
      expect(phone.events, isEmpty);
    });

    test('fresh config is cached and read back on the next launch', () async {
      final phone = TestPhone()..adapter.respond = config('0.0.7');
      final firstRun = _start(phone);

      expect(
        await firstRun.read(clientConfigProvider.notifier).refresh(),
        isTrue,
      );
      expect(firstRun.read(clientConfigProvider).minimumAppVersion, '0.0.7');
      expect(
        await phone.storedPreferences(),
        contains(PreferenceKeys.clientConfig),
      );
      firstRun.dispose();

      // Next launch, offline: the cache is used.
      phone.adapter.respond = offline;
      final secondRun = _start(phone);
      expect(
        secondRun.read(clientConfigProvider),
        ClientConfigRepository.defaults,
        reason: 'nothing is read before refresh()',
      );
      expect(
        await secondRun.read(clientConfigProvider.notifier).refresh(),
        isFalse,
      );
      expect(secondRun.read(clientConfigProvider).minimumAppVersion, '0.0.7');
    });

    for (final MapEntry(key: name, value: failure) in _failures.entries) {
      test(
        'config fetch failure ($name) keeps the defaults, or the cache',
        () async {
          final phone = TestPhone()..adapter.respond = failure;
          final noCache = _start(phone);
          expect(
            await noCache.read(clientConfigProvider.notifier).refresh(),
            isFalse,
          );
          expect(
            noCache.read(clientConfigProvider),
            ClientConfigRepository.defaults,
          );
          noCache.dispose();

          final cached = TestPhone()..adapter.respond = failure;
          await cached.seedPreference(
            PreferenceKeys.clientConfig,
            '{"minimumAppVersion":"0.0.3","featureFlags":{"buddy":true},'
            '"thresholds":{}}',
          );
          final app = _start(cached);
          expect(
            await app.read(clientConfigProvider.notifier).refresh(),
            isFalse,
          );
          expect(app.read(clientConfigProvider).minimumAppVersion, '0.0.3');
          expect(app.read(clientConfigProvider).featureFlags, {'buddy': true});
        },
      );
    }

    test('a corrupt cache is ignored and replaced by the next fetch', () async {
      final phone = TestPhone()..adapter.respond = offline;
      await phone.seedPreference(PreferenceKeys.clientConfig, '{"broken');
      final app = _start(phone);

      await app.read(clientConfigProvider.notifier).refresh();
      expect(app.read(clientConfigProvider), ClientConfigRepository.defaults);

      phone.adapter.respond = config('0.0.9');
      await app.read(clientConfigProvider.notifier).refresh();
      expect(app.read(clientConfigProvider).minimumAppVersion, '0.0.9');
      expect(
        (await phone.storedPreferences())[PreferenceKeys.clientConfig],
        contains('0.0.9'),
      );
    });

    test('a refresh while one is in flight joins it', () async {
      final answer = Completer<ResponseBody>();
      final phone = TestPhone()..adapter.respond = (_) => answer.future;
      final app = _start(phone);
      final notifier = app.read(clientConfigProvider.notifier);

      final first = notifier.refresh();
      final second = notifier.refresh();
      await pumpEventQueue();
      answer.complete(config('0.0.1')(RequestOptions()) as ResponseBody);

      expect(await Future.wait([first, second]), [true, true]);
      expect(phone.adapter.requests, hasLength(1));
      // Done: the next call fetches again.
      phone.adapter.respond = config('0.0.2');
      expect(await notifier.refresh(), isTrue);
      expect(phone.adapter.requests, hasLength(2));
    });
  });

  group('update gate', () {
    test('minimumAppVersion above the app version gates; equal or below '
        "doesn't", () async {
      for (final (minimum, gated) in [
        ('0.1.1', true),
        ('0.2.0', true),
        ('1.0.0', true),
        ('0.1.0', false),
        ('0.0.9', false),
        ('0.0.0', false),
      ]) {
        final phone = TestPhone()..adapter.respond = config(minimum);
        final app = _start(phone);
        await app.read(clientConfigProvider.notifier).refresh();

        expect(await _updateRequired(app), gated, reason: minimum);
      }
    });

    test(
      'malformed versions fail open (A8): the own version or the minimum',
      () async {
        for (final (installed, minimum) in [
          ('0.1.0-dev', '9.9.9'),
          ('', '9.9.9'),
          ('0.1', '9.9.9'),
          ('0.1.0', '9.9'),
          ('0.1.0', 'latest'),
        ]) {
          final phone = TestPhone(appVersion: installed)
            ..adapter.respond = config(minimum);
          final app = _start(phone);
          await app.read(clientConfigProvider.notifier).refresh();

          expect(
            await _updateRequired(app),
            isFalse,
            reason:
                '$installed '
                'vs $minimum',
          );
        }
      },
    );

    test('the default minimum (0.0.0) never reads the package info', () {
      final phone = TestPhone();
      final app = _start(phone);

      expect(app.read(updateRequiredProvider), isFalse);
      expect(phone.events, isNot(contains('package info')));
    });

    test(
      '426 from any request trips the gate and refreshes the config',
      () async {
        final phone = TestPhone();
        phone.adapter.respond = (request) => request.path == '/v1/config'
            ? config('0.2.0')(request)
            : problem(ProblemTypes.upgradeRequired, 426)(request);
        final app = await _startAuthenticated(phone);

        await expectLater(
          app.read(dioProvider).get<void>('/v1/anything'),
          throwsA(isA<DioException>()),
        );
        expect(app.read(upgradeSignalProvider), isTrue);
        expect(app.read(updateRequiredProvider), isTrue);
        await pumpEventQueue();
        // The refresh cached the new minimum, so the next start is gated too.
        expect(phone.adapter.requests.map((r) => r.path), [
          '/v1/anything',
          '/v1/config',
        ]);
        expect(app.read(clientConfigProvider).minimumAppVersion, '0.2.0');
      },
    );

    test('the config refreshes when the signal trips (core/api only trips '
        'it); clearing the signal fetches nothing', () async {
      final phone = TestPhone()..adapter.respond = config('0.0.0');
      // The config is alive before the trip, as in the app.
      final app = (await _startAuthenticated(phone))
        ..read(clientConfigProvider);

      phone.adapter.respond = (request) => request.path == '/v1/config'
          ? config('0.3.0')(request)
          : problem(ProblemTypes.upgradeRequired, 426)(request);
      await expectLater(
        app.read(dioProvider).get<void>('/v1/anything'),
        throwsA(isA<DioException>()),
      );
      await pumpEventQueue();
      expect(phone.adapter.requests.map((r) => r.path), [
        '/v1/anything',
        '/v1/config',
      ]);
      expect(app.read(clientConfigProvider).minimumAppVersion, '0.3.0');

      app.read(upgradeSignalProvider.notifier).clear();
      await pumpEventQueue();
      expect(phone.adapter.requests, hasLength(2));
    });

    test('a 426 without a problem body trips the gate', () async {
      final phone = TestPhone()
        ..adapter.respond = (_) => ResponseBody.fromString('', 426);
      final app = await _startAuthenticated(phone);

      await expectLater(
        app.read(dioProvider).get<void>('/v1/anything'),
        throwsA(isA<DioException>()),
      );
      expect(app.read(upgradeSignalProvider), isTrue);
    });

    test('problem type /errors/upgrade-required trips the gate', () async {
      final phone = TestPhone()
        // The type decides, whatever the status.
        ..adapter.respond = problem(ProblemTypes.upgradeRequired, 400);
      final app = await _startAuthenticated(phone);

      await expectLater(
        app.read(dioProvider).get<void>('/v1/anything'),
        throwsA(isA<DioException>()),
      );
      expect(app.read(upgradeSignalProvider), isTrue);
    });

    test('/v1/config itself answering 426 trips the gate without a refresh '
        'loop', () async {
      final phone = TestPhone()
        ..adapter.respond = problem(ProblemTypes.upgradeRequired, 426);
      final app = _start(phone);

      expect(await app.read(clientConfigProvider.notifier).refresh(), isFalse);
      await pumpEventQueue();

      expect(app.read(updateRequiredProvider), isTrue);
      expect(phone.adapter.requests, hasLength(1));
    });

    test('other errors do not trip the gate', () async {
      for (final failure in [
        offline,
        timeout,
        problem(ProblemTypes.rateLimited, 429),
        problem(ProblemTypes.validationFailed, 400),
        problem('about:blank', 404),
        json({'error': 'x'}, status: 500),
      ]) {
        final phone = TestPhone()..adapter.respond = failure;
        final app = await _startAuthenticated(phone);

        await expectLater(
          app.read(dioProvider).get<void>('/v1/anything'),
          throwsA(isA<DioException>()),
        );
        expect(app.read(upgradeSignalProvider), isFalse);
      }
    });
  });
}
