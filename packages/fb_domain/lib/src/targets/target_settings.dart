import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/targets/macros.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/targets/weekly_budget.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/week_calendar.dart';

/// Weekly budgeting or the simple fixed alternative (TG-044).
enum TargetMode {
  /// Seven-day budget, optionally rebalanced and weighted.
  weekly,

  /// Identical calories each day, no weekly logic.
  fixed,
}

/// Immutable input settings, shared by normal and Ramadan variants.
/// The app persists these through ChangeSetApplier; domain code only computes.
final class TargetPlan {
  /// A below-floor manual target is allowed only when acknowledged and fixed.
  new({
    required this.baseKcal,
    required this.floorKcal,
    this.mode = TargetMode.weekly,
    this.rebalancing = true,
    this.manual = false,
    this.acknowledged = false,
    Map<DayOfWeek, double> weights = const {},
    MacroSettings? macros,
  }) : weights = Map.unmodifiable(weights),
       macros = macros ?? MacroSettings() {
    checkTargetNumber(baseKcal);
    checkTargetNumber(floorKcal);
    if (baseKcal < floorKcal &&
        (!manual || !acknowledged || mode != TargetMode.fixed)) {
      throw ArgumentError(
        'below-floor target must be acknowledged manual fixed',
      );
    }
    this.weights.values.forEach(TargetLimits.checkWeight);
  }

  /// Daily base calories, unrounded.
  final double baseKcal;

  /// Transient SF-010 floor. Recompute from profile/date; never persist it.
  final double floorKcal;

  /// Fixed or weekly.
  final TargetMode mode;

  /// Whether earlier actual intake changes the remaining targets.
  final bool rebalancing;

  /// Whether the base came from an explicit user override.
  final bool manual;

  /// Explicit warning acknowledgement for below-limit manual values.
  final bool acknowledged;

  /// Immutable weekday weights; the caller can include workout-plan weights.
  final Map<DayOfWeek, double> weights;

  /// Daily macro rules resolved against base calories and goal/current weight.
  final MacroSettings macros;

  /// Derives, never stores, one historical/current day (G10).
  /// Fixed manual targets are returned as explicit values, not generated.
  TargetDay day({
    required LocalDate date,
    required double weightKg,
    Iterable<WeekIntake> earlierIntake = const [],
    Map<DayOfWeek, double> remainingWeights = const {},
    WeekCalendar calendar = const WeekCalendar(),
  }) {
    final week = mode == TargetMode.fixed
        ? null
        : WeeklyBudget.calculate(
            baseKcal: baseKcal,
            floorKcal: floorKcal,
            today: date,
            earlierIntake: earlierIntake,
            weights: weights,
            remainingWeights: remainingWeights,
            rebalancing: rebalancing,
            calendar: calendar,
          );
    final kcal = week?.targets[date] ?? baseKcal;
    return TargetDay._(
      kcal,
      MacroPlan.calculate(
        baseKcal: baseKcal,
        weightKg: weightKg,
        settings: macros,
      ).forDay(kcal),
      week,
      manual,
      acknowledged,
    );
  }
}

/// One computed day, not a persistence snapshot.
final class TargetDay {
  const new _(
    this.kcal,
    this.macros,
    this.week,
    this.manual,
    this.acknowledged,
  );

  /// Unrounded calories.
  final double kcal;

  /// Derived daily macros.
  final DailyMacros macros;

  /// Projection for weekly mode only.
  final WeekTargets? week;

  /// Explicit manual setting, allowing the UI to identify the exception.
  final bool manual;

  /// User acknowledged any below-limit manual target.
  final bool acknowledged;
}

/// An effective-dated settings version (TG-060 hook, G10).
final class TargetSettings {
  /// Ramadan dates/activation belong to A41; absence preserves normal settings.
  new({
    required this.id,
    required this.version,
    required this.effectiveFrom,
    required this.standard,
    this.ramadan,
  }) {
    if (!isUuidV7(id)) throw ArgumentError('settings ID must be UUIDv7');
    if (version < 1) throw ArgumentError('settings version must be positive');
  }

  /// Stable row identity, allocated on the device and retained across edits.
  final String id;

  /// Caller-supplied revision, separate from any storage optimistic version.
  final int version;

  /// Inclusive start date.
  final LocalDate effectiveFrom;

  /// Normal settings.
  final TargetPlan standard;

  /// Optional separate Ramadan settings; A41 controls when to activate them.
  final TargetPlan? ramadan;

  /// No mutation: automatic resumption is just selecting standard again.
  TargetPlan plan({bool ramadanActive = false}) =>
      ramadanActive ? ramadan ?? standard : standard;
}

/// Effective-date selection, including conflicting synced rows. The adapter
/// supplies the current LWW winner of each row ID, excluding tombstones.
/// Historical projections never write conflict resolutions back to storage.
final class TargetSettingsHistory {
  /// Keep rows in (effective date, revision, UUID) order. Equal dates/revisions
  /// from separate devices are valid read inputs, not provider exceptions.
  new(Iterable<TargetSettings> versions)
    : versions = List.unmodifiable(versions.toList()..sort(_compare));

  /// Immutable ordered rows, including same-date alternatives.
  final List<TargetSettings> versions;

  static int _compare(TargetSettings a, TargetSettings b) {
    final date = a.effectiveFrom.compareTo(b.effectiveFrom);
    if (date != 0) return date;
    final revision = a.version.compareTo(b.version);
    return revision != 0 ? revision : a.id.compareTo(b.id);
  }

  /// Validate a proposed local timeline before saving through ChangeSetApplier.
  /// Never apply this to a synced read: concurrent dates are resolved by [at].
  /// Revision numbers are local to a row, so they may repeat on other dates.
  static void validateForWrite(Iterable<TargetSettings> versions) {
    final dates = <LocalDate>{};
    final ids = <String>{};
    for (final version in versions) {
      if (!dates.add(version.effectiveFrom) || !ids.add(version.id)) {
        throw ArgumentError('duplicate target settings date or ID');
      }
    }
  }

  /// Latest effective date wins; for ties the higher revision, then UUID wins.
  /// Null before the first row. The result never depends on query input order.
  TargetSettings? at(LocalDate date) {
    TargetSettings? selected;
    for (final version in versions) {
      if (version.effectiveFrom.isAfter(date)) break;
      selected = version;
    }
    return selected;
  }
}
