import 'package:fb_domain/src/targets/goals.dart';
import 'package:fb_domain/src/targets/target_calculator.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/targets/target_records.dart';
import 'package:fb_domain/src/targets/target_settings.dart';
import 'package:fb_domain/src/targets/weekly_budget.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/week_calendar.dart';

/// One diary day's logged intake, as the app gathers it (D6).
final class DayIntake {
  /// [kcal] over [entryCount] live entries; [incomplete] is the day mark.
  new({
    required this.date,
    required this.kcal,
    required this.entryCount,
    this.incomplete = false,
  }) {
    checkTargetNumber(kcal, allowZero: true);
    if (entryCount < 0) throw ArgumentError('entry count must not be negative');
  }

  /// The diary day.
  final LocalDate date;

  /// Logged calories.
  final double kcal;

  /// Live entries that day. None means unknown, never zero (TG-032).
  final int entryCount;

  /// Whether the user marked the day incomplete.
  final bool incomplete;

  @override
  String toString() => 'DayIntake($date)';
}

/// Something about the stored targets the user should look at.
enum TargetIssue {
  /// A manual target below the floor that isn't acknowledged and fixed; it
  /// is shown raised to the floor (SF-012).
  manualNeedsReview,

  /// The active goal can't be resolved (deadline passed, target weight
  /// reached or passed); targets keep the stored base (PA3).
  goalNeedsUpdate,

  /// A weekday the user confirmed below the floor is planned below it on
  /// this date: it stays as set (A53 D4) and is shown calmly.
  dayBelowFloor,
}

/// The "This week" line (D7, HM-002): eaten minus planned over the known
/// complete earlier days of the week. Content-free [toString].
final class WeekPosition {
  const new _(this.kcal, this.uncountedDays);

  /// Positive: over; negative: under. Today is not included.
  final double kcal;

  /// Earlier days (on or after the first version) with unknown intake.
  final int uncountedDays;

  @override
  String toString() => 'WeekPosition';
}

/// Everything Today and Targets show for one date, derived (G10).
/// Content-free [toString].
final class DayTargets {
  new _({
    required this.day,
    required this.plan,
    required this.version,
    required this.floorKcal,
    required this.weightKg,
    required this.raisedToFloor,
    required Set<TargetIssue> issues,
    required this.week,
    this.ramadanMaintain = false,
  }) : issues = Set.unmodifiable(issues);

  /// The engine's day: calories, macros, the week (weekly mode).
  final TargetDay day;

  /// The plan the day was computed from: the suggestion (raised to the
  /// floor, Ramadan "maintain" applied) and the weekday factors. Targets
  /// draws the week and previews a day's change from it.
  final TargetPlan plan;

  /// The settings version in effect on the date.
  final TargetSettingsRecord version;

  /// The SF-010 floor on the date at [weightKg].
  final double floorKcal;

  /// The weight used: the trend weight, else the version's basis weight.
  final double weightKg;

  /// Whether the stored base was below the floor and was raised to it.
  final bool raisedToFloor;

  /// What needs the user's attention. Unmodifiable.
  final Set<TargetIssue> issues;

  /// The weekly line; null in fixed mode (TG-044).
  final WeekPosition? week;

  /// Whether "maintain during Ramadan" changed the base on this date
  /// (TG-060): the goal's deficit or surplus is left out.
  final bool ramadanMaintain;

  @override
  String toString() => 'DayTargets';
}

/// The numbers behind the plain-language explanation (TG-021).
/// Content-free [toString].
final class TargetExplanation {
  new _({
    required this.version,
    required this.calculated,
    required this.goal,
    required this.manual,
    required Set<TargetIssue> issues,
  }) : issues = Set.unmodifiable(issues);

  /// The version explained.
  final TargetSettingsRecord version;

  /// The generated calculation from the basis weight on the effective date
  /// (for an unresolvable or missing goal: maintenance, no goal line).
  final TargetCalculation calculated;

  /// The resolved goal; null drops the goal line.
  final ResolvedGoal? goal;

  /// The manual calculation with its warnings, for a computable manual
  /// version.
  final TargetCalculation? manual;

  /// goalNeedsUpdate and/or manualNeedsReview. Unmodifiable.
  final Set<TargetIssue> issues;

  @override
  String toString() => 'TargetExplanation';
}

