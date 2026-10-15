// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client_config.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The server's client configuration: minimum app version, feature flags,
/// thresholds (`/v1/config`, `09` §9, S06 plan D9, A1).
///
/// The single owner of loading and refreshing it. It starts from the
/// defaults with no I/O (UX-001); `AppBootstrap` calls [refresh] after the
/// first frame, which loads the cache, then fetches. Never on the startup
/// path, and offline it simply keeps the cache or the defaults.
///
/// When the server refuses this version (the upgrade signal trips), it
/// refreshes too, so the new minimum version is cached and the gate also
/// holds on the next start. That refresh joins one in flight (e.g. when
/// `/v1/config` itself answered 426), and a signal that is already tripped
/// doesn't notify again, so this can't loop.

@ProviderFor(ClientConfigNotifier)
final clientConfigProvider = ClientConfigNotifierProvider._();

/// The server's client configuration: minimum app version, feature flags,
/// thresholds (`/v1/config`, `09` §9, S06 plan D9, A1).
///
/// The single owner of loading and refreshing it. It starts from the
/// defaults with no I/O (UX-001); `AppBootstrap` calls [refresh] after the
/// first frame, which loads the cache, then fetches. Never on the startup
/// path, and offline it simply keeps the cache or the defaults.
///
/// When the server refuses this version (the upgrade signal trips), it
/// refreshes too, so the new minimum version is cached and the gate also
/// holds on the next start. That refresh joins one in flight (e.g. when
/// `/v1/config` itself answered 426), and a signal that is already tripped
/// doesn't notify again, so this can't loop.
final class ClientConfigNotifierProvider
    extends $NotifierProvider<ClientConfigNotifier, ClientConfig> {
  /// The server's client configuration: minimum app version, feature flags,
  /// thresholds (`/v1/config`, `09` §9, S06 plan D9, A1).
  ///
  /// The single owner of loading and refreshing it. It starts from the
  /// defaults with no I/O (UX-001); `AppBootstrap` calls [refresh] after the
  /// first frame, which loads the cache, then fetches. Never on the startup
  /// path, and offline it simply keeps the cache or the defaults.
  ///
  /// When the server refuses this version (the upgrade signal trips), it
  /// refreshes too, so the new minimum version is cached and the gate also
  /// holds on the next start. That refresh joins one in flight (e.g. when
  /// `/v1/config` itself answered 426), and a signal that is already tripped
  /// doesn't notify again, so this can't loop.
  ClientConfigNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientConfigNotifierHash();

  @$internal
  @override
  ClientConfigNotifier create() => ClientConfigNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClientConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClientConfig>(value),
    );
  }
}

String _$clientConfigNotifierHash() =>
    r'9270d10d5d70a5d5fa5b4872e5314548235e0a31';

/// The server's client configuration: minimum app version, feature flags,
/// thresholds (`/v1/config`, `09` §9, S06 plan D9, A1).
///
/// The single owner of loading and refreshing it. It starts from the
/// defaults with no I/O (UX-001); `AppBootstrap` calls [refresh] after the
/// first frame, which loads the cache, then fetches. Never on the startup
/// path, and offline it simply keeps the cache or the defaults.
///
/// When the server refuses this version (the upgrade signal trips), it
/// refreshes too, so the new minimum version is cached and the gate also
/// holds on the next start. That refresh joins one in flight (e.g. when
/// `/v1/config` itself answered 426), and a signal that is already tripped
/// doesn't notify again, so this can't loop.

abstract class _$ClientConfigNotifier extends $Notifier<ClientConfig> {
  ClientConfig build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ClientConfig, ClientConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ClientConfig, ClientConfig>,
              ClientConfig,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
