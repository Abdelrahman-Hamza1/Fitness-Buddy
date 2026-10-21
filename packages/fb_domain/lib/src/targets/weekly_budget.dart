import 'dart:math' as math;

import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/week_calendar.dart';

/// Earlier-day intake: missing/incomplete is unknown, never zero (TG-032).
final class WeekIntake {
  /// Only complete intake counts towards rebalancing. Zero is valid if known.
  new({required this.date, required this.kcal, this.complete = true}) {
    checkTargetNumber(kcal, allowZero: true);
  }

  /// Diary day.
  final LocalDate date;

  /// Logged calories, ignored for incomplete days.
  final double kcal;

  /// Whether this is a known full day's intake.
  final bool complete;
}

/// Pure weekly budget projection. No exercise-calorie input exists (WO-060).
abstract final class WeeklyBudget {
  /// Projects today through week end, with earlier known intake accounted.
  /// Missing/incomplete days reserve their planned calories. An acknowledged
  /// below-floor manual target is displayed directly, never generated here.
  /// [remainingWeights] changes only the remaining allocation (unplanned
  /// workouts); unknown earlier days keep their original planned reservation.
  /// [fixed] is the standalone equal-budget projection; TargetPlan fixed mode
  /// skips weekly logic entirely, including below-floor manual exceptions.
  static WeekTargets calculate({
    required double baseKcal,
    required double floorKcal,
    required LocalDate today,
    Iterable<WeekIntake> earlierIntake = const [],
    Map<DayOfWeek, double> weights = const {},
    Map<DayOfWeek, double> remainingWeights = const {},
    bool rebalancing = true,
    bool fixed = false,
    WeekCalendar calendar = const WeekCalendar(),
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    checkTargetNumber(baseKcal);
    checkTargetNumber(floorKcal);
    if (baseKcal < floorKcal) {
      throw ArgumentError('weekly base must meet the safety floor');
    }
    [
      ...weights.values,
      ...remainingWeights.values,
    ].forEach(TargetLimits.checkWeight);
    final start = calendar.weekStartOf(today);
    final days = [for (var i = 0; i < 7; i++) start.plusDays(i)];
    final past = <LocalDate, WeekIntake>{};
    for (final intake in earlierIntake) {
      if (intake.date.isBefore(start) ||
          !intake.date.isBefore(today) ||
          past.containsKey(intake.date)) {
        throw ArgumentError('intake must have unique earlier dates this week');
      }
      past[intake.date] = intake;
    }
    final lower = math.max(floorKcal, baseKcal * (1 - defaults.dailyFlex));
    final upper = baseKcal * (1 + defaults.dailyFlex);
    final budget = baseKcal * 7;
    final dayWeights = [for (final d in days) weights[d.weekday] ?? 1.0];
    final planned = fixed
        ? List.filled(7, baseKcal)
        : _allocate(budget, dayWeights, lower, upper);
    final elapsed = start.daysUntil(today);
    var accounted = 0.0;
    final unknown = <LocalDate>[];
    for (var i = 0; i < elapsed; i++) {
      final intake = past[days[i]];
      if (intake == null || !intake.complete) unknown.add(days[i]);
      accounted += !fixed && intake != null && intake.complete
          ? intake.kcal
          : planned[i];
    }
    final futureWeights = [
      for (final d in days.skip(elapsed))
        remainingWeights[d.weekday] ?? weights[d.weekday] ?? 1.0,
    ];
    final remaining = fixed || (!rebalancing && remainingWeights.isEmpty)
        ? planned.sublist(elapsed)
        : _allocate(
            rebalancing
                ? budget - accounted
                : planned.skip(elapsed).fold<double>(0, (a, b) => a + b),
            futureWeights,
            lower,
            upper,
          );
    final assigned = remaining.fold<double>(0, (sum, kcal) => sum + kcal);
    return WeekTargets._(
      weekStart: start,
      budgetKcal: budget,
      accountedPastKcal: accounted,
      carryKcal: accounted + assigned - budget,
      targets: {
        for (var i = elapsed; i < 7; i++) days[i]: remaining[i - elapsed],
      },
      planned: {for (var i = 0; i < 7; i++) days[i]: planned[i]},
      unknownDates: unknown,
    );
  }

  // Solve sum(clamp(multiplier * weight, lower, upper)) = feasible budget.
  // Monotonic bisection avoids freezing both extremes incorrectly. Normalize
  // weights first; 80 iterations cover the bounded 1e6 ratio.
  static List<double> _allocate(
    double budget,
    List<double> weights,
    double lower,
    double upper,
  ) {
    final feasible = budget.clamp(
      lower * weights.length,
      upper * weights.length,
    );
    final maxWeight = weights.reduce(math.max);
    final normalized = [for (final w in weights) w / maxWeight];
    var lo = 0.0;
    var hi = upper / normalized.reduce(math.min);
    for (var i = 0; i < TargetLimits.allocationIterations; i++) {
      final multiplier = (lo + hi) / 2;
      final total = normalized.fold<double>(
        0,
        (sum, w) => sum + (multiplier * w).clamp(lower, upper),
      );
      if (total < feasible) {
        lo = multiplier;
      } else {
        hi = multiplier;
      }
    }
    return [
      for (final w in normalized) ((lo + hi) / 2 * w).clamp(lower, upper),
    ];
  }
}

/// Immutable weekly result; positive carry is over, negative is under (TG-042).
final class WeekTargets {
  new _({
    required this.weekStart,
    required this.budgetKcal,
    required this.accountedPastKcal,
    required this.carryKcal,
    required Map<LocalDate, double> targets,
    required Map<LocalDate, double> planned,
    required List<LocalDate> unknownDates,
  }) : targets = Map.unmodifiable(targets),
       planned = Map.unmodifiable(planned),
       unknownDates = List.unmodifiable(unknownDates);

  /// First day according to the supplied WeekCalendar.
  final LocalDate weekStart;

  /// Always base calories times seven.
  final double budgetKcal;

  /// Actual known intake plus planned reservations for unknown past days.
  final double accountedPastKcal;

  /// Unallocated excess/deficit; identity includes unknown-day reservations.
  final double carryKcal;

  /// Today's and future targets only, in chronological order.
  final Map<LocalDate, double> targets;

  /// The whole week's initial weighted allocation, before actual intake.
  final Map<LocalDate, double> planned;

  /// Earlier dates whose intake is unknown; never treated as zero.
  final List<LocalDate> unknownDates;
}