/// The pure per-date read projection (D6): the app gathers stored rows,
/// the trend weight and intake; this decides every number.
abstract final class TargetsTimeline {
  /// The version in effect on [date] (A12 PA6 order), or null before the
  /// first.
  static TargetSettingsRecord? versionOn(
    Iterable<TargetSettingsRecord> settings,
    LocalDate date,
  ) {
    TargetSettingsRecord? selected;
    for (final version in settings) {
      if (version.effectiveFrom.isAfter(date)) continue;
      if (selected == null ||
          TargetSettingsHistory.compareKeys(version.key, selected.key) > 0) {
        selected = version;
      }
    }
    return selected;
  }

  /// The stored record of the phase [GoalHistory] projects for [date], or
  /// null in a gap.
  static GoalPhaseRecord? phaseOn(
    Iterable<GoalPhaseRecord> goals,
    LocalDate date,
  ) {
    final byId = {for (final goal in goals) goal.id: goal};
    final phase = GoalHistory([for (final goal in byId.values) goal.toPhase()])
        .at(date);
    return phase == null ? null : byId[phase.id];
  }

  /// [phase]'s goal for [weightKg] on [date], or null when it can't be
  /// resolved (PA3).
  static ResolvedGoal? resolve(
    GoalPhaseRecord phase, {
    required double weightKg,
    required LocalDate date,
  }) => _tryEngine(
    () => ResolvedGoal.resolve(
      type: phase.type,
      expression: phase.expression,
      currentKg: weightKg,
      date: date,
    ),
  );

  /// The targets for [date], or null without a profile, without a version
  /// in effect, or when the engine can't evaluate the stored values on
  /// [date] (an implausible synced height or basis weight, PA3).
  /// [bodyWeightKg] is the trend weight on or before [date] (TD-090); null
  /// falls back to the version's basis weight. [intake] holds the diary
  /// days the app has; other dates are ignored.
  static DayTargets? day({
    required LocalDate date,
    required Iterable<TargetSettingsRecord> settings,
    required ProfileRecord? profile,
    Iterable<GoalPhaseRecord> goals = const [],
    double? bodyWeightKg,
    Iterable<DayIntake> intake = const [],
    WeekCalendar calendar = const WeekCalendar(),
    TargetDefaults defaults = const TargetDefaults(),
    bool ramadanMaintain = false,
    Map<DayOfWeek, double> floorAcknowledged = const {},
  }) {
    final version = versionOn(settings, date);
    if (profile == null || version == null) return null;
    final weight = bodyWeightKg ?? version.basisWeightKg;
    final phase = phaseOn(goals, date);
    final floor = _tryEngine(
      () => TargetCalculator.floor(
        profile.toProfile(weight),
        date,
        defaults: defaults,
      ),
    );
    if (floor == null) return null;
    final storedPlan = _tryEngine(
      () =>
          version.toPlan(floor).copyWith(floorAcknowledged: floorAcknowledged),
    );
    if (storedPlan == null) return null;
    // TG-060: on a Ramadan day of a "maintain" season, a generated base
    // drops the goal's energy (the SF-011-capped rate), never below the
    // floor. A manual base is the user's own number and stays.
    final maintainBase = ramadanMaintain && !version.manual && phase != null
        ? _maintainBase(
            storedPlan.baseKcal,
            phase,
            weight,
            date,
            floor,
            defaults,
          )
        : null;
    final plan = maintainBase == null
        ? storedPlan
        : _tryEngine(() => storedPlan.copyWith(baseKcal: maintainBase));
    if (plan == null) return null;
    final goalWeight = switch (phase?.expression) {
      TargetDateGoal(:final targetKg) ||
      TargetRateGoal(:final targetKg) => targetKg,
      _ => null,
    };
    final first = settings
        .map((s) => s.effectiveFrom)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final weekStart = calendar.weekStartOf(date);
    final known = <LocalDate, WeekIntake>{
      for (final day in intake)
        if (!day.date.isBefore(weekStart) &&
            day.date.isBefore(date) &&
            !day.date.isBefore(first))
          if (day.incomplete)
            day.date: WeekIntake(
              date: day.date,
              kcal: day.kcal,
              complete: false,
            )
          else if (day.entryCount > 0)
            day.date: WeekIntake(date: day.date, kcal: day.kcal),
    };
    final targetDay = _tryEngine(
      () => plan.day(
        date: date,
        weightKg: goalWeight ?? weight,
        earlierIntake: known.values,
        calendar: calendar,
      ),
    );
    if (targetDay == null) return null;
    WeekPosition? position;
    if (targetDay.week case final week?) {
      var kcal = 0.0;
      for (final day in known.values) {
        if (day.complete) kcal += day.kcal - week.planned[day.date]!;
      }
      position = WeekPosition._(
        kcal,
        week.unknownDates.where((d) => !d.isBefore(first)).length,
      );
    }
    return DayTargets._(
      day: targetDay,
      plan: plan,
      version: version,
      floorKcal: floor,
      weightKg: weight,
      raisedToFloor: storedPlan.baseKcal != version.baseKcal,
      issues: {
        if (version.manual &&
            version.baseKcal < floor &&
            !version.mayStayBelowFloor)
          TargetIssue.manualNeedsReview,
        if (phase != null &&
            resolve(phase, weightKg: weight, date: date) == null)
          TargetIssue.goalNeedsUpdate,
        if (DayOfWeek.values.any(
          (d) => plan.keptBelowFloor(d) && plan.plannedKcal(d) < floor,
        ))
          TargetIssue.dayBelowFloor,
      },
      week: position,
      ramadanMaintain: maintainBase != null,
    );
  }

