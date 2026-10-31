import 'dart:async';
import 'dart:ui' show Locale;

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/l10n/l10n.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/notifications/application/notification_inputs.dart';
import 'package:fb_mobile/features/notifications/application/notification_links.dart';
import 'package:fb_mobile/features/notifications/application/notification_scheduler.dart';
import 'package:fb_mobile/features/notifications/data/notification_device_store.dart';
import 'package:fb_mobile/features/notifications/data/notification_platform.dart';
import 'package:fb_mobile/features/notifications/data/notification_profile.dart';
import 'package:flutter/widgets.dart' show AppLifecycleListener;
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ProviderSubscription;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_coordinator.g.dart';

/// Whether this build plans and schedules notifications. On in the app;
/// widget tests of other features keep it off (like the catalog update)
/// and the notification tests opt in.
@Riverpod(keepAlive: true)
bool notificationSchedulingEnabled(Ref ref) => true;

/// Opens a notification's deep link (a go_router location, NT-024). The
/// app wires it to the router (`lib/app/app_scope.dart`); features can't
/// import the router.
@Riverpod(keepAlive: true)
Future<void> Function(String location) notificationLinkOpener(Ref ref) =>
    (_) => throw UnimplementedError(
      'notificationLinkOpenerProvider must be overridden (app_scope.dart).',
    );

/// Keeps the phone's notifications equal to the plan (`09` §1, A40 D6):
/// started by the bootstrap after the first frame (UX-001), it re-plans on
/// the first run, on every change of the plan's inputs (data, settings),
/// on every domain event, and on resume (a new day or time zone). Runs are
/// serialized: one in flight, at most one more queued. All local (TD-013).
/// Taps open their deep link (NT-024).
///
/// **Profiles (A40 review 1):** a profile switch (sign-in, sign-out,
/// account deletion) drops the old inputs, stops any run in flight from
/// scheduling, then removes every notification of the app (scheduled and
/// shown) before the new profile's inputs plan again. Inputs and payloads
/// carry their profile; a tap from another profile is ignored.
final class NotificationCoordinator {
  /// Over [_ref].
  new(this._ref);

  final Ref _ref;
  bool _started = false;
  bool _disposed = false;
  bool _running = false;
  bool _again = false;
  bool _purge = false;
  int _generation = 0;
  NotificationInputs? _inputs;
  AppLifecycleListener? _lifecycle;
  StreamSubscription<DomainEvent>? _events;
  ProviderSubscription<AsyncValue<NotificationInputs>>? _inputsSub;
  ProviderSubscription<int>? _profileSub;
  Completer<void>? _idle;

  /// The English strings (R1 is English only, D-080): notifications are
  /// built outside the widget tree.
  static final AppLocalizations _l10n = lookupAppLocalizations(
    const Locale('en'),
  );

  /// Starts once: prepares the platform, opens a launch tap's link and
  /// begins following the inputs and the profile. Never throws.
  Future<void> start() async {
    if (_started || _disposed) return;
    if (!_ref.read(notificationSchedulingEnabledProvider)) return;
    _started = true;
    _generation = _ref.read(profileGenerationProvider);
    final platform = _ref.read(notificationPlatformProvider);
    try {
      await platform.initialize(
        channel: (
          name: _l10n.notifChannelName,
          description: _l10n.notifChannelDescription,
        ),
        onTap: (payload) => unawaited(openPayload(payload)),
      );
      // Finish a profile switch a crash interrupted before its purge (an
      // old owner on the phone), before anything else is opened.
      final key = await _ref.read(notificationProfileKeyProvider.future);
      await _scheduler().claim(NotificationScheduler.profileTagOf(key));
      await openPayload(await platform.takeLaunchPayload());
    } on Object {
      // No plugin (host tests, an unsupported platform): no notifications.
      _started = false;
      return;
    }
    if (_disposed) return;
    _lifecycle = AppLifecycleListener(onResume: refresh);
    _events = _ref
        .read(domainEventBusProvider)
        .events
        .listen((_) => _request());
    _profileSub = _ref.listen(profileGenerationProvider, (_, generation) {
      _generation = generation;
      _inputs = null;
      _purge = true;
      _request();
    });
    _inputsSub = _ref.listen(notificationInputsProvider, (_, next) {
      final inputs = next.value;
      // A value read for another profile is never planned from.
      if (inputs == null || inputs.generation != _generation) return;
      _inputs = inputs;
      _request();
    }, fireImmediately: true);
  }

  /// Reads the inputs again (today and the zone may have changed), then
  /// re-plans.
  void refresh() {
    if (_disposed) return;
    _ref
      ..invalidate(notificationInputsProvider)
      // Back from Android's settings, the banner reads the permission again.
      ..invalidate(notificationsAllowedProvider);
  }

  /// Opens [payload]'s deep link when it is ours and the open profile's;
  /// ignores anything else.
  Future<void> openPayload(String? payload) async {
    if (payload == null || _disposed) return;
    try {
      final key = await _ref.read(notificationProfileKeyProvider.future);
      final location = NotificationScheduler.locationOf(
        payload,
        profileTag: NotificationScheduler.profileTagOf(key),
      );
      if (location == null || _disposed) return;
      await _ref.read(notificationLinkOpenerProvider)(location);
    } on Object {
      // A link that can't be opened leaves the app where it is.
    }
  }

  /// Completes when no run is in flight or queued (tests).
  Future<void> get idle =>
      _running ? (_idle ??= Completer()).future : Future.value();

  void _request() {
    if (_disposed) return;
    if (_running) {
      _again = true;
      return;
    }
    unawaited(_run());
  }

