import 'package:fb_domain/fb_domain.dart';
import 'package:glados/glados.dart';

void main() {
  final start = DateTime.utc(2026, 10, 1, 9);
  DateTime day(int n) => start.add(Duration(days: n));

  test('AC-002 guest prompt not before the first week', () {
    for (final n in [0, 1, 6]) {
      expect(
        GuestPromptPolicy.shouldShow(
          isGuest: true,
          now: day(n),
          firstUseAt: start,
          lastShownAt: null,
        ),
        isFalse,
        reason: 'day $n',
      );
    }
    expect(
      GuestPromptPolicy.shouldShow(
        isGuest: true,
        now: day(7),
        firstUseAt: start,
        lastShownAt: null,
      ),
      isTrue,
    );
  });

  test('AC-002 guest prompt at most once a week', () {
    expect(
      GuestPromptPolicy.shouldShow(
        isGuest: true,
        now: day(13),
        firstUseAt: start,
        lastShownAt: day(7),
      ),
      isFalse,
    );
    expect(
      GuestPromptPolicy.shouldShow(
        isGuest: true,
        now: day(14),
        firstUseAt: start,
        lastShownAt: day(7),
      ),
      isTrue,
    );
  });

  test('AC-002 account-only action bypasses the first-week wait but not the '
      'weekly limit', () {
    expect(
      GuestPromptPolicy.shouldShow(
        isGuest: true,
        now: day(1),
        firstUseAt: start,
        lastShownAt: null,
        trigger: GuestPromptTrigger.accountOnlyAction,
      ),
      isTrue,
    );
    expect(
      GuestPromptPolicy.shouldShow(
        isGuest: true,
        now: day(2),
        firstUseAt: start,
        lastShownAt: day(1),
        trigger: GuestPromptTrigger.accountOnlyAction,
      ),
      isFalse,
    );
  });

  test('AC-002 registered users are never prompted', () {
    for (final trigger in GuestPromptTrigger.values) {
      expect(
        GuestPromptPolicy.shouldShow(
          isGuest: false,
          now: day(30),
          firstUseAt: start,
          lastShownAt: null,
          trigger: trigger,
        ),
        isFalse,
      );
    }
  });

  test('AC-002 a clock that moved backwards never shows the prompt', () {
    expect(
      GuestPromptPolicy.shouldShow(
        isGuest: true,
        now: day(20),
        firstUseAt: start,
        lastShownAt: day(40),
      ),
      isFalse,
    );
    expect(
      GuestPromptPolicy.shouldShow(
        isGuest: true,
        now: start,
        firstUseAt: day(10),
        lastShownAt: null,
      ),
      isFalse,
    );
  });

  Glados2(
    any.intInRange(0, 60 * 24 * 60),
    any.intInRange(0, 60 * 24 * 60),
  ).test('AC-002 never two prompts less than a week apart', (a, b) {
    final last = start.add(Duration(minutes: a));
    final now = start.add(Duration(minutes: b));
    final shown = GuestPromptPolicy.shouldShow(
      isGuest: true,
      now: now,
      firstUseAt: start,
      lastShownAt: last,
      trigger: GuestPromptTrigger.accountOnlyAction,
    );
    if (shown) {
      expect(
        now.difference(last),
        greaterThanOrEqualTo(const Duration(days: 7)),
      );
    }
  });
}
