import 'dart:async';

import 'package:fb_mobile/features/notifications/notifications.dart';

/// A phone's notifications in memory: what is scheduled, every platform
/// call in order, and the permission.
final class FakeNotificationPlatform implements NotificationPlatform {
  /// A platform with notifications [allowed] (or not, until granted when
  /// [grantOnRequest]).
  new({this.allowed = true, this.grantOnRequest = true, this.launchPayload});

  /// Whether the system lets the app notify.
  bool allowed;

  /// Whether a permission request grants it.
  bool grantOnRequest;

  /// The payload of the tap that started the app, if any.
  String? launchPayload;

  /// Scheduled and not shown: ID → notification.
  final Map<int, ScheduledNotification> scheduled = {};

  /// Calls: `schedule <id>`, `cancel <id>`, `request`.
  final List<String> calls = [];

  /// The tap callback the coordinator registered.
  void Function(String? payload)? onTap;

  /// Permission requests so far.
  int requests = 0;

  @override
  Future<void> initialize({
    required NotificationChannelText channel,
    required void Function(String? payload) onTap,
  }) async => this.onTap = onTap;

  @override
  Future<String?> takeLaunchPayload() async {
    final payload = launchPayload;
    launchPayload = null;
    return payload;
  }

  @override
  Future<Map<int, String>> pending() async => {
    for (final n in scheduled.values) n.id: n.payload,
  };

  @override
  Future<void> schedule(ScheduledNotification notification) async {
    await gate?.future;
    calls.add('schedule ${notification.id}');
    scheduled[notification.id] = notification;
  }

  @override
  Future<void> cancel(int id) async {
    calls.add('cancel $id');
    scheduled.remove(id);
  }

  @override
  Future<void> cancelEverything() async {
    calls.add('cancelEverything');
    scheduled.clear();
  }

  @override
  Future<void> openSettings() async {
    calls.add('openSettings');
    if (settingsEnable) allowed = true;
  }

  /// Whether the user turns notifications on in the opened settings.
  bool settingsEnable = false;

  /// Holds every schedule call until completed (delayed platform calls).
  Completer<void>? gate;

  @override
  Future<bool> enabled() async => allowed;

  @override
  Future<bool> requestPermission() async {
    calls.add('request');
    requests++;
    if (grantOnRequest) allowed = true;
    return allowed;
  }

  /// Marks every notification due by [now] as shown (removes it).
  void fireDue(DateTime now) =>
      scheduled.removeWhere((_, n) => !n.at.isAfter(now));
}

/// The device store in memory.
final class MemoryNotificationDeviceStore implements NotificationDeviceStore {
  /// The ledger.
  Map<int, int> ledger = {};

  /// Whether the permission was asked.
  bool asked = false;

  @override
  Future<Map<int, int>> readLedger() async => Map.of(ledger);

  @override
  Future<void> writeLedger(Map<int, int> entries) async =>
      ledger = Map.of(entries);

  @override
  Future<bool> permissionAsked() async => asked;

  @override
  Future<void> markPermissionAsked() async => asked = true;

  /// The stored owner tag.
  String? owner;

  @override
  Future<String?> ownerTag() async => owner;

  @override
  Future<void> setOwnerTag(String? tag) async => owner = tag;
}
