import 'package:fb_domain/src/notifications/notification_prefs.dart';
import 'package:fb_domain/src/time/clock.dart';
import 'package:fb_domain/src/time/local_date.dart';
import 'package:fb_domain/src/time/local_time.dart';

/// A wall-clock moment: a date and a minute of that day (0–1439).
typedef LocalMinute = ({LocalDate date, int minute});

/// When a pending proposal's reminder is due (NT-002): the instant (UTC)
/// and its wall-clock minute. See [NotificationState.pendingDue].
typedef PendingDue = ({LocalMinute local, DateTime atUtc});

/// What the planner knows about the user's data (A40 D4). All local; the
/// app reads it from the profile before each plan. Content-free
/// [toString].
final class NotificationState {
  /// The state; every field defaults to "nothing logged".
  new({
    this.mealsToday = 0,
    this.proteinToday = 0,
    this.proteinTargetToday,
    this.todayIncomplete = false,
    this.weekStart = DayOfWeek.saturday,
    Iterable<LocalDate> weighInDates = const [],
    Iterable<LocalDate> measurementDates = const [],
    Map<DayOfWeek, String> plan = const {},
    Iterable<LocalDate> workoutDates = const [],
    Iterable<PendingDue> pendingProposals = const [],
    Iterable<LocalDate> activeDates = const [],
  }) : weighInDates = Set.unmodifiable(weighInDates),
       measurementDates = Set.unmodifiable(measurementDates),
       plan = Map.unmodifiable(plan),
       workoutDates = Set.unmodifiable(workoutDates),
       pendingProposals = List.unmodifiable(pendingProposals),
       activeDates = Set.unmodifiable(activeDates);

  /// Meals (distinct meal slots with entries) logged today (NT-001).
  final int mealsToday;

  /// Protein eaten so far today, in grams (NT-006).
  final double proteinToday;

  /// Today's protein target in grams, or null before setup.
  final double? proteinTargetToday;

  /// Whether today is marked incomplete (DY-004): no protein check then.
  final bool todayIncomplete;

  /// The week's first day (LC-021): the weekly summary's day and the
  /// default weigh-in day.
  final DayOfWeek weekStart;

  /// Days with a weigh-in (NT-023: no weigh-in reminder on such a day).
  final Set<LocalDate> weighInDates;

  /// Days with a body measurement.
  final Set<LocalDate> measurementDates;

  /// The weekly workout plan: planned weekday → template ID (WO-021).
  final Map<DayOfWeek, String> plan;

  /// Days with a logged workout session.
  final Set<LocalDate> workoutDates;

  /// When each pending proposal's reminder is due ([pendingDue]).
  final List<PendingDue> pendingProposals;

  /// The reminder of a proposal created at [createdUtc]: the delay is added
  /// to the instant, then converted with [clock]'s zone, so a DST change in
  /// between never stretches or shrinks it (A40 review 6).
  static PendingDue pendingDue(DateTime createdUtc, Clock clock) {
    final at = createdUtc.toUtc().add(
      const Duration(minutes: NotificationPlanner.pendingDelayMinutes),
    );
    final local = EntryTime.at(at, clock).localDateTime;
    return (
      local: (date: local.date, minute: local.hour * 60 + local.minute),
      atUtc: at,
    );
  }

  /// Days of the last two weeks with any activity (a diary day, a weigh-in
  /// or a session): whether a finished week has a summary to read.
  final Set<LocalDate> activeDates;

  @override
  String toString() => 'NotificationState';
}

/// One notification the planner may keep (A40 D4). The built-in sources
/// make one per type and day; other sources (A41a's Ramadan reminders) pass
/// theirs as `extra` with their own exemptions. Content-free [toString].
final class NotificationCandidate {
  /// A candidate of [type] at [minute] on [date].
  new({
    required this.type,
    required this.date,
    required this.minute,
    this.templateId,
    this.atUtc,
    this.capExempt = false,
    this.quietHoursExempt = false,
  }) {
    if (minute < 0 || minute >= NotificationPrefs.minutesPerDay) {
      throw RangeError.range(minute, 0, 1439, 'minute');
    }
  }

  /// What it is.
  final NotificationType type;

  /// The day it fires.
  final LocalDate date;

  /// The minute of that day.
  final int minute;

  /// The planned template of a workout reminder (its deep link), or null.
  final String? templateId;

  /// The exact instant when known (a pending proposal's reminder, which a
  /// DST overlap would make ambiguous as a wall-clock time); else null.
  final DateTime? atUtc;

