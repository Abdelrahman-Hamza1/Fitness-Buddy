/// Whether a Buddy suggestion fits what's left today (AI-120, A68 D5): the
/// app drops options that would take the day more than [tolerance] of its
/// calorie target over it.
abstract final class SuggestionFit {
  /// How far over today's target an option may go and still fit: 5 % of
  /// the target.
  static const double tolerance = 0.05;

  /// Whether an option that leaves [remainingKcal] (negative: over) of a
  /// [targetKcal] day fits. An unknown target or remaining always fits.
  static bool fits({
    required double? remainingKcal,
    required double? targetKcal,
  }) =>
      remainingKcal == null ||
      targetKcal == null ||
      remainingKcal >= -targetKcal * tolerance;
}
