import 'package:fb_domain/src/nutrition/nutrients.dart';
import 'package:fb_domain/src/targets/macros.dart';
import 'package:fb_domain/src/targets/target_records.dart';
import 'package:fb_domain/src/targets/targets_timeline.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/week_calendar.dart';

/// One diary day the app has: the day's live-entry [totals] and the day mark
/// (A16 §3.1). Days with neither entries nor a mark are not passed (unknown,
/// TG-032). Content-free [toString].
final class DayLog {
  /// [date] with [entryCount] live entries adding up to [totals];
  /// [incomplete] is the day mark.
  new({
    required this.date,
    required this.totals,
    required this.entryCount,
    this.incomplete = false,
  }) {
    if (entryCount < 0) throw ArgumentError('entry count must not be negative');
  }

  /// The diary day.
  final LocalDate date;

  /// The sum of the day's entries (core five).
  final Nutrients totals;

  /// Live entries that day.
  final int entryCount;

  /// Whether the user marked the day incomplete (DY-004).
  final bool incomplete;

  @override
  String toString() => 'DayLog($date)';
}

/// How a day counts on the progress charts (A16 D5).
enum DayStatus {
  /// A past day with entries, not marked incomplete: counted.
  logged,

  /// Marked incomplete (DY-004): drawn with its logged intake, never counted
  /// in averages.
  incomplete,

  /// A past day with no entries and no mark: unknown, never zero (TG-032).
  unknown,

  /// Today, still in progress: drawn "so far", not counted yet.
  inProgress,
}

/// One date on the progress charts: what was eaten and the day's target as
/// Today shows it, recomputed from current data (G10). Content-free
/// [toString].
final class ProgressDay {
  /// The day.
  const new({
    required this.date,
    required this.eaten,
    required this.entryCount,
    required this.status,
    this.targetKcal,
    this.targetMacros,
  });

  /// The date.
  final LocalDate date;

  /// The day's logged totals (zero without entries).
  final Nutrients eaten;

  /// Live entries that day.
  final int entryCount;

  /// How the day counts.
  final DayStatus status;

  /// The day's calorie target, or null before setup.
  final double? targetKcal;

  /// The day's macro targets, or null before setup.
  final DailyMacros? targetMacros;

  /// Whether the day has logged food to draw.
  bool get hasIntake => entryCount > 0;

  /// Whether the day counts in averages (A16 D4).
  bool get counted => status == DayStatus.logged;

  @override
  String toString() => 'ProgressDay($date, ${status.name})';
}

/// The per-date series behind the calories and macro charts (IN-002,
/// IN-003, A16 D6).
abstract final class ProgressSeries {
  /// Every date from [from] to the earlier of [to] and [today], with the
  /// day's intake, status and the target [TargetsTimeline.day] gives it
  /// with the same inputs as Today's `dayTargetsProvider`: the trend weight
  /// on that date ([trendOn]), that week's earlier days and the week
  /// calendar. Evaluated per date (A16 PA3).
  ///
  /// [logs] must cover from `calendar.weekStartOf(from)`: the earlier days
  /// of the first week feed weekly-mode targets.
  static List<ProgressDay> build({
    required LocalDate from,
    required LocalDate to,
    required LocalDate today,
    required Iterable<TargetSettingsRecord> settings,
    required double? Function(LocalDate date) trendOn,
    required Iterable<DayLog> logs,
    ProfileRecord? profile,
    Iterable<GoalPhaseRecord> goals = const [],
    WeekCalendar calendar = const WeekCalendar(),
    Map<DayOfWeek, double> floorAcknowledged = const {},
  }) {
    final last = to.isAfter(today) ? today : to;
    if (last.isBefore(from)) return const [];
    final byDate = {for (final log in logs) log.date: log};
    final versions = settings.toList(growable: false);
    final phases = goals.toList(growable: false);
    final days = <ProgressDay>[];
    for (var date = from; !date.isAfter(last); date = date.plusDays(1)) {
      final weekStart = calendar.weekStartOf(date);
      final intake = <DayIntake>[
        for (var d = weekStart; d.isBefore(date); d = d.plusDays(1))
          if (byDate[d] case final log?)
            DayIntake(
              date: d,
              kcal: log.totals.kcal,
              entryCount: log.entryCount,
              incomplete: log.incomplete,
            ),
      ];
      final targets = versions.isEmpty
          ? null
          : TargetsTimeline.day(
              date: date,
              settings: versions,
              profile: profile,
              goals: phases,
              bodyWeightKg: trendOn(date),
              intake: intake,
              calendar: calendar,
              floorAcknowledged: floorAcknowledged,
            );
      final log = byDate[date];
      final entries = log?.entryCount ?? 0;
      days.add(
        ProgressDay(
          date: date,
          eaten: entries > 0 ? log!.totals : Nutrients.zero,
          entryCount: entries,
          status: statusOf(
            date: date,
            today: today,
            entryCount: entries,
            incomplete: log?.incomplete ?? false,
          ),
          targetKcal: targets?.day.kcal,
          targetMacros: targets?.day.macros,
        ),
      );
    }
    return days;
  }