  /// Doesn't count toward the daily cap (NT-022: Ramadan reminders).
  final bool capExempt;

  /// Fires in quiet hours too (NT-021: the suhoor reminder).
  final bool quietHoursExempt;

  /// The stable platform ID: one per type and day (A40 D5).
  int get id => type.code * 1000000 + date.epochDay % 1000000;

  @override
  bool operator ==(Object other) =>
      other is NotificationCandidate &&
      other.type == type &&
      other.date == date &&
      other.minute == minute &&
      other.templateId == templateId &&
      other.atUtc == atUtc &&
      other.capExempt == capExempt &&
      other.quietHoursExempt == quietHoursExempt;

  @override
  int get hashCode =>
      Object.hash(type, date, minute, templateId, capExempt, quietHoursExempt);

  @override
  String toString() => 'NotificationCandidate(${type.name}, $date, $minute)';
}

/// Plans the local reminders (`09` §1, TD-013, A40 D4): a pure function from
/// the settings, the clock and the data to the exact notifications that
/// should be scheduled for today and the next days.
abstract final class NotificationPlanner {
  /// Days planned ahead, today included (`09` §1).
  static const int horizonDays = 7;

  /// At most this many notifications a day, Ramadan ones aside (NT-022).
  static const int dailyCap = 2;

  /// The most pending notifications a platform keeps (iOS: 64).
  static const int maxPending = 64;

  /// Minutes after a proposal is created before its reminder (NT-002).
  static const int pendingDelayMinutes = 30;

  /// The protein check fires below this share of the target (NT-006).
  static const double proteinShare = 0.5;

  /// Days before a measurement reminder in which a measurement skips it.
  static const int measurementLookbackDays = 7;

  /// NT-022's order, highest priority first: dropped from the end.
  static const List<NotificationType> priority = [
    NotificationType.pendingProposal,
    NotificationType.weeklySummary,
    NotificationType.weighIn,
    NotificationType.logReminder,
    NotificationType.workout,
    NotificationType.proteinCheck,
    NotificationType.measurement,
  ];

  /// The IDs of today's notifications that still apply (switches, skip
  /// rules, quiet hours; no cap, any time of day). A reminder already due
  /// but not delivered yet (an inexact alarm) is kept only if its ID is
  /// here: one that stopped applying (the second meal logged, the card
  /// resolved, the type switched off) is cancelled, and a prior day's is
  /// never delivered late (A40 review 2).
  static Set<int> applyingToday({
    required NotificationPrefs prefs,
    required LocalDate today,
    required NotificationState state,
    Iterable<NotificationCandidate> extra = const [],
  }) => {
    if (prefs.enabled)
      for (final c in [..._builtIn(prefs, today, state), ...extra])
        if (c.date == today &&
            prefs.of(c.type).enabled &&
            (c.quietHoursExempt || !prefs.isQuiet(c.minute)))
          c.id,
  };

  /// The notifications to schedule, soonest first: for [today] (from after
  /// [nowMinute]) through [horizonDays] days, after the master and type
  /// switches (NT-020), the skip rules (NT-023), quiet hours (NT-021) and
  /// the daily cap by [priority] (NT-022), of which [shownToday] are
  /// already used up today. [extra] candidates (A41a) go through the same
  /// rules with their own exemptions. With [nowUtc], a candidate that knows
  /// its exact instant is kept only if that instant is after it.
  static List<NotificationCandidate> plan({
    required NotificationPrefs prefs,
    required LocalDate today,
    required int nowMinute,
    required NotificationState state,
    int shownToday = 0,
    Iterable<NotificationCandidate> extra = const [],
    DateTime? nowUtc,
  }) {
    if (!prefs.enabled) return const [];
    final last = today.plusDays(horizonDays - 1);
    // A candidate with an exact instant is compared as an instant (a DST
    // overlap repeats wall-clock minutes, A40 review 6); others by minute.
    bool future(NotificationCandidate c) => switch ((c.atUtc, nowUtc)) {
      (final at?, final now?) => at.isAfter(now),
      _ => c.date != today || c.minute > nowMinute,
    };
    bool inHorizon(NotificationCandidate c) =>
        !c.date.isBefore(today) && !c.date.isAfter(last) && future(c);
    final kept = [
      for (final c in [..._builtIn(prefs, today, state), ...extra])
        if (inHorizon(c) &&
            prefs.of(c.type).enabled &&
            (c.quietHoursExempt || !prefs.isQuiet(c.minute)))
          c,
    ];
    final byDate = <LocalDate, List<NotificationCandidate>>{};
    for (final c in kept) {
      (byDate[c.date] ??= []).add(c);
    }
    final planned = <NotificationCandidate>[];
    for (final MapEntry(key: date, value: day) in byDate.entries) {
      final capped = [
        for (final c in day)
          if (!c.capExempt) c,
      ]..sort((a, b) => _rank(a).compareTo(_rank(b)));
      final room = dailyCap - (date == today ? shownToday : 0);
      planned
        ..addAll(day.where((c) => c.capExempt))
        ..addAll(capped.take(room < 0 ? 0 : room));
    }
    planned.sort(
      (a, b) => a.date != b.date
          ? a.date.compareTo(b.date)
          : a.minute != b.minute
          ? a.minute.compareTo(b.minute)
          : _rank(a).compareTo(_rank(b)),
    );
    return planned.length <= maxPending
        ? planned
        : planned.sublist(0, maxPending);
  }

