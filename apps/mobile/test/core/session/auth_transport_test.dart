import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/dio_factory.dart';
import 'package:fb_mobile/core/api/problem_types.dart';
import 'package:fb_mobile/core/api/upgrade_required_interceptor.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:flutter_test/flutter_test.dart';

import 'session_fakes.dart';

final class AuthAdapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  int status = 200;
  Object? body;
  String? retryAfter;
  DioExceptionType? error;
  int closes = 0;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (error case final type?) {
      throw DioException(
        requestOptions: options,
        type: type,
        error: 'synthetic-content-canary',
      );
    }
    return ResponseBody.fromString(
      jsonEncode(body ?? tokens().toJson()),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        if (retryAfter != null) 'retry-after': [retryAfter!],
      },
    );
  }

  @override
  void close({bool force = false}) => closes++;
}

void main() {
  late FakeClock clock;
  late AuthAdapter adapter;
  late GeneratedAuthTransport auth;
  late Dio dio;
  var upgrade = false;

  setUp(() {
    clock = FakeClock();
    adapter = AuthAdapter();
    upgrade = false;
    dio = createApiDio(
      baseUrl: Uri.parse('https://api.example.test'),
      adapter: adapter,
      interceptors: [
        UpgradeRequiredInterceptor(onUpgradeRequired: () => upgrade = true),
      ],
    );
    auth = GeneratedAuthTransport(FbApi(dio), clock);
  });
  tearDown(() => dio.close());

  test(
    'AC-002 generated anonymous and refresh requests use existing contract',
    () async {
      await auth.createAnonymous();
      await auth.refresh('synthetic-refresh-canary');
      expect(adapter.requests.map((r) => r.path), [
        '/v1/auth/anonymous',
        '/v1/auth/refresh',
      ]);
      expect(
        adapter.requests.every(
          (r) =>
              r.method == 'POST' &&
              !r.followRedirects &&
              !r.headers.containsKey('Authorization'),
        ),
        isTrue,
      );
      expect(adapter.requests.first.data, isNull);
      expect(adapter.requests.last.data, {
        'refreshToken': 'synthetic-refresh-canary',
      });
    },
  );

  for (final (status, body, kind) in <(int, Object, AuthFailureKind)>[
    (401, {'type': ProblemTypes.unauthorized}, AuthFailureKind.unauthorized),
    (401, {'type': 'unknown'}, AuthFailureKind.retryable),
    (401, 'synthetic-content-canary', AuthFailureKind.retryable),
    (503, {'detail': 'synthetic-content-canary'}, AuthFailureKind.retryable),
    (429, {'type': ProblemTypes.rateLimited}, AuthFailureKind.throttled),
    (429, {'type': 'unknown'}, AuthFailureKind.retryable),
    (400, {'type': ProblemTypes.validationFailed}, AuthFailureKind.rejected),
    (403, {'type': ProblemTypes.forbidden}, AuthFailureKind.rejected),
    (409, {'type': ProblemTypes.identityConflict}, AuthFailureKind.rejected),
    (
      426,
      {'type': ProblemTypes.upgradeRequired},
      AuthFailureKind.upgradeRequired,
    ),
  ]) {
    test(
      'Rule:04.5-session-rotation $status $body maps to fixed $kind',
      () async {
        adapter
          ..status = status
          ..body = body;
        await expectLater(
          auth.refresh('synthetic-refresh-canary'),
          throwsA(
            isA<AuthFailure>()
                .having((e) => e.kind, 'kind', kind)
                .having(
                  (e) => e.toString(),
                  'redacted',
                  isNot(contains('canary')),
                ),
          ),
        );
        expect(adapter.requests, hasLength(1));
        expect(upgrade, status == 426);
      },
    );
  }

  for (final type in [
    DioExceptionType.connectionError,
    DioExceptionType.sendTimeout,
    DioExceptionType.receiveTimeout,
    DioExceptionType.connectionTimeout,
  ]) {
    test('OF-01 $type has no automatic auth replay or raw error', () async {
      adapter.error = type;
      await expectLater(
        auth.refresh('synthetic-refresh-canary'),
        throwsA(
          isA<AuthFailure>()
              .having((e) => e.kind, 'kind', AuthFailureKind.retryable)
              .having(
                (e) => e.refreshNotConsumed,
                'dispatch proof',
                type == DioExceptionType.connectionTimeout,
              ),
        ),
      );
      expect(adapter.requests, hasLength(1));
    });
  }

  for (final raw in ['180', 'invalid', '-1', '']) {
    test('Rule:04.5-session-rotation Retry-After "$raw" conversion', () async {
      clock.elapsed = const Duration(seconds: 10);
      adapter
        ..status = 429
        ..body = {'type': ProblemTypes.rateLimited}
        ..retryAfter = raw;
      await expectLater(
        auth.createAnonymous(),
        throwsA(
          isA<AuthFailure>().having(
            (e) => e.retryAt,
            'floor',
            raw == '180' ? const Duration(seconds: 190) : null,
          ),
        ),
      );
    });
  }

  test(
    'Rule:04.5-session-rotation HTTP-date converts once to monotonic deadline',
    () async {
      clock.elapsed = const Duration(seconds: 20);
      adapter
        ..status = 429
        ..body = {'type': ProblemTypes.rateLimited}
        ..retryAfter = HttpDate.format(
          clock.wallNow.add(const Duration(seconds: 240)),
        );
      AuthFailure? result;
      try {
        await auth.createAnonymous();
      } on AuthFailure catch (error) {
        result = error;
      }
      clock.wallNow = clock.wallNow.subtract(const Duration(days: 90));
      expect(result!.retryAt, const Duration(seconds: 260));
    },
  );

  test(
    'Rule:09.4-no-content-logging malformed generated body never escapes',
    () async {
      adapter.body = {
        'accessToken': 'synthetic-access-canary',
        'userText': 'synthetic-content-canary',
      };
      final printed = <String>[];
      await runZoned(
        () async {
          await expectLater(
            auth.createAnonymous(),
            throwsA(
              isA<AuthFailure>().having(
                (e) => e.toString(),
                'redacted',
                isNot(contains('canary')),
              ),
            ),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );
      expect(printed, isEmpty);
    },
  );
}