  Future<void> _run() async {
    _running = true;
    try {
      do {
        _again = false;
        // Coalesce the events of one change set into one run.
        await Future<void>.delayed(Duration.zero);
        if (_disposed) return;
        try {
          if (_purge) {
            _purge = false;
            await _scheduler().purge();
          }
          await _replan();
        } on Object {
          // A failed run leaves the last schedule; the next trigger retries.
        }
      } while ((_again || _purge) && !_disposed);
    } finally {
      _running = false;
      _idle?.complete();
      _idle = null;
    }
  }

  NotificationScheduler _scheduler() => NotificationScheduler(
    platform: _ref.read(notificationPlatformProvider),
    store: _ref.read(notificationDeviceStoreProvider),
    clock: _ref.read(clockProvider),
  );

  Future<void> _replan() async {
    final inputs = _inputs;
    if (inputs == null || inputs.generation != _generation) return;
    final generation = _generation;
    bool current() => !_disposed && !_purge && _generation == generation;
    final platform = _ref.read(notificationPlatformProvider);
    final store = _ref.read(notificationDeviceStoreProvider);
    final clock = _ref.read(clockProvider);
    final scheduler = _scheduler();
    // The phone holds only this profile's notifications (fix-check 1).
    await scheduler.claim(inputs.profileTag);
    if (!current()) return;
    if (!inputs.prefs.enabled) {
      await scheduler.cancelAll();
      return;
    }
    if (!await platform.enabled()) {
      // Asked once, in context: after the first use (A40 D8). Later only
      // from the Notifications screen.
      if (current() &&
          inputs.state.activeDates.isNotEmpty &&
          !await store.permissionAsked()) {
        await store.markPermissionAsked();
        if (await platform.requestPermission()) {
          await _replan();
          return;
        }
      }
      await scheduler.cancelAll();
      return;
    }
    final now = EntryTime.now(clock);
    final today = now.localDate;
    if (today != inputs.today) {
      // The day changed since the inputs were read: read them again.
      refresh();
      return;
    }
    final dayStart = EntryTime.fromLocal(LocalDateTime(today), clock);
    final local = now.localDateTime;
    final shown = await scheduler.shownSince(dayStart.occurredAtUtc);
    if (!current()) return;
    final planned = NotificationPlanner.plan(
      prefs: inputs.prefs,
      today: today,
      nowMinute: local.hour * 60 + local.minute,
      state: inputs.state,
      shownToday: shown,
      nowUtc: now.occurredAtUtc,
    );
    await scheduler.sync(
      [
        for (final c in planned)
          _scheduled(c, inputs.calendar, inputs.profileTag, clock),
      ],
      stillApplying: NotificationPlanner.applyingToday(
        prefs: inputs.prefs,
        today: today,
        state: inputs.state,
      ),
      profileTag: inputs.profileTag,
      isCurrent: current,
    );
  }

  static ScheduledNotification _scheduled(
    NotificationCandidate c,
    WeekCalendar calendar,
    String profileTag,
    Clock clock,
  ) {
    final at =
        c.atUtc ??
        EntryTime.fromLocal(
          LocalDateTime(c.date, hour: c.minute ~/ 60, minute: c.minute % 60),
          clock,
        ).occurredAtUtc;
    final text = notificationText(_l10n, c.type);
    final location = notificationRoute(c, calendar: calendar).location;
    return ScheduledNotification(
      id: c.id,
      at: at,
      title: text.title,
      body: text.body,
      payload: NotificationScheduler.payloadOf(
        profileTag: profileTag,
        at: at,
        title: text.title,
        body: text.body,
        location: location,
      ),
    );
  }

  /// Stops following the inputs.
  void dispose() {
    _disposed = true;
    _lifecycle?.dispose();
    unawaited(_events?.cancel());
    _inputsSub?.close();
    _profileSub?.close();
  }
}

/// The app's [NotificationCoordinator]: one for the app's life. A profile
/// switch (sign-in, sign-out, account deletion, A33/A35) purges the old
/// profile's notifications; the inputs then re-read the new profile.
@Riverpod(keepAlive: true)
NotificationCoordinator notificationCoordinator(Ref ref) {
  final coordinator = NotificationCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
}

/// Whether Android lets the app show notifications (the Notifications
/// screen's banner). False when it can't tell.
@riverpod
Future<bool> notificationsAllowed(Ref ref) async {
  try {
    return await ref.read(notificationPlatformProvider).enabled();
  } on Object {
    return false;
  }
}

/// The Notifications screen's Allow (A40 D8).
final class NotificationPermission {
  /// Over [_ref].
  new(this._ref);

  final Ref _ref;

  /// Asks Android for the permission now (or, when it won't ask any more,
  /// opens the app's notification settings) and re-plans; whether
  /// notifications are allowed afterwards.
  Future<bool> request() async {
    try {
      await _ref.read(notificationDeviceStoreProvider).markPermissionAsked();
      final platform = _ref.read(notificationPlatformProvider);
      var granted = await platform.requestPermission();
      // Denied for good (Android stops asking), or Android 12 and earlier:
      // the way back is the system's settings (A40 review 5).
      if (!granted) {
        await platform.openSettings();
        granted = await platform.enabled();
      }
      _ref
        ..invalidate(notificationsAllowedProvider)
        ..read(notificationCoordinatorProvider).refresh();
      return granted;
    } on Object {
      return false;
    }
  }
}

/// The app's [NotificationPermission].
@Riverpod(keepAlive: true)
NotificationPermission notificationPermission(Ref ref) =>
    NotificationPermission(ref);
