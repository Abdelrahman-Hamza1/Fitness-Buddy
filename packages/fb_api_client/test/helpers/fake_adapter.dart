import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A dio adapter that answers every request with one canned JSON response and
/// records the requests, so tests run the real retrofit + dio path offline.
class FakeAdapter implements HttpClientAdapter {
  /// Answers with [body] encoded as JSON, [statusCode] and [contentType].
  new({
    required this.body,
    this.statusCode = 200,
    this.contentType = 'application/json',
  });

  /// The response body, encoded with `jsonEncode`.
  final Object? body;

  /// The response status code.
  final int statusCode;

  /// The response `Content-Type`.
  final String contentType;

  /// Every request seen, oldest first.
  final List<RequestOptions> requests = [];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return ResponseBody.fromString(
      jsonEncode(body),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [contentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// A [Dio] that sends everything to [adapter].
Dio fakeDio(FakeAdapter adapter) =>
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter;

/// The client headers a dio interceptor sets (S03). Generated methods must not
/// take or send them (`skipped_parameters` in swagger_parser.yaml).
const clientHeaders = ['X-App-Version', 'X-Platform', 'X-Device-Id'];
