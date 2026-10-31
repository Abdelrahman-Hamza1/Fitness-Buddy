import 'dart:async';

import 'package:dio/dio.dart';

/// The zone key holding a guarded request's check.
final Object _guardKey = Object();

/// Runs [call] so that each request it makes is refused by
/// [RequestGuardInterceptor] unless [valid] still holds **after** the auth
/// interceptor attached the bearer (A34 D12, A35 fix 2): a sync run or an
/// account deletion started for one profile never sends with the
/// credentials of another.
Future<T> runGuarded<T>(bool Function() valid, Future<T> Function() call) =>
    runZoned(call, zoneValues: {_guardKey: valid});

/// Refuses a guarded request whose check failed (a `cancel` error, nothing
/// sent). Added to the shared Dio after `AuthInterceptor`; requests outside
/// [runGuarded] pass untouched.
final class RequestGuardInterceptor extends Interceptor {
  /// The interceptor.
  const new();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final guard = Zone.current[_guardKey];
    if (guard is bool Function() && !guard()) {
      handler.reject(
        DioException(requestOptions: options, type: DioExceptionType.cancel),
      );
      return;
    }
    handler.next(options);
  }
}
