import 'package:fb_domain/src/targets/target_calculator.dart';

/// The undo label of a successful targets command (A13 §3.3).
enum TargetsChangeKind {
  /// Setup completed.
  targetsSet,

  /// A profile field changed.
  profileUpdated,

  /// The active goal changed.
  goalUpdated,

  /// A new goal phase started.
  phaseStarted,

  /// Target settings changed.
  targetsUpdated,
}

/// Why a targets command wrote nothing.
enum TargetsFailure {
  /// The shown row changed since it was shown.
  changed,

  /// The shown row is gone.
  removed,

  /// The input breaks a targets rule.
  invalid,

  /// There is no profile or target settings yet.
  notSetUp,

  /// Setup ran already (perhaps on another device).
  alreadySetUp,

  /// Weekly-only controls are off for an acknowledged below-floor fixed
  /// manual target (PA7).
  fixedBelowFloor,

  /// The active goal can't be resolved any more (PA3).
  goalNeedsUpdate,

  /// A newly typed goal can't be resolved: a deadline not after today, or a
  /// target weight on the wrong side of the current weight (PA3).
  goalUnresolvable,

  /// The stored data couldn't be read or written just now (a database or
  /// read failure); nothing was written.
  unavailable,
}

/// The typed result of a targets command. Every [toString] is content-free
/// (PA14): kinds and codes only, never body values or kcal.
sealed class TargetsOutcome {
  const new();
}

/// The command wrote one change set with one undo entry.
final class TargetsDone extends TargetsOutcome {
  /// Undo entry [undoEntryId] of kind [kind].
  const new(
    this.undoEntryId,
    this.kind, {
    this.recomputedKcal,
    this.warnings = const {},
  });

  /// The undo-stack ID of the change set.
  final String undoEntryId;

  /// The undo label kind.
  final TargetsChangeKind kind;

  /// The new generated base when the command recomputed it; null when not
  /// recomputed (manual target, or the goal can't be resolved, PA3).
  final double? recomputedKcal;

  /// Safety codes of a stored generated base (lossRateCapped,
  /// calorieFloorApplied).
  final Set<TargetWarning> warnings;

  @override
  String toString() => 'TargetsDone(${kind.name})';
}

/// Nothing differs from what is stored; nothing written.
final class TargetsUnchanged extends TargetsOutcome {
  /// The single value.
  const new();

  @override
  String toString() => 'TargetsUnchanged';
}

/// Another targets command is in flight; nothing written.
final class TargetsPending extends TargetsOutcome {
  /// The single value.
  const new();

  @override
  String toString() => 'TargetsPending';
}

/// A manual target below the floor or implying loss beyond 1%/week needs
/// the user's acknowledgement first (SF-012); nothing written.
final class TargetsNeedsAcknowledgement extends TargetsOutcome {
  /// The limits the value breaks.
  new({
    required this.floorKcal,
    required this.impliedKgPerWeek,
    required Iterable<TargetWarning> warnings,
  }) : warnings = Set.unmodifiable(warnings);

  /// The safety floor on today.
  final double floorKcal;

  /// The signed weekly change the manual value implies.
  final double impliedKgPerWeek;

  /// manualBelowFloor and/or manualLossRateExceeded. Unmodifiable.
  final Set<TargetWarning> warnings;

  @override
  String toString() {
    final names = [
      for (final w in TargetWarning.values)
        if (warnings.contains(w)) w.name,
    ];
    return 'TargetsNeedsAcknowledgement(${names.join(', ')})';
  }
}

/// An expected refusal; nothing written.
final class TargetsFailed extends TargetsOutcome {
  /// Refused for [reason].
  const new(this.reason);

  /// The content-free reason.
  final TargetsFailure reason;

  @override
  String toString() => 'TargetsFailed(${reason.name})';
}
