import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/account/account_fakes.dart';
import '../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;

void main() {
  late FakeIdentity identity;
  late FakeSession session;
  late ProfileRegistry registry;

  setUp(() {
    final log = EventLog();
    identity = FakeIdentity();
    session = FakeSession(log);
    registry = memoryRegistry();
  });

  Future<void> pump(WidgetTester tester, {FakeGoogle? google}) async {
    final service = AccountService(
      identity: identity,
      transitions: AccountTransitions(
        registry: registry,
        session: session,
        host: FakeHost(EventLog()),
        newTag: () => 'tag',
      ),
      registry: registry,
      google: google ?? FakeGoogle(available: false),
      revoke: (_) async {},
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountServiceProvider.overrideWithValue(service),
          appNavigatorProvider.overrideWithValue(RecordingNavigator()),
        ],
        child: phoneApp(const SignInScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('AC-003 a 409 asks merge or discard; a wrong code says so', (
    tester,
  ) async {
    identity.linkConflicts = true;
    await pump(tester);
    await tester.enterText(find.byType(TextField), canaryEmail);
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    expect(find.text('Check your email'), findsOneWidget);
    expect(find.textContaining(canaryEmail), findsOneWidget);
    // Six digits continue on their own.
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(find.text('This account already exists'), findsOneWidget);
    expect(find.text('Add it to my account'), findsOneWidget);
    expect(find.text('Discard it'), findsOneWidget);

    await tester.tap(find.text('Add it to my account'));
    await tester.pumpAndSettle();
    // A sign-in code for the same address is on its way.
    expect(identity.calls.last, 'start:signIn');
    identity.offline = true;
    await tester.enterText(find.byType(TextField), '654321');
    await tester.pumpAndSettle();
    expect(find.textContaining("You're offline"), findsOneWidget);
  });

  testWidgets('AC-001 the code step: a paste fills the boxes, resend waits '
      'out its countdown, "Use a different email" goes back', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), canaryEmail);
    await tester.tap(find.text('Continue with email'));
    await tester.pump();
    await tester.pump();
    expect(find.text('Resend in 0:30'), findsOneWidget);
    expect(identity.calls, ['start:link']);
    await tester.pump(const Duration(seconds: 12));
    expect(find.text('Resend in 0:18'), findsOneWidget);
    await tester.pump(const Duration(seconds: 18));
    await tester.tap(find.text('Resend code'));
    await tester.pump();
    await tester.pump();
    expect(identity.calls, ['start:link', 'start:link']);
    expect(find.text('Resend in 0:30'), findsOneWidget);

    await tester.tap(find.text('Use a different email'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in or create an account'), findsOneWidget);
    expect(find.text('Continue with email'), findsOneWidget);
  });

  testWidgets('AC-001 the Google button shows only when available; '
      'unavailable shows its own error', (tester) async {
    final l10n = lookupAppLocalizations(const Locale('en'));
    await pump(tester);
    expect(find.text(l10n.signInGoogle), findsNothing);
    // A fresh tree: the screen's flow belongs to the service it started with.
    await tester.pumpWidget(const SizedBox());

    final google = FakeGoogle()
      ..failure = const GoogleIdTokenException(
        GoogleIdTokenFailure.unavailable,
      );
    await pump(tester, google: google);
    await tester.tap(find.text(l10n.signInGoogle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.signInErrorGoogleUnavailable), findsOneWidget);
    expect(identity.calls, isEmpty);

    google.failure = const GoogleIdTokenException(GoogleIdTokenFailure.failed);
    await tester.tap(find.text(l10n.signInGoogle));
    await tester.pumpAndSettle();
    expect(find.text(l10n.signInErrorOther), findsOneWidget);
    expect(find.text(l10n.signInErrorGoogleUnavailable), findsNothing);
  });
}
