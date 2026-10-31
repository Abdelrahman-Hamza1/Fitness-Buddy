import 'dart:async';

import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/events/domain_event_bus.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';
import '../body/support/weigh_in_harness.dart' show weighInDraft;
import 'support/fake_notifications.dart';

// Saturday 31 October 2026, 06:00 at UTC+3 (a Saturday week start).
final DateTime _start = DateTime.utc(2026, 10, 31, 3);
final LocalDate _sat = LocalDate(2026, 10, 31);

int _id(NotificationType type, LocalDate date) =>
    NotificationCandidate(type: type, date: date, minute: 0).id;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestPhone phone;
  late FakeNotificationPlatform platform;
  late ManualClock clock;
  late ProviderContainer container;
  late NotificationCoordinator coordinator;
  var failProfile = false;

  Future<void> settle() async {
    for (var i = 0; i < 5; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      await coordinator.idle;
    }
  }

  /// One app start on [phone] (a restart reuses the phone's platform and
  /// device store).
  Future<void> startApp() async {
    final clockOverride = clockProvider.overrideWithValue(clock);
    failProfile = false;
    final resolverOverride = activeProfileResolverProvider.overrideWithValue(
      () async => failProfile ? throw StateError('unreadable (test)') : 'local',
    );
    container = ProviderContainer.test(
      overrides: [
        for (final o in [...phone.overrides(), ...todayOverrides()])
          if (o.origin != clockOverride.origin &&
              o.origin != resolverOverride.origin)
            o,
        clockOverride,
        resolverOverride,
      ],
    );
    coordinator = container.read(notificationCoordinatorProvider);
    await coordinator.start();
    await settle();
  }

  setUp(() async {
    phone = TestPhone(notifications: true);
    platform = phone.notificationPlatform;
    clock = ManualClock(_start, offsetMinutes: 180);
    await startApp();
  });

  test('A40 D6 the first run schedules spec/17 defaults; re-planning with '
      'nothing changed makes no platform call', () async {
    expect(
      platform.scheduled.keys,
      containsAll([
        _id(NotificationType.weighIn, _sat),
        _id(NotificationType.logReminder, _sat),
      ]),
    );
    // Today 08:00 at UTC+3.
    expect(
      platform.scheduled[_id(NotificationType.weighIn, _sat)]!.at,
      DateTime.utc(2026, 10, 31, 5),
    );
    final calls = List.of(platform.calls);
    coordinator.refresh();
    container.read(domainEventBusProvider).emit(SettingsChanged(['x']));
    await settle();
    expect(platform.calls, calls);
  });

  test('NT-020 a settings change re-plans: a new time replaces the '
      'notification, the master switch off cancels everything', () async {
    final actions = container.read(settingsActionsProvider);
    final prefs = NotificationPrefs.defaults;
    await actions.setNotificationPrefs(
      prefs.withType(
        NotificationType.logReminder,
        NotificationTypePrefs(enabled: true, minute: 20 * 60),
      ),
    );
    await settle();
    expect(
      platform.scheduled[_id(NotificationType.logReminder, _sat)]!.at,
      DateTime.utc(2026, 10, 31, 17),
    );
    await actions.setNotificationPrefs(prefs.copyWith(enabled: false));
    await settle();
    expect(platform.scheduled, isEmpty);
  });

  test('A40 D6 a domain event after midnight reads the new day and plans '
      'its horizon', () async {
    final nextSat = _sat.plusDays(7);
    expect(
      platform.scheduled.containsKey(_id(NotificationType.weighIn, nextSat)),
      isFalse,
    );
    clock.advance(const Duration(days: 1));
    platform.fireDue(clock.nowUtc());
    container.read(domainEventBusProvider).emit(SettingsChanged(['x']));
    await settle();
    expect(
      platform.scheduled.containsKey(_id(NotificationType.weighIn, nextSat)),
      isTrue,
    );
  });

  test('A40 D8 notifications off at the system: nothing scheduled; the '
      'permission is asked once, after first use', () async {
    platform
      ..allowed = false
      ..grantOnRequest = false;
    coordinator.refresh();
    await settle();
    expect(platform.scheduled, isEmpty);
    // No activity yet: not asked.
    expect(platform.requests, 0);
    await container
        .read(settingsActionsProvider)
        .setWeekStart(DayOfWeek.sunday);
    await settle();
    expect(platform.requests, 0);
    // First use (a weigh-in yesterday): asked once, then never again.
    await container
        .read(weighInActionsProvider.notifier)
        .log(weighInDraft(84.2, date: _sat.plusDays(-1)));
    await settle();
    expect(platform.requests, 1);
    expect(phone.notificationStore.asked, isTrue);
    coordinator.refresh();
    await settle();
    expect(platform.requests, 1);
    expect(platform.scheduled, isEmpty);
    // Granted later (the Notifications screen's Allow): scheduled.
    platform.allowed = true;
    coordinator.refresh();
    await settle();
    expect(platform.scheduled, isNotEmpty);
  });

  group('A40 review 1 profiles:', () {
    test(
      'a profile switch (sign-in, sign-out, account deletion) removes '
      "every notification, then plans the new profile's with its tag",
      () async {
        expect(platform.scheduled, isNotEmpty);
        final oldTag = NotificationScheduler.profileTagOf('local');
        // What every account transition does (sign-in, sign-out, account
        // deletion into a fresh guest, A33/A35 OpenProfileHost.activate):
        // a new generation, then the new profile's key.
        container.read(profileGenerationProvider.notifier).bump();
        container.read(profileKeyProvider.notifier).select('guest-2');
        await settle();
        expect(platform.calls, contains('cancelEverything'));
        // The ledger holds only what was planned since.
        expect(
          phone.notificationStore.ledger.keys.toSet(),
          platform.scheduled.keys.toSet(),
        );
        final newTag = NotificationScheduler.profileTagOf('guest-2');
        expect(platform.scheduled, isNotEmpty);
        for (final n in platform.scheduled.values) {
          expect(n.payload, startsWith('v1|$newTag|'));
          expect(n.payload, isNot(startsWith('v1|$oldTag|')));
        }
      },
    );

    test('a run in flight when the profile changes schedules nothing more '
        'for the old profile', () async {
      container.read(profileKeyProvider.notifier).select('guest-2');
      platform
        ..gate = Completer<void>()
        ..scheduled.clear();
      phone.notificationStore.ledger = {};
      coordinator.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      // The re-plan waits on the platform; the profile switches meanwhile.
      container.read(profileKeyProvider.notifier).select('guest-3');
      container.read(profileGenerationProvider.notifier).bump();
      platform.gate!.complete();
      await settle();
      final tag = NotificationScheduler.profileTagOf('guest-3');
      expect(
        platform.scheduled.values.map((n) => n.payload),
        everyElement(startsWith('v1|$tag|')),
      );
    });

    test("when the new profile's inputs can't be read, nothing is "
        'scheduled (the old ones are gone)', () async {
      failProfile = true;
      container.read(profileGenerationProvider.notifier).bump();
      await settle();
      expect(platform.scheduled, isEmpty);
      expect(platform.calls, contains('cancelEverything'));
    });

    test('fix-check 1 a crash between a profile switch and its purge: the '
        "next start removes the old profile's notifications, shown ones "
        'included, before planning', () async {
      final oldTag = NotificationScheduler.profileTagOf('guest-old');
      // The last run belonged to another profile; the switch to `local`
      // happened, the purge never ran (the owner is still the old one).
      phone.notificationStore.owner = oldTag;
      final at = DateTime.utc(2026, 10, 31, 2);
      platform.scheduled[42] = ScheduledNotification(
        id: 42,
        at: at,
        title: 't',
        body: 'b',
        payload: NotificationScheduler.payloadOf(
          profileTag: oldTag,
          at: at,
          title: 't',
          body: 'b',
          location: '/today',
        ),
      );
      container.dispose();
      platform.calls.clear();
      await startApp();
      expect(platform.calls.first, 'cancelEverything');
      expect(platform.scheduled.containsKey(42), isFalse);
      final tag = NotificationScheduler.profileTagOf('local');
      expect(phone.notificationStore.owner, tag);
      expect(
        platform.scheduled.values.map((n) => n.payload),
        everyElement(startsWith('v1|$tag|')),
      );
    });
  });
}
