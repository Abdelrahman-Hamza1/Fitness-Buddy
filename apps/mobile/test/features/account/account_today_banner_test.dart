import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/account/application/guest_prompt.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;

final class _ShownPrompt extends GuestPrompt {
  @override
  Future<bool> build() async => true;
}

final class _HiddenPrompt extends GuestPrompt {
  @override
  Future<bool> build() async => false;
}

Future<RecordingNavigator> _pump(
  WidgetTester tester,
  AccountStatus status, {
  bool prompt = false,
}) async {
  final navigator = RecordingNavigator();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appNavigatorProvider.overrideWithValue(navigator),
        accountStatusProvider.overrideWith((ref) async => status),
        guestPromptProvider.overrideWith(
          prompt ? _ShownPrompt.new : _HiddenPrompt.new,
        ),
      ],
      child: phoneApp(const Scaffold(body: AccountTodayBanner())),
    ),
  );
  // Nothing is read in the first frame; the banner appears after it.
  expect(find.byType(Text), findsNothing);
  await tester.pumpAndSettle();
  return navigator;
}

void main() {
  testWidgets('AC-001 session expired: Today shows "sign in again", which '
      'opens sign-in', (tester) async {
    final navigator = await _pump(tester, AccountStatus.sessionExpired);
    expect(find.textContaining('Session expired'), findsOneWidget);
    await tester.tap(find.text('Sign in again'));
    expect(navigator.pushed, [isA<SignInRoute>()]);
  });

  testWidgets('AC-004 a read-only copy says so and offers sign-in', (
    tester,
  ) async {
    final navigator = await _pump(tester, AccountStatus.readOnlyCopy);
    expect(find.textContaining('read-only copy'), findsOneWidget);
    await tester.tap(find.text('Sign in or create an account'));
    expect(navigator.pushed, [isA<SignInRoute>()]);
  });

  testWidgets('AC-002 the guest prompt opens sign-in or hides on "Not now"', (
    tester,
  ) async {
    final navigator = await _pump(tester, AccountStatus.guest, prompt: true);
    await tester.tap(find.text('Create account'));
    expect(navigator.pushed, [isA<SignInRoute>()]);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Create account'), findsNothing);
  });

  testWidgets('AC-002 a signed-in account with a live session shows nothing', (
    tester,
  ) async {
    await _pump(tester, AccountStatus.signedIn, prompt: true);
    expect(find.byType(Text), findsNothing);
  });
}
