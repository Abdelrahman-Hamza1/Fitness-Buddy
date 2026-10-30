import 'dart:convert';

import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/config/app_config.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'pending_scans_store.g.dart';

/// Where a waiting scan stands (A28a D10).
enum PendingScanState {
  /// Not looked up yet (offline or the server was unavailable).
  waiting,

  /// Looked up later: a product is ready to log.
  ready,

  /// Looked up later: no product for the code.
  notFound,
}

/// One scan kept for a later lookup. [name] is the product name once found.
final class PendingScan {
  /// Creates the scan.
  const new({
    required this.code,
    required this.scannedAtMs,
    this.state = PendingScanState.waiting,
    this.name,
    this.fromOff = false,
  });

  /// The normalized barcode.
  final String code;

  /// When it was scanned (epoch ms).
  final int scannedAtMs;

  /// Where it stands.
  final PendingScanState state;

  /// The product name once found.
  final String? name;

  /// The name is Open Food Facts data (the list shows the ODbL credit).
  final bool fromOff;

  /// A copy with another state.
  PendingScan withState(
    PendingScanState state, {
    String? name,
    bool fromOff = false,
  }) => PendingScan(
    code: code,
    scannedAtMs: scannedAtMs,
    state: state,
    name: name,
    fromOff: fromOff,
  );

  Map<String, Object?> _toJson() => {
    'code': code,
    'at': scannedAtMs,
    'state': state.name,
    'name': ?name,
    if (fromOff) 'off': true,
  };

  static PendingScan? _fromJson(Object? json) {
    if (json is! Map) return null;
    final code = json['code'];
    final at = json['at'];
    final state = PendingScanState.values
        .where((s) => s.name == json['state'])
        .firstOrNull;
    final name = json['name'];
    if (code is! String || at is! int || state == null) return null;
    return PendingScan(
      code: code,
      scannedAtMs: at,
      state: state,
      name: name is String ? name : null,
      fromOff: json['off'] == true,
    );
  }
}

/// The pending-scan list in shared preferences: device state, never
/// synced, but private to one local profile (review fix 1): the key carries
/// the environment namespace and the profile key, so another account on
/// this phone never sees it. A broken value reads as empty.
final class PendingScansStore {
  /// A store over [_preferences] for the list at [key].
  const new(this._preferences, {this.key = PreferenceKeys.pendingScans});
  final SharedPreferencesAsync _preferences;

  /// The preference key of this profile's list.
  final String key;

  /// The key of [profileKey]'s list in the [namespace] environment.
  static String keyFor(String namespace, String profileKey) =>
      PreferenceKeys.pendingScansFor(namespace, profileKey);

  /// Deletes [profileKey]'s list (the profile was deleted).
  static Future<void> deleteFor(
    SharedPreferencesAsync preferences,
    String namespace,
    String profileKey,
  ) => preferences.remove(keyFor(namespace, profileKey));

  /// The stored scans, oldest first.
  Future<List<PendingScan>> read() async {
    try {
      final raw = await _preferences.getString(key);
      final list = raw == null ? null : jsonDecode(raw);
      return list is List ? [...list.map(PendingScan._fromJson).nonNulls] : [];
    } on Object {
      return [];
    }
  }

  /// Replaces the stored list.
  Future<void> write(List<PendingScan> scans) async {
    try {
      await _preferences.setString(
        key,
        jsonEncode([for (final s in scans) s._toJson()]),
      );
    } on Object {
      return;
    }
  }
}

/// The environment namespace of device-local per-profile state, the same as
/// the profile registry's.
@Riverpod(keepAlive: true)
String pendingScansNamespace(Ref ref) {
  final config = ref.watch(appConfigProvider);
  return '${config.flavor.name}|${config.apiBaseUrl}';
}

/// The open profile's pending-scan store (review fix 1). Rebuilt on every
/// profile switch (the generation and the selected key), so the list and
/// everything reading it follow the profile.
@Riverpod(keepAlive: true)
Future<PendingScansStore> pendingScansStore(Ref ref) async {
  ref.watch(profileGenerationProvider);
  final selected = ref.watch(profileKeyProvider);
  final resolve = ref.watch(activeProfileResolverProvider);
  final profile = selected ?? await resolve?.call() ?? 'local';
  return PendingScansStore(
    ref.watch(sharedPreferencesProvider),
    key: PendingScansStore.keyFor(
      ref.watch(pendingScansNamespaceProvider),
      profile,
    ),
  );
}
