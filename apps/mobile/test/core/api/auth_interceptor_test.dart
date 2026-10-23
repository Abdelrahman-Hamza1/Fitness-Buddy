import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:fb_mobile/core/api/auth_interceptor.dart';
import 'package:fb_mobile/core/api/client_headers_interceptor.dart';
import 'package:fb_mobile/core/api/dio_factory.dart';
import 'package:fb_mobile/core/api/failure_mapper.dart';
import 'package:fb_mobile/core/api/upgrade_required_interceptor.dart';
import 'package:fb_mobile/core/errors/error_reporting.dart';
import 'package:fb_mobile/core/errors/failure.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../../helpers/fake_http.dart';
import '../session/session_fakes.dart';

final Uri _origin = Uri.parse('https://api.example.test');

Dio _client(
  Fixture f,
  HttpClientAdapter adapter, {
  Uri? origin,
  void Function()? upgrade,
}) {
  final base = origin ?? _origin;
  final dio = createApiDio(
    baseUrl: base,
    adapter: adapter,
    interceptors: [
      ClientHeadersInterceptor(
        apiBaseUrl: base,
        appVersion: () async => '1.2.3',
        deviceId: () async => 'synthetic-device',
      ),
      UpgradeRequiredInterceptor(onUpgradeRequired: upgrade ?? () {}),
    ],
  );
  dio.interceptors.add(
    AuthInterceptor(apiBaseUrl: base, dio: dio, session: () => f.service),
  );
  addTearDown(() => dio.close(force: true));
  return dio;
}

