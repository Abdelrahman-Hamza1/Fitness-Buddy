import 'dart:math';

import 'package:dio/dio.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/api/client_headers_interceptor.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../helpers/fake_http.dart';
import '../../helpers/test_phone.dart';

/// One app start on [phone]: a fresh container (disposed after the test).
ProviderContainer _start(TestPhone phone) =>
    ProviderContainer.test(overrides: phone.overrides());

/// Calls `GET /v1/config` through the app's client and returns the request.
Future<RequestOptions> _getConfig(
  TestPhone phone,
  ProviderContainer app,
) async {
  await app.read(fbApiProvider).account.getConfig();
  return phone.adapter.requests.last;
}

/// A fixed clock for the id generator.
final class _FixedClock implements Clock {
  @override
  DateTime nowUtc() => DateTime.utc(2026, 10, 13, 12);

  @override
  int offsetMinutesAt(DateTime utc) => 0;
}

void main() {
  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.android);
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('ClientHeadersInterceptor sets X-App-Version, X-Platform and '
      'X-Device-Id (uuid), and no X-Request-Id', () async {
    final phone = TestPhone(appVersion: '1.4.2')
      ..adapter.respond = config('0.0.0');
    final app = _start(phone);

    final first = await _getConfig(phone, app);
    final second = await _getConfig(phone, app);

    for (final request in [first, second]) {
      expect(request.headers[ClientHeaders.appVersion], '1.4.2');
      expect(request.headers[ClientHeaders.platform], 'android');
      expect(
        isUuidV7(request.headers[ClientHeaders.deviceId] as String),
        isTrue,
      );
      // A4: request correlation isn't in the contract (S03 decides).
      expect(
        request.headers.keys.map((k) => k.toLowerCase()),
        isNot(contains('x-request-id')),
      );
    }
    expect(
      second.headers[ClientHeaders.deviceId],
      first.headers[ClientHeaders.deviceId],
    );
  });

  test('client headers go only to the API origin: a foreign host, scheme or '
      'port gets none', () async {
    final phone = TestPhone()..adapter.respond = config('0.0.0');
    final app = _start(phone);
    final dio = app.read(dioProvider);

    for (final foreign in [
      'https://evil.example.test/v1/config',
      'https://127.0.0.1:5198/v1/config',
      'http://127.0.0.1:9999/v1/config',
      'http://localhost:5198/v1/config',
    ]) {
      await dio.get<void>(foreign);
      final headers = phone.adapter.requests.last.headers.keys
          .map((k) => k.toLowerCase())
          .toSet();
      for (final header in [
        ClientHeaders.appVersion,
        ClientHeaders.platform,
        ClientHeaders.deviceId,
      ]) {
        expect(headers, isNot(contains(header.toLowerCase())), reason: foreign);
      }
    }
    // Not even looked up (or created) for a foreign request.
    expect(
      await phone.storedPreferences(),
      isNot(contains(PreferenceKeys.deviceId)),
    );
    // The API itself still gets them.
    await dio.get<void>('http://127.0.0.1:5198/v1/config');
    expect(
      phone.adapter.requests.last.headers,
      contains(ClientHeaders.deviceId),
    );
    expect(await phone.storedPreferences(), contains(PreferenceKeys.deviceId));
  });

  test('X-Platform follows the platform: ios on iOS, left out elsewhere', () {
    expect(ClientHeaders.platformValue(TargetPlatform.android), 'android');
    expect(ClientHeaders.platformValue(TargetPlatform.iOS), 'ios');
    for (final other in [
      TargetPlatform.fuchsia,
      TargetPlatform.linux,
      TargetPlatform.macOS,
      TargetPlatform.windows,
    ]) {
      expect(ClientHeaders.platformValue(other), isNull, reason: '$other');
    }
  });

  test('device id is created once and reused after a restart', () async {
    final phone = TestPhone()..adapter.respond = config('0.0.0');

    final firstRun = _start(phone);
    final id = (await _getConfig(
      phone,
      firstRun,
    )).headers[ClientHeaders.deviceId];
    firstRun.dispose();
    final secondRun = _start(phone);
    final again = (await _getConfig(
      phone,
      secondRun,
    )).headers[ClientHeaders.deviceId];

    expect(again, id);
    expect(
      await phone.storedPreferences(),
      containsPair(PreferenceKeys.deviceId, id),
    );
  });

  test(
    'TD-053 device id: concurrent first lookups share one id; a stored id that '
    'is not a UUID is replaced',
    () async {
      final store = InMemorySharedPreferencesAsync.withData({
        PreferenceKeys.deviceId: 'not-a-uuid',
      });
      SharedPreferencesAsyncPlatform.instance = store;
      final ids = UuidV7Generator(_FixedClock(), Random(1));
      final deviceIds = DeviceIdStore(SharedPreferencesAsync(), ids);

      final results = await Future.wait([
        deviceIds.deviceId(),
        deviceIds.deviceId(),
      ]);

      expect(results[0], results[1]);
      expect(isUuidV7(results[0]), isTrue);
      expect(
        await SharedPreferencesAsync().getString(PreferenceKeys.deviceId),
        results[0],
      );
    },
  );

  test('a request whose headers cannot be looked up is not sent', () async {
    final phone = TestPhone()
      ..adapter.respond = config('0.0.0')
      ..preferencesBroken = true;
    final app = _start(phone);

    await expectLater(
      app.read(fbApiProvider).account.getConfig(),
      throwsA(isA<DioException>()),
    );
    expect(phone.adapter.requests, isEmpty);
  });

  test('the API client never follows a redirect: a 302 fails and nothing is '
      'sent to its target', () async {
    final phone = TestPhone()
      ..adapter.respond = json(
        null,
        status: 302,
        headers: {'location': 'https://elsewhere.example/v1/config'},
      );
    final app = _start(phone);

    expect(app.read(dioProvider).options.followRedirects, isFalse);
    await expectLater(
      app.read(fbApiProvider).account.getConfig(),
      throwsA(isA<DioException>()),
    );
    expect(phone.adapter.requests, hasLength(1));
    expect(phone.adapter.requests.single.followRedirects, isFalse);
  });
}
