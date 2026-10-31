import 'package:fb_mobile/core/account/account_providers.dart';
import 'package:fb_mobile/core/account/account_removed_note_store.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/navigation/navigation.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/features/account/account.dart';
import 'package:fb_mobile/features/account/application/account_removed_note.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../../core/account/account_fakes.dart' show memoryRegistry;
import '../today/presentation/support/today_support.dart'
    show RecordingNavigator, phoneApp;

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('#241 the store gives the note only to the guest it was recorded '
      'for, once; a note for another profile is dropped, or kept while the '
      'removal is still pending', () async {
    final store = PreferencesAccountRemovedNoteStore(SharedPreferencesAsync());
    Future<String?> raw() =>
        SharedPreferencesAsync().getString(PreferenceKeys.accountRemovedNote);

    await store.mark(AccountRemovedKind.account, guestKey: 'guest-2');
    // The switch hasn't happened (a crash before it): kept, not shown.
    expect(await store.take('acct-1', removalPending: true), isNull);
    expect(await raw(), isNotNull);
    expect(
      await store.take('guest-2', removalPending: true),
      AccountRemovedKind.account,
    );
    expect(await raw(), isNull);
    expect(await store.take('guest-2', removalPending: false), isNull);

    // Another profile is active and no removal is pending: stale, dropped.
    await store.mark(AccountRemovedKind.local, guestKey: 'guest-3');
    expect(await store.take('acct-1', removalPending: false), isNull);
    expect(await raw(), isNull);
  });

  test('#241 the provider reads it on the profile switch a deletion ends '
      'with', () async {
    final registry = memoryRegistry();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(SharedPreferencesAsync()),
        profileRegistryProvider.overrideWithValue(registry),
      ],
    );
    addTearDown(container.dispose);
    final sub = container.listen(accountRemovedNoteProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(accountRemovedNoteProvider.future), isNull);

    final active = (await registry.read()).activeKey;
    await container
        .read(accountRemovedNoteStoreProvider)
        .mark(AccountRemovedKind.account, guestKey: active);
    container.read(profileGenerationProvider.notifier).bump();
    expect(
      await container.read(accountRemovedNoteProvider.future),
      AccountRemovedKind.account,
    );
    container.read(accountRemovedNoteProvider.notifier).dismiss();
    expect(container.read(accountRemovedNoteProvider).value, isNull);
  });

  testWidgets('#241 Today says what was removed, above the guest prompt; OK '
      'hides it', (tester) async {
    final registry = memoryRegistry();
    await PreferencesAccountRemovedNoteStore(SharedPreferencesAsync()).mark(
      AccountRemovedKind.account,
      guestKey: (await registry.read()).activeKey,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(SharedPreferencesAsync()),
          appNavigatorProvider.overrideWithValue(RecordingNavigator()),
          profileRegistryProvider.overrideWithValue(registry),
          accountStatusProvider.overrideWith(
            (ref) async => AccountStatus.guest,
          ),
        ],
        child: phoneApp(const AccountTodayBanner()),
      ),
    );
    await tester.pumpAndSettle();
    const note = ValueKey('account-removed-note');
    expect(find.byKey(note), findsOneWidget);
    expect(
      find.text(
        "Your account and its data were deleted. You're starting fresh as a "
        'guest.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    expect(find.byKey(note), findsNothing);
  });
}
