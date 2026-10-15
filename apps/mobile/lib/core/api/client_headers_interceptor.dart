import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// The client headers every `/v1/` request carries (`contracts/README.md`,
/// "Headers"; `contracts/openapi/components/headers.yaml`).
abstract final class ClientHeaders {
  /// The installed app version, `MAJOR.MINOR.PATCH`.
  static const appVersion = 'X-App-Version';

  /// `android` or `ios`.
  static const platform = 'X-Platform';

  /// The install's UUID (`DeviceIdStore`).
  static const deviceId = 'X-Device-Id';

  /// The `X-Platform` value for [platform]; null for platforms the API
  /// doesn't serve (the header is then left out and the server rejects the
  /// request).
  static String? platformValue(TargetPlatform platform) => switch (platform) {
    TargetPlatform.android => 'android',
    TargetPlatform.iOS => 'ios',
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => null,
  };
}

/// Sets the [ClientHeaders] on every request to the API (S06 plan D8, A4:
/// no `X-Request-Id`, it is not in the contract).
///
/// Only requests to the API's own origin (the scheme, host and port of
/// `apiBaseUrl`) get them: the install's device id never goes to another
/// host, even if a request on this client names a full foreign URL.
///
/// The version and the device id are looked up on the first request and
/// memoised by their sources, so the startup path never waits for them.
final class ClientHeadersInterceptor extends Interceptor {
  /// Creates the interceptor for the API at `apiBaseUrl`; `appVersion` and
  /// `deviceId` give the values.
  new({
    required Uri apiBaseUrl,
    required this._appVersion,
    required this._deviceId,
  }) : _api = apiBaseUrl;

  final Uri _api;
  final Future<String> Function() _appVersion;
  final Future<String> Function() _deviceId;

  /// Whether [uri] is on the API's origin (scheme, host and port).
  bool isApiOrigin(Uri uri) =>
      uri.scheme.toLowerCase() == _api.scheme.toLowerCase() &&
      uri.host.toLowerCase() == _api.host.toLowerCase() &&
      uri.port == _api.port;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!isApiOrigin(options.uri)) {
      handler.next(options);
      return;
    }
    try {
      final version = await _appVersion();
      final deviceId = await _deviceId();
      final platform = ClientHeaders.platformValue(defaultTargetPlatform);
      options.headers.addAll({
        ClientHeaders.appVersion: version,
        ClientHeaders.platform: ?platform,
        ClientHeaders.deviceId: deviceId,
      });
      handler.next(options);
    } on Object catch (error, stackTrace) {
      // A request without its headers would only be rejected by the server.
      handler.reject(
        DioException(
          requestOptions: options,
          error: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }
}