Future<void> _turns([int count = 30]) async {
  for (var i = 0; i < count; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

Matcher get _superseded => isA<DioException>().having(
  (e) => e.error,
  'session failure',
  isA<SessionFailure>().having(
    (e) => e.kind,
    'kind',
    SessionFailureKind.superseded,
  ),
);

void main() {
  for (final url in [
    'https://api.example.test/v1/me',
    'https://api.example.test:443/v1/me',
    'https://API.EXAMPLE.TEST/v1/me',
  ]) {
    test('Rule:TD-053-api-origin bearer on exact origin $url', () async {
      final f = Fixture();
      await f.service.startAfterFirstFrame();
      final adapter = FakeHttpAdapter(respond: json(null));
      await _client(f, adapter).get<void>(url);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer synthetic-access-1',
      );
    });
  }

  for (final url in [
    'http://api.example.test/v1/me',
    'https://api.example.test:444/v1/me',
    'https://sub.api.example.test/v1/me',
    'https://api.example.test.evil.test/v1/me',
    'https://foreign.test/v1/me',
  ]) {
    test('Rule:TD-053-api-origin foreign 401 strips bearer $url', () async {
      final f = Fixture();
      final adapter = FakeHttpAdapter(respond: json(null, status: 401));
      await expectLater(
        _client(f, adapter).get<void>(
          url,
          options: Options(
            headers: {'aUtHoRiZaTiOn': 'caller-secret'},
            followRedirects: true,
          ),
        ),
        throwsA(isA<DioException>()),
      );
      final request = adapter.requests.single;
      expect(
        request.headers.keys.map((e) => e.toLowerCase()),
        isNot(contains('authorization')),
      );
      expect(request.headers, isNot(contains(ClientHeaders.deviceId)));
      expect(request.followRedirects, isFalse);
      expect(f.auth.creates + f.auth.refreshes + f.secrets.reads, 0);
    });
  }

  for (final path in [
    '/v1/config',
    '/.well-known/jwks.json',
    '/v1/auth/anonymous',
    '/v1/auth/refresh',
    '/v1/auth/google',
    '/v1/auth/email/start',
    '/v1/auth/email/verify',
  ]) {
    test(
      'Rule:TD-053-api-origin public request never authenticates $path',
      () async {
        final f = Fixture();
        final adapter = FakeHttpAdapter(respond: json(null, status: 401));
        await expectLater(
          _client(f, adapter).post<void>(
            path,
            options: Options(headers: {'Authorization': 'caller-secret'}),
          ),
          throwsA(isA<DioException>()),
        );
        expect(
          adapter.requests.single.headers,
          isNot(contains('Authorization')),
        );
        expect(
          adapter.requests.single.headers[ClientHeaders.deviceId],
          'synthetic-device',
        );
        expect(f.auth.creates + f.auth.refreshes + f.secrets.reads, 0);
      },
    );
  }

  test(
    'AC-001 concurrent and delayed old-generation 401 join one rotation',
    () async {
      final f = Fixture();
      await f.service.startAfterFirstFrame();
      final delayed = Completer<ResponseBody>();
      final rotation = Completer<void>();
      f.auth.rotate = (_) async {
        await rotation.future;
        return tokens(suffix: '2');
      };
      final adapter = FakeHttpAdapter(
        respond: (r) {
          if (r.headers['Authorization'] == 'Bearer synthetic-access-2') {
            return json(null)(r);
          }
          if (r.path == '/delayed') return delayed.future;
          return json(null, status: 401)(r);
        },
      );
      final dio = _client(f, adapter);
      final late = dio.get<void>('/delayed');
      final requests = List.generate(10, (_) => dio.get<void>('/v1/me'));
      await _turns();
      expect(f.auth.refreshes, 1);
      rotation.complete();
      await Future.wait(requests);
      delayed.complete(json(null, status: 401)(RequestOptions()));
      await late;
      expect(f.auth.refreshes, 1);
      expect(adapter.requests, hasLength(22));
    },
  );

  test(
    'AC-001 replay preserves payload query options key and cancellation',
    () async {
      final f = Fixture();
      await f.service.startAfterFirstFrame();
      final adapter = FakeHttpAdapter();
      adapter.respond = (r) =>
          json(null, status: adapter.requests.length == 1 ? 401 : 200)(r);
      final token = CancelToken();
      final progress = <int>[];
      await _client(f, adapter).patch<void>(
        '/v1/item',
        data: {
          'text': ['synthetic-user-content'],
        },
        queryParameters: {'q': 'synthetic-query'},
        cancelToken: token,
        onSendProgress: (sent, _) => progress.add(sent),
        options: Options(
          headers: {'Idempotency-Key': 'synthetic-key'},
          extra: {'client': 'value'},
          followRedirects: true,
          receiveTimeout: const Duration(seconds: 123),
        ),
      );
      final first = adapter.requests.first;
      final retry = adapter.requests.last;
      expect(retry.method, 'PATCH');
      expect(retry.data, first.data);
      expect(retry.queryParameters, first.queryParameters);
      expect(retry.cancelToken, same(token));
      expect(retry.onSendProgress, same(first.onSendProgress));
      expect(retry.headers['Idempotency-Key'], 'synthetic-key');
      expect(retry.extra, {'client': 'value'});
      expect(retry.receiveTimeout, const Duration(seconds: 123));
      expect(retry.followRedirects, isFalse);
      expect(retry.headers[ClientHeaders.deviceId], 'synthetic-device');
    },
  );

  test('AC-001 mutable JSON is snapshotted before held 401', () async {
    final f = Fixture();
    await f.service.startAfterFirstFrame();
    final hold = Completer<ResponseBody>();
    final adapter = FakeHttpAdapter();
    adapter.respond = (r) =>
        adapter.requests.length == 1 ? hold.future : json(null)(r);
    final body = {
      'text': ['original'],
    };
    final request = _client(f, adapter).post<void>('/v1/item', data: body);
    await _turns();
    body['text']!.add('changed');
    hold.complete(json(null, status: 401)(RequestOptions()));
    await request;
    expect(adapter.requests.last.data, {
      'text': ['original'],
    });
  });

  test('AC-001 second 401 stops after one replay', () async {
    final f = Fixture();
    await f.service.startAfterFirstFrame();
    final adapter = FakeHttpAdapter(respond: json(null, status: 401));
    await expectLater(
      _client(f, adapter).get<void>('/v1/me'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(2));
    expect(f.auth.refreshes, 1);
  });

  for (final body in [
    Stream.value([1, 2]),
    FormData.fromMap({'text': 'synthetic'}),
  ]) {
    test(
      'Rule:04.5-session-rotation ${body.runtimeType} is never replayed',
      () async {
        final f = Fixture();
        await f.service.startAfterFirstFrame();
        final adapter = FakeHttpAdapter(respond: json(null, status: 401));
        await expectLater(
          _client(f, adapter).post<void>('/v1/item', data: body),
          throwsA(isA<DioException>()),
        );
        expect(adapter.requests, hasLength(1));
        expect(f.auth.refreshes, 0);
      },
    );
  }

  test(
    'AC-002 cancellation of one waiter leaves shared refresh alive',
    () async {
      final f = Fixture();
      await f.service.startAfterFirstFrame();
      final hold = Completer<void>();
      f.auth.rotate = (_) async {
        await hold.future;
        return tokens(suffix: '2');
      };
      final adapter = FakeHttpAdapter(
        respond: (r) => json(
          null,
          status: r.headers['Authorization'] == 'Bearer synthetic-access-1'
              ? 401
              : 200,
        )(r),
      );
      final dio = _client(f, adapter);
      final token = CancelToken();
      final cancelled = dio.get<void>('/cancel', cancelToken: token);
      final assertion = expectLater(
        cancelled,
        throwsA(
          isA<DioException>().having(
            (e) => e.type,
            'type',
            DioExceptionType.cancel,
          ),
        ),
      );
      final kept = dio.get<void>('/keep');
      await _turns();
      token.cancel();
      await assertion;
      expect(f.auth.refreshes, 1);
      hold.complete();
      await kept;
      expect(adapter.requests.where((r) => r.path == '/cancel'), hasLength(1));
      expect(adapter.requests.where((r) => r.path == '/keep'), hasLength(2));
    },
  );

  test('AC-002 guest replacement never receives original request', () async {
    final f = Fixture();
    await f.service.startAfterFirstFrame();
    f.auth.rotate = (_) async =>
        throw const AuthFailure(AuthFailureKind.unauthorized);
    f.auth.create = () async => tokens(id: 'replacement');
    final adapter = FakeHttpAdapter(respond: json(null, status: 401));
    await expectLater(
      _client(f, adapter).post<void>('/v1/paid', data: {'text': 'synthetic'}),
      throwsA(_superseded),
    );
    expect(adapter.requests, hasLength(1));
    expect(f.auth.creates, 2);
  });

  for (final sameAccount in [false, true]) {
    test(
      'AC-001 A33 acceptance fences delayed request sameAccount=$sameAccount',
      () async {
        final f = Fixture();
        await f.service.startAfterFirstFrame();
        final hold = Completer<ResponseBody>();
        final adapter = FakeHttpAdapter(respond: (_) => hold.future);
        final request = _client(f, adapter).get<void>('/v1/me');
        final assertion = expectLater(request, throwsA(_superseded));
        await _turns();
        await f.service.acceptAuthenticatedSession(
          tokens(
            id: sameAccount ? 'synthetic-guest' : 'registered',
            anonymous: false,
          ),
        );
        hold.complete(json(null, status: 401)(RequestOptions()));
        await assertion;
        expect(adapter.requests, hasLength(1));
        expect(f.auth.refreshes, 0);
      },
    );
  }

  test(
    'Rule:04.5-session-rotation interceptor respects shared cooldown',
    () async {
      final f = Fixture();
      await f.service.startAfterFirstFrame();
      f.auth.rotate = (_) async => throw const AuthFailure(
        AuthFailureKind.throttled,
        retryAt: Duration(seconds: 120),
      );
      final adapter = FakeHttpAdapter(respond: json(null, status: 401));
      final dio = _client(f, adapter);
      await expectLater(dio.get<void>('/v1/me'), throwsA(isA<DioException>()));
      for (var i = 0; i < 10; i++) {
        await expectLater(
          dio.get<void>('/v1/me'),
          throwsA(isA<DioException>()),
        );
        await dio.get<void>(
          '/v1/config',
          options: Options(validateStatus: (_) => true),
        );
      }
      expect(f.auth.refreshes, 1);
      expect(f.service.nextAttemptAt, const Duration(seconds: 120));
    },
  );

  for (final status in [403, 426, 429, 503]) {
    test(
      'AC-001 status $status retains FailureMapper and upgrade signalling',
      () async {
        final f = Fixture();
        await f.service.startAfterFirstFrame();
        var upgrades = 0;
        final adapter = FakeHttpAdapter(respond: json(null, status: status));
        try {
          await _client(
            f,
            adapter,
            upgrade: () => upgrades++,
          ).get<void>('/v1/me');
          fail('Expected HTTP failure');
        } on DioException catch (error) {
          final failure = FailureMapper.fromDio(error);
          expect(failure, switch (status) {
            403 => isA<ForbiddenFailure>(),
            426 => isA<UpgradeRequiredFailure>(),
            429 => isA<RateLimitedFailure>(),
            _ => isA<ServerFailure>(),
          });
        }
        expect(upgrades, status == 426 ? 1 : 0);
        expect(f.auth.refreshes, 0);
      },
    );
  }

  for (final fails in [false, true]) {
    test('Rule:09.4-no-content-logging interceptor sinks '
        'fails=$fails', () async {
      final f = Fixture();
      final printed = <String>[];
      final flutterErrors = <String>[];
      final original = FlutterError.onError;
      FlutterError.onError = (details) => flutterErrors.add(details.toString());
      addTearDown(() => FlutterError.onError = original);
      final options = SentryFlutterOptions();
      ErrorReporting.configure(
        options,
        dsn: 'https://key@sentry.example.test/1',
        environment: 'test',
        release: 'fb_mobile@test',
      );
      final sink = _EnvelopeSink(options);
      options.transport = sink;
      final hub = Hub(options);
      addTearDown(hub.close);
      await runZoned(
        () async {
          await f.service.startAfterFirstFrame();
          if (fails) {
            f.auth.rotate = (_) async =>
                throw StateError('synthetic-plugin-canary');
          }
          final adapter = FakeHttpAdapter(
            respond: (r) => json(
              {'text': 'synthetic-response-canary'},
              status: r.headers['Authorization'] == 'Bearer synthetic-access-1'
                  ? 401
                  : 200,
            )(r),
          );
          final dio = _client(f, adapter);
          try {
            await dio.post<void>(
              '/v1/item',
              data: {'text': 'synthetic-user-canary'},
            );
            expect(fails, isFalse);
          } on DioException catch (error) {
            expect(fails, isTrue);
            expect(error.toString(), isNot(contains('synthetic')));
            await hub.captureException(error);
          }
          // Exercise a raw request/response-bearing Dio error at the actual
          // telemetry boundary too; the serializer must not retain either body.
          await hub.captureException(
            DioException(
              requestOptions: adapter.requests.first,
              error: tokens(),
              message: 'synthetic-dio-canary',
              response: Response<Object?>(
                requestOptions: adapter.requests.first,
                data: {'text': 'synthetic-response-canary'},
              ),
            ),
          );
        },
        zoneSpecification: ZoneSpecification(
          print: (_, _, _, line) => printed.add(line),
        ),
      );
      expect(printed, isEmpty);
      expect(flutterErrors, isEmpty);
      expect(f.states.join(), isNot(contains('synthetic')));
      expect(sink.envelopes, isNotEmpty);
      expect(sink.envelopes.join(), isNot(contains('synthetic')));
    });
  }

  for (final phase in ['pending', 'pair']) {
    test(
      'Rule:04.5-session-rotation $phase barrier gates send and replay',
      () async {
        final f = Fixture();
        await f.service.startAfterFirstFrame();
        final barrier = Completer<void>();
        if (phase == 'pending') f.barrier.hold = barrier;
        f.auth.rotate = (_) async {
          if (phase == 'pair') f.barrier.hold = barrier;
          return tokens(suffix: '2');
        };
        final adapter = FakeHttpAdapter(
          respond: (r) => json(
            null,
            status: r.headers['Authorization'] == 'Bearer synthetic-access-1'
                ? 401
                : 200,
          )(r),
        );
        final request = _client(f, adapter).get<void>('/v1/me');
        await _turns();
        expect(adapter.requests, hasLength(1));
        expect(f.auth.refreshes, phase == 'pending' ? 0 : 1);
        barrier.complete();
        await request;
        expect(adapter.requests, hasLength(2));
      },
    );
  }

  test('AC-001 failed rotated-pair barrier prevents replay', () async {
    final f = Fixture();
    await f.service.startAfterFirstFrame();
    f.auth.rotate = (_) async {
      f.barrier.failAt = f.barrier.commits + 1;
      return tokens(suffix: '2');
    };
    final adapter = FakeHttpAdapter(respond: json(null, status: 401));
    await expectLater(
      _client(f, adapter).get<void>('/v1/me'),
      throwsA(
        isA<DioException>().having(
          (e) => e.error,
          'failure',
          isA<SessionFailure>().having(
            (e) => e.kind,
            'kind',
            SessionFailureKind.storage,
          ),
        ),
      ),
    );
    expect(adapter.requests, hasLength(1));
  });

  test('AC-001 cancellation after refresh prevents replay', () async {
    final f = Fixture();
    await f.service.startAfterFirstFrame();
    final token = CancelToken();
    f.auth.rotate = (_) async {
      token.cancel();
      return tokens(suffix: '2');
    };
    final adapter = FakeHttpAdapter(respond: json(null, status: 401));
    await expectLater(
      _client(f, adapter).get<void>('/v1/me', cancelToken: token),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.cancel,
        ),
      ),
    );
    await _turns();
    expect(adapter.requests, hasLength(1));
    expect(f.auth.refreshes, 1);
  });

  test('AC-001 A33 acceptance during rotation prevents replay', () async {
    final f = Fixture();
    await f.service.startAfterFirstFrame();
    final hold = Completer<void>();
    f.auth.rotate = (_) async {
      await hold.future;
      return tokens(suffix: '2');
    };
    final adapter = FakeHttpAdapter(respond: json(null, status: 401));
    final request = _client(f, adapter).get<void>('/v1/me');
    final assertion = expectLater(request, throwsA(_superseded));
    await _turns();
    await f.service.acceptAuthenticatedSession(
      tokens(id: 'registered', anonymous: false),
    );
    hold.complete();
    await assertion;
    expect(adapter.requests, hasLength(1));
  });

  test('Rule:TD-053-api-origin independent auth transport enforces '
      'caller redirect override', () async {
    final adapter = FakeHttpAdapter(respond: json(null));
    final dio = createApiDio(
      baseUrl: _origin,
      adapter: adapter,
      interceptors: [],
    );
    addTearDown(dio.close);
    await dio.post<void>(
      '/v1/auth/refresh',
      options: Options(
        followRedirects: true,
        headers: {'authorization': 'caller-secret'},
      ),
    );
    expect(adapter.requests.single.followRedirects, isFalse);
    expect(
      adapter.requests.single.headers.keys,
      isNot(contains('authorization')),
    );
  });

  for (final code in [301, 302, 303, 307, 308]) {
    test(
      'Rule:TD-053-api-origin socket $code redirects reach no second origin',
      () async {
        final f = Fixture();
        await f.service.startAfterFirstFrame();
        final source = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        final target = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => source.close(force: true));
        addTearDown(() => target.close(force: true));
        var destinationRequests = 0;
        var sourceRequests = 0;
        target.listen((r) {
          destinationRequests++;
          unawaited(r.response.close());
        });
        source.listen((r) {
          sourceRequests++;
          expect(r.headers.value('authorization'), startsWith('Bearer '));
          // Exercise initial requests and a replay reaching a redirect.
          r.response.statusCode = sourceRequests == 1 ? 401 : code;
          r.response.headers.set(
            'location',
            'http://127.0.0.1:${target.port}/target',
          );
          unawaited(r.response.close());
        });
        final dio = _client(
          f,
          IOHttpClientAdapter(
            createHttpClient: () => _RealHttp().createHttpClient(null),
          ),
          origin: Uri.parse('http://127.0.0.1:${source.port}'),
        );
        await expectLater(
          dio.get<void>('/v1/me', options: Options(followRedirects: true)),
          throwsA(isA<DioException>()),
        );
        await expectLater(
          dio.get<void>('/v1/me', options: Options(followRedirects: true)),
          throwsA(isA<DioException>()),
        );
        expect(sourceRequests, 3);
        expect(destinationRequests, 0);
      },
    );
  }
}

// Bypass Flutter's mock HttpClient only for the two loopback servers.
final class _RealHttp extends HttpOverrides;

final class _EnvelopeSink extends Transport {
  new(this.options);
  final SentryOptions options;
  final envelopes = <String>[];

  @override
  Future<SentryId?> send(SentryEnvelope envelope) async {
    final bytes = await envelope
        .envelopeStream(options)
        .expand((chunk) => chunk)
        .toList();
    envelopes.add(utf8.decode(bytes));
    return envelope.header.eventId;
  }
}
