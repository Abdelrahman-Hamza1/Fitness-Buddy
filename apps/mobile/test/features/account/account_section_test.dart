import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;

final class _Actions extends AccountActions {
  final calls = <String>[];

  @override
  Future<void> signOut(SignOutChoice choice) async =>
      calls.add('signOut:${choice.name}');

  @override
  Future<void> continueAsGuest() async => calls.add('continueAsGuest');
}

Future<(RecordingNavigator, _Actions)> _pump(
  WidgetTester tester,
  AccountStatus status,
) async {
  final navigator = RecordingNavigator();
  final actions = _Actions();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appNavigatorProvider.overrideWithValue(navigator),
        accountStatusProvider.overrideWith((ref) async => status),
        accountActionsProvider.overrideWith(() => actions),
      ],
      child: phoneApp(
        const Scaffold(body: SingleChildScrollView(child: AccountSection())),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (navigator, actions);
}

void main() {
  testWidgets('AC-002 a guest sees the guest line and can open sign-in, but '
      'has nothing to sign out of', (tester) async {
    final (navigator, _) = await _pump(tester, AccountStatus.guest);
    expect(find.textContaining('as a guest'), findsOneWidget);
    expect(find.text('Sign out'), findsNothing);
    expect(find.text('Sync status'), findsNothing);
    await tester.tap(find.text('Sign in or create an account'));
    expect(navigator.pushed, [isA<SignInRoute>()]);
  });

  testWidgets('AC-004 signed in: Sign out asks keep or remove and passes the '
      'choice on; sync and delete are placeholders', (tester) async {
    final (_, actions) = await _pump(tester, AccountStatus.signedIn);
    expect(find.text('Signed in'), findsOneWidget);
    expect(find.text('Sync status'), findsOneWidget);
    expect(find.text('Delete account'), findsOneWidget);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Keep a copy on this phone'), findsOneWidget);
    expect(find.text('Remove from this phone'), findsOneWidget);
    await tester.tap(find.text('Keep a copy on this phone'));
    await tester.pumpAndSettle();
    expect(actions.calls, ['signOut:keep']);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove from this phone'));
    await tester.pumpAndSettle();
    expect(actions.calls, ['signOut:keep', 'signOut:remove']);
  });

  testWidgets('AC-004 a read-only copy offers sign-in and continuing as a '
      'guest', (tester) async {
    final (navigator, actions) = await _pump(
      tester,
      AccountStatus.readOnlyCopy,
    );
    await tester.tap(find.text('Continue as guest'));
    await tester.pumpAndSettle();
    expect(actions.calls, ['continueAsGuest']);
    await tester.tap(find.text('Sign in or create an account'));
    expect(navigator.pushed, [isA<SignInRoute>()]);
  });

  testWidgets('AC-001 session expired offers "Sign in again" and sign-out', (
    tester,
  ) async {
    final (navigator, _) = await _pump(tester, AccountStatus.sessionExpired);
    expect(find.text('Sign out'), findsOneWidget);
    await tester.tap(find.text('Sign in again'));
    expect(navigator.pushed, [isA<SignInRoute>()]);
  });
}
