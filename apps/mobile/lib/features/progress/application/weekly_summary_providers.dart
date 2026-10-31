import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/progress/application/progress_providers.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weekly_summary_providers.g.dart';

/// The first day of the week containing today (follows midnight and the
/// week-start setting).
@riverpod
Future<LocalDate> currentWeekStart(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final weekStartFuture = ref.watch(weekStartProvider.future);
  final calendar = WeekCalendar(weekStart: await weekStartFuture);
  return calendar.weekStartOf(await todayFuture);
}

/// The [WeeklySummary] of the week from [weekStart] (IN-001, A39a D1):
/// the same per-date series as the charts ([progressDaysProvider], so the
/// numbers agree with them), the weight trend and the week's workouts. All
/// local; follows every source. A week after today has no summary (null).
/// No automatic retry: the card shows the error with Try again (UX-052).
@Riverpod(retry: _noAutomaticRetry)
Future<WeeklySummary?> weeklySummary(Ref ref, LocalDate weekStart) async {
  final todayFuture = ref.watch(todayProvider.future);
  final end = weekStart.plusDays(6);
  final daysFuture = ref.watch(progressDaysProvider(weekStart, end).future);
  final trendFuture = ref.watch(weightTrendProvider.future);
  final workoutsFuture = ref.watch(
    weeklyWorkoutSummaryProvider(weekStart).future,
  );
  final today = await todayFuture;
  if (weekStart.isAfter(today)) return null;
  final days = await daysFuture;
  final trend = await trendFuture;
  final workouts = await workoutsFuture;
  return WeeklySummary.of(
    weekStart: weekStart,
    today: today,
    days: days,
    trendOn: trend.trendOn,
    workouts: workouts,
  );
}

/// The earliest date a weekly summary can show (IN-001 "any past week"):
/// the charts' earliest data date or the first logged workout, whichever
/// is earlier, so a week with only workouts is reachable (A40 review 7).
@riverpod
Future<LocalDate> summaryEarliestDate(Ref ref) async {
  final earliestFuture = ref.watch(progressEarliestDateProvider.future);
  final sessionsFuture = ref.watch(allWorkoutSessionsProvider.future);
  var earliest = await earliestFuture;
  for (final session in await sessionsFuture) {
    if (session.draft.date.isBefore(earliest)) earliest = session.draft.date;
  }
  return earliest;
}

Duration? _noAutomaticRetry(int retryCount, Object error) => null;
