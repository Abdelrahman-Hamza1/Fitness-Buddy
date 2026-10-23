import 'package:dio/dio.dart';

/// TD-053: URI.port includes the effective default port for HTTP(S).
bool isApiOrigin(Uri uri, Uri api) =>
    uri.scheme.toLowerCase() == api.scheme.toLowerCase() &&
    uri.host.toLowerCase() == api.host.toLowerCase() &&
    uri.port == api.port;

/// These contract endpoints never carry a session bearer.
bool isPublicApiRequest(Uri uri) => const {
  '/v1/config',
  '/.well-known/jwks.json',
  '/v1/auth/anonymous',
  '/v1/auth/refresh',
  '/v1/auth/google',
  '/v1/auth/email/start',
  '/v1/auth/email/verify',
}.contains(uri.path);

/// Applies transport safety even on the independent auth Dio.
final class ApiBoundaryInterceptor extends Interceptor {
  /// Binds this transport to the configured API origin.
  new(this._api);

  final Uri _api;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // BaseOptions alone can be overridden by callers. Redirects bypass Dio's
    // interceptor chain and can forward credentials and install identifiers.
    options.followRedirects = false;
    if (!isApiOrigin(options.uri, _api) || isPublicApiRequest(options.uri)) {
      stripAuthorization(options);
    }
    handler.next(options);
  }
}

/// Header names are case-insensitive, including caller-supplied variants.
void stripAuthorization(RequestOptions options) {
  options.headers = {
    for (final entry in options.headers.entries)
      if (entry.key.toLowerCase() != 'authorization') entry.key: entry.value,
  };
}