  /// [base] without [phase]'s goal energy on [date] at [weightKg] (TG-060),
  /// at least [floor]; null when the goal can't be resolved or has no
  /// energy (maintain).
  static double? _maintainBase(
    double base,
    GoalPhaseRecord phase,
    double weightKg,
    LocalDate date,
    double floor,
    TargetDefaults defaults,
  ) {
    final goal = resolve(phase, weightKg: weightKg, date: date);
    if (goal == null || goal.requestedKgPerWeek == 0) return null;
    final rate = goal.requestedKgPerWeek < -weightKg * defaults.maxLossFraction
        ? -weightKg * defaults.maxLossFraction
        : goal.requestedKgPerWeek;
    final kcal = base - rate * defaults.kcalPerKg / 7;
    return kcal < floor ? floor : kcal;
  }

  /// The explanation of the version in effect on [date], computed from its
  /// basis weight on its effective date. It reproduces the stored base
  /// exactly only for a generated version written under the current
  /// profile and goal, which the recompute rule guarantees for today's
  /// version (PA13). Null without a profile or version, or when the profile
  /// can't be evaluated.
  static TargetExplanation? explain({
    required LocalDate date,
    required Iterable<TargetSettingsRecord> settings,
    required ProfileRecord? profile,
    Iterable<GoalPhaseRecord> goals = const [],
    TargetDefaults defaults = const TargetDefaults(),
  }) {
    final version = versionOn(settings, date);
    if (profile == null || version == null) return null;
    final at = version.effectiveFrom;
    final weight = version.basisWeightKg;
    final phase = phaseOn(goals, at);
    final goal = phase == null
        ? null
        : resolve(phase, weightKg: weight, date: at);
    final basis =
        goal ??
        ResolvedGoal.resolve(
          type: GoalType.maintain,
          expression: GoalExpression.weekly(0),
          currentKg: weight,
          date: at,
        );
    TargetCalculation? calculate({double? manualKcal}) => _tryEngine(
      () => TargetCalculator.calculate(
        profile: profile.toProfile(weight),
        goal: basis,
        date: at,
        manualKcal: manualKcal,
        acknowledged: manualKcal != null && version.acknowledged,
        defaults: defaults,
      ),
    );
    final calculated = calculate();
    if (calculated == null) return null;
    final manual = version.manual
        ? calculate(manualKcal: version.baseKcal)
        : null;
    return TargetExplanation._(
      version: version,
      calculated: calculated,
      goal: goal,
      manual: manual,
      issues: {
        if (phase != null && goal == null) TargetIssue.goalNeedsUpdate,
        if (version.manual && manual == null) TargetIssue.manualNeedsReview,
      },
    );
  }
}

/// The engine signals impossible inputs with content-free ArgumentErrors;
/// the read side turns them into "no value" instead of a crash (PA3).
T? _tryEngine<T>(T Function() compute) {
  try {
    return compute();
  }
  // The engine's documented signal for impossible input; nothing else is
  // caught, so programming errors elsewhere still surface.
  // ignore: avoid_catching_errors
  on ArgumentError {
    return null;
  }
}
