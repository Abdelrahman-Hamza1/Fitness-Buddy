import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/time/local_date.dart';

/// Goal direction (TG-010).
enum GoalType {
  /// Negative weight change.
  lose,

  /// No intended change.
  maintain,

  /// Positive weight change.
  gain,
}

/// User expressions, converted without discarding their original form.
sealed class GoalExpression {
  /// Target weight on a date.
  factory targetDate(double targetKg, LocalDate date) = TargetDateGoal;

  /// Target weight at a positive weekly speed; direction comes from weight.
  factory targetRate(double targetKg, double kgPerWeek) = TargetRateGoal;

  /// Signed kg/week (negative loss, positive gain).
  factory weekly(double kgPerWeek) = WeeklyGoal;

  /// Signed kg over the full specified calendar month (TG-011).
  factory monthly(double kg, LocalDate month) = MonthlyGoal;

  const new _();
}

/// A target weight and deadline.
final class TargetDateGoal extends GoalExpression {
  /// The target in kg, with an explicit deadline.
  new(this.targetKg, this.date) : super._() {
    checkTargetNumber(targetKg);
  }

  /// Target weight, kg.
  final double targetKg;

  /// Requested deadline.
  final LocalDate date;
}

/// A target weight and weekly speed.
final class TargetRateGoal extends GoalExpression {
  /// Positive speed; the resolver determines direction.
  new(this.targetKg, this.kgPerWeek) : super._() {
    checkTargetNumber(targetKg);
    checkTargetNumber(kgPerWeek);
  }

  /// Target weight, kg.
  final double targetKg;

  /// Absolute speed, kg/week.
  final double kgPerWeek;
}

/// A signed weekly rate.
final class WeeklyGoal extends GoalExpression {
  /// Negative loss, zero maintenance, positive gain.
  new(this.kgPerWeek) : super._() {
    checkTargetNumber(kgPerWeek.abs(), allowZero: true);
  }

  /// Signed kg/week.
  final double kgPerWeek;
}

/// A signed change over an actual calendar month, including leap days.
final class MonthlyGoal extends GoalExpression {
  /// [month] can be any date in the named month.
  new(this.kg, this.month) : super._() {
    checkTargetNumber(kg.abs(), allowZero: true);
  }

  /// Signed kg per named month.
  final double kg;

  /// The named month.
  final LocalDate month;

  /// Its calendar duration (28–31 days).
  int get days => daysIn(month);

  /// Calendar duration for rate conversions, including leap February.
  static int daysIn(LocalDate month) =>
      DateTime.utc(month.year, month.month + 1, 0).day;
}

/// Converts a signed weekly rate back to kg over the named calendar month.
/// Use requested or achievable rates for their corresponding display (TG-011).
double monthlyKgFromWeeklyRate(double kgPerWeek, LocalDate month) {
  checkTargetNumber(kgPerWeek.abs(), allowZero: true);
  return kgPerWeek * MonthlyGoal.daysIn(month) / 7;
}

/// Goal conversion; safety caps are applied by TargetCalculator.
final class ResolvedGoal {
  const new _(this.type, this.requestedKgPerWeek, this.targetKg);

  /// Converts a user expression; rejects contradictory goal directions.
  factory resolve({
    required GoalType type,
    required GoalExpression expression,
    required double currentKg,
    required LocalDate date,
  }) {
    checkTargetNumber(currentKg);
    double? target;
    final double rate;
    switch (expression) {
      case TargetDateGoal(:final targetKg, date: final end):
        final days = date.daysUntil(end);
        if (days <= 0) throw ArgumentError('deadline must be after start');
        target = targetKg;
        rate = (targetKg - currentKg) * 7 / days;
      case TargetRateGoal(:final targetKg, :final kgPerWeek):
        target = targetKg;
        rate = (targetKg - currentKg).sign * kgPerWeek;
      case WeeklyGoal(:final kgPerWeek):
        rate = kgPerWeek;
      case MonthlyGoal(:final kg, :final days):
        rate = kg * 7 / days;
    }
    final direction = switch (type) {
      GoalType.lose => -1,
      GoalType.maintain => 0,
      GoalType.gain => 1,
    };
    if (!rate.isFinite || rate.sign != direction) {
      throw ArgumentError('goal direction does not match expression');
    }
    return ResolvedGoal._(type, rate, target);
  }

