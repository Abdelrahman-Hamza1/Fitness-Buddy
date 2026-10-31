import 'package:fb_domain/fb_domain.dart';
import 'package:fb_domain/testing.dart';
import 'package:test/test.dart';

// Saturday-start weeks; today is Saturday 31 October 2026 (a week start).
final LocalDate _sat = LocalDate(2026, 10, 31);
final LocalDate _sun = LocalDate(2026, 11, 1); // also the 1st of the month
final LocalDate _mon = LocalDate(2026, 11, 2);

typedef _Row = (NotificationType, LocalDate, int);

const NotificationType _log = NotificationType.logReminder;
const NotificationType _pending = NotificationType.pendingProposal;
const NotificationType _weighIn = NotificationType.weighIn;
const NotificationType _summary = NotificationType.weeklySummary;
const NotificationType _workout = NotificationType.workout;
const NotificationType _protein = NotificationType.proteinCheck;
const NotificationType _measure = NotificationType.measurement;

int _hm(int h, [int m = 0]) => h * 60 + m;

/// A proposal created at [minute] on [date] (UTC zone): its reminder.
PendingDue _created(LocalDate date, int minute) => NotificationState.pendingDue(
  DateTime.utc(date.year, date.month, date.day).add(Duration(minutes: minute)),
  ManualClock(DateTime.utc(2026)),
);

/// Every type on, defaults otherwise.
NotificationPrefs _allOn({
  int quietStart = NotificationPrefs.defaultQuietStart,
  int quietEnd = NotificationPrefs.defaultQuietEnd,
  Map<NotificationType, int> minutes = const {},
  Set<NotificationType> off = const {},
  DayOfWeek? weighInDay,
}) => NotificationPrefs(
  quietStart: quietStart,
  quietEnd: quietEnd,
  weighInDay: weighInDay,
  types: {
    for (final t in NotificationType.values)
      t: NotificationTypePrefs(
        enabled: !off.contains(t),
        minute: minutes[t] ?? t.defaultMinute ?? 0,
      ),
  },
);

/// Only [on] enabled (at their default or [minutes] times).
NotificationPrefs _only(
  Set<NotificationType> on, {
  Map<NotificationType, int> minutes = const {},
  int quietStart = NotificationPrefs.defaultQuietStart,
  int quietEnd = NotificationPrefs.defaultQuietEnd,
  DayOfWeek? weighInDay,
}) => _allOn(
  off: NotificationType.values.toSet().difference(on),
  minutes: minutes,
  quietStart: quietStart,
  quietEnd: quietEnd,
  weighInDay: weighInDay,
);

List<_Row> _plan({
  required NotificationPrefs prefs,
  LocalDate? today,
  int now = 6 * 60,
  NotificationState? state,
  int shown = 0,
  Iterable<NotificationCandidate> extra = const [],
}) => [
  for (final c in NotificationPlanner.plan(
    prefs: prefs,
    today: today ?? _sat,
    nowMinute: now,
    state: state ?? NotificationState(),
    shownToday: shown,
    extra: extra,
  ))
    (c.type, c.date, c.minute),
];

List<_Row> _on(List<_Row> rows, LocalDate date) => [
  for (final r in rows)
    if (r.$2 == date) r,
];

List<_Row> _ofType(List<_Row> rows, NotificationType type) => [
  for (final r in rows)
    if (r.$1 == type) r,
];