  /// A day's [DayStatus]: a mark wins (the user said so), then today is in
  /// progress, then entries make it logged, else unknown (TG-032).
  static DayStatus statusOf({
    required LocalDate date,
    required LocalDate today,
    required int entryCount,
    required bool incomplete,
  }) {
    if (incomplete) return DayStatus.incomplete;
    if (date == today) return DayStatus.inProgress;
    return entryCount > 0 ? DayStatus.logged : DayStatus.unknown;
  }
}

/// How many days one bar covers (A16 D4).
enum ProgressBucketSize {
  /// One day per bar (spans up to 62 days).
  day,

  /// One week per bar, aligned to the week start (up to 366 days).
  week,

  /// One calendar month per bar (longer spans).
  month,
}

/// Average macro targets of a bucket: `carbs` and `fat` are null in
/// calories/protein mode.
typedef MacroAverages = ({
  double kcal,
  double protein,
  double? carbs,
  double? fat,
  double fiber,
});

/// One bar of the progress charts (A16 D4). A daily bucket carries its
/// day's actual intake and target whatever its status (an incomplete day
/// keeps its hatched bar, PA1); a week or month bucket averages over its
/// counted days only and is empty without one. Content-free [toString].
final class ProgressBucket {
  /// The bucket.
  const new({
    required this.start,
    required this.end,
    required this.size,
    required this.countedDays,
    required this.uncountedDays,
    this.avgKcal,
    this.avgTargetKcal,
    this.avgEaten,
    this.avgTargets,
    this.status,
  });

  /// The first date.
  final LocalDate start;

  /// The last date (inclusive, never after today).
  final LocalDate end;

  /// Day, week or month.
  final ProgressBucketSize size;

  /// Intake: the day's for a daily bucket, else the average over counted
  /// days; null when there is nothing to draw.
  final double? avgKcal;

  /// The calorie target, the same way; null before setup.
  final double? avgTargetKcal;

  /// The nutrients eaten, the same way.
  final Nutrients? avgEaten;

  /// The macro targets, the same way.
  final MacroAverages? avgTargets;

  /// Days that count (logged, not incomplete, not today).
  final int countedDays;

  /// Days in the bucket that don't count (incomplete, unknown, today).
  final int uncountedDays;

  /// The day's status, for daily buckets only.
  final DayStatus? status;

  @override
  String toString() =>
      'ProgressBucket($start, ${size.name}, $countedDays counted)';
}

/// Groups a [ProgressSeries] into bars (A16 D4, IN-009).
abstract final class ProgressBuckets {
  /// Spans up to this many days get daily bars.
  static const int maxDailyDays = 62;

