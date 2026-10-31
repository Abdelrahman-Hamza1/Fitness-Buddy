import 'package:fb_domain/src/ids/uuid_v7.dart';
import 'package:fb_domain/src/targets/macros.dart';
import 'package:fb_domain/src/targets/target_profile.dart';
import 'package:fb_domain/src/targets/weekly_budget.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/week_calendar.dart';

/// The ordering key of one settings version: row `id`, domain `revision`
/// and `effectiveFrom` date (A12 PA6).
typedef SettingsVersionKey = ({
  String id,
  int revision,
  LocalDate effectiveFrom,
});

/// Every unordered pair of distinct [ids], each as (smaller, larger).
Set<(String, String)> targetIdPairs(Iterable<String> ids) {
  final sorted = ids.toSet().toList()..sort();
  return {
    for (var i = 0; i < sorted.length; i++)
      for (var j = i + 1; j < sorted.length; j++) (sorted[i], sorted[j]),
  };
}

/// Weekly budgeting or the simple fixed alternative (TG-044).
enum TargetMode {
  /// Seven-day budget, optionally rebalanced.
  weekly,

  /// Each day its planned number, no weekly logic.
  fixed,
}

/// Immutable input settings, shared by normal and Ramadan variants.
/// The app persists these through ChangeSetApplier; domain code only computes.
final class TargetPlan {
  /// A below-floor manual target is allowed only when acknowledged and fixed.
  /// [dayFactors] are each weekday's number as a factor of [baseKcal]
  /// (D-090, A53 D1); a missing weekday is the suggestion itself.
  new({
    required this.baseKcal,
    required this.floorKcal,
    this.mode = TargetMode.weekly,
    this.rebalancing = true,
    this.manual = false,
    this.acknowledged = false,
    Map<DayOfWeek, double> dayFactors = const {},
    Map<DayOfWeek, double> floorAcknowledged = const {},
    MacroSettings? macros,
  }) : dayFactors = Map.unmodifiable(dayFactors),
       floorAcknowledged = Map.unmodifiable(floorAcknowledged),
       macros = macros ?? MacroSettings() {
    checkTargetNumber(baseKcal);
    checkTargetNumber(floorKcal);
    if (baseKcal < floorKcal &&
        (!manual || !acknowledged || mode != TargetMode.fixed)) {
      throw ArgumentError(
        'below-floor target must be acknowledged manual fixed',
      );
    }
    this.dayFactors.values.forEach(TargetLimits.checkDayFactor);
  }

  /// The daily suggestion, unrounded: the calculated (or the user's own)
  /// target that every weekday starts from.
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

  /// Immutable weekday factors of [baseKcal].
  final Map<DayOfWeek, double> dayFactors;

  /// The weekday factors the user confirmed below the floor (A53 D4, the
  /// SF-012 warning): such a day stays as set while its factor is the one
  /// confirmed; any other day below the floor is raised to it (SF-010).
  final Map<DayOfWeek, double> floorAcknowledged;

  /// Daily macro rules resolved against base calories and goal/current weight.
  final MacroSettings macros;

  /// Whether this is an acknowledged manual target below the floor (PA7):
  /// the same number every day, factors ignored, no weekly logic.
  bool get belowFloorFixed => baseKcal < floorKcal;

  /// [weekday]'s planned number: the suggestion times its factor, raised
  /// to the floor unless the user confirmed that factor below it.
  double plannedKcal(DayOfWeek weekday) {
    if (belowFloorFixed) return baseKcal;
    final kcal = baseKcal * (dayFactors[weekday] ?? 1);
    return kcal < floorKcal && !keptBelowFloor(weekday) ? floorKcal : kcal;
  }

  /// Whether [weekday]'s factor is one the user confirmed below the floor.
  bool keptBelowFloor(DayOfWeek weekday) {
    final factor = dayFactors[weekday];
    final confirmed = floorAcknowledged[weekday];
    return factor != null &&
        confirmed != null &&
        (factor - confirmed).abs() < 1e-9;
  }

  /// Every weekday's planned number.
  Map<DayOfWeek, double> get plannedWeek => {
    for (final day in DayOfWeek.values) day: plannedKcal(day),
  };

  /// Derives, never stores, one historical/current day (G10).
  /// Fixed mode returns the day's planned number, with no week.
  TargetDay day({
    required LocalDate date,
    required double weightKg,
    Iterable<WeekIntake> earlierIntake = const [],
    WeekCalendar calendar = const WeekCalendar(),
  }) {
    final week = mode == TargetMode.fixed
        ? null
        : WeeklyBudget.calculate(
            planned: plannedWeek,
            floorKcal: floorKcal,
            today: date,
            earlierIntake: earlierIntake,
            rebalancing: rebalancing,
            calendar: calendar,
          );
    final kcal = week?.targets[date] ?? plannedKcal(date.weekday);
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

  /// A copy with the given fields replaced.
  TargetPlan copyWith({
    double? baseKcal,
    Map<DayOfWeek, double>? dayFactors,
    Map<DayOfWeek, double>? floorAcknowledged,
  }) => TargetPlan(
    baseKcal: baseKcal ?? this.baseKcal,
    floorKcal: floorKcal,
    mode: mode,
    rebalancing: rebalancing,
    manual: manual,
    acknowledged: acknowledged,
    dayFactors: dayFactors ?? this.dayFactors,
    floorAcknowledged: floorAcknowledged ?? this.floorAcknowledged,
    macros: macros,
  );
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

  /// The ordering key shared with stored records (A12 PA6).
  SettingsVersionKey get key =>
      (id: id, revision: version, effectiveFrom: effectiveFrom);

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

  static int _compare(TargetSettings a, TargetSettings b) =>
      compareKeys(a.key, b.key);

  /// The selection order (A12 PA6): effective date, then revision, then
  /// UUID; the later key wins a date. Shared by stored-record projections.
  static int compareKeys(SettingsVersionKey a, SettingsVersionKey b) {
    final date = a.effectiveFrom.compareTo(b.effectiveFrom);
    if (date != 0) return date;
    final revision = a.revision.compareTo(b.revision);
    return revision != 0 ? revision : a.id.compareTo(b.id);
  }

  /// Every pair of distinct row IDs sharing an effective date (PA2), each
  /// pair ordered (smaller ID first), so the set is independent of input
  /// order. A local write is refused only when it adds a pair (TD-089).
  static Set<(String, String)> conflicts(
    Iterable<SettingsVersionKey> versions,
  ) {
    final byDate = <LocalDate, Set<String>>{};
    for (final version in versions) {
      (byDate[version.effectiveFrom] ??= {}).add(version.id);
    }
    return {for (final ids in byDate.values) ...targetIdPairs(ids)};
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
