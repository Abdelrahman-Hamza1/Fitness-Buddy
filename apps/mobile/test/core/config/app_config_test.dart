import 'dart:convert';
import 'dart:io';

import 'package:fb_mobile/core/config/app_config.dart';
import 'package:flutter_test/flutter_test.dart';

/// The flavor config files, by flavor name (`config/<flavor>.json`).
Map<String, Map<String, String>> _configFiles() => {
  for (final flavor in AppFlavor.values)
    flavor.name: (jsonDecode(
      File('config/${flavor.name}.json').readAsStringSync(),
    ) as Map<String, Object?>).cast<String, String>(),
};

const Map<String, String> _valid = {
  AppConfig.flavorKey: 'staging',
  AppConfig.apiBaseUrlKey: 'https://api.example.test',
  AppConfig.sentryDsnKey: 'https://key@o123.ingest.de.sentry.io/1',
};

void main() {
  group('AppConfig reads every key; each config JSON has all keys; '
      'staging/prod URLs are https', () {
    test('reads every key', () {
      final config = AppConfig.fromDefines(_valid);

      expect(config.flavor, AppFlavor.staging);
      expect(config.apiBaseUrl, Uri.parse('https://api.example.test'));
      expect(config.sentryDsn, 'https://key@o123.ingest.de.sentry.io/1');
      expect(AppConfig.keys, _valid.keys.toSet());
    });

    test('each config JSON has all keys, its own flavor and parses', () {
      for (final MapEntry(key: name, value: defines)
          in _configFiles().entries) {
        expect(defines.keys.toSet(), AppConfig.keys, reason: name);
        final config = AppConfig.fromDefines(defines);
        expect(config.flavor.name, name);
        // No Sentry project yet (A11): reporting is off in every flavor.
        expect(config.sentryDsn, isEmpty, reason: name);
      }
    });

    test('staging/prod URLs are https; the dev URL is loopback', () {
      final files = _configFiles();
      for (final name in ['staging', 'prod']) {
        final url = AppConfig.fromDefines(files[name]!).apiBaseUrl;
        expect(url.scheme, 'https', reason: name);
      }
      // Cleartext is allowed only to the local API (S06 plan D6, A8).
      final dev = AppConfig.fromDefines(files['dev']!).apiBaseUrl;
      expect(InternetAddress.tryParse(dev.host)?.isLoopback, isTrue);
    });
  });

  test('PR-11 DSN shape: EU ingest accepted, US/http/garbage rejected in '
      'staging/prod, empty = off', () {
    for (final flavor in ['staging', 'prod']) {
      for (final dsn in ['', 'https://key@o123.ingest.de.sentry.io/1']) {
        expect(
          AppConfig.fromDefines({
            ..._valid,
            AppConfig.flavorKey: flavor,
            AppConfig.sentryDsnKey: dsn,
          }).sentryDsn,
          dsn,
        );
      }
      for (final dsn in [
        'https://key@o123.ingest.us.sentry.io/1',
        'http://key@o123.ingest.de.sentry.io/1',
        'garbage',
        'https://key:password@o123.ingest.de.sentry.io/1',
        'https://key@o123.ingest.de.sentry.io/1?x=1',
      ]) {
        expect(
          () => AppConfig.fromDefines({
            ..._valid,
            AppConfig.flavorKey: flavor,
            AppConfig.sentryDsnKey: dsn,
          }),
          throwsA(isA<AppConfigException>()),
        );
      }
    }
  });

  test(
    'AC-041-style privacy: AppConfig/DSN errors never contain the value',
    () {
      for (final key in AppConfig.keys) {
        for (final value in [
          'PRIVATE_CANARY',
          'https://u:PRIVATE_CANARY@host/path',
          'https://host/?q=PRIVATE_CANARY',
          'https://host/#PRIVATE_CANARY',
        ]) {
          try {
            AppConfig.fromDefines({..._valid, key: value});
            fail('invalid configuration accepted');
          } on AppConfigException catch (error) {
            expect(error.toString(), contains(key));
            expect(error.toString(), isNot(contains(value)));
            expect(error.toString(), isNot(contains('PRIVATE_CANARY')));
          }
        }
      }
    },
  );

  group('AppConfig rejects', () {
    void expectRejected(Map<String, String> defines, String mentions) => expect(
      () => AppConfig.fromDefines(defines),
      throwsA(
        isA<AppConfigException>().having(
          (e) => e.message,
          'message',
          contains(mentions),
        ),
      ),
    );

    test('a missing or empty flavor or URL', () {
      for (final key in [AppConfig.flavorKey, AppConfig.apiBaseUrlKey]) {
        expectRejected({..._valid}..remove(key), key);
        expectRejected({..._valid, key: ''}, key);
      }
    });

    test('an unknown flavor', () {
      expectRejected({
        ..._valid,
        AppConfig.flavorKey: 'qa',
      }, AppConfig.flavorKey);
    });

    test('a URL that is not absolute http(s)', () {
      for (final url in ['api.example.test', 'ftp://x.test', 'https://']) {
        expectRejected({
          ..._valid,
          AppConfig.apiBaseUrlKey: url,
        }, AppConfig.apiBaseUrlKey);
      }
    });

    test('a missing Sentry DSN key (empty is allowed)', () {
      expectRejected(
        {..._valid}..remove(AppConfig.sentryDsnKey),
        AppConfig.sentryDsnKey,
      );
      expect(
        AppConfig.fromDefines({..._valid, AppConfig.sentryDsnKey: ''})
            .sentryDsn,
        isEmpty,
      );
    });

    test('staging/prod with an http URL (https only outside dev)', () {
      for (final flavor in ['staging', 'prod']) {
        expectRejected({
          ..._valid,
          AppConfig.flavorKey: flavor,
          AppConfig.apiBaseUrlKey: 'http://api.example.test',
        }, 'must be https in the $flavor flavor');
      }
      expect(
        AppConfig.fromDefines({
          ..._valid,
          AppConfig.flavorKey: 'dev',
          AppConfig.apiBaseUrlKey: 'http://127.0.0.1:5198',
        }).apiBaseUrl.scheme,
        'http',
      );
    });

    test('a missing key is reported as missing, an empty one as empty', () {
      expectRejected({..._valid}..remove(AppConfig.flavorKey), 'missing');
      expectRejected({..._valid, AppConfig.apiBaseUrlKey: ''}, 'empty');
    });

    test('a build without --dart-define-from-file reports the keys as '
        'missing', () {
      // `flutter test` passes no defines.
      expect(
        AppConfig.fromEnvironment,
        throwsA(
          isA<AppConfigException>().having(
            (e) => e.message,
            'message',
            contains('${AppConfig.flavorKey} is missing'),
          ),
        ),
      );
    });

    test('definedOnly drops undefined keys and keeps empty ones', () {
      final defines = AppConfig.definedOnly({
        AppConfig.flavorKey: 'dev',
        AppConfig.apiBaseUrlKey: null,
        AppConfig.sentryDsnKey: '',
      });

      expect(defines, {AppConfig.flavorKey: 'dev', AppConfig.sentryDsnKey: ''});
      expectRejected(defines, '${AppConfig.apiBaseUrlKey} is missing');
      expectRejected(
        AppConfig.definedOnly({
          AppConfig.flavorKey: 'dev',
          AppConfig.apiBaseUrlKey: 'http://127.0.0.1:5198',
          AppConfig.sentryDsnKey: null,
        }),
        '${AppConfig.sentryDsnKey} is missing',
      );
    });
  });
}
