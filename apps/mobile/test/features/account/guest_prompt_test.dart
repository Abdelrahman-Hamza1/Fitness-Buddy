import 'package:fb_domain/testing.dart';
import 'package:fb_mobile/core/storage/preferences.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/account/application/guest_prompt.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  late ManualClock clock;
  late AccountStatus status;

  ProviderContainer container() {
    final c = ProviderContainer(
      overrides: [
        clockProvider.overrideWithValue(clock),
        sharedPreferencesProvider.overrideWithValue(SharedPreferencesAsync()),
        accountStatusProvider.overrideWith((ref) async => status),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    clock = ManualClock(DateTime.utc(2026, 10, 1, 9));
    status = AccountStatus.guest;
  });

  test('AC-002 the first check starts the first week; the card shows from '
      'day 7, once per run, and records when it showed', () async {
    expect(await container().read(guestPromptProvider.future), isFalse);
    clock.advance(const Duration(days: 6));
    expect(await container().read(guestPromptProvider.future), isFalse);
    clock.advance(const Duration(days: 1));
    final run = container();
    expect(await run.read(guestPromptProvider.future), isTrue);
    // Shown counts: a new run the next day doesn't show it again.
    clock.advance(const Duration(days: 1));
    expect(await container().read(guestPromptProvider.future), isFalse);
    // A week after it showed, it may show again.
    clock.advance(const Duration(days: 6));
    expect(await container().read(guestPromptProvider.future), isTrue);
    final stored = await SharedPreferencesAsync().getString(
      PreferenceKeys.guestPrompt,
    );
    expect(stored, contains('lastShownAt'));
    expect(stored, isNot(contains('@')));
  });

  test('AC-002 "Not now" hides the card for this run', () async {
    await container().read(guestPromptProvider.future);
    clock.advance(const Duration(days: 8));
    final run = container();
    expect(await run.read(guestPromptProvider.future), isTrue);
    run.read(guestPromptProvider.notifier).dismiss();
    expect(run.read(guestPromptProvider).value, isFalse);
  });

  test('AC-002 registered users and read-only copies never see it', () async {
    for (final s in [
      AccountStatus.signedIn,
      AccountStatus.sessionExpired,
      AccountStatus.readOnlyCopy,
    ]) {
      status = s;
      clock.advance(const Duration(days: 30));
      expect(await container().read(guestPromptProvider.future), isFalse);
    }
  });
}
