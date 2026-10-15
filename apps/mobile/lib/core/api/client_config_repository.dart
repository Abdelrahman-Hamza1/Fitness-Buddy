import 'dart:convert';

import 'package:fb_api_client/fb_api_client.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'client_config_repository.g.dart';

/// Reads `/v1/config` and keeps the last good answer (S06 plan D9).
///
/// Both reads swallow every failure (offline, timeout, server error, a
/// corrupt cache): the config is optional, and the app runs on the cache or
/// [defaults] without it (`09` §9).
final class ClientConfigRepository {
  /// Creates the repository over the `api` and the `preferences` cache.
  new({required this._api, required this._preferences});

  final FbApi _api;
  final SharedPreferencesAsync _preferences;

  /// The config before the first successful fetch: no minimum version, no
  /// flags (a missing flag is off), no thresholds (built-in defaults).
  static const defaults = ClientConfig(
    minimumAppVersion: '0.0.0',
    featureFlags: {},
    thresholds: {},
  );

  /// The cached config, or null when there is none or it can't be read.
  Future<ClientConfig?> loadCached() async {
    try {
      final json = await _preferences.getString(PreferenceKeys.clientConfig);
      if (json == null) return null;
      return ClientConfig.fromJson(jsonDecode(json) as Map<String, Object?>);
    } on Object {
      // A corrupt or old-format cache is ignored; the next fetch replaces it.
      return null;
    }
  }

  /// Fetches a fresh config and caches it. Null when the fetch fails.
  Future<ClientConfig?> fetch() async {
    final ClientConfig config;
    try {
      config = await _api.account.getConfig();
    } on Object {
      // Offline, timeout, 5xx, 426 (the interceptor has already tripped the
      // gate) or a malformed body: keep what we have.
      return null;
    }
    try {
      await _preferences.setString(
        PreferenceKeys.clientConfig,
        jsonEncode(config.toJson()),
      );
    } on Object {
      // Not cached this time; the fresh value still applies to this run.
    }
    return config;
  }
}

/// The app's [ClientConfigRepository].
@Riverpod(keepAlive: true)
ClientConfigRepository clientConfigRepository(Ref ref) =>
    ClientConfigRepository(
      api: ref.watch(fbApiProvider),
      preferences: ref.watch(sharedPreferencesProvider),
    );
