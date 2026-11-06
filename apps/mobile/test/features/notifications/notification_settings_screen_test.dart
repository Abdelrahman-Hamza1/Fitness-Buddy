import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/settings/settings_store.dart';
import 'package:fb_mobile/features/notifications/notifications.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/pump_app.dart';
import '../settings/presentation/settings_support.dart';

Future<NotificationPrefs?> _stored(
  WidgetTester tester,
  ProviderContainer container,
) => tester.runAsync(
  () =>
      container.read(settingsStoreProvider).read(AppSettings.notificationPrefs),
);

void main() {
  testWidgets('NT-020 A40 D10 Me › Notifications: spec/17 defaults, a type '
      'switched off and the master switch, each saved with Undo; the '
      'Android permission banner asks', (tester) async {
    final phone = TestPhone()..notificationPlatform.allowed = false;
    final container = await pumpAt(tester, phone: phone);
    await openMe(tester);
    await tester.tap(find.byKey(const ValueKey('settings-notifications')));
    await tester.pumpAndSettle();
    expect(find.byType(NotificationSettingsScreen), findsOneWidget);

    // Defaults: master on; the log reminder on with its time row, the
    // workout reminder off without one.
    Switch switchOf(String key) => tester.widget<Switch>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Switch),
      ),
    );
    expect(switchOf('notif-master').value, isTrue);
    expect(switchOf('notif-logReminder').value, isTrue);
    expect(
      find.byKey(const ValueKey('notif-logReminder-time')),
      findsOneWidget,
    );
    expect(switchOf('notif-workout').value, isFalse);
    expect(find.byKey(const ValueKey('notif-workout-time')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('notif-logReminder')));
    await settleWrites(tester);
    expect(
      (await _stored(
        tester,
        container,
      ))!.of(NotificationType.logReminder).enabled,
      isFalse,
    );
    expect(find.text('Undo'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('notif-master')));
    await settleWrites(tester);
    expect((await _stored(tester, container))!.enabled, isFalse);
    expect(find.byKey(const ValueKey('notif-quiet')), findsNothing);

    // Android blocks notifications: Allow asks once.
    expect(find.byKey(const ValueKey('notif-permission')), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('notif-permission')),
        matching: find.byType(TextButton),
      ),
    );
    await settleWrites(tester);
    expect(phone.notificationPlatform.requests, 1);
    expect(find.byKey(const ValueKey('notif-permission')), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('NT-021 #243 a reminder time inside quiet hours says it '
      "won't show; outside them it says nothing", (tester) async {
    final container = await pumpAt(tester);
    // Started like a tap's write (in the test zone), then settled.
    unawaited(
      container
          .read(settingsActionsProvider)
          .setNotificationPrefs(
            NotificationPrefs.defaults.copyWith(quietStart: 20 * 60),
          ),
    );
    await settleWrites(tester);
    await openMe(tester);
    await tester.tap(find.byKey(const ValueKey('settings-notifications')));
    await tester.pumpAndSettle();
    // The log reminder (21:00) falls in 20:00–07:00; the weigh-in (08:00)
    // doesn't.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('notif-logReminder-time')),
        matching: find.text("In quiet hours: won't show"),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('notif-weighIn-time')),
        matching: find.text("In quiet hours: won't show"),
      ),
      findsNothing,
    );
    await unmountApp(tester, container);
  });

  testWidgets("A40 review 5 Allow after a permanent denial opens the app's "
      'notification settings; turned on there, the banner goes', (
    tester,
  ) async {
    final phone = TestPhone();
    phone.notificationPlatform
      ..allowed = false
      ..grantOnRequest = false
      ..settingsEnable = true;
    final container = await pumpAt(tester, phone: phone);
    await openMe(tester);
    await tester.tap(find.byKey(const ValueKey('settings-notifications')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('notif-permission')),
        matching: find.byType(TextButton),
      ),
    );
    await settleWrites(tester);
    expect(phone.notificationPlatform.calls, ['request', 'openSettings']);
    expect(find.byKey(const ValueKey('notif-permission')), findsNothing);
    await unmountApp(tester, container);
  });

  testWidgets('UX-052 A63 T-S4 a failed read of the reminder choices shows '
      'Try again, not the defaults as if saved', (tester) async {
    var fail = true;
    final container = await pumpAt(
      tester,
      overrides: [
        notificationPrefsProvider.overrideWith(
          (ref) => fail
              ? Stream<NotificationPrefs>.error(StateError('storage'))
              : Stream.value(NotificationPrefs.defaults),
        ),
      ],
    );
    await openMe(tester);
    await tester.tap(find.byKey(const ValueKey('settings-notifications')));
    await tester.pumpAndSettle();
    final failed = find.byKey(const ValueKey('notif-load-failed'));
    expect(failed, findsOneWidget);
    expect(find.byKey(const ValueKey('notif-master')), findsNothing);
    fail = false;
    await tester.tap(
      find.descendant(of: failed, matching: find.byType(TextButton)),
    );
    await tester.pumpAndSettle();
    expect(failed, findsNothing);
    expect(find.byKey(const ValueKey('notif-master')), findsOneWidget);
    await unmountApp(tester, container);
  });

  testWidgets('A65 m4 M4 each reminder sits in its own card with its time; '
      'the Ramadan pair comes last under a note', (tester) async {
    final container = await pumpAt(tester);
    await openMe(tester);
    await tester.tap(find.byKey(const ValueKey('settings-notifications')));
    await tester.pumpAndSettle();
    // The log reminder's switch and time share one card.
    final card = find.ancestor(
      of: find.byKey(const ValueKey('notif-logReminder')),
      matching: find.byType(FbCard),
    );
    expect(
      find.descendant(
        of: card,
        matching: find.byKey(const ValueKey('notif-logReminder-time')),
      ),
      findsOneWidget,
    );
    final note = find.byKey(const ValueKey('notif-ramadan-note'));
    await tester.scrollUntilVisible(note, 200);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notif-iftar')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('notif-iftar'))).dy,
      lessThan(tester.getTopLeft(note).dy),
    );
    await unmountApp(tester, container);
  });
}
