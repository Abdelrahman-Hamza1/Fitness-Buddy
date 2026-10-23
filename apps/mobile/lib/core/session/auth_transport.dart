import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/problem_types.dart';
import 'package:fb_mobile/core/session/session_clock.dart';

/// Fixed outcomes; no underlying credential-bearing diagnostics escape.
enum AuthFailureKind {
  /// Invalid/expired/reused refresh, as determined by the server.
  unauthorized,

  /// Connection, timeout, server failure or unknown response.
  retryable,

  /// Verified pre-handler throttling; the refresh was not consumed.
  throttled,

  /// Validation/forbidden/conflict: stop automatic attempts.
  rejected,

  /// The app needs an update.
  upgradeRequired,
}

/// Redacted auth outcome with a monotonic throttling floor.
final class AuthFailure implements Exception {
  /// Contains no response body, headers, request or cause.
  const new(this.kind, {this.retryAt, this.refreshNotConsumed = false});

  /// Safe diagnostic category.
  final AuthFailureKind kind;

  /// True only with proof the Identity handler could not consume the token.
  final bool refreshNotConsumed;

  /// Retry-After converted once at response receipt; never capped.
  final Duration? retryAt;

  @override
  String toString() => 'AuthFailure(${kind.name})';
}

/// Core-only transport. Generated tokens must never enter provider state.
abstract interface class AuthTransport {
  /// Creates an identity; no automatic transport replay.
  Future<AuthTokens> createAnonymous();

  /// Sends this rotating credential exactly once.
  Future<AuthTokens> refresh(String refreshToken);
}

/// Adapter over the existing generated contract, on an independent auth Dio.
final class GeneratedAuthTransport implements AuthTransport {
  /// The client must have no bearer/refresh interceptor or logging interceptor.
  const new(this._api, this._clock);

  final FbApi _api;
  final SessionClock _clock;

  @override
  Future<AuthTokens> createAnonymous() =>
      _send(() => _api.identity.createAnonymous());

  @override
  Future<AuthTokens> refresh(String refreshToken) => _send(
    () => _api.identity.refreshSession(
      body: RefreshRequest(refreshToken: refreshToken),
    ),
  );

  Future<AuthTokens> _send(Future<AuthTokens> Function() call) async {
    try {
      return await call();
    } on DioException catch (error) {
      final response = error.response;
      final data = response?.data;
      final type = data is Map ? data['type'] : null;
      final status = response?.statusCode;
      final kind = switch ((status, type)) {
        (401, ProblemTypes.unauthorized) => AuthFailureKind.unauthorized,
        (429, ProblemTypes.rateLimited) => AuthFailureKind.throttled,
        (426, _) => AuthFailureKind.upgradeRequired,
        (400, ProblemTypes.validationFailed) ||
        (403, ProblemTypes.forbidden) ||
        (409, ProblemTypes.identityConflict) => AuthFailureKind.rejected,
        _ => AuthFailureKind.retryable,
      };
      throw AuthFailure(
        kind,
        retryAt: _retryAt(_singleRetryAfter(response?.headers)),
        // Dio's connection timeout/TLS rejection occurs before HTTP dispatch.
        // A generic SocketException can occur after dispatch and is ambiguous.
        refreshNotConsumed:
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.badCertificate,
      );
    } on Object {
      // Includes malformed generated response parsing and header-source errors.
      throw const AuthFailure(AuthFailureKind.retryable);
    }
  }

  String? _singleRetryAfter(Headers? headers) {
    final values = headers?['retry-after'];
    return values?.length == 1 ? values!.single : null;
  }

  Duration? _retryAt(String? raw) {
    if (raw == null) return null;
    final seconds = int.tryParse(raw.trim());
    Duration delay;
    if (seconds != null && seconds >= 0) {
      delay = Duration(seconds: seconds);
    } else {
      try {
        delay = HttpDate.parse(raw).difference(_clock.wallNow);
      } on Object {
        return null;
      }
    }
    return _clock.elapsed + (delay.isNegative ? Duration.zero : delay);
  }
}
