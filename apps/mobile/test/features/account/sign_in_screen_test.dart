import 'dart:async';

import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_service.dart';
import 'package:fb_mobile/core/account/account_transitions.dart';
import 'package:fb_mobile/core/account/google_id_token_source.dart';
import 'package:fb_mobile/core/account/local_identity_store.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/account/application/account_removed_note.dart';
import 'package:fb_mobile/features/account/application/local_identity.dart';
import 'package:fb_mobile/l10n/gen/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../core/account/account_fakes.dart';
import '../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;

/// The sign-in screen's providers over the fakes; who signed in is kept
/// as the app keeps it ([keepSignedIn], A63 review).
List<Override> _signInOverrides({
  required FakeIdentity identity,
  required FakeSession session,
  required ProfileRegistry registry,
  required FakeGoogle google,
  required LocalIdentityStore store,
}) => [
  accountServiceProvider.overrideWith(
    (ref) => AccountService(
      identity: identity,
      transitions: AccountTransitions(
        registry: registry,
        session: session,
        host: FakeHost(EventLog()),
        newTag: () => 'tag',
      ),
      registry: registry,
      google: google,
      revoke: (_) async {},
      onSignedIn: keepSignedIn(ref),
    ),
  ),
  appNavigatorProvider.overrideWithValue(RecordingNavigator()),
  localIdentityStoreProvider.overrideWithValue(store),
];

/// A sign-in that switched to `acct-me` and still asks its name.
final class _AskingRecent extends RecentSignIn {
  @override
  ({String profileKey, bool askName})? build() =>
      (profileKey: 'acct-me', askName: true);
}

/// The switched-to profile: its email, no name yet.
final class _Unnamed extends MeIdentity {
  @override
  Future<({String profileKey, LocalIdentity identity})?> build() async => (
    profileKey: 'acct-me',
    identity: const LocalIdentity(email: canaryEmail),
  );
}

final class _NoNote extends AccountRemovedNote {
  @override
  Future<AccountRemovedKind?> build() async => null;
}

/// Today's account line right after a sign-in whose profile switch closed
/// the sign-in screen (A63 review).
List<Override> _afterSwitchOverrides() => [
  recentSignInProvider.overrideWith(_AskingRecent.new),
  meIdentityProvider.overrideWith(_Unnamed.new),
  accountRemovedNoteProvider.overrideWith(_NoNote.new),
  accountStatusProvider.overrideWith((ref) async => AccountStatus.signedIn),
  appNavigatorProvider.overrideWithValue(RecordingNavigator()),
];

void main() {
  late FakeIdentity identity;
  late FakeSession session;
  late ProfileRegistry registry;

  setUp(() {
    // The identity store's preferences, in memory (no platform channel).
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final log = EventLog();
    identity = FakeIdentity();
    session = FakeSession(log);
    registry = memoryRegistry();
  });

  Future<void> pump(
    WidgetTester tester, {
    FakeGoogle? google,
    LocalIdentityStore? store,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._signInOverrides(
            identity: identity,
            session: session,
            registry: registry,
            google: google ?? FakeGoogle(available: false),
            store:
                store ??
                LocalIdentityStore(SharedPreferencesAsync(), namespace: 'dev'),
          ),
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

  testWidgets('UX-045 A57 T-S4 T-S7 the code step: an error and the busy '
      'state keep the Verify button where it is', (tester) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), canaryEmail);
    await tester.tap(find.byKey(const ValueKey('sign-in-email-button')));
    await tester.pumpAndSettle();
    final verify = find.byKey(const ValueKey('sign-in-verify-button'));
    final size = tester.getSize(verify);
    final top = tester.getTopLeft(verify).dy;

    identity.offline = true;
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    expect(
      tester.widget<FbCodeBoxes>(find.byType(FbCodeBoxes)).errorText,
      isNotNull,
    );
    expect(tester.getTopLeft(verify).dy, top, reason: 'error');

    identity
      ..offline = false
      ..hold = Completer<void>();
    await tester.enterText(find.byType(TextField), '654321');
    await tester.pump();
    final button = tester.widget<FbButton>(verify);
    expect(button.busy, isTrue);
    expect(button.onPressed, isNull);
    expect(tester.getSize(verify), size, reason: 'busy');
    expect(tester.getTopLeft(verify).dy, top, reason: 'busy');
    identity.hold!.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('AC-005 AC-001 M2 T-M2 email sign-in asks once for a name and '
      'stores it with the email; skipping stores no name; Google stores its '
      'name and email without asking', (tester) async {
    final store = LocalIdentityStore(
      SharedPreferencesAsync(),
      namespace: 'dev',
    );
    // In-memory preferences: the reads complete in the test's fake zone
    // (runAsync would wait on a queue only that zone completes).
    Future<LocalIdentity> stored() async =>
        await store.read((await registry.read()).activeKey);

    await pump(tester, store: store);
    await tester.enterText(find.byType(TextField), canaryEmail);
    await tester.tap(find.byKey(const ValueKey('sign-in-email-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    final name = find.byKey(const ValueKey('sign-in-name'));
    expect(name, findsOneWidget);
    await tester.enterText(
      find.descendant(of: name, matching: find.byType(TextField)),
      '  Abood ',
    );
    await tester.tap(find.byKey(const ValueKey('sign-in-done')));
    await tester.pumpAndSettle();
    expect(
      await stored(),
      const LocalIdentity(name: 'Abood', email: canaryEmail),
    );

    // Skipped: the email only.
    registry = memoryRegistry();
    final skipStore = LocalIdentityStore(
      SharedPreferencesAsync(),
      namespace: 'dev',
    );
    await tester.pumpWidget(const SizedBox());
    await pump(tester, store: skipStore);
    await tester.enterText(find.byType(TextField), canaryEmail);
    await tester.tap(find.byKey(const ValueKey('sign-in-email-button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('sign-in-done')));
    await tester.pumpAndSettle();
    final skipped = await skipStore.read((await registry.read()).activeKey);
    expect(skipped, const LocalIdentity(email: canaryEmail));
  });

  testWidgets('AC-005 T-M2 Google sign-in stores the Google name and email; '
      'the done step asks nothing', (tester) async {
    final store = LocalIdentityStore(
      SharedPreferencesAsync(),
      namespace: 'dev',
    );
    await pump(tester, google: FakeGoogle(), store: store);
    await tester.tap(find.byType(FbGoogleButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sign-in-done')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign-in-name')), findsNothing);
    final stored = await store.read((await registry.read()).activeKey);
    expect(
      stored,
      const LocalIdentity(name: canaryGoogleName, email: canaryGoogleEmail),
    );
  });

  testWidgets('AC-005 M2 A63 review after an email sign-in whose switch '
      'closed the screen, Today asks for the name once; Not now hides it', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [..._afterSwitchOverrides()],
        child: phoneApp(const AccountTodayBanner()),
      ),
    );
    await tester.pumpAndSettle();
    final prompt = find.byKey(const ValueKey('sign-in-name-prompt'));
    expect(prompt, findsOneWidget);
    expect(find.text('What should we call you?'), findsOneWidget);
    await tester.tap(
      find.descendant(of: prompt, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();
    expect(prompt, findsNothing);
  });
}
