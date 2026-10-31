import 'dart:convert';

import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'notification_device_store.g.dart';

/// This install's notification state (A40 D5, D8): device state, never
/// synced or sent, nothing personal.
abstract interface class NotificationDeviceStore {
  /// The ledger of what was scheduled: notification ID → instant (ms since
  /// epoch, UTC); empty when there is none or it can't be read. The
  /// scheduler derives "already shown today" from it (NT-022).
  Future<Map<int, int>> readLedger();

  /// Stores the ledger.
  Future<void> writeLedger(Map<int, int> entries);

  /// Whether the app already asked for the notification permission once.
  Future<bool> permissionAsked();

  /// Remembers that it asked.
  Future<void> markPermissionAsked();

  /// The tag of the profile whose notifications may be on the phone, or
  /// null when none are (after a purge). Written only after its purge
  /// succeeded, so an interrupted profile switch is finished at the next
  /// start (A40 fix-check 1).
  Future<String?> ownerTag();

  /// Stores [tag] (null: nothing on the phone).
  Future<void> setOwnerTag(String? tag);
}

/// [NotificationDeviceStore] in shared preferences: the ledger as JSON
/// `{"<id>": <ms>}` under `PreferenceKeys.notificationLedger`, the flag
/// under `PreferenceKeys.notificationPermissionAsked`.
final class PreferencesNotificationDeviceStore
    implements NotificationDeviceStore {
  /// Over the app's preferences.
  const new(this._preferences);

  final SharedPreferencesAsync _preferences;

  @override
  Future<Map<int, int>> readLedger() async {
    final text = await _preferences.getString(
      PreferenceKeys.notificationLedger,
    );
    if (text == null) return {};
    try {
      final json = jsonDecode(text);
      if (json is! Map<String, Object?>) return {};
      return {
        for (final MapEntry(:key, :value) in json.entries)
          if (int.tryParse(key) case final id? when value is int) id: value,
      };
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> writeLedger(Map<int, int> entries) => _preferences.setString(
    PreferenceKeys.notificationLedger,
    jsonEncode({
      for (final MapEntry(:key, :value) in entries.entries) '$key': value,
    }),
  );

  @override
  Future<bool> permissionAsked() async =>
      await _preferences.getBool(PreferenceKeys.notificationPermissionAsked) ??
      false;

  @override
  Future<void> markPermissionAsked() =>
      _preferences.setBool(PreferenceKeys.notificationPermissionAsked, true);

  @override
  Future<String?> ownerTag() =>
      _preferences.getString(PreferenceKeys.notificationOwner);

  @override
  Future<void> setOwnerTag(String? tag) => tag == null
      ? _preferences.remove(PreferenceKeys.notificationOwner)
      : _preferences.setString(PreferenceKeys.notificationOwner, tag);
}

/// The app's [NotificationDeviceStore]; tests override it in memory.
@Riverpod(keepAlive: true)
NotificationDeviceStore notificationDeviceStore(Ref ref) =>
    PreferencesNotificationDeviceStore(ref.watch(sharedPreferencesProvider));
