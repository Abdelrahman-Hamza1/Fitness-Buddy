import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fb_mobile/core/api/api_origin.dart';
import 'package:fb_mobile/core/session/session_service.dart';

/// Origin-bound bearer attachment and one same-account, reproducible replay.
/// Auth uses a separate Dio; cancellation of a waiter never cancels rotation.
final class AuthInterceptor extends Interceptor {
  /// The lazy callback keeps public config/JWKS independent of sessions.
  new({required Uri apiBaseUrl, required this._dio, required this._session})
    : _api = apiBaseUrl;

  final Uri _api;
  final Dio _dio;

  /// The same session and origin, replaying a refreshed request on [dio]: a
  /// clone with extra interceptors (Buddy's raw answers, A22) gets its own,
  /// so the replay passes through those interceptors too.
  AuthInterceptor forDio(Dio dio) =>
      AuthInterceptor(apiBaseUrl: _api, dio: dio, session: _session);

  final SessionService Function() _session;
  // Private metadata cannot be forged via caller extras or leak in diagnostics.
  final _attempts = Expando<_Attempt>();

  bool _protected(RequestOptions options) =>
      isApiOrigin(options.uri, _api) && !isPublicApiRequest(options.uri);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.followRedirects = false;
    stripAuthorization(options);
    if (!_protected(options)) {
      handler.next(options);
      return;
    }
    try {
      _cancelled(options);
      final previous = _attempts[options];
      final service = _session();
      final lease = previous != null
          ? previous.lease
          : await _wait(service.ensureAvailable(), options);
      _cancelled(options);
      if (!service.isCurrentLease(lease)) {
        throw const SessionFailure(SessionFailureKind.superseded);
      }
      _attempts[options] = previous ?? _Attempt(lease, _snapshot(options.data));
      options.headers['Authorization'] = 'Bearer ${lease.bearer}';
      handler.next(options);
    } on DioException catch (error) {
      handler.reject(error);
    } on SessionFailure catch (error) {
      handler.reject(DioException(requestOptions: options, error: error));
    }
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final attempt = _attempts[options];
    if (err.response?.statusCode != 401 ||
        !_protected(options) ||
        attempt == null ||
        attempt.replayed ||
        !attempt.body.reproducible ||
        options.requestEncoder != null) {
      handler.next(err);
      return;
    }
    try {
      _cancelled(options);
      final service = _session();
      if (!service.ownsLease(attempt.lease)) {
        throw const SessionFailure(SessionFailureKind.superseded);
      }
      final lease = await _wait(
        service.refreshIfCurrent(attempt.lease.generation),
        options,
      );
      _cancelled(options);
      if (!service.ownsLease(attempt.lease) ||
          lease.accountReference != attempt.lease.accountReference ||
          !service.isCurrentLease(lease)) {
        throw const SessionFailure(SessionFailureKind.superseded);
      }
      final retry = options.copyWith(
        data: attempt.body.value,
        headers: Map.of(options.headers),
        extra: Map.of(options.extra),
        followRedirects: false,
      );
      _attempts[retry] = _Attempt(lease, attempt.body, replayed: true);
      handler.resolve(await _dio.fetch<Object?>(retry));
    } on DioException catch (failure) {
      handler.next(failure);
    } on SessionFailure catch (failure) {
      handler.next(DioException(requestOptions: options, error: failure));
    }
  }

  void _cancelled(RequestOptions options) {
    final error = options.cancelToken?.cancelError;
    if (error != null) throw error;
  }

  Future<T> _wait<T>(Future<T> future, RequestOptions options) async {
    final token = options.cancelToken;
    if (token == null) return await future;
    return await Future.any([
      future,
      token.whenCancel.then<T>((error) => throw error),
    ]);
  }
}

final class _Attempt {
  new(this.lease, this.body, {this.replayed = false});
  final SessionLease lease;
  final _Body body;
  final bool replayed;

  @override
  String toString() => 'AuthAttempt(redacted)';
}

final class _Body {
  const new(this.value, {this.reproducible = true});
  final Object? value;
  final bool reproducible;
}

// Snapshot before dispatch: mutable JSON must not change under a held 401.
// Unknown encoders, streams and multipart objects have no safe replay contract.
_Body _snapshot(Object? value) {
  if (value == null || value is String || value is num || value is bool) {
    return _Body(value);
  }
  if (value is Uint8List) return _Body(Uint8List.fromList(value));
  if (value is List) {
    final entries = value.map(_snapshot).toList();
    return _Body(
      entries.map((entry) => entry.value).toList(),
      reproducible: entries.every((entry) => entry.reproducible),
    );
  }
  if (value is Map<String, dynamic>) {
    final entries = value.map((key, value) => MapEntry(key, _snapshot(value)));
    return _Body(
      entries.map((key, value) => MapEntry(key, value.value)),
      reproducible: entries.values.every((entry) => entry.reproducible),
    );
  }
  return const _Body(null, reproducible: false);
}
