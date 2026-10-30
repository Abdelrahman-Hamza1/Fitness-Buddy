/// Why the app wants to suggest an account to a guest (AC-002, A33 D8).
enum GuestPromptTrigger {
  /// A routine check, e.g. opening Today or Me.
  routine,

  /// The guest tried an action that needs an account (e.g. sync, backup).
  accountOnlyAction,
}

/// When the gentle, dismissible "create an account" prompt may show to a
/// guest (AC-002, A33 D8): after the first week of use, or before an
/// account-only action, and at most once a week either way.
///
/// Pure: the caller passes the instants (no clock reads here).
abstract final class GuestPromptPolicy {
  /// The wait after first use before a routine prompt.
  static const Duration firstWeek = Duration(days: 7);

  /// The minimum gap between two prompts.
  static const Duration minInterval = Duration(days: 7);

  /// Whether to show the prompt at [now].
  ///
  /// [isGuest] is false for registered users (never prompted). [firstUseAt]
  /// is when the app was first used on this install; [lastShownAt] is when
  /// the prompt last showed (shown or dismissed), or `null` if never. A clock
  /// that moved backwards (an instant after [now]) counts as "just now", so
  /// a wrong phone clock can't make the prompt nag.
  static bool shouldShow({
    required bool isGuest,
    required DateTime now,
    required DateTime firstUseAt,
    required DateTime? lastShownAt,
    GuestPromptTrigger trigger = GuestPromptTrigger.routine,
  }) {
    if (!isGuest) return false;
    if (lastShownAt != null && _elapsed(lastShownAt, now) < minInterval) {
      return false;
    }
    return switch (trigger) {
      GuestPromptTrigger.accountOnlyAction => true,
      GuestPromptTrigger.routine => _elapsed(firstUseAt, now) >= firstWeek,
    };
  }

  static Duration _elapsed(DateTime from, DateTime now) {
    final gap = now.difference(from);
    return gap.isNegative ? Duration.zero : gap;
  }
}
