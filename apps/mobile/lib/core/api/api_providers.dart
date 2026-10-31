import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/auth_interceptor.dart';
import 'package:fb_mobile/core/api/client_headers_interceptor.dart';
import 'package:fb_mobile/core/api/dio_factory.dart';
import 'package:fb_mobile/core/api/request_guard.dart';
import 'package:fb_mobile/core/api/session_reachability_interceptor.dart';
import 'package:fb_mobile/core/api/upgrade_required_interceptor.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_providers.g.dart';

/// The HTTP transport under [dio]: the platform's client. Tests override it
/// with a fake adapter. Creating it opens no connection.
@Riverpod(keepAlive: true)
HttpClientAdapter httpClientAdapter(Ref ref) => HttpClientAdapter();

/// The [Dio] every API call goes through (S06 plan D8, A1): the flavor's
/// base URL, the timeouts, the client headers and the upgrade signal.
///
/// Only `core/` and `data/` folders use it; screens never do (A3).
@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final baseUrl = ref.watch(appConfigProvider).apiBaseUrl;
  final dio = createApiDio(
    baseUrl: baseUrl,
    adapter: ref.watch(httpClientAdapterProvider),
    interceptors: [
      ClientHeadersInterceptor(
        apiBaseUrl: baseUrl,
        appVersion: () async =>
            (await ref.read(packageInfoProvider.future)).version,
        deviceId: () => ref.read(deviceIdStoreProvider).deviceId(),
      ),
      // Only trips the signal; the client config listens to it and
      // refreshes (core/config depends on core/api, not the reverse).
      UpgradeRequiredInterceptor(
        onUpgradeRequired: () =>
            ref.read(upgradeSignalProvider.notifier).trip(),
      ),
    ],
  );
  dio.interceptors.add(
    AuthInterceptor(
      apiBaseUrl: baseUrl,
      dio: dio,
      session: () => ref.read(sessionServiceProvider),
    ),
  );
  // A34 D12, A35: after the bearer is attached, refuse a guarded request
  // (sync run, account deletion) whose profile is no longer current.
  dio.interceptors.add(const RequestGuardInterceptor());
  dio.interceptors.add(
    SessionReachabilityInterceptor(
      apiBaseUrl: baseUrl,
      onSuccess: ref.read(sessionTransportSucceededProvider),
    ),
  );
  ref.onDispose(dio.close);
  return dio;
}

/// The generated API client (`fb_api_client`) on [dio].
@Riverpod(keepAlive: true)
FbApi fbApi(Ref ref) => FbApi(ref.watch(dioProvider));
