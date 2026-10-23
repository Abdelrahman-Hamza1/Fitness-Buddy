import 'package:dio/dio.dart';
import 'package:fb_mobile/core/api/api_origin.dart';

/// Only a successful response from our exact origin is a reachability signal.
/// Installed on normal Dio, never on auth Dio (which would self-wake).
final class SessionReachabilityInterceptor extends Interceptor {
  /// The success callback is lazy. Constructing public config transport
  /// starts no auth.
  new({required Uri apiBaseUrl, required this._onSuccess}) : _api = apiBaseUrl;

  final Uri _api;
  final void Function() _onSuccess;

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final status = response.statusCode;
    if (status != null &&
        status >= 200 &&
        status < 300 &&
        isApiOrigin(response.requestOptions.uri, _api)) {
      _onSuccess();
    }
    handler.next(response);
  }
}
