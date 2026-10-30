import 'package:dio/dio.dart';
import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/client_headers_interceptor.dart';
import 'package:fb_mobile/core/api/dio_factory.dart';
import 'package:fb_mobile/core/api/upgrade_required_interceptor.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:fb_mobile/core/session/auth_transport.dart';
import 'package:fb_mobile/core/session/session_clock.dart';
import 'package:fb_mobile/core/session/session_lifecycle.dart';
import 'package:fb_mobile/core/session/session_retry_scheduler.dart';
import 'package:fb_mobile/core/session/session_service.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/storage/device_id_store.dart';
import 'package:fb_mobile/core/storage/secure_session_store.dart';
import 'package:fb_mobile/core/storage/session_storage_durability.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_providers.g.dart';

/// Watching safe state alone does no I/O or session startup.
@Riverpod(keepAlive: true)
class SessionStateView extends _$SessionStateView {
  @override
  SessionState build() => const SessionState(status: SessionStatus.none);

  /// Core coordinator publication only; contains no request material.
  // A callback method keeps all observed values on Riverpod's state property.
  // ignore: use_setters_to_change_properties
  void publish(SessionState value) => state = value;
}

/// Public token-free session view; observation never starts auth.
@Riverpod(keepAlive: true)
SessionState sessionState(Ref ref) => ref.watch(sessionStateViewProvider);

/// Injectable monotonic and wall clocks, shared by transport and coordinator.
@Riverpod(keepAlive: true)
SessionClock sessionClock(Ref ref) =>
    ElapsedSessionClock(ref.watch(clockProvider));

/// The one writer for this flavor/origin's session keys.
@Riverpod(keepAlive: true)
SecureSessionStore secureSessionStore(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return SecureSessionStore(
    flavor: config.flavor.name,
    origin: config.apiBaseUrl,
    storage: const PluginSessionSecretStorage(),
    durability: const AndroidSessionStorageDurability(),
  );
}

/// Auth and normal Dio have independent adapter ownership.
@Riverpod(keepAlive: true)
HttpClientAdapter authHttpClientAdapter(Ref ref) => HttpClientAdapter();

/// No auth interceptor, so refresh cannot recurse through the normal API Dio.
@Riverpod(keepAlive: true)
AuthTransport authTransport(Ref ref) {
  final baseUrl = ref.watch(appConfigProvider).apiBaseUrl;
  final dio = createApiDio(
    baseUrl: baseUrl,
    adapter: ref.watch(authHttpClientAdapterProvider),
    interceptors: [
      ClientHeadersInterceptor(
        apiBaseUrl: baseUrl,
        appVersion: () async =>
            (await ref.read(packageInfoProvider.future)).version,
        deviceId: () => ref.read(deviceIdStoreProvider).deviceId(),
      ),
      UpgradeRequiredInterceptor(
        onUpgradeRequired: () =>
            ref.read(upgradeSignalProvider.notifier).trip(),
      ),
    ],
  );
  ref.onDispose(dio.close);
  return GeneratedAuthTransport(FbApi(dio), ref.watch(sessionClockProvider));
}

/// A33 security 7: revokes a newly issued session that is abandoned before
/// it is committed (cancelled flow, refused merge) with its **own** bearer,
/// best effort. Uses the auth adapter; the token lives only in this call and
/// is never logged or stored.
@Riverpod(keepAlive: true)
Future<void> Function(String accessToken) abandonedSessionRevoker(Ref ref) {
  final baseUrl = ref.watch(appConfigProvider).apiBaseUrl;
  final adapter = ref.watch(authHttpClientAdapterProvider);
  return (accessToken) async {
    final dio = createApiDio(
      baseUrl: baseUrl,
      adapter: adapter,
      interceptors: [
        ClientHeadersInterceptor(
          apiBaseUrl: baseUrl,
          appVersion: () async =>
              (await ref.read(packageInfoProvider.future)).version,
          deviceId: () => ref.read(deviceIdStoreProvider).deviceId(),
        ),
        _OwnBearer(accessToken),
      ],
    );
    // The adapter is shared with the auth transport: never close it here.
    await FbApi(dio).identity.logoutSession();
  };
}

final class _OwnBearer extends Interceptor {
  new(this._token);

  final String _token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $_token';
    handler.next(options);
  }

  @override
  String toString() => '_OwnBearer(redacted)';
}

/// Lazy keepAlive coordinator; construction performs no storage/network I/O.
@Riverpod(keepAlive: true)
SessionService sessionService(Ref ref) {
  final service = SessionService(
    store: ref.watch(secureSessionStoreProvider),
    transport: ref.watch(authTransportProvider),
    clock: ref.watch(sessionClockProvider),
    onState: ref.read(sessionStateViewProvider.notifier).publish,
  );
  ref.onDispose(service.dispose);
  return service;
}

/// Deferred lifecycle/scheduler; only bootstrap activates it after the frame.
@Riverpod(keepAlive: true)
SessionLifecycle sessionLifecycle(Ref ref) {
  final lifecycle = SessionLifecycle(
    SessionRetryScheduler(
      service: ref.watch(sessionServiceProvider),
      clock: ref.watch(sessionClockProvider),
    ),
    WidgetsBinding.instance,
  );
  ref.onDispose(lifecycle.dispose);
  return lifecycle;
}

/// Transport notifications before bootstrap are deliberately discarded. Reading
/// this callback creates neither a lifecycle observer nor a session service.
@Riverpod(keepAlive: true)
void Function() sessionTransportSucceeded(Ref ref) {
  return () {
    if (ref.mounted && ref.exists(sessionLifecycleProvider)) {
      // Wake the existing scheduler without changing its deadline.
      ref.read(sessionLifecycleProvider).transportSucceeded();
    }
  };
}
