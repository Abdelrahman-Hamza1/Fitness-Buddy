import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../patrol_test/support/account_fake_api.dart';
import '../../helpers/pump_app.dart';

/// Pumps (fake clock) until [done], or fails with the visible texts.
Future<void> _until(
  WidgetTester tester,
  bool Function() done,
  String what,
) async {
  for (var i = 0; i < 300 && !done(); i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (!done()) {
    final texts = [
      for (final e in find.byType(Text).evaluate())
        (e.widget as Text).data ?? '',
    ];
    fail('Timed out waiting for $what; texts: $texts');
  }
}

Future<void> _tapMeRow(WidgetTester tester, String row) async {
  final me = find.descendant(
    of: find.byType(MeScreen),
    matching: find.byType(Scrollable),
  );
  await _until(tester, () => me.evaluate().isNotEmpty, 'Me');
  for (var i = 0; i < 20 && find.text(row).evaluate().isEmpty; i++) {
    await tester.drag(me.first, const Offset(0, -200));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await tester.ensureVisible(find.text(row));
  await tester.pump(const Duration(milliseconds: 100));
  await tester.tap(find.text(row));
}

/// The device journey (`patrol_test/account_sign_in_test.dart`) on the host,
/// with the same fakes, so a failure shows up without an emulator.
void main() {
  testWidgets('AC-003 AC-004 host replay of the device journey: a guest '
      'upgrades with an email code (same user id), then signs out keeping a '
      'read-only copy', (tester) async {
    final api = AccountFakeApiAdapter();
    final auth = AccountFakeAuthAdapter();
    final c = await pumpApp(tester, overrides: accountFakeApi(api, auth: auth));
    final registry = c.read(profileRegistryProvider);

    await _until(
      tester,
      () => c.read(sessionStateProvider).status == SessionStatus.anonymous,
      'the guest session',
    );

    // Me › Account › Sign in (pushed, as on the device).
    showRoute(c, const MeRoute());
    await _tapMeRow(tester, 'Sign in or create an account');
    await _until(
      tester,
      () => find.byType(SignInScreen).evaluate().isNotEmpty,
      'the sign-in screen',
    );
    await tester.enterText(find.byType(TextField), 'journey@example.invalid');
    await tester.tap(find.text('Send code'));
    await _until(
      tester,
      () => find.text('6-digit code').evaluate().isNotEmpty,
      'the code field',
    );
    await tester.enterText(find.byType(TextField), accountJourneyCode);
    await tester.tap(find.text('Continue'));
    await _until(
      tester,
      () => find.text("You're signed in").evaluate().isNotEmpty,
      'the signed-in step',
    );
    expect(
      api.calls,
      containsAllInOrder([
        'POST /v1/auth/link/email/start (Bearer $accountJourneyGuestAccess)',
        'POST /v1/auth/link/email (Bearer $accountJourneyGuestAccess)',
      ]),
    );
    final active = await tester.runAsync(
      () async => (await registry.read()).active,
    );
    expect(active!.kind, ProfileKind.registered);
    expect(active.ownerRef, registry.ownerRefFor(accountJourneyUserId));

    // Done closes sign-in; sign out keeping a read-only copy.
    await tester.tap(find.text('Done'));
    await _until(
      tester,
      () => find.byType(SignInScreen).evaluate().isEmpty,
      'sign-in to close',
    );
    await _tapMeRow(tester, 'Sign out');
    await _until(
      tester,
      () => find.text('Keep a copy on this phone').evaluate().isNotEmpty,
      'the sign-out sheet',
    );
    // Let the sheet finish sliding in before tapping its option.
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.tap(find.text('Keep a copy on this phone'));
    await _until(
      tester,
      () => find.textContaining('read-only copy').evaluate().isNotEmpty,
      'the read-only copy',
    );
    final after = await tester.runAsync(
      () async => (await registry.read()).active,
    );
    expect(after!.readOnly, isTrue);
    await unmountApp(tester, c);
  });
}
