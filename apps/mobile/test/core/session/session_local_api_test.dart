import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/client_headers_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const defined = String.fromEnvironment('FB_LOCAL_IDENTITY_API');
  final base = defined.isNotEmpty
      ? defined
      : Platform.environment['FB_LOCAL_IDENTITY_API'] ?? '';
  test(
    'AC-002 local Identity issuance rotation reuse revokes family',
    () async {
      final dio =
          Dio(
              BaseOptions(
                baseUrl: base,
                followRedirects: false,
                // The server rejects requests without the app's client headers
                // (TD-053); the real app adds them in ClientHeadersInterceptor.
                headers: {
                  ClientHeaders.appVersion: _appVersion(),
                  ClientHeaders.platform: 'android',
                  ClientHeaders.deviceId:
                      '0192f000-0000-7000-8000-0000000000a2',
                },
              ),
            )
            // flutter_test_config installs a mock HttpClient for widget tests.
            ..httpClientAdapter = IOHttpClientAdapter(
              createHttpClient: () => _RealHttp().createHttpClient(null),
            );
      addTearDown(dio.close);
      final api = FbApi(dio);
      // Catch raw generated/parser/Dio exceptions so test failures cannot dump
      // request bodies or generated AuthTokens into the runner output.
      try {
        final first = await api.identity.createAnonymous();
        expect(first.isAnonymous, isTrue);
        expect(first.userId.isNotEmpty, isTrue);
        expect(first.expiresAt.isBefore(first.refreshExpiresAt), isTrue);
        dio.options.headers['Authorization'] = 'Bearer ${first.accessToken}';
        final me = await api.account.getMe();
        expect(me.userId == first.userId, isTrue);
        expect(me.isAnonymous, isTrue);
        dio.options.headers.remove('Authorization');
        final rotated = await api.identity.refreshSession(
          body: RefreshRequest(refreshToken: first.refreshToken),
        );
        expect(rotated.userId == first.userId, isTrue);
        expect(rotated.isAnonymous, isTrue);
        expect(rotated.expiresAt.isBefore(rotated.refreshExpiresAt), isTrue);
        expect(rotated.refreshExpiresAt == first.refreshExpiresAt, isTrue);
        expect(!rotated.expiresAt.isBefore(first.expiresAt), isTrue);
        dio.options.headers['Authorization'] = 'Bearer ${rotated.accessToken}';
        expect((await api.account.getMe()).userId == first.userId, isTrue);
        dio.options.headers.remove('Authorization');
        await _unauthorized(
          () => api.identity.refreshSession(
            body: RefreshRequest(refreshToken: first.refreshToken),
          ),
        );
        dio.options.headers['Authorization'] = 'Bearer ${rotated.accessToken}';
        await _unauthorized(api.account.getMe);
      } on DioException {
        fail('Local Identity transport failed (details suppressed)');
      } on FormatException {
        fail('Local Identity response malformed (details suppressed)');
      } on Object catch (error) {
        fail('Local Identity check failed (${error.runtimeType})');
      }
    },
    skip: base.isEmpty
        ? 'Set FB_LOCAL_IDENTITY_API for enabled Identity'
        : false,
    timeout: const Timeout(Duration(minutes: 1)),
  );
}

Future<void> _unauthorized(Future<Object?> Function() action) async {
  try {
    await action();
  } on DioException catch (error) {
    expect(error.response?.statusCode, 401);
    final data = error.response?.data;
    expect(data is Map && data['type'] == '/errors/unauthorized', isTrue);
    return;
  }
  fail('Expected unauthorized');
}

final class _RealHttp extends HttpOverrides;

/// The app's own version (the server answers 426 below its minimum).
String _appVersion() {
  final line = File('pubspec.yaml')
      .readAsLinesSync()
      .firstWhere((l) => l.startsWith('version:'));
  return line.substring('version:'.length).trim().split('+').first;
}
