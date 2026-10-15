import 'dart:async';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/client_config_repository.dart';
import 'package:fb_mobile/core/config/upgrade_signal.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'client_config.g.dart';

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
@Riverpod(keepAlive: true, name: 'clientConfigProvider')
class ClientConfigNotifier extends _$ClientConfigNotifier {
  Future<bool>? _refreshing;
  bool _cacheLoaded = false;

  @override
  ClientConfig build() {
    // fireImmediately: a signal tripped before this provider was first
    // read still refreshes the config.
    ref.listen(upgradeSignalProvider, (_, tripped) {
      if (tripped) unawaited(refresh());
    }, fireImmediately: true);
    return ClientConfigRepository.defaults;
  }

  /// Loads the cache (first call only), then fetches a fresh config.
  /// Completes with whether the fetch succeeded. A call while a refresh is
  /// in flight joins it.
  Future<bool> refresh() =>
      _refreshing ??= _refresh().whenComplete(() => _refreshing = null);

  Future<bool> _refresh() async {
    final repository = ref.read(clientConfigRepositoryProvider);
    if (!_cacheLoaded) {
      _cacheLoaded = true;
      final cached = await repository.loadCached();
      if (!ref.mounted) return false;
      if (cached != null) state = cached;
    }
    final fresh = await repository.fetch();
    if (!ref.mounted || fresh == null) return false;
    state = fresh;
    return true;
  }
}
