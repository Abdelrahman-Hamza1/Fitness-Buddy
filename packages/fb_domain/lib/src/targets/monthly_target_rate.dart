import 'package:fb_domain/src/targets/targets_timeline.dart';

/// Why there is no monthly weight target.
enum MonthlyRateGap {
  /// No profile or no target version yet.
  noTargets,

  /// No active goal (maintenance, or no phase).
  noGoal,

  /// The active goal can't be resolved (deadline passed, target reached).
  goalNeedsUpdate,

  /// A manual target needs review (unacknowledged, below the floor): its
  /// rate isn't known, and the generated one doesn't apply.
  manualNeedsReview,
}

/// The weekly rate behind this month's weight target (TG-011, WB-023): the
/// rate the targets show, from a manual or a generated target, or why
/// there is none. A manual target that needs review never falls back to
/// the generated rate (A15a review).
sealed class MonthlyTargetRate {
  /// Reads [explanation] (the targets' explanation for today).
  factory of(TargetExplanation? explanation) {
    if (explanation == null) {
      return const MonthlyRateUnavailable(MonthlyRateGap.noTargets);
    }
    if (explanation.goal == null) {
      return MonthlyRateUnavailable(
        explanation.issues.contains(TargetIssue.goalNeedsUpdate)
            ? MonthlyRateGap.goalNeedsUpdate
            : MonthlyRateGap.noGoal,
      );
    }
    final manual = explanation.manual;
    if (explanation.version.manual) {
      if (manual == null ||
          explanation.issues.contains(TargetIssue.manualNeedsReview)) {
        return const MonthlyRateUnavailable(MonthlyRateGap.manualNeedsReview);
      }
      return ManualMonthlyRate(manual.achievableKgPerWeek);
    }
    return GeneratedMonthlyRate(explanation.calculated.achievableKgPerWeek);
  }

  const new _();

  /// The signed kg/week, or null when unavailable.
  double? get kgPerWeek;
}

/// The rate of a manual (computable, acknowledged) target.
final class ManualMonthlyRate extends MonthlyTargetRate {
  /// With [kgPerWeek].
  const new(this.kgPerWeek) : super._();

  @override
  final double kgPerWeek;

  @override
  String toString() => 'ManualMonthlyRate';
}

/// The rate of the generated target (SF-011-capped, floor-adjusted).
final class GeneratedMonthlyRate extends MonthlyTargetRate {
  /// With [kgPerWeek].
  const new(this.kgPerWeek) : super._();

  @override
  final double kgPerWeek;

  @override
  String toString() => 'GeneratedMonthlyRate';
}

/// No monthly target, and why.
final class MonthlyRateUnavailable extends MonthlyTargetRate {
  /// Because of [gap].
  const new(this.gap) : super._();

  /// Why.
  final MonthlyRateGap gap;

  @override
  double? get kgPerWeek => null;

  @override
  String toString() => 'MonthlyRateUnavailable(${gap.name})';
}