  /// Goal direction.
  final GoalType type;

  /// Requested signed kg/week before safety adjustments.
  final double requestedKgPerWeek;

  /// Optional target for completion projections.
  final double? targetKg;
}

/// An immutable phase; IDs/names are data and never used as log messages.
final class GoalPhase {
  /// Inclusive dates; [end] absent means still active.
  new({
    required this.id,
    required this.name,
    required this.start,
    required this.type,
    required this.expression,
    this.version = 1,
    this.end,
  }) {
    if (!isUuidV7(id) ||
        version < 1 ||
        name.trim().isEmpty ||
        (end != null && end!.isBefore(start))) {
      throw ArgumentError('invalid goal phase');
    }
  }

  /// Stable caller-supplied phase identifier.
  final String id;

  /// Domain revision for same-start ties, separate from storage row versions.
  final int version;

  /// User title; never logged.
  final String name;

  /// Inclusive first day.
  final LocalDate start;

  /// Inclusive last day, or still active.
  final LocalDate? end;

  /// Direction for this phase.
  final GoalType type;

  /// Original user expression.
  final GoalExpression expression;

  /// Whether this phase covers [date].
  bool contains(LocalDate date) =>
      !date.isBefore(start) && (end == null || !date.isAfter(end!));
}

/// Conflict-tolerant phase projection (TG-012), not a storage rewrite. The
/// adapter supplies current LWW rows by ID, with tombstones already excluded.
final class GoalHistory {
  /// Same-start rows pick the higher revision, then UUID. A later start ends
  /// the earlier projected phase the day before, even if the later phase ends.
  /// Superseded rows remain in [records] for history/recovery presentation.
  new(Iterable<GoalPhase> phases)
    : records = List.unmodifiable(phases.toList()..sort(_compare)) {
    final byStart = <LocalDate, GoalPhase>{};
    for (final phase in records) {
      byStart[phase.start] = phase;
    }
    final winners = byStart.values.toList();
    this.phases = List.unmodifiable([
      for (var i = 0; i < winners.length; i++)
        _project(winners[i], i + 1 < winners.length ? winners[i + 1] : null),
    ]);
  }

  /// Immutable original rows, ordered by start, revision and UUID.
  final List<GoalPhase> records;

  /// Nonoverlapping effective phases, never persisted back as corrections.
  late final List<GoalPhase> phases;

  static int _compare(GoalPhase a, GoalPhase b) {
    final date = a.start.compareTo(b.start);
    if (date != 0) return date;
    final revision = a.version.compareTo(b.version);
    return revision != 0 ? revision : a.id.compareTo(b.id);
  }

  static GoalPhase _project(GoalPhase phase, GoalPhase? next) {
    if (next == null ||
        (phase.end != null && phase.end!.isBefore(next.start))) {
      return phase;
    }
    return GoalPhase(
      id: phase.id,
      name: phase.name,
      version: phase.version,
      start: phase.start,
      end: next.start.plusDays(-1),
      type: phase.type,
      expression: phase.expression,
    );
  }

  /// Strict checks for a proposed local timeline before ChangeSetApplier saves
  /// it. Never use for synced reads; a valid local write can later conflict.
  static void validateForWrite(Iterable<GoalPhase> phases) {
    final ordered = phases.toList()..sort(_compare);
    final ids = <String>{};
    GoalPhase? previous;
    for (final phase in ordered) {
      if (!ids.add(phase.id) ||
          (previous != null &&
              (previous.end == null || !phase.start.isAfter(previous.end!)))) {
        throw ArgumentError('overlapping or duplicate goal phases');
      }
      previous = phase;
    }
  }

  /// Effective phase for [date], or null in a gap. No earlier-phase revival
  /// after a later phase's end; the later start supersedes its predecessor.
  GoalPhase? at(LocalDate date) {
    for (final phase in phases) {
      if (phase.contains(date)) return phase;
    }
    return null;
  }
}
