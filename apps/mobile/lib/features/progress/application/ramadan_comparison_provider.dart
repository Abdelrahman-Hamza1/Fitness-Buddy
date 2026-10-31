import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/today/today.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ramadan_comparison_provider.g.dart';

/// The Ramadan comparison on Progress (IN-008, A41a D9): the latest
/// Ramadan with the mode on, from its first day until 30 days after its
/// end; null otherwise. Local data only.
@riverpod
Future<RamadanComparison?> ramadanComparison(Ref ref) async {
  final todayFuture = ref.watch(todayProvider.future);
  final periodsFuture = ref.watch(ramadanOnPeriodsProvider.future);
  final today = await todayFuture;
  final period = RamadanComparison.shownOn(today, await periodsFuture);
  if (period == null) return null;
  final from = period.start.plusDays(-RamadanComparison.beforeDays);
  final to = today.isBefore(period.end) ? today : period.end;
  final totalsFuture = ref.watch(_totalsProvider(from, to).future);
  final marksFuture = ref.watch(_marksProvider(from, to).future);
  final trendFuture = ref.watch(weightTrendProvider.future);
  final workoutsFuture = ref.watch(loggedWorkoutDatesProvider(from, to).future);
  final marks = {for (final m in await marksFuture) m.localDate: m};
  final trend = await trendFuture;
  return RamadanComparison.compute(
    period: period,
    today: today,
    days: [
      for (final t in await totalsFuture)
        (
          date: t.date,
          kcal: t.totals.kcal,
          entryCount: t.entryCount,
          incomplete: marks[t.date]?.incomplete ?? false,
        ),
    ],
    trendOn: trend.trendOn,
    workoutDates: await workoutsFuture,
  );
}

@riverpod
Stream<List<DailyTotals>> _totals(Ref ref, LocalDate from, LocalDate to) =>
    ref.watch(diaryRepositoryProvider).watchDailyTotals(from, to);

@riverpod
Stream<List<DayMark>> _marks(Ref ref, LocalDate from, LocalDate to) =>
    ref.watch(diaryRepositoryProvider).watchDayMarks(from, to);
