import 'package:dio/dio.dart';
import 'package:fb_mobile/core/api/failure_mapper.dart';
import 'package:fb_mobile/core/errors/failure.dart';

/// Calls [onUpgradeRequired] when any response says this app version is
/// too old: a 426, or the `/errors/upgrade-required` problem type (S06 plan
/// D10, A1). The error still reaches the caller.
final class UpgradeRequiredInterceptor extends Interceptor {
  /// Creates the interceptor.
  new({required this.onUpgradeRequired});

  /// Trips the upgrade signal (`upgradeSignalProvider`); nothing else.
  final void Function() onUpgradeRequired;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.type == DioExceptionType.badResponse &&
        FailureMapper.fromDio(err) is UpgradeRequiredFailure) {
      onUpgradeRequired();
    }
    handler.next(err);
  }
}
