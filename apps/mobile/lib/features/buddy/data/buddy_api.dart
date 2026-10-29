import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/api/auth_interceptor.dart';
import 'package:fb_mobile/core/api/failure_mapper.dart';
import 'package:fb_mobile/core/errors/failure.dart';
import 'package:fb_mobile/features/buddy/data/interpret_request_builder.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_api.g.dart';

/// Why an interpret call failed (A22 D6, PA3), as the closed set the send
/// path acts on. Codes only, never the response.
enum BuddySendFailure {
  /// No connection: retry with the same request.
  offline,

  /// No answer in time: retry with the same request.
  timeout,

  /// A server error other than 503: retry with the same request.
  server,

  /// 503 (an attempt in flight or the provider unavailable): retry once
  /// with the same request; a second 503 stops retrying.
  unavailable,

  /// 400, 409 or any other refusal (incl. 401/426 the interceptors couldn't
  /// recover): never retried; search is offered.
  rejected,

  /// 429, today's limit: never retried.
  rateLimited;

  /// Whether Try again replays the same request.
  bool get retryable => switch (this) {
    offline || timeout || server || unavailable => true,
    rejected || rateLimited => false,
  };
}

/// What an interpret call gave.
sealed class BuddyInterpretResult {
  const new _();
}

/// A contract-valid answer, as the plain JSON the proposal loader reads.
/// Holds user content: never logged.
final class BuddyInterpreted extends BuddyInterpretResult {
  /// The answer [json].
  const new(this.json) : super._();

  /// The raw answer object (a deep copy), validated by the generated
  /// `BuddyInterpretation` but never round-tripped through it.
  final Map<String, Object?> json;

  @override
  String toString() => 'BuddyInterpreted(redacted)';
}

/// A 200 whose body isn't a contract-valid interpretation.
final class BuddyUnusableReply extends BuddyInterpretResult {
  /// The fixed outcome; the parse error is dropped (it can quote the body).
  const new() : super._();

  @override
  String toString() => 'BuddyUnusableReply';
}

/// The call failed with [failure].
final class BuddyInterpretFailed extends BuddyInterpretResult {
  /// Failed as [failure].
  const new(this.failure) : super._();

  /// Why.
  final BuddySendFailure failure;

  @override
  String toString() => 'BuddyInterpretFailed(${failure.name})';
}

/// The interpret endpoint over the generated client (A22 D6).
///
/// Buddy calls wait up to [receiveTimeout] for the answer (B08's provider
/// deadline plus repair), overriding the 15 s every other endpoint uses; the
/// clone shares the app dio's interceptors (auth, client headers, upgrade)
/// and transport. Nothing here logs: requests, answers and errors can carry
/// user text.
final class BuddyApi {
  /// Calls through [dio] (the app's API dio).
  new(Dio dio) {
    final clone = dio.clone(
      options: dio.options.copyWith(receiveTimeout: receiveTimeout),
      interceptors: Interceptors(),
    );
    // The auth interceptor replays a refreshed request (401 → refresh) on
    // the dio it holds; bound to the clone, the replay's answer passes
    // through [_RawAnswers] too (A22a review).
    clone.interceptors
      ..addAll([
        for (final i in dio.interceptors)
          if (i is AuthInterceptor) i.forDio(clone) else i,
      ])
      ..add(_RawAnswers(_raw));
    _client = BuddyClient(clone);
  }

  /// The Buddy-only receive timeout.
  static const receiveTimeout = Duration(seconds: 45);

  late final BuddyClient _client;

  /// The raw answer bodies by Idempotency-Key, until [interpret] takes them.
  final Map<String, Map<String, Object?>> _raw = {};

  /// Sends [request] with its `requestId` as the Idempotency-Key, so a
  /// retry of the same prepared request is replayed by the server, never
  /// charged twice.
  Future<BuddyInterpretResult> interpret(PreparedInterpret request) async {
    try {
      // The generated model checks the contract; the decoder reads the raw
      // map, never a round-tripped model (an unrecognized intent would
      // serialize as `{kind}` only, and newer fields would be dropped).
      await _client.interpretMessage(
        idempotencyKey: request.requestId,
        body: request.body,
      );
      final raw = _raw.remove(request.requestId);
      return raw == null ? const BuddyUnusableReply() : BuddyInterpreted(raw);
    } on DioException catch (error) {
      // A body dio couldn't even type as an object (dio wraps the cast's
      // TypeError) is a reply that can't become a card, not a transport
      // failure.
      if (error.type == DioExceptionType.unknown && error.error is TypeError) {
        return const BuddyUnusableReply();
      }
      return BuddyInterpretFailed(_classify(FailureMapper.fromDio(error)));
    } on Exception {
      // json_serializable's CheckedFromJsonException quotes the body.
      return const BuddyUnusableReply();
      // A body of the wrong shape surfaces as TypeError: same fixed outcome.
      // ignore: avoid_catching_errors
    } on TypeError {
      return const BuddyUnusableReply();
    } finally {
      // Nothing of a failed answer stays behind.
      _raw.remove(request.requestId);
    }
  }

  static BuddySendFailure _classify(Failure failure) => switch (failure) {
    OfflineFailure() => BuddySendFailure.offline,
    TimeoutFailure() => BuddySendFailure.timeout,
    ServerFailure(status: 503) => BuddySendFailure.unavailable,
    ServerFailure() => BuddySendFailure.server,
    RateLimitedFailure() => BuddySendFailure.rateLimited,
    InvalidInputFailure() ||
    ConflictFailure() ||
    NotFoundFailure() ||
    UnauthorizedFailure() ||
    ForbiddenFailure() ||
    UpgradeRequiredFailure() ||
    UnexpectedFailure() => BuddySendFailure.rejected,
  };

  @override
  String toString() => 'BuddyApi';
}

/// Keeps each interpret answer's raw JSON object (a deep copy) for
/// [BuddyApi.interpret], keyed by its Idempotency-Key.
final class _RawAnswers extends Interceptor {
  new(this._raw);

  final Map<String, Map<String, Object?>> _raw;

  @override
  void onResponse(
    Response<Object?> response,
    ResponseInterceptorHandler handler,
  ) {
    final key = response.requestOptions.headers['Idempotency-Key'];
    final data = response.data;
    if (key is String && data is Map<String, Object?>) {
      _raw[key] = jsonDecode(jsonEncode(data)) as Map<String, Object?>;
    }
    handler.next(response);
  }
}

/// The app's interpret endpoint on the app dio.
@Riverpod(keepAlive: true)
BuddyApi buddyApi(Ref ref) => BuddyApi(ref.watch(dioProvider));