  /// Spans up to this many days get weekly bars; longer ones monthly.
  static const int maxWeeklyDays = 366;

  /// The bar size for a span of [days] days.
  static ProgressBucketSize sizeFor(int days) => days <= maxDailyDays
      ? ProgressBucketSize.day
      : days <= maxWeeklyDays
      ? ProgressBucketSize.week
      : ProgressBucketSize.month;

  /// The bars of [days] (consecutive dates, oldest first), sized by their
  /// span ([sizeFor]); weeks start on [calendar]'s week start.
  static List<ProgressBucket> of(
    List<ProgressDay> days, {
    WeekCalendar calendar = const WeekCalendar(),
  }) {
    final size = sizeFor(days.length);
    if (size == ProgressBucketSize.day) {
      return [for (final day in days) _daily(day)];
    }
    final buckets = <ProgressBucket>[];
    var group = <ProgressDay>[];
    Object? groupKey;
    for (final day in days) {
      final key = size == ProgressBucketSize.week
          ? calendar.weekStartOf(day.date)
          : (day.date.year, day.date.month);
      if (group.isNotEmpty && key != groupKey) {
        buckets.add(_aggregate(group, size));
        group = [];
      }
      groupKey = key;
      group.add(day);
    }
    if (group.isNotEmpty) buckets.add(_aggregate(group, size));
    return buckets;
  }

  static ProgressBucket _daily(ProgressDay day) {
    final macros = day.targetMacros;
    return ProgressBucket(
      start: day.date,
      end: day.date,
      size: ProgressBucketSize.day,
      countedDays: day.counted ? 1 : 0,
      uncountedDays: day.counted ? 0 : 1,
      avgKcal: day.hasIntake ? day.eaten.kcal : null,
      avgTargetKcal: day.targetKcal,
      avgEaten: day.hasIntake ? day.eaten : null,
      avgTargets: macros == null
          ? null
          : (
              kcal: macros.kcal,
              protein: macros.proteinGrams,
              carbs: macros.carbsGrams,
              fat: macros.fatGrams,
              fiber: macros.fiberGrams,
            ),
      status: day.status,
    );
  }

  static ProgressBucket _aggregate(
    List<ProgressDay> group,
    ProgressBucketSize size,
  ) {
    final counted = [
      for (final day in group)
        if (day.counted) day,
    ];
    final targeted = [
      for (final day in counted)
        if (day.targetMacros != null) day.targetMacros!,
    ];
    double? mean(Iterable<double?> values) {
      var sum = 0.0;
      var n = 0;
      for (final v in values) {
        if (v == null) continue;
        sum += v;
        n++;
      }
      return n == 0 ? null : sum / n;
    }

    final n = counted.length;
    Nutrients? eaten;
    if (n > 0) {
      double avg(double Function(Nutrients) of) =>
          counted.fold<double>(0, (sum, d) => sum + of(d.eaten)) / n;
      eaten = Nutrients(
        kcal: avg((e) => e.kcal),
        protein: avg((e) => e.protein),
        carbs: avg((e) => e.carbs),
        fat: avg((e) => e.fat),
        fiber: avg((e) => e.fiber),
      );
    }
    return ProgressBucket(
      start: group.first.date,
      end: group.last.date,
      size: size,
      countedDays: n,
      uncountedDays: group.length - n,
      avgKcal: eaten?.kcal,
      avgTargetKcal: mean(counted.map((d) => d.targetKcal)),
      avgEaten: eaten,
      avgTargets: targeted.isEmpty
          ? null
          : (
              kcal: mean(targeted.map((m) => m.kcal))!,
              protein: mean(targeted.map((m) => m.proteinGrams))!,
              carbs: mean(targeted.map((m) => m.carbsGrams)),
              fat: mean(targeted.map((m) => m.fatGrams)),
              fiber: mean(targeted.map((m) => m.fiberGrams))!,
            ),
    );
  }
}
