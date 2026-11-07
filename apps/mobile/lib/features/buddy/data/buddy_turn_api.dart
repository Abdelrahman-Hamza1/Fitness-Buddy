import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/api/auth_interceptor.dart';
import 'package:fb_mobile/core/api/failure_mapper.dart';
import 'package:fb_mobile/core/errors/failure.dart';
import 'package:fb_mobile/features/buddy/data/sse_frame_reader.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_turn_api.g.dart';

/// One event of a round: the generated [event], its SSE [id] and the raw
/// JSON object it was decoded from (the proposal loader reads the raw
/// `intent`, so newer fields survive). Holds user content: never logged.
final class TurnFrame {
  /// A frame.
  const new({required this.id, required this.event, required this.raw});

  /// The SSE id (`{turnId}:{round}:{seq}`), or `null`.
  final String? id;

  /// The decoded event (`unrecognized` for an unknown type).
  final BuddyTurnEvent event;

  /// The event's JSON object.
  final Map<String, Object?> raw;

  @override
  String toString() => 'TurnFrame($id, ${event.runtimeType})';
}

/// Why a round's post was refused before any event (A66 D3). Codes only.
enum TurnRefusal {
  /// Never reached the server (no connection), or refused with 503 before
  /// any stream: the same request is posted again later, as the same
  /// attempt (AI-047, AI-153).
  pending,

  /// Sent, then lost (a reset, a timeout, a 5xx other than 503): the round
  /// may have started; recovered by the one retry with `priorAttempt`
  /// (06 §3.4).
  ambiguous,

  /// 429: today's limit.
  rateLimited,

  /// 409: the round already ran and was acknowledged.
  alreadyRan,

  /// Any other refusal (400/401/403/422/426…): never retried.
  rejected,
}

/// What posting a round gave.
sealed class TurnPost {
  const new _();
}

/// The round streams [frames] (in order; an error event of the stream is a
/// broken connection).
final class TurnStreaming extends TurnPost {
  /// Streaming.
  const new(this.frames) : super._();

  /// The round's events.
  final Stream<TurnFrame> frames;

  @override
  String toString() => 'TurnStreaming';
}

/// The post was refused as [refusal].
final class TurnRefused extends TurnPost {
  /// Refused.
  const new(this.refusal) : super._();

  /// Why.
  final TurnRefusal refusal;

  @override
  String toString() => 'TurnRefused(${refusal.name})';
}

/// The agent turn routes (TD-125) over the app dio's interceptors and
/// transport. The bodies and events are the generated contract types; the
/// generated retrofit methods can't stream, so the post is made here and
/// the stream framed by [SseFrameReader]. Nothing here logs: bodies, events
/// and errors can carry user text.
final class BuddyTurnApi {
  /// Calls through [dio] (the app's API dio).
  new(Dio dio) {
    _dio = dio.clone(
      options: dio.options.copyWith(receiveTimeout: idleTimeout),
      interceptors: Interceptors(),
    );
    _dio.interceptors.addAll([
      for (final i in dio.interceptors)
        if (i is AuthInterceptor) i.forDio(_dio) else i,
    ]);
  }

  /// The longest silence a stream may have (the server pings every 10 s).
  static const idleTimeout = Duration(seconds: 30);

  /// The start route (`startBuddyTurn`).
  static const startPath = '/v1/buddy/turns';

  /// The continue route (`continueBuddyTurn`).
  static const continuePath = '/v1/buddy/turns/continue';

  late final Dio _dio;

  /// Posts round 0 of turn [body].
  Future<TurnPost> start(Map<String, Object?> body, {CancelToken? cancel}) =>
      _post(startPath, body, cancel);

  /// Posts a continue round [body].
  Future<TurnPost> resume(Map<String, Object?> body, {CancelToken? cancel}) =>
      _post(continuePath, body, cancel);

  Future<TurnPost> _post(
    String path,
    Map<String, Object?> body,
    CancelToken? cancel,
  ) async {
    final turnId = body['turnId'];
    if (turnId is! String) return const TurnRefused(TurnRefusal.rejected);
    try {
      final response = await _dio.post<ResponseBody>(
        path,
        data: body,
        cancelToken: cancel,
        options: Options(
          responseType: ResponseType.stream,
          headers: {
            'Idempotency-Key': turnId,
            Headers.acceptHeader: 'text/event-stream',
          },
        ),
      );
      final stream = response.data?.stream;
      if (stream == null) return const TurnRefused(TurnRefusal.ambiguous);
      return TurnStreaming(frames(stream));
    } on DioException catch (error) {
      return TurnRefused(classify(error));
    }
  }

  /// The events of a `text/event-stream` [bytes] stream: each frame's data
  /// decoded as a generated [BuddyTurnEvent]; a frame that isn't a JSON
  /// object or doesn't decode is skipped (additive rule).
  static Stream<TurnFrame> frames(Stream<List<int>> bytes) async* {
    await for (final frame in const SseFrameReader().bind(bytes)) {
      final Object? decoded;
      try {
        decoded = jsonDecode(frame.data);
      } on FormatException {
        continue;
      }
      if (decoded is! Map<String, Object?>) continue;
      final BuddyTurnEvent event;
      try {
        event = BuddyTurnEvent.fromJson(decoded);
        // json_serializable reports a wrong shape as a TypeError or a
        // CheckedFromJsonException; either quotes the body: skipped.
        // ignore: avoid_catches_without_on_clauses
      } catch (_) {
        continue;
      }
      yield TurnFrame(id: frame.id, event: event, raw: decoded);
    }
  }

  /// The refusal class of a failed post (A66 D3).
  static TurnRefusal classify(DioException error) {
    switch (error.type) {
      // Proven connection establishment failures only (DNS, refused,
      // unreachable, connect timeout: dio raises them while opening the
      // connection, before a byte is sent). "Connection closed before full
      // header was received" is a connectionError too, but after sending:
      // ambiguous (A66 review 8).
      case DioExceptionType.connectionTimeout:
        return TurnRefusal.pending;
      case DioExceptionType.connectionError:
        return error.error is SocketException
            ? TurnRefusal.pending
            : TurnRefusal.ambiguous;
      // Sent, then lost: the round may have started (B25 handoff (b)).
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.cancel:
      case DioExceptionType.unknown:
      case DioExceptionType.transformTimeout:
        return TurnRefusal.ambiguous;
      case DioExceptionType.badCertificate:
        return TurnRefusal.rejected;
      case DioExceptionType.badResponse:
        break;
    }
    // Only clear pre-admission refusals keep the attempt: 503 before any
    // stream waits; 429, 409, 400/401/426 end; any other 5xx is ambiguous.
    return switch (FailureMapper.fromDio(error)) {
      ServerFailure(status: 503) => TurnRefusal.pending,
      ServerFailure() => TurnRefusal.ambiguous,
      OfflineFailure() => TurnRefusal.pending,
      TimeoutFailure() => TurnRefusal.ambiguous,
      RateLimitedFailure() => TurnRefusal.rateLimited,
      ConflictFailure() => TurnRefusal.alreadyRan,
      _ => TurnRefusal.rejected,
    };
  }

  @override
  String toString() => 'BuddyTurnApi';
}

/// The app's turn routes on the app dio.
@Riverpod(keepAlive: true)
BuddyTurnApi buddyTurnApi(Ref ref) => BuddyTurnApi(ref.watch(dioProvider));