void main() {
  group('NT-020 switches and times:', () {
    test('NT-020 the master switch off plans nothing', () {
      expect(_plan(prefs: _allOn().copyWith(enabled: false)), isEmpty);
    });

    test('NT-020 spec/17 defaults on a quiet week: the weigh-in at 08:00 '
        'and the log reminder at 21:00 today; workout, protein and '
        'measurement off', () {
      final rows = _plan(prefs: NotificationPrefs.defaults);
      expect(_on(rows, _sat), [
        (_weighIn, _sat, _hm(8)),
        (_log, _sat, _hm(21)),
      ]);
      expect(
        rows.map((r) => r.$1).toSet(),
        isNot(
          anyOf(contains(_workout), contains(_protein), contains(_measure)),
        ),
      );
      // A log reminder every day of the horizon.
      expect(_ofType(rows, _log), hasLength(NotificationPlanner.horizonDays));
    });

    test('NT-020 each type off removes only that type; a changed time '
        'moves it', () {
      final rows = [
        // (prefs, type, expected minute or null when off)
        (_allOn(off: {_log}), _log, null),
        (_allOn(minutes: {_log: _hm(20, 30)}), _log, _hm(20, 30)),
        (_allOn(off: {_weighIn}), _weighIn, null),
        (_allOn(minutes: {_weighIn: _hm(9, 15)}), _weighIn, _hm(9, 15)),
      ];
      for (final (prefs, type, minute) in rows) {
        final today = _ofType(_on(_plan(prefs: prefs), _sat), type);
        expect(
          today.map((r) => r.$3),
          minute == null ? isEmpty : [minute],
          reason: '$type $minute',
        );
      }
    });
  });

  group('NT-021 quiet hours:', () {
    test('NT-021 a time inside quiet hours is dropped, at the edges kept', () {
      final rows = [
        // (quiet start, quiet end, log reminder minute, kept)
        (_hm(23), _hm(7), _hm(23, 30), false), // crosses midnight: late
        (_hm(23), _hm(7), _hm(6, 59), false), //   early
        (_hm(23), _hm(7), _hm(7), true), //        the end is not quiet
        (_hm(23), _hm(7), _hm(22, 59), true),
        (_hm(23), _hm(7), _hm(23), false), //      the start is quiet
        (_hm(13), _hm(14), _hm(13, 30), false), // same-day window
        (_hm(13), _hm(14), _hm(21), true),
        (_hm(22), _hm(22), _hm(22), true), //      equal: no quiet hours
      ];
      for (final (start, end, minute, kept) in rows) {
        final prefs = _only(
          {_log},
          quietStart: start,
          quietEnd: end,
          minutes: {_log: minute},
        );
        expect(
          _on(_plan(prefs: prefs, now: 0), _mon),
          kept ? [(_log, _mon, minute)] : isEmpty,
          reason: 'quiet $start–$end at $minute',
        );
      }
    });

    test('NT-021 a quiet-hours-exempt candidate (the suhoor hook) fires '
        'in quiet hours; a plain extra does not', () {
      final rows = _plan(
        prefs: _only({_log}),
        extra: [
          NotificationCandidate(
            type: _log,
            date: _mon,
            minute: _hm(4),
            capExempt: true,
            quietHoursExempt: true,
          ),
          NotificationCandidate(type: _log, date: _sun, minute: _hm(4)),
        ],
      );
      expect(rows, contains((_log, _mon, _hm(4))));
      expect(rows, isNot(contains((_log, _sun, _hm(4)))));
    });
  });

  group('NT-022 at most 2 a day by priority:', () {
    // Saturday: weigh-in 08:00, summary 09:00 (last week was active), a
    // pending proposal at 10:00 + 30, the log reminder 21:00, a planned
    // workout 18:00 and the protein check 20:00.
    final busy = NotificationState(
      activeDates: [LocalDate(2026, 10, 28)],
      pendingProposals: [_created(_sat, _hm(10))],
      plan: {DayOfWeek.saturday: 't1'},
      proteinTargetToday: 150,
    );

    test('NT-022 the two highest of pending > summary > weigh-in > log > '
        'workout > protein > measurement are kept, in time order', () {
      final rows = [
        // (types off, the two kept)
        (<NotificationType>{}, [_summary, _pending]),
        ({_pending}, [_weighIn, _summary]),
        ({_pending, _summary}, [_weighIn, _log]),
        ({_pending, _summary, _weighIn}, [_workout, _log]),
        ({_pending, _summary, _weighIn, _log}, [_workout, _protein]),
        ({_pending, _summary, _weighIn, _log, _workout}, [_protein]),
      ];
      for (final (off, kept) in rows) {
        final today = _on(
          _plan(
            prefs: _allOn(off: off),
            state: busy,
          ),
          _sat,
        );
        expect(today.map((r) => r.$1), kept, reason: 'off: $off');
      }
    });

    test('NT-022 measurement is last: protein and workout beat it', () {
      final state = NotificationState(
        plan: {DayOfWeek.sunday: 't1'},
        proteinTargetToday: 150,
      );
      final sunday = _on(
        _plan(prefs: _only({_measure, _protein, _workout}), state: state),
        _sun,
      );
      expect(sunday.map((r) => r.$1), [_workout, _protein]);
    });

    test("NT-022 today's already shown notifications use up slots first; "
        'other days keep both', () {
      final rows = [
        // (shown today, kept today)
        (0, [_summary, _pending]),
        (1, [_pending]),
        (2, <NotificationType>[]),
        (3, <NotificationType>[]),
      ];
      for (final (shown, kept) in rows) {
        final all = _plan(prefs: _allOn(), state: busy, shown: shown);
        expect(_on(all, _sat).map((r) => r.$1), kept, reason: 'shown $shown');
        expect(_on(all, _mon), hasLength(2), reason: 'shown $shown');
      }
    });

    test('NT-022 cap-exempt candidates (Ramadan) do not count', () {
      final rows = _plan(
        prefs: _allOn(),
        state: busy,
        extra: [
          for (final m in [_hm(7, 30), _hm(19), _hm(22)])
            NotificationCandidate(
              type: _log,
              date: _sat,
              minute: m,
              capExempt: true,
            ),
        ],
      );
      final today = _on(rows, _sat);
      expect(today, hasLength(5));
      expect(today.where((r) => r.$1 != _log).map((r) => r.$1), [
        _summary,
        _pending,
      ]);
    });
  });

  group('NT-023 skipped when they do not apply:', () {
    test('NT-001 the log reminder only while fewer than 2 meals are logged '
        'today; later days are assumed to apply', () {
      for (final (meals, today) in [
        (0, true),
        (1, true),
        (2, false),
        (4, false),
      ]) {
        final rows = _plan(
          prefs: _only({_log}),
          state: NotificationState(mealsToday: meals),
        );
        expect(
          _on(rows, _sat),
          today ? [(_log, _sat, _hm(21))] : isEmpty,
          reason: '$meals meals',
        );
        expect(_on(rows, _sun), [(_log, _sun, _hm(21))], reason: '$meals');
      }
    });

    test('NT-003 the weigh-in reminder on the chosen day (the week start '
        'by default), not on a day with a weigh-in', () {
      final rows = [
        // (weigh-in day, weighed dates, expected dates)
        (null, <LocalDate>[], [_sat]),
        (null, [_sat], <LocalDate>[]),
        (DayOfWeek.monday, <LocalDate>[], [_mon]),
        (DayOfWeek.monday, [_sat], [_mon]),
      ];
      for (final (day, weighed, expected) in rows) {
        final plan = _plan(
          prefs: _only({_weighIn}, weighInDay: day),
          state: NotificationState(weighInDates: weighed),
        );
        expect(plan.map((r) => r.$2), expected, reason: '$day $weighed');
      }
    });

    test('NT-004 the weekly summary on the week start only when the week '
        'that ended had activity; a week still running is assumed to', () {
      final rows = [
        // (today, active dates, expected summary dates)
        (_sat, [LocalDate(2026, 10, 30)], [_sat]),
        (_sat, [LocalDate(2026, 10, 24)], [_sat]),
        (_sat, [LocalDate(2026, 10, 23)], <LocalDate>[]), // the week before
        (_sat, <LocalDate>[], <LocalDate>[]),
        (_sun, <LocalDate>[], [LocalDate(2026, 11, 7)]), // next week start
      ];
      for (final (today, active, expected) in rows) {
        final plan = _plan(
          prefs: _only({_summary}),
          today: today,
          state: NotificationState(activeDates: active),
        );
        expect(plan.map((r) => r.$2), expected, reason: '$today $active');
      }
    });

    test('NT-005 the workout reminder on planned weekdays, with the '
        'template, not on a day with a logged session', () {
      final state = NotificationState(
        plan: {DayOfWeek.monday: 'push', DayOfWeek.saturday: 'legs'},
        workoutDates: [_sat],
      );
      final planned = NotificationPlanner.plan(
        prefs: _only({_workout}),
        today: _sat,
        nowMinute: 0,
        state: state,
      );
      expect(planned.map((c) => (c.date, c.templateId)), [(_mon, 'push')]);
      expect(
        _plan(prefs: _only({_workout})),
        isEmpty,
        reason: 'no plan, no workout reminder',
      );
    });

    test('NT-006 the protein check only with a target and under half of it '
        'today, not on a day marked incomplete', () {
      final rows = [
        // (target, eaten, incomplete, today, later days)
        (150.0, 60.0, false, true, true),
        (150.0, 74.9, false, true, true),
        (150.0, 75.0, false, false, true),
        (150.0, 10.0, true, false, true),
        (null, 0.0, false, false, false),
      ];
      for (final (target, eaten, incomplete, today, later) in rows) {
        final rows = _plan(
          prefs: _only({_protein}),
          state: NotificationState(
            proteinTargetToday: target,
            proteinToday: eaten,
            todayIncomplete: incomplete,
          ),
        );
        expect(_on(rows, _sat).isNotEmpty, today, reason: '$target $eaten');
        expect(_on(rows, _mon).isNotEmpty, later, reason: '$target $eaten');
      }
    });

    test('NT-007 the measurement reminder on the 1st, not after a '
        'measurement in the 7 days before', () {
      final rows = [
        // (measured dates, fires on the 1st)
        (<LocalDate>[], true),
        ([LocalDate(2026, 10, 25)], true), // 7 days before: outside
        ([LocalDate(2026, 10, 26)], false),
        ([_sat], false),
      ];
      for (final (measured, fires) in rows) {
        final plan = _plan(
          prefs: _only({_measure}),
          state: NotificationState(measurementDates: measured),
        );
        expect(
          plan,
          fires ? [(_measure, _sun, _hm(9))] : isEmpty,
          reason: '$measured',
        );
      }
    });

    test('NT-002 30 minutes after a pending proposal, once: a past time is '
        'never planned, the earliest per day, quiet hours apply', () {
      final rows = [
        // (created, now, expected)
        ([_created(_sat, _hm(10))], _hm(6), [(_sat, _hm(10, 30))]),
        ([_created(_sat, _hm(5))], _hm(6), <(LocalDate, int)>[]),
        (
          [_created(_sat, _hm(12)), _created(_sat, _hm(11))],
          _hm(6),
          [(_sat, _hm(11, 30))],
        ),
        ([_created(_sat, _hm(22, 50))], _hm(6), <(LocalDate, int)>[]),
        (
          [_created(LocalDate(2026, 10, 30), _hm(23, 45))],
          0,
          <(LocalDate, int)>[], // 00:15 today: quiet
        ),
        (
          [_created(_sat, _hm(10))],
          _hm(10, 30),
          <(LocalDate, int)>[], // exactly now: already due
        ),
      ];
      for (final (created, now, expected) in rows) {
        final plan = _plan(
          prefs: _only({_pending}),
          now: now,
          state: NotificationState(pendingProposals: created),
        );
        expect(plan.map((r) => (r.$2, r.$3)), expected, reason: '$created');
      }
    });
  });

  group('horizon and platform limits:', () {
    test('only today after now and the next 6 days; never a past time', () {
      final rows = _plan(prefs: _only({_log}), now: _hm(21));
      expect(rows.first.$2, _sun);
      expect(rows.last.$2, _sat.plusDays(6));
      expect(rows, hasLength(6));
    });

    test('at most 64 pending (the iOS limit), the soonest kept', () {
      final extra = [
        for (var d = 0; d < 7; d++)
          for (var m = 0; m < 12; m++)
            NotificationCandidate(
              type: _log,
              date: _sat.plusDays(d),
              minute: _hm(8 + m),
              capExempt: true,
            ),
      ];
      final rows = _plan(prefs: _only({_log}), extra: extra, now: 0);
      expect(rows, hasLength(NotificationPlanner.maxPending));
      expect(rows.first, (_log, _sat, _hm(8)));
    });

    test('a candidate has a stable ID per type and day', () {
      final a = NotificationCandidate(type: _log, date: _sat, minute: 1);
      final b = NotificationCandidate(type: _log, date: _sat, minute: 900);
      final c = NotificationCandidate(type: _weighIn, date: _sat, minute: 1);
      final d = NotificationCandidate(type: _log, date: _sun, minute: 1);
      expect(a.id, b.id);
      expect({a.id, c.id, d.id}, hasLength(3));
      expect(a.id, _log.code * 1000000 + _sat.epochDay);
      expect(
        () => NotificationCandidate(type: _log, date: _sat, minute: 1440),
        throwsRangeError,
      );
    });

    test('planning twice with the same input gives the same plan', () {
      final state = NotificationState(
        pendingProposals: [_created(_sat, _hm(10))],
        plan: {DayOfWeek.monday: 't'},
      );
      List<NotificationCandidate> once() => NotificationPlanner.plan(
        prefs: _allOn(),
        today: _sat,
        nowMinute: _hm(6),
        state: state,
      );
      expect(once(), once());
    });
  });

  group('A40 review fixes:', () {
    // Europe/Berlin-like zone: +2 h until 25 Oct 2026 01:00 UTC, then +1 h;
    // +1 h until 29 Mar 2026 01:00 UTC, then +2 h.
    int berlin(DateTime utc) =>
        utc.isBefore(DateTime.utc(2026, 3, 29, 1)) ||
            !utc.isBefore(DateTime.utc(2026, 10, 25, 1))
        ? 60
        : 120;
    final clock = ManualClock(DateTime.utc(2026), zone: berlin);

    test('NT-002 review 6 the 30 minutes are elapsed time across a DST '
        'change: both 01:45 of the fall-back overlap and spring forward', () {
      final rows = [
        // (created UTC, expected local minute, expected instant)
        // 01:45 (+2): due 00:15 UTC = 02:15 +2.
        (
          DateTime.utc(2026, 10, 24, 23, 45),
          _hm(2, 15),
          DateTime.utc(2026, 10, 25, 0, 15),
        ),
        // The first 02:45 of the overlap (+2, 00:45 UTC): due 01:15 UTC =
        // 02:15 +1 (the wall clock went back), 30 minutes later.
        (
          DateTime.utc(2026, 10, 25, 0, 45),
          _hm(2, 15),
          DateTime.utc(2026, 10, 25, 1, 15),
        ),
        // The second 02:45 (+1, 01:45 UTC): due 02:15 UTC = 03:15 +1.
        (
          DateTime.utc(2026, 10, 25, 1, 45),
          _hm(3, 15),
          DateTime.utc(2026, 10, 25, 2, 15),
        ),
        // Spring forward: 01:45 +1 → 01:15 UTC = 03:15 +2.
        (
          DateTime.utc(2026, 3, 29, 0, 45),
          _hm(3, 15),
          DateTime.utc(2026, 3, 29, 1, 15),
        ),
      ];
      for (final (created, minute, at) in rows) {
        final due = NotificationState.pendingDue(created, clock);
        expect(due.atUtc, at, reason: '$created');
        expect(due.atUtc.difference(created), const Duration(minutes: 30));
        expect(due.local.minute, minute, reason: '$created');
      }
      // The candidate carries the exact instant.
      final due = NotificationState.pendingDue(rows.first.$1, clock);
      final planned = NotificationPlanner.plan(
        prefs: _only({_pending}, quietStart: 0, quietEnd: 0),
        today: due.local.date,
        nowMinute: 0,
        state: NotificationState(pendingProposals: [due]),
      );
      expect(planned.single.atUtc, due.atUtc);
    });

    test('NT-023 review 2 applyingToday: what still applies today, at any '
        'time, without the cap; nothing with the master switch off', () {
      final state = NotificationState(
        mealsToday: 1,
        pendingProposals: [_created(_sat, _hm(10))],
        activeDates: [LocalDate(2026, 10, 28)],
      );
      final ids = NotificationPlanner.applyingToday(
        prefs: _allOn(),
        today: _sat,
        state: state,
      );
      int id(NotificationType t) =>
          NotificationCandidate(type: t, date: _sat, minute: 0).id;
      expect(
        ids,
        containsAll([id(_log), id(_pending), id(_weighIn), id(_summary)]),
      );
      // Two meals logged: the log reminder no longer applies.
      expect(
        NotificationPlanner.applyingToday(
          prefs: _allOn(),
          today: _sat,
          state: NotificationState(mealsToday: 2),
        ),
        isNot(contains(id(_log))),
      );
      expect(
        NotificationPlanner.applyingToday(
          prefs: _allOn(off: {_log}),
          today: _sat,
          state: state,
        ),
        isNot(contains(id(_log))),
      );
      expect(
        NotificationPlanner.applyingToday(
          prefs: _allOn().copyWith(enabled: false),
          today: _sat,
          state: state,
        ),
        isEmpty,
      );
    });

    test('NT-002 review 6 (fix-check) during the fall-back overlap a reminder '
        'created at the first 02:45 is due at the second 02:15 and is kept '
        '(compared as instants, not wall-clock minutes)', () {
      final due = NotificationState.pendingDue(
        DateTime.utc(2026, 10, 25, 0, 45), // the first 02:45 (+2)
        clock,
      );
      expect(due.local.minute, _hm(2, 15)); // the second 02:15 (+1)
      final now = DateTime.utc(2026, 10, 25, 0, 50); // 02:50 (+2)
      List<NotificationCandidate> plan({DateTime? nowUtc}) =>
          NotificationPlanner.plan(
            prefs: _only({_pending}, quietStart: 0, quietEnd: 0),
            today: due.local.date,
            nowMinute: _hm(2, 50),
            state: NotificationState(pendingProposals: [due]),
            nowUtc: nowUtc,
          );
      expect(plan(nowUtc: now).single.atUtc, due.atUtc);
      // By wall-clock minutes alone it would look past (135 < 170).
      expect(plan(), isEmpty);
      // Once the instant has passed it is gone.
      expect(plan(nowUtc: due.atUtc), isEmpty);
    });
  });
}
