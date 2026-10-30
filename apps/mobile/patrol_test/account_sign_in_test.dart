import 'package:fb_design_system/fb_design_system.dart';
import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/catalog/catalog_models.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/account_fake_api.dart';
import 'support/patrol_support.dart';

const _banana = 'usda:banana_raw';

Future<int> _liveEntries(ProviderContainer container) async {
  final db = container.read(appDatabaseProvider);
  final rows = await (db.select(
    db.diaryEntries,
  )..where((t) => t.deletedAt.isNull())).get();
  return rows.length;
}

Future<LogFoodOutcome> _logBanana(ProviderContainer container) async {
  final catalog = container.read(foodCatalogRepositoryProvider);
  CatalogFood? food;
  for (var attempt = 0; attempt < 60 && food == null; attempt++) {
    food = (await catalog.foodsByIds([_banana]))[_banana]?.firstOrNull;
    if (food == null) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
  if (food == null) fail('The pack has no food $_banana after 30 s');
  return await container.read(logFoodProvider)(
    choice: catalogChoice(food),
    input: Quantity(100, 'g'),
    date: EntryTime.now(container.read(clockProvider)).localDate,
    slotId: DefaultSlots.breakfastId,
  );
}

Future<void> _openMeRow(WidgetTester tester, String row) async {
  await tapExactly(
    tester,
    find.descendant(of: find.byType(NavigationBar), matching: find.text('Me')),
    'the Me tab',
  );
  final me = find.descendant(
    of: find.byType(MeScreen),
    matching: find.byType(Scrollable),
  );
  await waitUntil(tester, () => me.evaluate().isNotEmpty, 'the Me screen');
  for (var i = 0; i < 20 && find.text(row).evaluate().isEmpty; i++) {
    await tester.drag(me.first, const Offset(0, -200));
    await pumpFor(tester, const Duration(milliseconds: 200));
  }
  await tapExactly(tester, find.text(row), row);
}

/// Waits like [waitUntil]; on timeout fails with what the journey needs to
/// diagnose itself: every visible text, the session, the busy state, the
/// profile registry (hashes and flags only) and the fake API calls.
Future<void> _waitOrDump(
  WidgetTester tester,
  ProviderContainer container,
  AccountFakeApiAdapter api,
  bool Function() done,
  String what,
) async {
  final watch = Stopwatch()..start();
  while (!done() && watch.elapsed < const Duration(seconds: 30)) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (done()) return;
  final texts = [
    for (final e in find.byType(Text).evaluate()) (e.widget as Text).data ?? '',
  ];
  final session = container.read(sessionStateProvider);
  final busy = container.read(accountBusyProvider);
  final snapshot = await container.read(profileRegistryProvider).read();
  fail(
    'Timed out waiting for $what; texts=$texts; session=$session; '
    'busy=$busy; profiles=${snapshot.profiles}; active=${snapshot.activeKey}; '
    'transition=${snapshot.transition}; reserved=${snapshot.reserved}; '
    'api=${api.calls}',
  );
}

/// AC-001 AC-003 AC-004 on the device (A33): the real app on a throw-away
/// profile, the guest session and the email link served by in-app fakes on
/// both HTTP clients, an in-memory session store. The device's real profile
/// registry is saved and restored; no profile files are deleted.
void main() {
  patrolTest(
    'AC-003 AC-004 guest logs food, upgrades with an email code, keeps the '
    'same data and user id, then signs out keeping a read-only copy',
    ($) async {
      final prefs = SharedPreferencesAsync();
      final savedRegistry = await prefs.getString(ProfileRegistry.storageKey);
      await prefs.remove(ProfileRegistry.storageKey);
      addTearDown(() async {
        if (savedRegistry == null) {
          await prefs.remove(ProfileRegistry.storageKey);
        } else {
          await prefs.setString(ProfileRegistry.storageKey, savedRegistry);
        }
      });

      final api = AccountFakeApiAdapter();
      final auth = AccountFakeAuthAdapter();
      final container = await bootApp(
        $,
        'it-account',
        rootName: 'fb_account_it',
        overrides: accountFakeApi(api, auth: auth),
      );
      final tester = $.tester;

      // The guest session arrives in the background after the first frame.
      await waitUntil(
        tester,
        () =>
            container.read(sessionStateProvider).status ==
            SessionStatus.anonymous,
        'the guest session',
      );
      expect(await _logBanana(container), isA<FoodLogged>());
      expect(await _liveEntries(container), 1);

      // Me › Account › Sign in: email, then the code.
      await _openMeRow(tester, 'Sign in or create an account');
      await waitUntil(
        tester,
        () => find.byType(SignInScreen).evaluate().isNotEmpty,
        'the sign-in screen',
      );
      await tester.enterText(find.byType(TextField), 'journey@example.invalid');
      await tapExactly(tester, find.text('Send code'), 'Send code');
      await waitUntil(
        tester,
        () => find.text('6-digit code').evaluate().isNotEmpty,
        'the code field',
      );
      await tester.enterText(find.byType(TextField), accountJourneyCode);
      await tapExactly(tester, find.text('Continue'), 'Continue');
      await _waitOrDump(
        tester,
        container,
        api,
        () => find.text("You're signed in").evaluate().isNotEmpty,
        'the signed-in step',
      );

      // The code came from the authenticated link start, with the guest's
      // own bearer; the account is the same user, now registered.
      expect(
        api.calls,
        containsAllInOrder([
          'POST /v1/auth/link/email/start (Bearer $accountJourneyGuestAccess)',
          'POST /v1/auth/link/email (Bearer $accountJourneyGuestAccess)',
        ]),
      );
      final envelope = await container
          .read(secureSessionStoreProvider)
          .readActive();
      expect(envelope!.userId, accountJourneyUserId);
      expect(envelope.kind, SessionKind.registered);
      final registry = container.read(profileRegistryProvider);
      final active = (await registry.read()).active;
      expect(active.kind, ProfileKind.registered);
      expect(active.ownerRef, registry.ownerRefFor(accountJourneyUserId));
      expect(await _liveEntries(container), 1, reason: 'same data');

      await tapExactly(tester, find.text('Done'), 'Done');
      await pumpFor(tester, const Duration(milliseconds: 500));

      // Sign out, keeping a read-only copy: data visible, editing refused.
      await _openMeRow(tester, 'Sign out');
      await _waitOrDump(
        tester,
        container,
        api,
        () => find.text('Keep a copy on this phone').evaluate().isNotEmpty,
        'the sign-out sheet',
      );
      await tapExactly(
        tester,
        find.text('Keep a copy on this phone'),
        'Keep a copy',
      );
      await waitUntilAsync(
        tester,
        () async => (await registry.read()).active.readOnly,
        'the read-only copy',
      );
      expect(await _liveEntries(container), 1);
      expect(await _logBanana(container), isNot(isA<FoodLogged>()));
      expect(await _liveEntries(container), 1);
      expect(
        container.read(sessionStateProvider).status,
        isNot(SessionStatus.registered),
      );
      expect(find.byType(FbListRow), findsWidgets);
    },
  );
}