  static int _rank(NotificationCandidate c) {
    final i = priority.indexOf(c.type);
    return i < 0 ? priority.length : i;
  }

  /// One candidate per built-in type and applicable day (NT-023).
  static Iterable<NotificationCandidate> _builtIn(
    NotificationPrefs prefs,
    LocalDate today,
    NotificationState state,
  ) sync* {
    int minute(NotificationType t) => prefs.of(t).minute;
    final weighInDay = prefs.weighInDay ?? state.weekStart;
    for (var i = 0; i < horizonDays; i++) {
      final date = today.plusDays(i);
      final isToday = i == 0;
      // NT-001: only while fewer than 2 meals are logged (future days are
      // assumed to apply; a re-plan cancels today's once it doesn't).
      if (!isToday || state.mealsToday < 2) {
        yield NotificationCandidate(
          type: NotificationType.logReminder,
          date: date,
          minute: minute(NotificationType.logReminder),
        );
      }
      if (date.weekday == weighInDay && !state.weighInDates.contains(date)) {
        yield NotificationCandidate(
          type: NotificationType.weighIn,
          date: date,
          minute: minute(NotificationType.weighIn),
        );
      }
      if (date.weekday == state.weekStart &&
          _weekHadActivity(date, today, state)) {
        yield NotificationCandidate(
          type: NotificationType.weeklySummary,
          date: date,
          minute: minute(NotificationType.weeklySummary),
        );
      }
      final template = state.plan[date.weekday];
      if (template != null && !state.workoutDates.contains(date)) {
        yield NotificationCandidate(
          type: NotificationType.workout,
          date: date,
          minute: minute(NotificationType.workout),
          templateId: template,
        );
      }
      final target = state.proteinTargetToday;
      if (target != null &&
          target > 0 &&
          (!isToday ||
              (!state.todayIncomplete &&
                  state.proteinToday < target * proteinShare))) {
        yield NotificationCandidate(
          type: NotificationType.proteinCheck,
          date: date,
          minute: minute(NotificationType.proteinCheck),
        );
      }
      if (date.day == NotificationPrefs.measurementDayOfMonth &&
          !_measuredRecently(date, state)) {
        yield NotificationCandidate(
          type: NotificationType.measurement,
          date: date,
          minute: minute(NotificationType.measurement),
        );
      }
    }
    // NT-002: 30 minutes after each pending proposal, once (a past time is
    // dropped by the horizon); the earliest per day.
    final earliest = <LocalDate, PendingDue>{};
    for (final due in state.pendingProposals) {
      final current = earliest[due.local.date];
      if (current == null || due.atUtc.isBefore(current.atUtc)) {
        earliest[due.local.date] = due;
      }
    }
    for (final due in earliest.values) {
      yield NotificationCandidate(
        type: NotificationType.pendingProposal,
        date: due.local.date,
        minute: due.local.minute,
        atUtc: due.atUtc,
      );
    }
  }

  /// Whether the week ending the day before [weekStart] has anything to
  /// summarize; a week that isn't over yet is assumed to.
  static bool _weekHadActivity(
    LocalDate weekStart,
    LocalDate today,
    NotificationState state,
  ) {
    // The summary day is after today: its week is still running.
    if (weekStart.isAfter(today)) return true;
    for (
      var d = weekStart.plusDays(-7);
      d.isBefore(weekStart);
      d = d.plusDays(1)
    ) {
      if (state.activeDates.contains(d)) return true;
    }
    return false;
  }

  static bool _measuredRecently(LocalDate date, NotificationState state) {
    for (var i = 0; i < measurementLookbackDays; i++) {
      if (state.measurementDates.contains(date.plusDays(-i))) return true;
    }
    return false;
  }
}
