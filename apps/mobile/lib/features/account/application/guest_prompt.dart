import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/account/application/sign_in_controller.dart';
import 'package:fb_mobile/features/account/data/guest_prompt_store.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guest_prompt.g.dart';

/// Whether the gentle, dismissible "create an account" card shows on Today
/// (AC-002, A33 D8): the cadence rule is [GuestPromptPolicy]; this only
/// reads and records the instants. Once shown it stays for this run until
/// dismissed or the user is no longer a guest.
@Riverpod(keepAlive: true)
class GuestPrompt extends _$GuestPrompt {
  bool _shownThisRun = false;
  bool _dismissed = false;

  @override
  Future<bool> build() async {
    final status = await ref.watch(accountStatusProvider.future);
    if (status != AccountStatus.guest || _dismissed) return false;
    if (_shownThisRun) return true;
    final store = ref.read(guestPromptStoreProvider);
    final now = ref.read(clockProvider).nowUtc();
    final stored = await store.read();
    final firstUseAt = stored.firstUseAt;
    if (firstUseAt == null) {
      // The first check starts the first-week wait.
      await store.write(GuestPromptState(firstUseAt: now));
      return false;
    }
    final show = GuestPromptPolicy.shouldShow(
      isGuest: true,
      now: now,
      firstUseAt: firstUseAt,
      lastShownAt: stored.lastShownAt,
    );
    if (show) {
      // Showing counts, so the weekly limit holds even if never dismissed.
      await store.write(
        GuestPromptState(firstUseAt: firstUseAt, lastShownAt: now),
      );
      _shownThisRun = true;
    }
    return show;
  }

  /// "Not now": hides the card for this run (the weekly limit already
  /// started when it showed).
  void dismiss() {
    _dismissed = true;
    state = const AsyncData(false);
  }
}
