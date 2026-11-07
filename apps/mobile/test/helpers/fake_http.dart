import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Answers one request: a response, or a thrown [DioException].
typedef FakeResponder = FutureOr<ResponseBody> Function(RequestOptions request);

/// A dio transport for tests: records every request and answers through a
/// [FakeResponder] that the test can swap at any time. Starts offline.
final class FakeHttpAdapter implements HttpClientAdapter {
  /// Creates the adapter; [respond] defaults to [offline].
  new({FakeResponder? respond}) : respond = respond ?? offline;

  /// How the next requests are answered.
  FakeResponder respond;

  /// Every request seen, oldest first.
  final List<RequestOptions> requests = [];

  /// Called with every request before it is answered.
  void Function(RequestOptions request)? onRequest;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    onRequest?.call(options);
    // A responder that throws becomes a failed request.
    return Future.sync(() => respond(options));
  }

  @override
  void close({bool force = false}) {}
}

/// No network: the connection fails.
ResponseBody offline(RequestOptions request) =>
    throw DioException.connectionError(
      requestOptions: request,
      reason: 'offline (test)',
      // As dio raises it: the connection couldn't be opened.
      error: const SocketException('offline (test)'),
    );

/// The server doesn't answer in time.
ResponseBody timeout(RequestOptions request) =>
    throw DioException.receiveTimeout(
      timeout: const Duration(seconds: 15),
      requestOptions: request,
    );

/// A JSON answer: [body] with [status] and [contentType].
FakeResponder json(
  Object? body, {
  int status = 200,
  String contentType = 'application/json',
  Map<String, String> headers = const {},
}) =>
    (_) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [contentType],
        for (final MapEntry(:key, :value) in headers.entries) key: [value],
      },
    );

/// A problem+json answer (RFC 9457) with [type] and [status].
FakeResponder problem(
  String type,
  int status, {
  Map<String, Object?> extensions = const {},
  Map<String, String> headers = const {},
}) => json(
  {'type': type, 'title': 'Test problem', 'status': status, ...extensions},
  status: status,
  contentType: 'application/problem+json',
  headers: headers,
);

/// A `/v1/config` body with [minimumAppVersion] and empty flags/thresholds.
Map<String, Object?> configBody(String minimumAppVersion) => {
  'minimumAppVersion': minimumAppVersion,
  'featureFlags': <String, Object?>{},
  'thresholds': <String, Object?>{},
};

/// A successful `/v1/config` answer.
FakeResponder config(String minimumAppVersion) =>
    json(configBody(minimumAppVersion));

/// A Buddy turn round answered as `text/event-stream` (TD-125): the
/// [events] for the request's `turnId` and `round` (0 for a start), each
/// with its `{turnId}:{round}:{seq}` id. Synthetic only.
FakeResponder turnEvents(
  List<Map<String, Object?>> Function(String turnId, int round) events,
) => (request) {
  final body = request.data;
  final turnId = body is Map ? body['turnId'] as String? ?? '' : '';
  final round = body is Map ? body['round'] as int? ?? 0 : 0;
  final out = StringBuffer();
  for (final (seq, event) in events(turnId, round).indexed) {
    out.write('id: $turnId:$round:$seq\ndata: ${jsonEncode(event)}\n\n');
  }
  return ResponseBody.fromString(
    out.toString(),
    200,
    headers: {
      Headers.contentTypeHeader: ['text/event-stream'],
    },
  );
};

/// A turn that proposes each intent of interpretation [answer] (the A22
/// fixtures' shape) as its own card, then ends: the agent's fast path.
FakeResponder turnOf(Map<String, Object?> answer) => turnEvents(
  (turnId, round) => [
    {'type': 'step', 'code': 'searchingFoods'},
    for (final (i, intent) in (answer['intents']! as List<Object?>).indexed)
      {
        'type': 'proposal',
        'proposalId': '$turnId-p$i',
        'revision': 1,
        'replaces': null,
        'intent': intent,
      },
    {
      'type': 'done',
      'reason': 'answered',
      'usage': {'sends': 1, 'inputTokens': 0, 'outputTokens': 0},
    },
  ],
);
