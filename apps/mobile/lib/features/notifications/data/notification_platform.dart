import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:timezone/timezone.dart' as tz;

part 'notification_platform.g.dart';

/// One local notification as the platform holds it (A40 D5). [payload]
/// carries the deep link and the fingerprint the scheduler compares; it
/// is never user content. Content-free [toString].
@immutable
final class ScheduledNotification {
  /// A notification [id] at [at] (an instant) with neutral [title] and
  /// [body] (NT-025).
  const new({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });

  /// The stable ID (one per type and day).
  final int id;

  /// When it fires.
  final DateTime at;

  /// The heading.
  final String title;

  /// The line under it.
  final String body;

  /// What the platform stores with it.
  final String payload;

  @override
  String toString() => 'ScheduledNotification($id)';
}

/// The channel's words, set once at start (NT-025).
typedef NotificationChannelText = ({String name, String description});

/// The local notifications on the phone (A40 D5): the one place the
/// notifications plugin is used, so the scheduler is testable with a fake.
abstract interface class NotificationPlatform {
  /// Prepares the platform; [onTap] gets the payload of a notification the
  /// user taps while the app runs. Safe to call more than once.
  Future<void> initialize({
    required NotificationChannelText channel,
    required void Function(String? payload) onTap,
  });

  /// The payload of the notification that started the app, once; null when
  /// the app wasn't started by one.
  Future<String?> takeLaunchPayload();

  /// What is scheduled and not shown yet: ID → payload.
  Future<Map<int, String>> pending();

  /// Schedules [notification] (replacing one with its ID).
  Future<void> schedule(ScheduledNotification notification);

  /// Cancels notification [id] (nothing when there is none).
  Future<void> cancel(int id);

  /// Cancels every notification of the app, scheduled or already shown (a
  /// profile switch, sign-out or account deletion).
  Future<void> cancelEverything();

  /// Whether the system lets the app show notifications.
  Future<bool> enabled();

  /// Asks the system for permission (Android 13+); whether it is granted.
  Future<bool> requestPermission();

  /// Opens the system's notification settings for the app (the way back
  /// after a permanent denial, or on Android 12 and earlier).
  Future<void> openSettings();
}

/// [NotificationPlatform] over `flutter_local_notifications` (A40 D7):
/// every notification **inexact** (`inexactAllowWhileIdle`: no exact-alarm
/// permission, battery friendly; none of the types needs the minute), one
/// "Reminders" channel, the monochrome launcher layer as the small icon.
/// Instants are passed in UTC, so no time-zone database is needed: the
/// coordinator re-plans when the zone changes (resume).
final class PluginNotificationPlatform implements NotificationPlatform {
  /// Over [plugin].
  new([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// The channel's permanent ID.
  static const channelId = 'reminders';

  late NotificationChannelText _channel;
  Future<void>? _initialized;
  bool _launchTaken = false;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  @override
  Future<void> initialize({
    required NotificationChannelText channel,
    required void Function(String? payload) onTap,
  }) {
    _channel = channel;
    return _initialized ??= _plugin
        .initialize(
          settings: const InitializationSettings(
            android: AndroidInitializationSettings('ic_launcher_monochrome'),
          ),
          onDidReceiveNotificationResponse: (response) =>
              onTap(response.payload),
        )
        .then((_) {});
  }

  @override
  Future<String?> takeLaunchPayload() async {
    if (_launchTaken) return null;
    _launchTaken = true;
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  @override
  Future<Map<int, String>> pending() async => {
    for (final r in await _plugin.pendingNotificationRequests())
      r.id: r.payload ?? '',
  };

  @override
  Future<void> schedule(ScheduledNotification n) {
    final channel = _channel;
    return _plugin.zonedSchedule(
      id: n.id,
      scheduledDate: tz.TZDateTime.from(n.at.toUtc(), tz.UTC),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channel.name,
          channelDescription: channel.description,
          category: AndroidNotificationCategory.reminder,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      title: n.title,
      body: n.body,
      payload: n.payload,
    );
  }

  @override
  Future<void> cancel(int id) => _plugin.cancel(id: id);

  @override
  Future<void> cancelEverything() => _plugin.cancelAll();

  @override
  Future<void> openSettings() async {
    await _android?.openAppNotificationSettings();
  }

  @override
  Future<bool> enabled() async =>
      await _android?.areNotificationsEnabled() ?? false;

  @override
  Future<bool> requestPermission() async =>
      await _android?.requestNotificationsPermission() ?? false;
}

/// The app's [NotificationPlatform]; tests override it with a fake.
@Riverpod(keepAlive: true)
NotificationPlatform notificationPlatform(Ref ref) =>
    PluginNotificationPlatform();

/// A platform call that failed because the plugin isn't there (a host
/// test, an unsupported platform): treated as "no notifications".
bool isMissingPlugin(Object error) => error is MissingPluginException;
