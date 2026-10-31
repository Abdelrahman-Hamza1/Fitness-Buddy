import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/core/account/profile_generation.dart';
import 'package:fb_mobile/core/time/clock_provider.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/buddy/buddy.dart';
import 'package:fb_mobile/features/diary/diary.dart';
import 'package:fb_mobile/features/notifications/application/notification_scheduler.dart';
import 'package:fb_mobile/features/notifications/data/notification_profile.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notification_inputs.g.dart';

/// Everything one plan needs (A40 D4, D6), read from the profile.
/// Content-free [toString].
final class NotificationInputs {
  /// The inputs.
  const new({
    required this.prefs,
    required this.today,
    required this.calendar,
    required this.state,
    required this.generation,
    required this.profileTag,
  });

  /// The profile generation the inputs were read in (A40 review 1).
  final int generation;

  /// The tag of the profile they belong to (in every payload).
  final String profileTag;

  /// The settings.
  final NotificationPrefs prefs;

  /// The day the state was read for.
  final LocalDate today;

  /// The week calendar (LC-021).
  final WeekCalendar calendar;

  /// The data the skip rules read.
  final NotificationState state;

  @override
  String toString() => 'NotificationInputs($today)';
}

/// Days back the planner looks at (the summary's ended week, the
/// measurement look-back).
const int _lookBackDays = 14;

/// The [NotificationInputs] now: the settings and the local data the rules
/// need. Follows every source, so a logged meal, a weigh-in, a session, a
/// resolved card or a settings change re-plans (A40 D6). Today comes from
/// the clock (the coordinator invalidates this on resume, so a new day or
/// time zone is read). With the master switch off nothing else is read.
@riverpod
Future<NotificationInputs> notificationInputs(Ref ref) async {
  final generation = ref.watch(profileGenerationProvider);
  final clock = ref.watch(clockProvider);
  final today = EntryTime.now(clock).localDate;
  final profileTag = NotificationScheduler.profileTagOf(
    await ref.watch(notificationProfileKeyProvider.future),
  );
  final prefs = await ref.watch(notificationPrefsProvider.future);
  final calendar = WeekCalendar(
    weekStart: await ref.watch(weekStartProvider.future),
  );
  if (!prefs.enabled) {
    return NotificationInputs(
      prefs: prefs,
      today: today,
      calendar: calendar,
      state: NotificationState(weekStart: calendar.weekStart),
      generation: generation,
      profileTag: profileTag,
    );
  }
  final from = today.plusDays(-_lookBackDays);
  final totalsFuture = ref.watch(_totalsProvider(from, today).future);
  final marksFuture = ref.watch(_marksProvider(today).future);
  final targetsFuture = ref.watch(dayTargetsProvider(today).future);
  final weighInsFuture = ref.watch(weighInsProvider.future);
  final measurementsFuture = ref.watch(measurementsProvider.future);
  final planFuture = ref.watch(weeklyPlanProvider.future);
  final workoutsFuture = ref.watch(
    loggedWorkoutDatesProvider(from, today.plusDays(7)).future,
  );
  final pendingFuture = ref.watch(_pendingCardsProvider.future);
  final totals = await totalsFuture;
  final marks = await marksFuture;
  final targets = await targetsFuture;
  final weighIns = await weighInsFuture;
  final measurements = await measurementsFuture;
  final plan = await planFuture;
  final workouts = await workoutsFuture;
  final pending = await pendingFuture;
  final todayTotals = totals.where((t) => t.date == today).firstOrNull;
  final weighInDates = {for (final w in weighIns) w.localDate};
  return NotificationInputs(
    prefs: prefs,
    today: today,
    calendar: calendar,
    generation: generation,
    profileTag: profileTag,
    state: NotificationState(
      mealsToday: todayTotals?.mealCount ?? 0,
      proteinToday: todayTotals?.totals.protein ?? 0,
      proteinTargetToday: targets?.day.macros.proteinGrams,
      todayIncomplete: marks.any((m) => m.localDate == today && m.incomplete),
      weekStart: calendar.weekStart,
      weighInDates: weighInDates,
      measurementDates: {
        for (final m in measurements.measurements) m.localDate,
      },
      plan: plan,
      workoutDates: workouts,
      pendingProposals: [
        for (final p in pending)
          NotificationState.pendingDue(p.createdAt, clock),
      ],
      activeDates: {
        for (final t in totals)
          if (t.entryCount > 0) t.date,
        for (final d in weighInDates)
          if (!d.isBefore(from)) d,
        for (final d in workouts)
          if (!d.isAfter(today)) d,
      },
    ),
  );
}

@riverpod
Stream<List<DailyTotals>> _totals(Ref ref, LocalDate from, LocalDate to) =>
    ref.watch(diaryRepositoryProvider).watchDailyTotals(from, to);

@riverpod
Stream<List<DayMark>> _marks(Ref ref, LocalDate date) =>
    ref.watch(diaryRepositoryProvider).watchDayMarks(date, date);

/// Buddy's pending meal cards (NT-002); the weekly check-in is announced
/// with the summary (NT-004), not as a pending card.
@riverpod
Stream<List<ProposalRecord>> _pendingCards(Ref ref) =>
    ref.watch(proposalRepositoryProvider).watchPending(kind: foodLogKind);
