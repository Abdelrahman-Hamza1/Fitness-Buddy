import 'package:fb_mobile/app/app_scope.dart';
import 'package:fb_mobile/core/api/api_providers.dart';
import 'package:fb_mobile/core/catalog/catalog_providers.dart';
import 'package:fb_mobile/core/catalog/online_food_search.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/config/package_info.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

import '../features/notifications/support/fake_notifications.dart';
import 'fake_http.dart';

/// The configuration the tests run with (the dev flavor's values).
final AppConfig testConfig = AppConfig(
  flavor: AppFlavor.dev,
  apiBaseUrl: Uri.parse('http://127.0.0.1:5198'),
  sentryDsn: '',
);

/// One install of the app on a fake phone: its preferences survive
/// "restarts" (new provider containers), the network is a
/// [FakeHttpAdapter] (offline unless told otherwise), and the installed
/// version is [appVersion].
///
/// [events] records, in order, every preference read and write
/// (`prefs get fb.device_id`, `prefs set fb.device_id`), package info
/// lookup (`package info`) and request (`GET /v1/config`), so tests can
/// check what happens before the first frame (UX-001).
final class TestPhone {
  /// Creates a phone with the app installed at [appVersion]. [onlineSearch]
  /// and [packUpdates] opt in to the A24 online food search and background
  /// pack check; both are off by default so request logs stay exact.
  new({
    this.appVersion = '0.1.0',
    AppConfig? config,
    this.onlineSearch = false,
    this.packUpdates = false,
    this.notifications = false,
  }) : config = config ?? testConfig {
    adapter.onRequest = (r) => events.add('${r.method} ${r.path}');
  }

  /// The installed app version (`PackageInfo.version`).
  String appVersion;

  /// The flavor configuration compiled into the app.
  final AppConfig config;

  /// The network.
  final FakeHttpAdapter adapter = FakeHttpAdapter();

  /// Whether food search also asks the server catalog (A24).
  final bool onlineSearch;

  /// Whether the bootstrap checks for a newer catalog pack (A24).
  final bool packUpdates;

  /// Whether the app plans and schedules notifications (A40).
  final bool notifications;

  /// The phone's notifications.
  final FakeNotificationPlatform notificationPlatform =
      FakeNotificationPlatform();

  /// The notification ledger and permission flag.
  final MemoryNotificationDeviceStore notificationStore =
      MemoryNotificationDeviceStore();

  /// When set, the app can't open its preferences.
  bool preferencesBroken = false;

  /// What happened, in order (see the class doc).
  final List<String> events = [];

  late final _RecordingPreferences _store = _RecordingPreferences(events);

  /// The stored preferences, by key (what survives a restart).
  Future<Map<String, Object>> storedPreferences() => _store.getPreferences(
    const GetPreferencesParameters(filter: PreferencesFilters()),
    const SharedPreferencesOptions(),
  );

  /// Stores [value] under [key] as if an earlier run had (not recorded).
  Future<void> seedPreference(String key, String value) =>
      _store.seed(key, value);

  /// The overrides for one app start: [appOverrides] plus this phone.
  List<Override> overrides() => [
    ...appOverrides(config),
    sharedPreferencesProvider.overrideWith((ref) {
      if (preferencesBroken) throw StateError('preferences broken (test)');
      // SharedPreferencesAsync binds to the platform when it is created.
      SharedPreferencesAsyncPlatform.instance = _store;
      return SharedPreferencesAsync();
    }),
    httpClientAdapterProvider.overrideWithValue(adapter),
    // A24: off unless the test opts in (each adds requests to the log).
    catalogPackUpdatesEnabledProvider.overrideWithValue(packUpdates),
    onlineFoodSearchEnabledProvider.overrideWithValue(onlineSearch),
    // A40: no scheduling unless a test opts in; the fakes never touch a
    // platform channel or the recorded preferences.
    notificationSchedulingEnabledProvider.overrideWithValue(notifications),
    notificationPlatformProvider.overrideWithValue(notificationPlatform),
    notificationDeviceStoreProvider.overrideWithValue(notificationStore),
    packageInfoProvider.overrideWith((ref) async {
      events.add('package info');
      return PackageInfo(
        appName: 'Fitness Buddy',
        packageName: 'fb.test',
        version: appVersion,
        buildNumber: '1',
      );
    }),
  ];
}

/// The in-memory platform store, recording reads and writes.
final class _RecordingPreferences extends InMemorySharedPreferencesAsync {
  new(this._events) : super.empty();

  final List<String> _events;

  Future<void> seed(String key, String value) =>
      super.setString(key, value, const SharedPreferencesOptions());

  @override
  Future<String?> getString(String key, SharedPreferencesOptions options) {
    _events.add('prefs get $key');
    return super.getString(key, options);
  }

  @override
  Future<bool> setString(
    String key,
    String value,
    SharedPreferencesOptions options,
  ) {
    _events.add('prefs set $key');
    return super.setString(key, value, options);
  }
}
