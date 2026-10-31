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

/// Pure weekly budget projection (TG-040–042, D-090). No exercise-calorie
/// input exists (WO-060).
abstract final class WeeklyBudget {
  /// Projects today through week end from each weekday's [planned] number
  /// (all seven weekdays; the suggestion or the user's own number for that
  /// day). The weekly budget is their sum. With [rebalancing], earlier known
  /// intake changes the remaining days in proportion to their planned
  /// numbers, each within ±[TargetDefaults.dailyFlex] of its own planned
  /// number and never below [floorKcal]; a day planned below the floor (the
  /// user's acknowledged choice, A53 D4) is never lowered further. Missing
  /// or incomplete earlier days reserve their planned number (TG-032).
  static WeekTargets calculate({
    required Map<DayOfWeek, double> planned,
    required double floorKcal,
    required LocalDate today,
    Iterable<WeekIntake> earlierIntake = const [],
    bool rebalancing = true,
    WeekCalendar calendar = const WeekCalendar(),
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    checkTargetNumber(floorKcal);
    if (planned.length != DayOfWeek.values.length) {
      throw ArgumentError('every weekday needs a planned number');
    }
    planned.values.forEach(checkTargetNumber);
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
    final week = [for (final d in days) planned[d.weekday]!];
    final budget = week.fold<double>(0, (a, b) => a + b);
    final elapsed = start.daysUntil(today);
    var accounted = 0.0;
    final unknown = <LocalDate>[];
    for (var i = 0; i < elapsed; i++) {
      final intake = past[days[i]];
      if (intake == null || !intake.complete) unknown.add(days[i]);
      accounted += intake != null && intake.complete ? intake.kcal : week[i];
    }
    final ahead = week.sublist(elapsed);
    final remaining = rebalancing
        ? _allocate(budget - accounted, ahead, floorKcal, defaults.dailyFlex)
        : ahead;
    final assigned = remaining.fold<double>(0, (sum, kcal) => sum + kcal);
    return WeekTargets._(
      weekStart: start,
      budgetKcal: budget,
      accountedPastKcal: accounted,
      carryKcal: accounted + assigned - budget,
      targets: {
        for (var i = elapsed; i < 7; i++) days[i]: remaining[i - elapsed],
      },
      planned: {for (var i = 0; i < 7; i++) days[i]: week[i]},
      unknownDates: unknown,
    );
  }

  // Solve sum(clamp(m * planned, lower, upper)) = feasible budget for the
  // multiplier m by monotonic bisection. A budget equal to the planned sum
  // returns the planned numbers exactly.
  static List<double> _allocate(
    double budget,
    List<double> planned,
    double floor,
    double flex,
  ) {
    final sum = planned.fold<double>(0, (a, b) => a + b);
    if ((budget - sum).abs() <= 1e-9 * sum) return planned;
    final lower = [
      for (final p in planned)
        if (p < floor) p else math.max(floor, p * (1 - flex)),
    ];
    final upper = [for (final p in planned) p * (1 + flex)];
    final feasible = budget.clamp(
      lower.fold<double>(0, (a, b) => a + b),
      upper.fold<double>(0, (a, b) => a + b),
    );
    double at(double m, int i) => (m * planned[i]).clamp(lower[i], upper[i]);
    var lo = 0.0;
    var hi = 1 + flex;
    for (var i = 0; i < TargetLimits.allocationIterations; i++) {
      final m = (lo + hi) / 2;
      var total = 0.0;
      for (var j = 0; j < planned.length; j++) {
        total += at(m, j);
      }
      if (total < feasible) {
        lo = m;
      } else {
        hi = m;
      }
    }
    final m = (lo + hi) / 2;
    return [for (var j = 0; j < planned.length; j++) at(m, j)];
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

  /// The sum of the seven planned numbers.
  final double budgetKcal;

  /// Actual known intake plus planned reservations for unknown past days.
  final double accountedPastKcal;

  /// Unallocated excess/deficit; identity includes unknown-day reservations.
  final double carryKcal;

  /// Today's and future targets only, in chronological order.
  final Map<LocalDate, double> targets;

  /// The whole week's planned numbers, before actual intake.
  final Map<LocalDate, double> planned;

  /// Earlier dates whose intake is unknown; never treated as zero.
  final List<LocalDate> unknownDates;
}
