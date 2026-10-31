import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/profile_registry.dart';
import 'package:fb_mobile/core/db/app_database.dart';
import 'package:fb_mobile/core/db/db_providers.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/session/session_providers.dart';
import 'package:fb_mobile/core/session/session_state.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/foods/foods.dart';
import 'package:fb_mobile/features/me/me.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../patrol_test/support/account_fake_api.dart';
import '../../helpers/pump_app.dart';
import '../foods/presentation/support/sheet_support.dart' show foodOf;

/// Like [_until], but lets real I/O run between frames: once the profile
/// database has been used, the upgrade's quiesce waits on it.
Future<void> _untilWithIo(
  WidgetTester tester,
  bool Function() done,
  String what,
) async {
  for (var i = 0; i < 300 && !done(); i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
  if (!done()) await _until(tester, done, what);
}

/// The live (not deleted) diary rows of the open profile.
Future<List<DiaryEntryRow>> _liveEntries(ProviderContainer c) {
  final db = c.read(appDatabaseProvider);
  return (db.select(db.diaryEntries)..where((t) => t.deletedAt.isNull())).get();
}

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

Future<void> _tapMeRow(
  WidgetTester tester,
  String row, {
  Type screen = MeScreen,
}) async {
  final me = find.descendant(
    of: find.byType(screen),
    matching: find.byType(Scrollable),
  );
  await _until(tester, () => me.evaluate().isNotEmpty, '$screen');
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

    // Me's account card › Sign in (pushed, as on the device).
    showRoute(c, const MeRoute());
    await _tapMeRow(tester, 'Sign in');
    await _until(
      tester,
      () => find.byType(SignInScreen).evaluate().isNotEmpty,
      'the sign-in screen',
    );
    await tester.enterText(find.byType(TextField), 'journey@example.invalid');
    await tester.tap(find.text('Continue with email'));
    await _until(
      tester,
      () => find.text('Check your email').evaluate().isNotEmpty,
      'the code boxes',
    );
    // The sixth digit continues on its own.
    await tester.enterText(find.byType(TextField), accountJourneyCode);
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
    await _tapMeRow(tester, 'Account & data');
    await _tapMeRow(tester, 'Sign out', screen: MeAccountScreen);
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

  testWidgets('AC-001 AC-003 host replay: a guest upgrades with Google (fake '
      'source), same data and user id', (tester) async {
    final api = AccountFakeApiAdapter();
    final auth = AccountFakeAuthAdapter();
    final google = FakeGoogleIdTokenSource();
    final c = await pumpApp(
      tester,
      overrides: [
        ...accountFakeApi(api, auth: auth),
        googleIdTokenSourceProvider.overrideWithValue(google),
      ],
    );
    final registry = c.read(profileRegistryProvider);

    await _until(
      tester,
      () => c.read(sessionStateProvider).status == SessionStatus.anonymous,
      'the guest session',
    );
    final before = await tester.runAsync(
      () async => (await registry.read()).activeKey,
    );
    // The guest logs one food before the upgrade (A50 review).
    final logged = await tester.runAsync(
      () => c.read(logFoodProvider)(
        choice: catalogChoice(foodOf('usda:banana_raw', 'Banana', kcal: 89)),
        input: Quantity(120, 'g'),
        date: EntryTime.now(c.read(clockProvider)).localDate,
        slotId: DefaultSlots.breakfastId,
      ),
    );
    expect(logged, isA<FoodLogged>());
    final seeded = (await tester.runAsync(() => _liveEntries(c)))!;
    expect(seeded, hasLength(1));

    showRoute(c, const MeRoute());
    await _tapMeRow(tester, 'Sign in');
    await _until(
      tester,
      () => find.byType(SignInScreen).evaluate().isNotEmpty,
      'the sign-in screen',
    );
    await tester.tap(find.text('Continue with Google'));
    await _untilWithIo(
      tester,
      () => find.text("You're signed in").evaluate().isNotEmpty,
      'the signed-in step',
    );

    expect(google.tokenRequests, 1);
    expect(
      api.calls,
      contains('POST /v1/auth/link/google (Bearer $accountJourneyGuestAccess)'),
    );
    final active = await tester.runAsync(
      () async => (await registry.read()).active,
    );
    expect(active!.kind, ProfileKind.registered);
    expect(active.ownerRef, registry.ownerRefFor(accountJourneyUserId));
    expect(active.profileKey, before, reason: 'same database, same data');
    final kept = (await tester.runAsync(() => _liveEntries(c)))!;
    expect(kept, hasLength(1), reason: 'the guest entry survives');
    final (a, b) = (seeded.single, kept.single);
    expect(
      (b.id, b.localDate, b.slotId, b.nameEn, b.inputAmount, b.inputUnit),
      (a.id, a.localDate, a.slotId, 'Banana', 120.0, 'g'),
    );
    expect((b.kcal, b.proteinG), (a.kcal, a.proteinG));
    await unmountApp(tester, c);
  });
}
