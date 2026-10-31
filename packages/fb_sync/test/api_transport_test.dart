import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fb_sync/fb_sync.dart';
import 'package:test/test.dart';

/// Answers every request with [status], [body] and [headers], or throws
/// [error] (a connection failure).
final class _Adapter implements HttpClientAdapter {
  new({
    this.status = 200,
    this.body = '{}',
    this.headers = const {},
    this.error,
  });

  final int status;
  final String body;
  final Map<String, List<String>> headers;
  final DioException? error;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    if (error != null) throw error!;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
        ...headers,
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

ApiSyncTransport _transport(_Adapter adapter) => ApiSyncTransport(
  Dio(BaseOptions(baseUrl: 'http://127.0.0.1'))..httpClientAdapter = adapter,
);

Future<SyncFailure> _failure(Future<void> Function() call) async {
  try {
    await call();
  } on SyncFailure catch (f) {
    return f;
  }
  fail('no SyncFailure');
}

void main() {
  group('ApiSyncTransport:', () {
    test('pull parses a page and sends the binding', () async {
      final adapter = _Adapter(
        body: jsonEncode({
          'changes': <Object>[],
          'nextCursor': '7',
          'datasetId': '00000000-0000-7000-8000-000000000777',
          'serverTime': '2026-10-30T00:00:00Z',
          'reason': null,
        }),
      );
      final page = await _transport(adapter).pull(
        cursor: '7',
        limit: 100,
        datasetId: '00000000-0000-7000-8000-000000000777',
      );
      expect(page.nextCursor, '7');
      expect(adapter.last!.uri.queryParameters, {
        'cursor': '7',
        'limit': '100',
        'datasetId': '00000000-0000-7000-8000-000000000777',
      });
    });

    test('HTTP failures map to fixed kinds, Retry-After is kept', () async {
      final cases = {
        401: SyncFailureKind.unauthorized,
        403: SyncFailureKind.forbidden,
        413: SyncFailureKind.payloadTooLarge,
        426: SyncFailureKind.upgradeRequired,
        429: SyncFailureKind.rateLimited,
        500: SyncFailureKind.server,
        503: SyncFailureKind.server,
        400: SyncFailureKind.protocol,
      };
      for (final MapEntry(key: status, value: kind) in cases.entries) {
        final failure = await _failure(
          () => _transport(
            _Adapter(
              status: status,
              headers: {
                'retry-after': ['30'],
              },
            ),
          ).push(const [], datasetId: null),
        );
        expect(failure.kind, kind, reason: '$status');
        if (status == 429) {
          expect(failure.retryAfter, const Duration(seconds: 30));
        }
      }
    });

    test(
      'connection failures are offline; an unreadable body is protocol',
      () async {
        final offline = await _failure(
          () => _transport(
            _Adapter(
              error: DioException.connectionError(
                requestOptions: RequestOptions(),
                reason: 'refused',
              ),
            ),
          ).pull(cursor: '0', limit: 1, datasetId: null),
        );
        expect(offline.kind, SyncFailureKind.offline);
        final garbled = await _failure(
          () =>
              _transport(_Adapter(body: '{"changes": 3}'))
                  .pull(cursor: '0', limit: 1, datasetId: null),
        );
        expect(garbled.kind, SyncFailureKind.protocol);
        expect('$garbled', 'SyncFailure(protocol)', reason: 'no content');
      },
    );
  });
}
