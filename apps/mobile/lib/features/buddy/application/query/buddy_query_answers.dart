import 'package:fb_domain/fb_domain.dart';
import 'package:fb_mobile/features/body/body.dart';
import 'package:fb_mobile/features/buddy/data/buddy_phone_reads.dart';
import 'package:fb_mobile/features/buddy/data/phone_tools.dart';
import 'package:fb_mobile/features/progress/progress.dart';
import 'package:fb_mobile/features/ramadan/ramadan.dart';
import 'package:fb_mobile/features/settings/settings.dart';
import 'package:fb_mobile/features/targets/targets.dart';
import 'package:fb_mobile/features/workouts/workouts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'buddy_query_answers.g.dart';

/// Answers Buddy's `queryData` calls on the phone (A68 D1–D4): resolves the
/// plan's window (week start, Ramadan and goal-phase anchors), reads only
/// what the plan needs through the features that own the data (the same
/// Progress series as the charts, G10) and lets the [QueryEngine] compute.
/// Read-only; holds user data, never logs.
final class BuddyQueryAnswers implements QueryAnswers {
  /// Reads through [_ref].
  const new(this._ref, this._reads);

  final Ref _ref;
  final BuddyPhoneReads _reads;

  @override
  Future<QueryAnswer?> answer(QueryPlan plan, LocalDate today) async {
    if (!QueryEngine.supports(plan)) return null;
    final calendar = WeekCalendar(
      weekStart: await _read(weekStartProvider.future),
    );
    LocalDate? ramadanStart;
    LocalDate? phaseStart;
    if (plan.period.kind == QueryPeriodKind.since) {
      switch (plan.period.since) {
        case QuerySince.ramadanStart:
          ramadanStart = (await _read(ramadanCalendarProvider.future))
              .lastStartBy(today);
        case QuerySince.phaseStart:
          phaseStart = _phaseStart(
            await _read(targetsDataProvider.future),
            today,
          );
        case QuerySince.date || null:
          break;
      }
    }
    final window = QueryEngine.window(
      plan.period,
      today: today,
      calendar: calendar,
      ramadanStart: ramadanStart,
      phaseStart: phaseStart,
    );
    if (window == null) return null;
    final needs = QueryEngine.needs(plan);
    var data = const QueryData();
    if (needs.contains(QueryInput.days)) {
      data = QueryData(
        days: await _read(progressDaysProvider(window.from, window.to).future),
      );
    }
    if (needs.contains(QueryInput.slotIntake)) {
      final slotIntake = await _slotIntake(plan.filters.slot!, window);
      if (slotIntake == null) return null;
      data = QueryData(days: data.days, slotIntake: slotIntake);
    }
    if (needs.contains(QueryInput.weights)) {
      data = QueryData(
        weights: [
          for (final (date, kg) in await _reads.weights(window.from, window.to))
            (date: date, value: kg),
        ],
      );
    }
    if (needs.contains(QueryInput.trend)) {
      data = QueryData(
        trendOn: (await _read(weightTrendProvider.future)).trendOn,
      );
    }
    if (needs.contains(QueryInput.measurements)) {
      final values = await _measurements(plan.measurementType!);
      if (values == null) return null;
      data = QueryData(values: values);
    }
    if (needs.contains(QueryInput.sessions)) {
      data = QueryData(sessions: await _sessions(window.to));
    }
    return QueryEngine.answer(plan, window: window, data: data);
  }

  /// [provider]'s value, kept alive until it has one (an auto-dispose
  /// provider nobody else watches would be disposed while loading).
  Future<T> _read<T>(ProviderListenable<Future<T>> provider) async {
    final sub = _ref.listen(provider, (_, _) {});
    try {
      return await sub.read();
    } finally {
      sub.close();
    }
  }

  /// The start of the goal phase in effect on [today], or null.
  static LocalDate? _phaseStart(TargetsData data, LocalDate today) {
    LocalDate? start;
    for (final p in data.phases) {
      final phase = p.value;
      if (phase.start.isAfter(today)) continue;
      if (phase.end case final end? when end.isBefore(today)) continue;
      if (start == null || phase.start.isAfter(start)) start = phase.start;
    }
    return start;
  }

  /// The intake per date of the slot named [name] (its ID, name or default
  /// key, ignoring case), or null when no slot has that name.
  Future<Map<LocalDate, IntakeTotals>?> _slotIntake(
    String name,
    QueryWindow window,
  ) async {
    final (entries, slots) = await _reads.diary(window.from, window.to);
    final key = name.trim().toLowerCase();
    final ids = {
      for (final s in slots)
        if ([
          s.id,
          s.name,
          s.defaultKey,
        ].any((n) => n != null && n.trim().toLowerCase() == key))
          s.id,
    };
    if (ids.isEmpty) return null;
    final byDate = <LocalDate, List<DiaryEntry>>{};
    for (final e in entries) {
      if (ids.contains(e.slotId)) (byDate[e.localDate] ??= []).add(e);
    }
    return {
      for (final MapEntry(:key, :value) in byDate.entries)
        key: IntakeTotals.ofEntries(value),
    };
  }

  /// The values of measurement type [type] (a built-in kind code or a
  /// custom type ID), the day's last one per date; null for an unknown
  /// type.
  Future<List<QueryValue>?> _measurements(String type) async {
    final kind = MeasurementKind.fromCode(type);
    final MeasurementTypeRef ref;
    if (kind != null && kind != MeasurementKind.custom) {
      ref = MeasurementTypeRef.builtIn(kind);
    } else if (isUuid(type)) {
      ref = MeasurementTypeRef.custom(type);
    } else {
      return null;
    }
    final data = await _read(measurementsProvider.future);
    final byDate = <LocalDate, double>{
      // Ordered by date and time: the day's last value wins.
      for (final m in data.measurements)
        if (m.type == ref) m.localDate: m.value,
    };
    return [
      for (final MapEntry(:key, :value) in byDate.entries)
        (date: key, value: value),
    ];
  }

  /// Every session up to [to] (PR changes look before the window), with
  /// each exercise's type and primary muscle from the library.
  Future<List<QuerySession>> _sessions(LocalDate to) async {
    final sessions = await _read(allWorkoutSessionsProvider.future);
    final library = await _read(exerciseLibraryProvider.future);
    return [
      for (final s in sessions)
        if (!s.draft.date.isAfter(to))
          (
            id: s.ref.id,
            date: s.draft.date,
            exercises: [
              for (final e in s.draft.exercises)
                (
                  ref: e.exerciseId,
                  type: library.byId[e.exerciseId]?.type,
                  primary: library.byId[e.exerciseId]?.primary,
                  sets: [for (final set in e.sets) set.values],
                ),
            ],
          ),
    ];
  }

  @override
  String toString() => 'BuddyQueryAnswers';
}

/// Buddy's phone tools with the QueryEngine behind `queryData` (A68 D4).
@Riverpod(keepAlive: true)
PhoneTools buddyPhoneTools(Ref ref) {
  final reads = ref.watch(buddyPhoneReadsProvider);
  return PhoneTools(reads, queries: BuddyQueryAnswers(ref, reads));
}
